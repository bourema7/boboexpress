from django.utils import timezone
from rest_framework import filters, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response

from .models import Cart, CartItem, Category, Favorite, Product, ProductVariant, PromoCode, Review
from .serializers import (
    CartItemSerializer,
    CartSerializer,
    CategorySerializer,
    ProductSerializer,
    ProductVariantSerializer,
    PromoCodeSerializer,
    PromoCodeValidateSerializer,
    ReviewSerializer,
    FavoriteSerializer,
)


class CategoryViewSet(viewsets.ModelViewSet):
    serializer_class = CategorySerializer

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [permissions.AllowAny()]
        return [permissions.IsAdminUser()]

    def get_queryset(self):
        user = self.request.user
        profile = getattr(user, 'profile', None)
        if user.is_authenticated and (user.is_staff or (profile and profile.role == 'admin')):
            return Category.objects.all()
        return Category.objects.filter(is_active=True).all()


class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.select_related('category', 'store__owner', 'store__category').prefetch_related('variants', 'reviews').all()
    serializer_class = ProductSerializer
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'description', 'store__name', 'category__name']
    ordering_fields = ['price', 'created_at']
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        qs = super().get_queryset()
        user = self.request.user
        profile = getattr(user, 'profile', None)
        
        # Admin et vendeurs voient tous leurs produits (même en rupture) pour gestion
        is_manager = user.is_authenticated and user.is_staff or (profile and profile.role in ('admin', 'seller'))
        
        # Pour les clients : masquer les produits inactifs ou en rupture de stock
        if not is_manager:
            qs = qs.filter(is_active=True, stock__gt=0)
        
        category = self.request.query_params.get('category')
        category_id = self.request.query_params.get('category_id')
        store = self.request.query_params.get('store')
        min_price = self.request.query_params.get('min_price')
        max_price = self.request.query_params.get('max_price')
        is_new = self.request.query_params.get('is_new')
        is_promo = self.request.query_params.get('is_promo')
        if category:
            qs = qs.filter(category__slug=category)
        if category_id:
            qs = qs.filter(category_id=category_id)
        if store:
            qs = qs.filter(store__slug=store)
        if min_price:
            qs = qs.filter(price__gte=min_price)
        if max_price:
            qs = qs.filter(price__lte=max_price)
        if is_new == 'true':
            qs = qs.filter(is_new=True)
        if is_promo == 'true':
            qs = qs.filter(is_promo=True)
        return qs

    def perform_create(self, serializer):
        user_profile = getattr(self.request.user, 'profile', None)
        if user_profile is None or user_profile.role not in ('seller', 'admin'):
            raise PermissionDenied('Seuls les vendeurs ou administrateurs peuvent ajouter des produits.')
        
        store = serializer.validated_data.get('store')
        if store is None:
            if user_profile.role == 'admin':
                from stores.models import Store
                store = Store.objects.first()
                if not store:
                    from django.utils.text import slugify
                    import uuid
                    store = Store.objects.create(
                        name='Boutique BoboExpress',
                        slug=f'boboexpress-{uuid.uuid4().hex[:6]}',
                        owner=user_profile,
                        city='Bobo-Dioulasso',
                        is_approved=True
                    )
            else:
                store = user_profile.stores.filter(is_active=True, is_approved=True).first()
            if store is None:
                raise PermissionDenied('Vous devez avoir une boutique active pour publier un produit.')
        
        if user_profile.role != 'admin' and store.owner != user_profile:
            raise PermissionDenied('Vous ne pouvez pas publier un produit pour une boutique qui ne vous appartient pas.')
            
        slug = serializer.validated_data.get('slug')
        if not slug:
            from django.utils.text import slugify
            import uuid
            name = serializer.validated_data.get('name', 'produit')
            slug = f"{slugify(name)}-{uuid.uuid4().hex[:6]}"
            
        save_kwargs = {'store': store, 'slug': slug}
        if 'is_active' not in self.request.data:
            save_kwargs['is_active'] = True

        serializer.save(**save_kwargs)

    def perform_update(self, serializer):
        user_profile = getattr(self.request.user, 'profile', None)
        if user_profile is None or user_profile.role not in ('seller', 'admin'):
            raise PermissionDenied('Non autorisé.')
        product = self.get_object()
        if user_profile.role != 'admin' and product.store.owner != user_profile:
            raise PermissionDenied('Vous ne pouvez modifier que vos propres produits.')
        serializer.save()

    def perform_destroy(self, instance):
        user_profile = getattr(self.request.user, 'profile', None)
        if user_profile is None or user_profile.role not in ('seller', 'admin'):
            raise PermissionDenied('Non autorisé.')
        if user_profile.role != 'admin' and instance.store.owner != user_profile:
            raise PermissionDenied('Suppression non autorisée.')
        instance.delete()

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def toggle_favorite(self, request, pk=None):
        product = self.get_object()
        favorite, created = Favorite.objects.get_or_create(user=request.user, product=product)
        if not created:
            favorite.delete()
            return Response({'is_favorite': False})
        return Response({'is_favorite': True})

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def favorites(self, request):
        products = Product.objects.filter(favorited_by__user=request.user)
        page = self.paginate_queryset(products)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(products, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get', 'post'])
    def variants(self, request, pk=None):
        """Lister ou créer des variantes d'un produit."""
        product = self.get_object()
        if request.method == 'GET':
            serializer = ProductVariantSerializer(product.variants.all(), many=True)
            return Response(serializer.data)
        # POST — créer une variante
        profile = getattr(request.user, 'profile', None)
        if not profile or profile.role not in ('seller', 'admin'):
            raise PermissionDenied('Réservé au vendeur.')
        serializer = ProductVariantSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(product=product)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class ReviewViewSet(viewsets.ModelViewSet):
    queryset = Review.objects.select_related('product').all()
    serializer_class = ReviewSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def perform_create(self, serializer):
        username = self.request.user.get_full_name() or self.request.user.username
        serializer.save(user=self.request.user, username=username)


class PromoCodeViewSet(viewsets.ModelViewSet):
    queryset = PromoCode.objects.all()
    serializer_class = PromoCodeSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    @action(detail=False, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def validate(self, request):
        """Valider un code promo et retourner les avantages."""
        serializer = PromoCodeValidateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        code_str = serializer.validated_data['code']
        order_amount = serializer.validated_data['order_amount']
        try:
            promo = PromoCode.objects.get(code=code_str, active=True)
        except PromoCode.DoesNotExist:
            return Response({'detail': 'Code promo invalide ou inactif.'}, status=status.HTTP_400_BAD_REQUEST)
        if promo.expires_at and promo.expires_at < timezone.now():
            return Response({'detail': 'Ce code promo a expiré.'}, status=status.HTTP_400_BAD_REQUEST)

        if order_amount < promo.min_order_amount:
            return Response({'detail': f'Montant minimum requis : {promo.min_order_amount} XOF.'}, status=status.HTTP_400_BAD_REQUEST)
        discount = 0
        if promo.discount_percent:
            discount = float(order_amount) * promo.discount_percent / 100
        if promo.discount_fixed:
            discount += float(promo.discount_fixed)
        return Response({
            'code': promo.code,
            'discount_amount': round(discount, 2),
            'free_delivery': promo.free_delivery,
            'cashback_percent': promo.cashback_percent,
        })


class CartViewSet(viewsets.ViewSet):
    """Gestion du panier utilisateur."""
    permission_classes = [permissions.IsAuthenticated]

    def _get_cart(self, user):
        cart, _ = Cart.objects.get_or_create(user=user)
        return cart

    def list(self, request):
        cart = self._get_cart(request.user)
        return Response(CartSerializer(cart, context={'request': request}).data)

    @action(detail=False, methods=['post'])
    def add(self, request):
        """Ajouter un article au panier."""
        cart = self._get_cart(request.user)
        serializer = CartItemSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        product = serializer.validated_data['product']
        variant = serializer.validated_data.get('variant')
        quantity = serializer.validated_data.get('quantity', 1)
        special_instructions = serializer.validated_data.get('special_instructions', '')

        # Si nouveau store, vider le panier (un panier = une boutique)
        if cart.store and cart.store != product.store:
            cart.items.all().delete()
        cart.store = product.store
        cart.save()

        # Vérification et diminution du stock
        target = variant if variant else product
        if target.stock < quantity:
            return Response({'detail': f'Stock insuffisant. Disponible: {target.stock}'}, status=status.HTTP_400_BAD_REQUEST)
        
        target.stock -= quantity
        target.save()

        item, created = CartItem.objects.get_or_create(
            cart=cart, product=product, variant=variant,
            defaults={'quantity': quantity, 'special_instructions': special_instructions}
        )
        if not created:
            item.quantity += quantity
            item.save()
        return Response(CartSerializer(cart, context={'request': request}).data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['post'])
    def update_item(self, request):
        """Modifier la quantité d'un article."""
        cart = self._get_cart(request.user)
        item_id = request.data.get('item_id')
        quantity = request.data.get('quantity', 1)
        try:
            item = CartItem.objects.get(id=item_id, cart=cart)
        except CartItem.DoesNotExist:
            return Response({'detail': 'Article introuvable.'}, status=status.HTTP_404_NOT_FOUND)
        if int(quantity) <= 0:
            item.delete()
        else:
            item.quantity = quantity
            item.save()
        return Response(CartSerializer(cart, context={'request': request}).data)

    @action(detail=False, methods=['post'])
    def remove_item(self, request):
        """Supprimer un article du panier."""
        cart = self._get_cart(request.user)
        item_id = request.data.get('item_id')
        CartItem.objects.filter(id=item_id, cart=cart).delete()
        return Response(CartSerializer(cart, context={'request': request}).data)

    @action(detail=False, methods=['post'])
    def clear(self, request):
        """Vider le panier."""
        cart = self._get_cart(request.user)
        cart.items.all().delete()
        cart.store = None
        cart.save()
        return Response({'detail': 'Panier vidé.'})


class FavoriteViewSet(viewsets.ModelViewSet):
    serializer_class = FavoriteSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Favorite.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
