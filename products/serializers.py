from rest_framework import serializers

from .models import Cart, CartItem, Category, Product, ProductVariant, PromoCode, Review, Favorite
from stores.models import Store
from stores.serializers import StoreSerializer


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name', 'slug', 'icon_url', 'description', 'is_active']


class ProductVariantSerializer(serializers.ModelSerializer):
    final_price = serializers.ReadOnlyField()

    class Meta:
        model = ProductVariant
        fields = ['id', 'name', 'color', 'size', 'sku', 'price_extra', 'final_price', 'stock', 'is_active']


class ReviewSerializer(serializers.ModelSerializer):
    class Meta:
        model = Review
        fields = ['id', 'product', 'username', 'rating', 'comment', 'created_at']
        read_only_fields = ['created_at']


class ProductSerializer(serializers.ModelSerializer):
    category = CategorySerializer(read_only=True)
    store = StoreSerializer(read_only=True)
    category_id = serializers.PrimaryKeyRelatedField(queryset=Category.objects.all(), write_only=True, source='category')
    store_id = serializers.PrimaryKeyRelatedField(queryset=Store.objects.all(), write_only=True, source='store', required=False)
    variants = ProductVariantSerializer(many=True, read_only=True)
    average_rating = serializers.SerializerMethodField()
    is_favorite = serializers.SerializerMethodField()
    slug = serializers.SlugField(required=False)

    class Meta:
        model = Product
        fields = [
            'id', 'store', 'store_id', 'category', 'category_id',
            'name', 'slug', 'description', 'price', 'stock',
            'image_url', 'image', 'is_active', 'is_new', 'is_promo', 'discount_price',
            'variants', 'average_rating', 'is_favorite',
            'created_at', 'updated_at',
        ]

    def get_average_rating(self, obj):
        reviews = obj.reviews.all()
        if not reviews.exists():
            return 5.0
        return round(sum(r.rating for r in reviews) / reviews.count(), 1)

    def get_is_favorite(self, obj):
        user = self.context.get('request').user if 'request' in self.context else None
        if user and user.is_authenticated:
            return Favorite.objects.filter(user=user, product=obj).exists()
        return False


class FavoriteSerializer(serializers.ModelSerializer):
    product_details = ProductSerializer(source='product', read_only=True)
    
    class Meta:
        model = Favorite
        fields = ['id', 'product', 'product_details', 'created_at']
        read_only_fields = ['user', 'created_at']


class PromoCodeSerializer(serializers.ModelSerializer):
    class Meta:
        model = PromoCode
        fields = '__all__'


class PromoCodeValidateSerializer(serializers.Serializer):
    """Valider un code promo et retourner ses détails."""
    code = serializers.CharField()
    order_amount = serializers.DecimalField(max_digits=12, decimal_places=2)


class CartItemSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    product_image = serializers.SerializerMethodField()
    variant_name = serializers.CharField(source='variant.name', read_only=True, allow_null=True)
    unit_price = serializers.ReadOnlyField()
    line_total = serializers.ReadOnlyField()

    class Meta:
        model = CartItem
        fields = [
            'id', 'product', 'product_name', 'product_image', 'variant', 'variant_name',
            'quantity', 'special_instructions', 'unit_price', 'line_total',
        ]
        read_only_fields = ['cart']

    def get_product_image(self, obj):
        if obj.product.image:
            return self.context['request'].build_absolute_uri(obj.product.image.url)
        return obj.product.image_url

    def validate(self, attrs):
        product = attrs.get('product')
        variant = attrs.get('variant')
        quantity = attrs.get('quantity', 1)
        if variant and variant.product != product:
            raise serializers.ValidationError('Cette variante n\'appartient pas à ce produit.')
        stock = variant.stock if variant else product.stock
        if quantity > stock:
            raise serializers.ValidationError(f'Stock insuffisant. Disponible: {stock}')
        return attrs


class CartSerializer(serializers.ModelSerializer):
    items = CartItemSerializer(many=True, read_only=True)
    total = serializers.ReadOnlyField()
    store_name = serializers.CharField(source='store.name', read_only=True, allow_null=True)

    class Meta:
        model = Cart
        fields = ['id', 'store', 'store_name', 'items', 'total', 'updated_at']
