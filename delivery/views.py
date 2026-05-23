from django.db import transaction
from django.db.models import F
from django.utils import timezone
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response

from notifications.models import NotificationLog
from orders.models import Order, OrderStatusHistory
from users.models import UserProfile
from .models import DeliveryMission
from .serializers import (
    DeliveryMissionSerializer,
    LocationUpdateSerializer,
    OTPConfirmSerializer,
    ProofUploadSerializer,
)





class DeliveryMissionViewSet(viewsets.ReadOnlyModelViewSet):
    """Gestion des missions de livraison."""
    serializer_class = DeliveryMissionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        profile = getattr(user, 'profile', None)
        if user.is_staff:
            return DeliveryMission.objects.select_related(
                'driver__user', 'order__buyer__profile', 'order__store', 'order__address'
            ).all()
        if profile and profile.role == 'delivery':
            return DeliveryMission.objects.filter(driver=profile).select_related(
                'driver__user', 'order__buyer__profile', 'order__store', 'order__address'
            )
        raise PermissionDenied('Accès réservé aux livreurs et administrateurs.')

    # ─── Étape 1 : Accepter la mission ───────────────────────────────────────
    @action(detail=True, methods=['post'])
    def accept(self, request, pk=None):
        mission = self.get_object()
        self._check_driver(request, mission)
        if mission.status != 'assigned':
            return Response({'detail': 'La mission n\'est pas en attente d\'acceptation.'}, status=status.HTTP_400_BAD_REQUEST)
        mission.status = 'accepted'
        mission.accepted_at = timezone.now()
        # Calculer le gain
        mission.driver_earning = mission.calculate_earning()
        mission.save()
        return Response(DeliveryMissionSerializer(mission).data)

    # ─── Étape 2 : Livreur se dirige vers la boutique ────────────────────────
    @action(detail=True, methods=['post'])
    def start_pickup(self, request, pk=None):
        mission = self.get_object()
        self._check_driver(request, mission)
        if mission.status not in ('accepted',):
            return Response({'detail': 'Mission non acceptée.'}, status=status.HTTP_400_BAD_REQUEST)
        mission.status = 'picking_up'
        mission.save()
        return Response(DeliveryMissionSerializer(mission).data)

    # ─── Étape 3 : Livreur récupère le colis ─────────────────────────────────
    @action(detail=True, methods=['post'])
    def confirm_pickup(self, request, pk=None):
        mission = self.get_object()
        self._check_driver(request, mission)
        if mission.status != 'picking_up':
            return Response({'detail': 'Statut invalide pour cette action.'}, status=status.HTTP_400_BAD_REQUEST)
        mission.status = 'picked_up'
        mission.picked_up_at = timezone.now()
        mission.save()
        mission.order.status = 'shipping'
        mission.order.save()
        OrderStatusHistory.objects.create(order=mission.order, status='shipping', created_by=request.user)
        return Response(DeliveryMissionSerializer(mission).data)

    # ─── Étape 4 : Livreur démarre la livraison ───────────────────────────────
    @action(detail=True, methods=['post'])
    def start_delivery(self, request, pk=None):
        mission = self.get_object()
        self._check_driver(request, mission)
        if mission.status != 'picked_up':
            return Response({'detail': 'Statut invalide.'}, status=status.HTTP_400_BAD_REQUEST)
        mission.status = 'on_route'
        mission.save()
        return Response(DeliveryMissionSerializer(mission).data)

    # ─── Étape 5 : Confirmation par OTP ──────────────────────────────────────
    @transaction.atomic
    @action(detail=True, methods=['post'])
    def confirm_otp(self, request, pk=None):
        mission = self.get_object()
        self._check_driver(request, mission)
        serializer = OTPConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        otp = serializer.validated_data['otp_code']
        if mission.order.delivery_otp != otp:
            return Response({'detail': 'Code OTP incorrect.'}, status=status.HTTP_400_BAD_REQUEST)
        if mission.status not in ('on_route', 'picked_up'):
            return Response({'detail': 'OTP non applicable à ce stade.'}, status=status.HTTP_400_BAD_REQUEST)
        # Marquer comme livrée
        mission.status = 'delivered'
        mission.delivered_at = timezone.now()
        mission.save()
        mission.order.status = 'delivered'
        mission.order.save()
        OrderStatusHistory.objects.create(order=mission.order, status='delivered', created_by=request.user, note='Confirmé par OTP')
        # Créditer le livreur (Calcul simple)
        driver_profile = mission.driver
        driver_profile.wallet_balance += mission.driver_earning
        driver_profile.total_deliveries += 1
        driver_profile.save()
        return Response(DeliveryMissionSerializer(mission).data)

    # ─── Upload preuve photo ──────────────────────────────────────────────────
    @action(detail=True, methods=['post'])
    def upload_proof(self, request, pk=None):
        mission = self.get_object()
        self._check_driver(request, mission)
        serializer = ProofUploadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        if serializer.validated_data.get('proof_photo_url'):
            mission.proof_photo_url = serializer.validated_data['proof_photo_url']
        if serializer.validated_data.get('signature_data'):
            mission.signature_data = serializer.validated_data['signature_data']
        mission.save()
        return Response({'detail': 'Preuve enregistrée.', 'proof_photo_url': mission.proof_photo_url})


    # ─── Mise à jour GPS en temps réel (par mission ID) ────────────────────────
    @action(detail=True, methods=['post'])
    def update_location(self, request, pk=None):
        mission = self.get_object()
        self._check_driver(request, mission)
        serializer = LocationUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        mission.current_lat = serializer.validated_data['latitude']
        mission.current_lng = serializer.validated_data['longitude']
        if serializer.validated_data.get('estimated_duration') is not None:
            mission.estimated_duration = serializer.validated_data['estimated_duration']
        mission.save(update_fields=['current_lat', 'current_lng', 'estimated_duration'])
        # Aussi mettre à jour le profil du livreur
        mission.driver.current_lat = mission.current_lat
        mission.driver.current_lng = mission.current_lng
        mission.driver.save(update_fields=['current_lat', 'current_lng'])
        return Response({
            'detail': 'Position mise à jour.',
            'latitude': str(mission.current_lat),
            'longitude': str(mission.current_lng),
            'estimated_duration': mission.estimated_duration,
        })

    # ─── Signaler un échec ────────────────────────────────────────────────────
    @action(detail=True, methods=['post'])
    def report_failure(self, request, pk=None):
        mission = self.get_object()
        self._check_driver(request, mission)
        reason = request.data.get('reason', 'Client absent')
        mission.status = 'failed'
        mission.save()
        return Response({'detail': 'Échec signalé.'})

    # ─── Mes missions actives ─────────────────────────────────────────────────
    @action(detail=False, methods=['get'])
    def my_active(self, request):
        profile = getattr(request.user, 'profile', None)
        if not profile or profile.role != 'delivery':
            raise PermissionDenied('Réservé aux livreurs.')
        missions = DeliveryMission.objects.filter(
            driver=profile,
            status__in=['assigned', 'accepted', 'picking_up', 'picked_up', 'on_route']
        ).select_related('order__buyer', 'order__store', 'order__address')
        return Response(DeliveryMissionSerializer(missions, many=True).data)

    # ─── Historique missions ──────────────────────────────────────────────────
    @action(detail=False, methods=['get'])
    def history(self, request):
        profile = getattr(request.user, 'profile', None)
        if not profile or profile.role != 'delivery':
            raise PermissionDenied('Réservé aux livreurs.')
        missions = DeliveryMission.objects.filter(
            driver=profile,
            status__in=['delivered', 'failed', 'cancelled']
        ).select_related('order__buyer', 'order__store')
        return Response(DeliveryMissionSerializer(missions, many=True).data)

    def _check_driver(self, request, mission):
        profile = getattr(request.user, 'profile', None)
        if not request.user.is_staff:
            if not profile or profile.role != 'delivery' or mission.driver != profile:
                raise PermissionDenied('Réservé au livreur assigné.')
