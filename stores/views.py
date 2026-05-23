from django.utils import timezone
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response

from .models import Promotion, Store, StoreCategory
from .serializers import PromotionSerializer, StoreCategorySerializer, StoreSerializer


class StoreViewSet(viewsets.ModelViewSet):
    queryset = Store.objects.select_related('category', 'owner__user').all()
    serializer_class = StoreSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        qs = super().get_queryset()
        if not self.request.user.is_staff:
            # Les utilisateurs normaux ne voient que les boutiques actives et approuvées,
            # sauf s'ils en sont le propriétaire
            profile = getattr(self.request.user, 'profile', None)
            if profile and profile.role == 'seller':
                qs = qs.filter(models.Q(is_active=True, is_approved=True) | models.Q(owner=profile))
            else:
                qs = qs.filter(is_active=True, is_approved=True)
        return qs

    def perform_create(self, serializer):
        profile = getattr(self.request.user, 'profile', None)
        if profile is None or profile.role != 'seller':
            raise PermissionDenied('Seuls les vendeurs peuvent créer une boutique.')
        serializer.save(owner=profile)

    def perform_update(self, serializer):
        profile = getattr(self.request.user, 'profile', None)
        if not self.request.user.is_staff and (profile is None or self.get_object().owner != profile):
            raise PermissionDenied('Vous ne pouvez modifier que votre propre boutique.')
        serializer.save()

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def approve(self, request, pk=None):
        """Administrateur approuve une boutique."""
        store = self.get_object()
        store.is_approved = True
        store.save(update_fields=['is_approved'])
        return Response({'detail': f'La boutique {store.name} a été approuvée.'})

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def reject(self, request, pk=None):
        """Administrateur rejette/désapprouve une boutique."""
        store = self.get_object()
        store.is_approved = False
        store.save(update_fields=['is_approved'])
        return Response({'detail': f'La boutique {store.name} a été rejetée/désapprouvée.'})


class StoreCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = StoreCategory.objects.all()
    serializer_class = StoreCategorySerializer


class PromotionViewSet(viewsets.ModelViewSet):
    queryset = Promotion.objects.select_related('store').all()
    serializer_class = PromotionSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        qs = super().get_queryset()
        # Ne montrer que les promotions actives et non expirées aux clients
        if not self.request.user.is_staff:
            now = timezone.now()
            qs = qs.filter(is_active=True, start_date__lte=now, end_date__gte=now)
        return qs

    def perform_create(self, serializer):
        profile = getattr(self.request.user, 'profile', None)
        store = serializer.validated_data.get('store')
        if not self.request.user.is_staff and (profile is None or profile.role != 'seller' or store.owner != profile):
            raise PermissionDenied('Vous ne pouvez créer une promotion que pour votre boutique.')
        serializer.save()

    def perform_update(self, serializer):
        profile = getattr(self.request.user, 'profile', None)
        promotion = self.get_object()
        if not self.request.user.is_staff and (profile is None or profile.role != 'seller' or promotion.store.owner != profile):
            raise PermissionDenied('Vous ne pouvez modifier que les promotions de votre boutique.')
        serializer.save()
