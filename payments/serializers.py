from rest_framework import serializers
from .models import PaymentTransaction, WalletTransaction, StoreSettlement, PlatformRevenue, StoreSubscription


class PaymentTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentTransaction
        fields = '__all__'
        read_only_fields = ['user', 'created_at', 'updated_at']


class WalletTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = WalletTransaction
        fields = '__all__'
        read_only_fields = ['user', 'balance_after', 'created_at']


class WalletTopUpSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, min_value=100)
    payment_method = serializers.ChoiceField(choices=['momo', 'card'])


class StoreSettlementSerializer(serializers.ModelSerializer):
    store_name = serializers.CharField(source='store.name', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = StoreSettlement
        fields = [
            'id', 'store', 'store_name', 'period', 'period_start', 'period_end',
            'gross_amount', 'commission_amount', 'net_amount',
            'status', 'status_display', 'payment_reference', 'paid_at', 'created_at',
        ]
        read_only_fields = ['gross_amount', 'commission_amount', 'net_amount', 'created_at']


class PlatformRevenueSerializer(serializers.ModelSerializer):
    source_display = serializers.CharField(source='get_source_display', read_only=True)

    class Meta:
        model = PlatformRevenue
        fields = ['id', 'source', 'source_display', 'amount', 'order', 'store', 'description', 'created_at']


class StoreSubscriptionSerializer(serializers.ModelSerializer):
    store_name = serializers.CharField(source='store.name', read_only=True)
    plan_display = serializers.CharField(source='get_plan_display', read_only=True)

    class Meta:
        model = StoreSubscription
        fields = ['id', 'store', 'store_name', 'plan', 'plan_display', 'is_active', 'start_date', 'end_date', 'amount_paid', 'created_at']
