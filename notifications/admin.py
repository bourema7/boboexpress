from django.contrib import admin
from .models import NotificationLog, NotificationTemplate


@admin.register(NotificationTemplate)
class NotificationTemplateAdmin(admin.ModelAdmin):
    list_display = ['title', 'channel', 'is_active']
    list_filter = ['channel', 'is_active']


@admin.register(NotificationLog)
class NotificationLogAdmin(admin.ModelAdmin):
    list_display = ['user', 'title', 'notification_type', 'channel', 'is_read', 'sent_at']
    list_filter = ['notification_type', 'channel', 'is_read']
    search_fields = ['user__username', 'title']
    date_hierarchy = 'sent_at'
