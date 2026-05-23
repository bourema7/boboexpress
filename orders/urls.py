from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import OrderViewSet

router = DefaultRouter()
router.register('orders', OrderViewSet, basename='order')

urlpatterns = [
    path('', include(router.urls)),
    # Tracking public: /api/orders/track/<tracking_code>/
    path('track/<str:tracking_code>/', OrderViewSet.as_view({'get': 'track'}), name='order-track'),
]
