from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import PromotionViewSet, StoreCategoryViewSet, StoreViewSet

router = DefaultRouter()
router.register('stores', StoreViewSet)
router.register('store-categories', StoreCategoryViewSet)
router.register('promotions', PromotionViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
