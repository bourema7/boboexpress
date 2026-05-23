from django.contrib import admin
from .models import DeliveryMission


@admin.register(DeliveryMission)
class DeliveryMissionAdmin(admin.ModelAdmin):
    list_display = ['id', 'order', 'driver', 'status', 'driver_earning', 'distance_km', 'assigned_at', 'delivered_at']
    list_filter = ['status']
    search_fields = ['order__tracking_code', 'driver__user__username']
    readonly_fields = ['assigned_at', 'accepted_at', 'picked_up_at', 'delivered_at', 'driver_earning']
