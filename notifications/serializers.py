from rest_framework import serializers
from .models import NotificationLog


class NotificationSerializer(serializers.ModelSerializer):
    type_display = serializers.CharField(source='get_notification_type_display', read_only=True)
    channel_display = serializers.CharField(source='get_channel_display', read_only=True)
    order_tracking_code = serializers.CharField(source='related_order.tracking_code', read_only=True, allow_null=True)

    class Meta:
        model = NotificationLog
        fields = [
            'id', 'title', 'message',
            'notification_type', 'type_display',
            'channel', 'channel_display',
            'order_tracking_code', 'related_order',
            'is_read', 'read_at', 'sent_at',
        ]
        read_only_fields = ['sent_at', 'read_at']
