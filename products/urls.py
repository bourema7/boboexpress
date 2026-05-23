from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import CartViewSet, CategoryViewSet, ProductViewSet, PromoCodeViewSet, ReviewViewSet

router = DefaultRouter()
router.register('categories', CategoryViewSet, basename='category')
router.register('products', ProductViewSet, basename='product')
router.register('reviews', ReviewViewSet, basename='review')
router.register('promo-codes', PromoCodeViewSet, basename='promo-code')
router.register('cart', CartViewSet, basename='cart')

urlpatterns = [
    path('', include(router.urls)),
]
