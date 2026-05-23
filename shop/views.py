from rest_framework import generics, permissions
from rest_framework.exceptions import PermissionDenied

from .models import (
    Address,
    Category,
    Order,
    Product,
    Profile,
    Review,
    Store,
    WishlistItem,
)
from .serializers import (
    AddressSerializer,
    CategorySerializer,
    OrderSerializer,
    ProductSerializer,
    RegisterSerializer,
    ReviewSerializer,
    StoreSerializer,
    UserSerializer,
    WishlistItemSerializer,
)


class CategoryListAPIView(generics.ListAPIView):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer


class StoreListCreateAPIView(generics.ListCreateAPIView):
    queryset = Store.objects.select_related('owner', 'category').all()
    serializer_class = StoreSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def perform_create(self, serializer):
        profile = getattr(self.request.user, 'profile', None)
        if profile is None:
            profile = Profile.objects.create(user=self.request.user, role='seller')
        if profile.role != 'seller':
            raise PermissionDenied('Seuls les vendeurs peuvent créer une boutique.')
        serializer.save(owner=profile)


class StoreRetrieveUpdateDestroyAPIView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Store.objects.select_related('owner', 'category').all()
    serializer_class = StoreSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]


class RegisterAPIView(generics.CreateAPIView):
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]


class UserDetailAPIView(generics.RetrieveAPIView):
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user


class ProductListCreateAPIView(generics.ListCreateAPIView):
    queryset = Product.objects.select_related('category', 'store__owner', 'store__category').all()
    serializer_class = ProductSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def perform_create(self, serializer):
        profile = getattr(self.request.user, 'profile', None)
        if profile is None or profile.role != 'seller':
            raise PermissionDenied('Seuls les vendeurs peuvent créer un produit.')

        store = serializer.validated_data.get('store')
        if store is None:
            store = profile.stores.filter(is_active=True, is_approved=True).first()
            if store is None:
                raise PermissionDenied('Vous devez avoir une boutique approuvée pour créer un produit.')

        if store.owner != profile:
            raise PermissionDenied('Vous ne pouvez créer un produit que pour votre propre boutique.')
        serializer.save(store=store)


class ProductRetrieveUpdateDestroyAPIView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Product.objects.select_related('category', 'store').all()
    serializer_class = ProductSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]


class OrderListCreateAPIView(generics.ListCreateAPIView):
    queryset = Order.objects.select_related('buyer', 'store', 'address').all()
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return self.queryset.filter(buyer=user)

    def perform_create(self, serializer):
        serializer.save(buyer=self.request.user)


class OrderRetrieveAPIView(generics.RetrieveAPIView):
    queryset = Order.objects.select_related('buyer', 'store', 'address').all()
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]


class WishlistListCreateAPIView(generics.ListCreateAPIView):
    queryset = WishlistItem.objects.select_related('product', 'user').all()
    serializer_class = WishlistItemSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return self.queryset.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class ReviewListCreateAPIView(generics.ListCreateAPIView):
    queryset = Review.objects.select_related('product', 'user').all()
    serializer_class = ReviewSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]


class AddressListCreateAPIView(generics.ListCreateAPIView):
    queryset = Address.objects.select_related('user').all()
    serializer_class = AddressSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return self.queryset.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
