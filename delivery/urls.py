from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import DeliveryMissionViewSet

router = DefaultRouter()
router.register('missions', DeliveryMissionViewSet, basename='mission')

urlpatterns = [
    path('', include(router.urls)),
]
