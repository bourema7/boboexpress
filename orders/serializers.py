from django.utils import timezone
from rest_framework import serializers

from products.models import Product, ProductVariant, PromoCode
from products.serializers import ProductSerializer, ProductVariantSerializer
from users.models import Address
from users.serializers import AddressSerializer, UserProfileSerializer
from .models import Order, OrderItem, OrderStatusHistory


class OrderItemReadSerializer(serializers.ModelSerializer):
    product = ProductSerializer(read_only=True)
    variant = ProductVariantSerializer(read_only=True)
    line_total = serializers.ReadOnlyField()

    class Meta:
        model = OrderItem
        fields = ['id', 'product', 'variant', 'quantity', 'unit_price', 'line_total', 'special_instructions']


class OrderItemWriteSerializer(serializers.ModelSerializer):
    product_id = serializers.PrimaryKeyRelatedField(queryset=Product.objects.all(), source='product')
    variant_id = serializers.PrimaryKeyRelatedField(queryset=ProductVariant.objects.all(), source='variant', required=False, allow_null=True)

    class Meta:
        model = OrderItem
        fields = ['product_id', 'variant_id', 'quantity', 'special_instructions']

    def validate(self, attrs):
        product = attrs['product']
        variant = attrs.get('variant')
        quantity = attrs.get('quantity', 1)
        if variant and variant.product != product:
            raise serializers.ValidationError('Cette variante n\'appartient pas à ce produit.')
        stock = variant.stock if variant else product.stock
        if quantity > stock:
            raise serializers.ValidationError(f'Stock insuffisant pour {product.name}. Disponible: {stock}')
        return attrs


class OrderStatusHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = OrderStatusHistory
        fields = ['id', 'status', 'note', 'created_by', 'created_at']


class OrderSerializer(serializers.ModelSerializer):
    buyer = serializers.StringRelatedField(read_only=True)
    store_name = serializers.CharField(source='store.name', read_only=True)
    address = AddressSerializer(read_only=True)
    address_id = serializers.PrimaryKeyRelatedField(queryset=Address.objects.all(), write_only=True, source='address')
    promo_code_str = serializers.CharField(source='promo_code.code', read_only=True, allow_null=True)
    promo_code_input = serializers.CharField(write_only=True, required=False, allow_blank=True, allow_null=True)
    items = OrderItemReadSerializer(many=True, read_only=True)
    items_input = OrderItemWriteSerializer(many=True, write_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    status_history = OrderStatusHistorySerializer(many=True, read_only=True)
    deliverer_profile = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = [
            'id', 'buyer', 'store_name', 'address', 'address_id',
            'subtotal', 'delivery_fee', 'discount_amount', 'cashback_amount', 'total_amount',
            'promo_code_str', 'promo_code_input',
            'payment_method', 'payment_status', 'transaction_id', 'delivery_type',
            'status', 'status_display', 'tracking_code', 'delivery_otp',
            'deliverer', 'deliverer_profile',
            'current_latitude', 'current_longitude',
            'note', 'items', 'items_input', 'status_history',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'buyer', 'status', 'status_display', 'tracking_code', 'delivery_otp',
            'subtotal', 'discount_amount', 'cashback_amount', 'total_amount',
            'deliverer_profile',
            'created_at', 'updated_at',
        ]

    def get_deliverer_profile(self, obj):
        if obj.deliverer and hasattr(obj.deliverer, 'profile'):
            return UserProfileSerializer(obj.deliverer.profile).data
        return None

    def _calculate_delivery_fee(self, delivery_type, promo=None):
        if promo and promo.free_delivery:
            return 0
        return 500 if delivery_type == 'standard' else 1000  # XOF

    def create(self, validated_data):
        items_data = validated_data.pop('items_input', [])
        promo_code_input = validated_data.pop('promo_code_input', None)
        store = validated_data.get('store')
        delivery_type = validated_data.get('delivery_type', 'standard')
        payment_method = validated_data.get('payment_method')
        buyer = self.context['request'].user

        # Résoudre le code promo
        promo = None
        if promo_code_input:
            try:
                promo = PromoCode.objects.get(code=promo_code_input, active=True)
            except PromoCode.DoesNotExist:
                raise serializers.ValidationError({'promo_code_input': 'Code promo invalide.'})
            if promo.expires_at and promo.expires_at < timezone.now():
                raise serializers.ValidationError({'promo_code_input': 'Code promo expiré.'})

        delivery_fee = self._calculate_delivery_fee(delivery_type, promo)

        order = Order.objects.create(
            **validated_data,
            buyer=buyer,
            store=store if store else items_data[0]['product'].store if items_data else None,
            delivery_fee=delivery_fee,
            subtotal=0,
            total_amount=0,
            discount_amount=0,
            cashback_amount=0,
            promo_code=promo,
        )

        subtotal = 0
        for item_data in items_data:
            product = item_data['product']
            variant = item_data.get('variant')
            quantity = item_data['quantity']
            special_instructions = item_data.get('special_instructions', '')
            unit_price = variant.final_price if variant else product.price
            # Décrémentation stock
            if variant:
                variant.stock -= quantity
                variant.save(update_fields=['stock'])
            else:
                product.stock -= quantity
                product.save(update_fields=['stock'])
            OrderItem.objects.create(
                order=order,
                product=product,
                variant=variant,
                quantity=quantity,
                unit_price=unit_price,
                special_instructions=special_instructions,
            )
            subtotal += unit_price * quantity

        # Calcul des réductions
        discount = 0
        cashback = 0
        if promo:
            if promo.min_order_amount <= subtotal:
                if promo.discount_percent:
                    discount += subtotal * promo.discount_percent / 100
                if promo.discount_fixed:
                    discount += float(promo.discount_fixed)
                if promo.cashback_percent:
                    cashback = subtotal * promo.cashback_percent / 100
                promo.used_count += 1
                promo.save(update_fields=['used_count'])

        total = float(subtotal) + float(delivery_fee) - float(discount)

        # Paiement wallet
        if payment_method == 'wallet':
            profile = getattr(buyer, 'profile', None)
            if not profile or profile.wallet_balance < total:
                raise serializers.ValidationError({'payment_method': 'Solde wallet insuffisant.'})
            profile.wallet_balance -= total
            profile.save(update_fields=['wallet_balance'])

        order.subtotal = subtotal
        order.discount_amount = discount
        order.cashback_amount = cashback
        order.total_amount = total
        order.save()

        # Appliquer cashback au wallet
        if cashback > 0:
            profile = getattr(buyer, 'profile', None)
            if profile:
                profile.wallet_balance += cashback
                profile.save(update_fields=['wallet_balance'])

        # Enregistrer historique de statut
        OrderStatusHistory.objects.create(order=order, status='pending', created_by=buyer)

        return order


class OrderTrackingSerializer(serializers.ModelSerializer):
    """Vue légère pour tracking public."""
    status_display = serializers.CharField(source='get_status_display')
    store_name = serializers.CharField(source='store.name')
    driver_position = serializers.SerializerMethodField()
    status_history = OrderStatusHistorySerializer(many=True)

    class Meta:
        model = Order
        fields = [
            'tracking_code', 'status', 'status_display', 'store_name',
            'current_latitude', 'current_longitude',
            'driver_position', 'status_history', 'created_at'
        ]

    def get_driver_position(self, obj):
        mission = getattr(obj, 'delivery_mission', None)
        if mission and mission.current_lat and mission.current_lng:
            return {
                'latitude': str(mission.current_lat),
                'longitude': str(mission.current_lng),
                'estimated_duration_min': mission.estimated_duration,
            }
        return None
