from rest_framework import serializers
from .models import DeliveryMission
from orders.serializers import OrderSerializer


class DeliveryMissionSerializer(serializers.ModelSerializer):
    order_tracking_code = serializers.CharField(source='order.tracking_code', read_only=True)
    order_status = serializers.CharField(source='order.get_status_display', read_only=True)
    store_name = serializers.CharField(source='order.store.name', read_only=True)
    store_address = serializers.CharField(source='order.store.city', read_only=True)
    client_name = serializers.SerializerMethodField()
    client_phone = serializers.SerializerMethodField()
    delivery_address = serializers.SerializerMethodField()
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    driver_name = serializers.SerializerMethodField()
    driver_phone = serializers.SerializerMethodField()
    driver_rating = serializers.DecimalField(source='driver.rating', max_digits=3, decimal_places=2, read_only=True)

    class Meta:
        model = DeliveryMission
        fields = [
            'id', 'status', 'status_display',
            'order_tracking_code', 'order_status',
            'store_name', 'store_address',
            'client_name', 'client_phone', 'delivery_address',
            'driver_name', 'driver_phone', 'driver_rating',
            'pickup_lat', 'pickup_lng', 'dropoff_lat', 'dropoff_lng',
            'current_lat', 'current_lng',
            'driver_earning', 'distance_km', 'estimated_duration',
            'proof_photo_url', 'signature_data',
            'assigned_at', 'accepted_at', 'picked_up_at', 'delivered_at',
        ]
        read_only_fields = [
            'driver_earning', 'assigned_at', 'accepted_at', 'picked_up_at', 'delivered_at',
        ]

    def get_client_name(self, obj):
        buyer = obj.order.buyer
        return buyer.get_full_name() or buyer.username

    def get_client_phone(self, obj):
        profile = getattr(obj.order.buyer, 'profile', None)
        return profile.phone if profile else ''

    def get_delivery_address(self, obj):
        addr = obj.order.address
        if not addr:
            return None
        return {
            'street': addr.street,
            'city': addr.city,
            'landmark': addr.landmark,
            'latitude': str(addr.latitude) if addr.latitude else None,
            'longitude': str(addr.longitude) if addr.longitude else None,
        }

    def get_driver_name(self, obj):
        return obj.driver.user.get_full_name() or obj.driver.user.username

    def get_driver_phone(self, obj):
        return obj.driver.phone


class LocationUpdateSerializer(serializers.Serializer):
    latitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    longitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    estimated_duration = serializers.IntegerField(required=False)


class OTPConfirmSerializer(serializers.Serializer):
    otp_code = serializers.CharField(max_length=6)


class ProofUploadSerializer(serializers.Serializer):
    proof_photo_url = serializers.URLField(required=False, allow_blank=True)
    signature_data = serializers.CharField(required=False, allow_blank=True)
