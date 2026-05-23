from rest_framework import serializers

from .models import Promotion, Store, StoreCategory
from users.serializers import UserProfileSerializer


class StoreCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = StoreCategory
        fields = ['id', 'name', 'slug', 'icon_url']


class PromotionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Promotion
        fields = ['id', 'store', 'title', 'description', 'discount_percent', 'min_order_amount', 'is_active', 'start_date', 'end_date', 'banner_url']


class StoreSerializer(serializers.ModelSerializer):
    owner = UserProfileSerializer(read_only=True)
    category = StoreCategorySerializer(read_only=True)
    category_id = serializers.PrimaryKeyRelatedField(queryset=StoreCategory.objects.all(), source='category', write_only=True, required=False, allow_null=True)
    type_display = serializers.CharField(source='get_type_display', read_only=True)

    class Meta:
        model = Store
        fields = [
            'id', 'owner', 'name', 'slug', 'description', 'type', 'type_display',
            'category', 'category_id', 'city', 'address', 'latitude', 'longitude', 'phone',
            'logo_url', 'cover_url', 'opening_hours',
            'is_active', 'is_approved', 'is_premium', 'premium_expires_at',
            'commission_rate', 'average_rating', 'total_orders',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['is_approved', 'is_premium', 'premium_expires_at', 'commission_rate', 'average_rating', 'total_orders', 'created_at', 'updated_at']

    def validate_opening_hours(self, value):
        if not isinstance(value, dict):
            raise serializers.ValidationError("opening_hours doit être un objet JSON valide.")
        return value
