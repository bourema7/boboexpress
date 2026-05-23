from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    PaymentTransactionViewSet,
    PlatformRevenueViewSet,
    StoreSettlementViewSet,
    StoreSubscriptionViewSet,
    WalletTransactionViewSet,
)

router = DefaultRouter()
router.register('transactions', PaymentTransactionViewSet, basename='payment')
router.register('wallet', WalletTransactionViewSet, basename='wallet')
router.register('settlements', StoreSettlementViewSet, basename='settlement')
router.register('revenues', PlatformRevenueViewSet, basename='revenue')
router.register('subscriptions', StoreSubscriptionViewSet, basename='subscription')

urlpatterns = [
    path('', include(router.urls)),
]
