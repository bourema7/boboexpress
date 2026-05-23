from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response

from notifications.models import NotificationLog
from users.models import UserProfile
from .models import Order, OrderStatusHistory
from .serializers import OrderSerializer, OrderTrackingSerializer
from delivery.models import DeliveryMission
import math


def haversine_distance(lat1, lon1, lat2, lon2):
    """Calcule la distance en km entre deux coordonnées GPS."""
    R = 6371
    phi1, phi2 = math.radians(float(lat1)), math.radians(float(lat2))
    dphi = math.radians(float(lat2) - float(lat1))
    dlambda = math.radians(float(lon2) - float(lon1))
    a = math.sin(dphi/2)**2 + math.cos(phi1)*math.cos(phi2)*math.sin(dlambda/2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


class OrderViewSet(viewsets.ModelViewSet):
    queryset = Order.objects.select_related('buyer', 'store', 'address', 'promo_code').prefetch_related(
        'items__product', 'items__variant', 'status_history', 'delivery_mission'
    ).all()
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        profile = getattr(user, 'profile', None)
        from django.db.models import Q
        
        # Base: commandes achetées par l'utilisateur
        query = Q(buyer=user)
        
        # Admin ou Staff : Vue globale sur tout
        if user.is_staff or (profile and profile.role == 'admin'):
            return self.queryset.order_by('-id')
            
        # Ajouter les commandes où il est vendeur
        if profile and profile.role == 'seller':
            query |= Q(store__owner=profile)
            
        # Ajouter les commandes où il est livreur
        if profile and profile.role == 'delivery':
            # Pour le livreur, on montre ses livraisons passées et présentes
            query |= Q(deliverer=user)
            # On peut aussi ajouter les commandes disponibles à ramasser
            query |= Q(status__in=['confirmed', 'preparing', 'ready'], deliverer__isnull=True)
            
        return self.queryset.filter(query).distinct().order_by('-id')

    def perform_create(self, serializer):
        # La boutique est dérivée des articles dans le serializer
        serializer.save()

    def _notify(self, user, title, message, channel='inapp', notif_type='info', order=None):
        NotificationLog.objects.create(
            user=user, title=title, message=message, channel=channel,
            notification_type=notif_type,
            related_order=order,
        )

    def _add_status_history(self, order, new_status, user, note=''):
        OrderStatusHistory.objects.create(order=order, status=new_status, created_by=user, note=note)

    def _assign_delivery(self, order):
        """Attribution automatique du livreur par proximité GPS."""
        store = order.store
        # Chercher livreurs disponibles non occupés
        available_drivers = UserProfile.objects.filter(
            role='delivery',
            is_available=True,
            is_blocked=False,
        ).exclude(missions__status__in=['assigned', 'accepted', 'picking_up', 'picked_up', 'on_route'])

        best_driver = None
        min_distance = float('inf')

        if store.latitude and store.longitude:
            for driver in available_drivers:
                if driver.current_lat and driver.current_lng:
                    dist = haversine_distance(driver.current_lat, driver.current_lng, store.latitude, store.longitude)
                    if dist < min_distance:
                        min_distance = dist
                        best_driver = driver
        if not best_driver:
            best_driver = available_drivers.order_by('?').first()

        if best_driver:
            mission, _ = DeliveryMission.objects.get_or_create(order=order, defaults={
                'driver': best_driver,
                'status': 'assigned',
                'pickup_lat': store.latitude,
                'pickup_lng': store.longitude,
                'dropoff_lat': order.address.latitude if order.address else None,
                'dropoff_lng': order.address.longitude if order.address else None,
                'distance_km': round(min_distance, 2) if min_distance != float('inf') else 0,
            })
            return mission
        return None

    @action(detail=True, methods=['post'])
    def accept(self, request, pk=None):
        """Commerçant accepte la commande."""
        order = self.get_object()
        profile = getattr(request.user, 'profile', None)
        # Autoriser si vendeur propriétaire OU si admin
        is_owner = profile and profile.role == 'seller' and order.store.owner == profile
        is_admin = request.user.is_staff or (profile and profile.role == 'admin')
        
        if not (is_owner or is_admin):
            raise PermissionDenied('Permissions insuffisantes pour accepter cette commande.')
        order.status = 'confirmed'
        order.save()
        self._add_status_history(order, 'confirmed', request.user)
        self._notify(order.buyer, '✅ Commande confirmée',
                     f'Votre commande {order.tracking_code} a été acceptée par {order.store.name}.',
                     notif_type='order_confirmed', order=order)
        mission = self._assign_delivery(order)
        if mission:
            self._notify(mission.driver.user, '🚴 Nouvelle mission',
                         f'Mission assignée pour {order.tracking_code}. Gain: {mission.driver_earning} XOF.',
                         notif_type='new_mission', order=order)
        return Response(self.get_serializer(order).data)

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        """Commerçant refuse la commande."""
        order = self.get_object()
        profile = getattr(request.user, 'profile', None)
        is_owner = profile and profile.role == 'seller' and order.store.owner == profile
        is_admin = request.user.is_staff or (profile and profile.role == 'admin')
        
        if not (is_owner or is_admin):
            raise PermissionDenied('Permissions insuffisantes pour rejeter cette commande.')
        reason = request.data.get('reason', '')
        order.status = 'cancelled'
        order.save()
        self._add_status_history(order, 'cancelled', request.user, note=reason)
        self._notify(order.buyer, '❌ Commande refusée',
                     f'La commande {order.tracking_code} a été refusée. Raison: {reason}',
                     notif_type='order_cancelled', order=order)
        return Response(self.get_serializer(order).data)

    @action(detail=True, methods=['post'])
    def mark_preparing(self, request, pk=None):
        """Commerçant marque la commande en préparation."""
        order = self.get_object()
        profile = getattr(request.user, 'profile', None)
        is_owner = profile and profile.role == 'seller' and order.store.owner == profile
        is_admin = request.user.is_staff or (profile and profile.role == 'admin')
        
        if not (is_owner or is_admin):
            raise PermissionDenied('Accès refusé.')
        order.status = 'preparing'
        order.save()
        self._add_status_history(order, 'preparing', request.user)
        self._notify(order.buyer, '👨‍🍳 En préparation',
                     f'Votre commande {order.tracking_code} est en cours de préparation.',
                     notif_type='preparing', order=order)
        return Response(self.get_serializer(order).data)

    @action(detail=True, methods=['post'])
    def mark_ready(self, request, pk=None):
        """Commerçant marque la commande prête pour livraison."""
        order = self.get_object()
        profile = getattr(request.user, 'profile', None)
        is_owner = profile and profile.role == 'seller' and order.store.owner == profile
        is_admin = request.user.is_staff or (profile and profile.role == 'admin')
        
        if not (is_owner or is_admin):
            raise PermissionDenied('Accès refusé.')
        order.status = 'ready'
        order.save()
        self._add_status_history(order, 'ready', request.user)
        self._notify(order.buyer, '📦 Commande prête',
                     f'Votre commande {order.tracking_code} est prête. Un livreur arrive bientôt.',
                     notif_type='order_ready', order=order)
        # Notifier le livreur assigné
        mission = getattr(order, 'delivery_mission', None)
        if mission:
            self._notify(mission.driver.user, '📦 Commande prête à récupérer',
                         f'La commande {order.tracking_code} est prête. Rendez-vous chez {order.store.name}.',
                         notif_type='pickup_ready', order=order)
        return Response(self.get_serializer(order).data)

    @action(detail=True, methods=['post'])
    def mark_shipping(self, request, pk=None):
        """Marque la commande en livraison (déclenche le GPS côté client)."""
        order = self.get_object()
        profile = getattr(request.user, 'profile', None)
        is_owner = profile and profile.role == 'seller' and order.store.owner == profile
        is_admin = request.user.is_staff or (profile and profile.role == 'admin')
        is_driver = order.deliverer == request.user
        can_take = profile and profile.role == 'delivery' and order.deliverer is None
        
        if not (is_owner or is_admin or is_driver or can_take):
            raise PermissionDenied('Accès refusé.')
        
        if order.status not in ['ready', 'confirmed', 'preparing']:
            return Response({'detail': f'Impossible depuis le statut actuel: {order.status}'}, status=400)
        
        if can_take:
            order.deliverer = request.user
            
        order.status = 'shipping'
        # Position GPS de départ simulée (boutique)
        if order.store and order.store.latitude:
            order.current_latitude = order.store.latitude
            order.current_longitude = order.store.longitude
        else:
            order.current_latitude = 11.18
            order.current_longitude = -4.29
        order.save()
        self._add_status_history(order, 'shipping', request.user, note='Expédition lancée')
        self._notify(order.buyer, '🏍️ Colis en route !',
                     f'Votre commande {order.tracking_code} est en livraison. Suivez votre livreur en temps réel !',
                     notif_type='new_mission', order=order)
        return Response(self.get_serializer(order).data)

    @action(detail=True, methods=['post'])
    def assign_driver(self, request, pk=None):
        """Admin ou Vendeur assigne manuellement un livreur."""
        order = self.get_object()
        profile = getattr(request.user, 'profile', None)
        
        # Autoriser Admin OU Vendeur proprio de la boutique OU Acheteur (si c'est sa commande)
        is_owner = profile and profile.role == 'seller' and order.store.owner == profile
        is_admin = request.user.is_staff or (profile and profile.role == 'admin')
        is_buyer = order.buyer == request.user
        
        if not (is_owner or is_admin or is_buyer):
            raise PermissionDenied('Permissions insuffisantes pour assigner un livreur.')

        driver_id = request.data.get('driver_id')
        if not driver_id:
            return Response({'detail': 'driver_id requis.'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            # Note: driver_id refers to UserProfile.id
            driver_profile = UserProfile.objects.get(id=driver_id, role='delivery')
            driver = driver_profile.user
        except UserProfile.DoesNotExist:
            return Response({'detail': 'Livreur introuvable.'}, status=status.HTTP_404_NOT_FOUND)
        
        # Assigner le livreur à la commande
        order.deliverer = driver
        if order.status == 'pending':
            order.status = 'confirmed'
        order.save()
        
        # Créer/Mettre à jour la mission de livraison
        mission, created = DeliveryMission.objects.get_or_create(order=order, defaults={
            'driver': driver_profile,
            'status': 'assigned',
            'pickup_lat': order.store.latitude,
            'pickup_lng': order.store.longitude,
            'dropoff_lat': order.address.latitude if order.address else None,
            'dropoff_lng': order.address.longitude if order.address else None,
        })
        if not created:
            mission.driver = driver_profile
            mission.status = 'assigned'
            mission.save()

        self._add_status_history(order, order.status, request.user, note=f'Livreur assigné : {driver.username}')
        
        self._notify(driver, '🚴 Nouvelle mission assignée',
                     f'Le marchand {order.store.name} vous a choisi pour la commande {order.tracking_code}.',
                     notif_type='new_mission', order=order)
        
        return Response(self.get_serializer(order).data)

    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        """Annuler une commande (Client, Vendeur ou Admin)."""
        order = self.get_object()
        user = request.user
        profile = getattr(user, 'profile', None)
        
        is_buyer = order.buyer == user
        is_seller = profile and profile.role == 'seller' and order.store.owner == profile
        is_admin = user.is_staff or (profile and profile.role == 'admin')
        
        if not (is_buyer or is_seller or is_admin):
            raise PermissionDenied('Permissions insuffisantes pour annuler cette commande.')

        # Règles d'annulation selon l'état
        if order.status in ['shipping', 'delivered']:
            return Response({'detail': 'Impossible d\'annuler : commande déjà en cours de livraison ou livrée.'}, 
                            status=status.HTTP_400_BAD_REQUEST)
        
        if is_buyer and order.status not in ['pending', 'confirmed']:
            return Response({'detail': 'Le client ne peut annuler que si la commande n\'est pas encore en préparation.'}, 
                            status=status.HTTP_400_BAD_REQUEST)

        order.status = 'cancelled'
        order.save()
        
        # Annuler la mission si elle existe
        DeliveryMission.objects.filter(order=order).update(status='cancelled')

        self._add_status_history(order, 'cancelled', user, note=f'Annulée par {user.username}')
        
        # Notifications
        if is_buyer:
            self._notify(order.store.owner.user, '❌ Commande annulée par le client',
                         f'La commande {order.tracking_code} a été annulée par l\'acheteur.')
        else:
            self._notify(order.user, '❌ Commande annulée',
                         f'Votre commande {order.tracking_code} a été annulée par le marchand.')
        
        return Response(self.get_serializer(order).data)

    @action(detail=False, methods=['get'], url_path='track/(?P<tracking_code>[^/.]+)', permission_classes=[permissions.AllowAny])
    def track(self, request, tracking_code=None):
        """Suivi public d'une commande par code de tracking."""
        try:
            order = Order.objects.select_related(
                'store', 'delivery_mission__driver'
            ).prefetch_related('status_history').get(tracking_code=tracking_code)
        except Order.DoesNotExist:
            return Response({'detail': 'Commande introuvable.'}, status=status.HTTP_404_NOT_FOUND)
        return Response(OrderTrackingSerializer(order).data)

    @action(detail=True, methods=['post'])
    def init_payment(self, request, pk=None):
        """Initialise un paiement Mobile Money avec détails opérateur."""
        order = self.get_object()
        if order.payment_status == 'paid':
            return Response({'detail': 'Cette commande est déjà payée.'}, status=status.HTTP_400_BAD_REQUEST)
        
        momo_type = request.data.get('momo_type', 'orange') # 'orange' ou 'moov'
        
        # Simulation d'un ID de transaction unique par opérateur
        prefix = "OM" if momo_type == 'orange' else "MM"
        import random
        import string
        suffix = ''.join(random.choices(string.digits, k=8))
        transaction_id = f"{prefix}.{suffix}"
        
        order.transaction_id = transaction_id
        order.payment_status = 'pending'
        order.save()

        return Response({
            'transaction_id': transaction_id,
            'merchant_momo': order.store.momo_number,
            'merchant_momo_type': momo_type,
            'merchant_name': order.store.name,
            'amount': order.total_amount,
            'customer_phone': order.buyer.profile.phone,
            'message': f"Paiement {momo_type.upper()} Money initialisé. Un message de confirmation a été envoyé au {order.buyer.profile.phone}."
        })

    @action(detail=True, methods=['post'])
    def confirm_payment(self, request, pk=None):
        """Valide le paiement et met à jour l'état de la commande."""
        order = self.get_object()
        
        # Dans un vrai système, on vérifierait ici le statut via l'API de l'opérateur
        order.payment_status = 'paid'
        if order.status == 'pending':
            order.status = 'confirmed'
        order.save()
        
        self._add_status_history(order, 'confirmed', order.buyer, note=f"Paiement Mobile Money ({order.transaction_id}) validé avec succès.")
        
        # Notifier le marchand
        self._notify(order.store.owner.user, '💰 Paiement reçu !', 
                     f'Le paiement de {order.total_amount} XOF pour la commande {order.tracking_code} a été versé sur votre compte {order.store.momo_number}.',
                     notif_type='payment_received', order=order)
        
        return Response({
            'status': 'success',
            'message': 'Paiement validé avec succès.',
            'order_status': order.status
        })

    @action(detail=True, methods=['post'])
    def update_location(self, request, pk=None):
        """Mise à jour GPS de la position du colis (utilisé par le livreur)."""
        order = self.get_object()
        profile = getattr(request.user, 'profile', None)
        lat = request.data.get('latitude')
        lng = request.data.get('longitude')
        
        is_owner = profile and profile.role == 'seller' and order.store.owner == profile
        is_admin = request.user.is_staff or (profile and profile.role == 'admin')
        is_driver = order.deliverer == request.user
        
        if not (is_owner or is_admin or is_driver):
            raise PermissionDenied('Accès refusé.')

        if not lat or not lng:
            return Response({'detail': 'latitude et longitude requis.'}, status=status.HTTP_400_BAD_REQUEST)
        
        order.current_latitude = lat
        order.current_longitude = lng
        order.save()
        return Response({'status': 'Position mise à jour'})

    @action(detail=True, methods=['post'])
    def verify_otp(self, request, pk=None):
        """Finaliser la livraison avec le code OTP fourni par le client."""
        order = self.get_object()
        profile = getattr(request.user, 'profile', None)
        
        is_owner = profile and profile.role == 'seller' and order.store.owner == profile
        is_admin = request.user.is_staff or (profile and profile.role == 'admin')
        is_driver = order.deliverer == request.user
        
        if not (is_owner or is_admin or is_driver):
            raise PermissionDenied('Accès refusé.')

        otp = request.data.get('otp')
        if not otp:
            return Response({'detail': 'Code OTP requis.'}, status=status.HTTP_400_BAD_REQUEST)
        
        if order.delivery_otp != otp:
            return Response({'detail': 'Code OTP incorrect.'}, status=status.HTTP_400_BAD_REQUEST)
        
        order.status = 'delivered'
        order.save()
        self._add_status_history(order, 'delivered', request.user, note='Livraison confirmée par OTP')
        
        # Notifier le client
        self._notify(order.buyer, '🏁 Livraison terminée',
                     f'Merci d\'avoir utilisé BoboExpress ! Votre commande {order.tracking_code} a été livrée.',
                     notif_type='delivered', order=order)
        
        return Response({'status': 'Livraison confirmée', 'order_status': 'delivered'})

