from django.urls import path
from django.views.generic import RedirectView

from .views import (
    AddressListCreateAPIView,
    CategoryListAPIView,
    OrderListCreateAPIView,
    OrderRetrieveAPIView,
    ProductListCreateAPIView,
    ProductRetrieveUpdateDestroyAPIView,
    RegisterAPIView,
    ReviewListCreateAPIView,
    StoreListCreateAPIView,
    StoreRetrieveUpdateDestroyAPIView,
    UserDetailAPIView,
    WishlistListCreateAPIView,
)

urlpatterns = [
    path('', RedirectView.as_view(url='products/', permanent=False)),
    path('auth/register/', RegisterAPIView.as_view(), name='auth-register'),
    path('auth/me/', UserDetailAPIView.as_view(), name='auth-me'),
    path('categories/', CategoryListAPIView.as_view(), name='category-list'),
    path('stores/', StoreListCreateAPIView.as_view(), name='store-list-create'),
    path('stores/<int:pk>/', StoreRetrieveUpdateDestroyAPIView.as_view(), name='store-detail'),
    path('products/', ProductListCreateAPIView.as_view(), name='product-list-create'),
    path('products/<int:pk>/', ProductRetrieveUpdateDestroyAPIView.as_view(), name='product-detail'),
    path('orders/', OrderListCreateAPIView.as_view(), name='order-list-create'),
    path('orders/<int:pk>/', OrderRetrieveAPIView.as_view(), name='order-detail'),
    path('wishlist/', WishlistListCreateAPIView.as_view(), name='wishlist-list-create'),
    path('reviews/', ReviewListCreateAPIView.as_view(), name='review-list-create'),
    path('addresses/', AddressListCreateAPIView.as_view(), name='address-list-create'),
]
