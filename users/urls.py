from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    AddressViewSet,
    DriverLocationUpdateView,
    MyProfileView,
    RegisterView,
    UserAdminViewSet,
    ChangePasswordView,
    AvailableDriversView,
    PasswordResetConfirmView,
    PasswordResetRequestView,
)

router = DefaultRouter()
router.register(r'addresses', AddressViewSet, basename='address')
router.register(r'admin/users', UserAdminViewSet, basename='admin-users')

urlpatterns = [
    path('', include(router.urls)),
    path('me/', MyProfileView.as_view(), name='my-profile'),
    path('available-drivers/', AvailableDriversView.as_view(), name='available-drivers'),
    path('driver/location/', DriverLocationUpdateView.as_view(), name='driver-location'),
    path('change-password/', ChangePasswordView.as_view(), name='change-password'),
    path('password-reset/request/', PasswordResetRequestView.as_view(), name='password-reset-request'),
    path('password-reset/confirm/', PasswordResetConfirmView.as_view(), name='password-reset-confirm'),
]
