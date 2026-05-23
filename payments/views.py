from django.db import transaction
from django.db.models import Sum, F
from django.utils import timezone
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import PaymentTransaction, PlatformRevenue, StoreSettlement, StoreSubscription, WalletTransaction
from .serializers import (
    PaymentTransactionSerializer,
    PlatformRevenueSerializer,
    StoreSettlementSerializer,
    StoreSubscriptionSerializer,
    WalletTopUpSerializer,
    WalletTransactionSerializer,
)


class PaymentTransactionViewSet(viewsets.ModelViewSet):
    queryset = PaymentTransaction.objects.select_related('user', 'order').all()
    serializer_class = PaymentTransactionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_staff:
            return self.queryset
        return self.queryset.filter(user=user)


class WalletTransactionViewSet(viewsets.ReadOnlyModelViewSet):
    """Historique des transactions wallet de l'utilisateur connecté."""
    queryset = WalletTransaction.objects.select_related('user').all()
    serializer_class = WalletTransactionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return self.queryset.filter(user=self.request.user)

    @action(detail=False, methods=['get'])
    def balance(self, request):
        """Solde wallet actuel."""
        profile = getattr(request.user, 'profile', None)
        return Response({'balance': float(profile.wallet_balance) if profile else 0, 'currency': 'XOF'})

    @action(detail=False, methods=['post'])
    def top_up(self, request):
        """Recharger le wallet (simulation)."""
        serializer = WalletTopUpSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        amount = serializer.validated_data['amount']
        profile = getattr(request.user, 'profile', None)
        if not profile:
            return Response({'detail': 'Profil introuvable.'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Calcul simple
        profile.wallet_balance += amount
        profile.save()
        
        WalletTransaction.objects.create(
            user=request.user,
            amount=amount,
            type='credit',
            source='top_up',
            description=f'Rechargement via {serializer.validated_data["payment_method"]}',
            balance_after=profile.wallet_balance,
        )
        return Response({'detail': f'{amount} XOF crédité.', 'new_balance': float(profile.wallet_balance)})


class StoreSettlementViewSet(viewsets.ModelViewSet):
    """Reversements aux commerçants — Admin uniquement."""
    queryset = StoreSettlement.objects.select_related('store').all()
    serializer_class = StoreSettlementSerializer
    permission_classes = [permissions.IsAdminUser]

    @action(detail=True, methods=['post'])
    def mark_paid(self, request, pk=None):
        """Marquer un reversement comme payé."""
        settlement = self.get_object()
        ref = request.data.get('payment_reference', '')
        settlement.status = 'paid'
        settlement.payment_reference = ref
        settlement.paid_at = timezone.now()
        settlement.save()
        return Response(StoreSettlementSerializer(settlement).data)

    @action(detail=False, methods=['post'])
    def generate(self, request):
        """Générer les reversements pour une boutique ou toutes les boutiques."""
        from django.db.models import F, ExpressionWrapper, DecimalField
        from orders.models import Order
        from stores.models import Store
        import datetime

        period = request.data.get('period', 'weekly')
        store_id = request.data.get('store_id')
        today = timezone.now().date()
        if period == 'weekly':
            period_start = today - datetime.timedelta(days=7)
        else:
            period_start = today - datetime.timedelta(days=30)

        stores = Store.objects.filter(is_active=True, is_approved=True)
        if store_id:
            stores = stores.filter(id=store_id)

        created = []
        for store in stores:
            orders = Order.objects.filter(
                store=store,
                status='delivered',
                created_at__date__gte=period_start,
                created_at__date__lte=today,
            )
            gross = orders.aggregate(total=Sum('subtotal'))['total'] or 0
            commission = float(gross) * float(store.commission_rate) / 100
            net = float(gross) - commission
            if gross > 0:
                s = StoreSettlement.objects.create(
                    store=store,
                    period=period,
                    period_start=period_start,
                    period_end=today,
                    gross_amount=gross,
                    commission_amount=commission,
                    net_amount=net,
                )
                created.append(s.id)
        return Response({'detail': f'{len(created)} reversements créés.', 'settlement_ids': created})


class PlatformRevenueViewSet(viewsets.ReadOnlyModelViewSet):
    """Revenus de la plateforme — Admin uniquement."""
    queryset = PlatformRevenue.objects.select_related('order', 'store').all()
    serializer_class = PlatformRevenueSerializer
    permission_classes = [permissions.IsAdminUser]

    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Résumé des revenus par source."""
        summary = PlatformRevenue.objects.values('source').annotate(total=Sum('amount'))
        total = PlatformRevenue.objects.aggregate(total=Sum('amount'))['total'] or 0
        return Response({'by_source': list(summary), 'grand_total': total, 'currency': 'XOF'})


class StoreSubscriptionViewSet(viewsets.ModelViewSet):
    """Abonnements premium boutiques."""
    queryset = StoreSubscription.objects.select_related('store').all()
    serializer_class = StoreSubscriptionSerializer
    permission_classes = [permissions.IsAdminUser]
