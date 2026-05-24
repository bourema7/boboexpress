from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import NotificationViewSet

router = DefaultRouter()
router.register('notifications', NotificationViewSet, basename='notification')

notification_list = NotificationViewSet.as_view({'get': 'list'})
notification_broadcast = NotificationViewSet.as_view({'post': 'broadcast'})
notification_unread_count = NotificationViewSet.as_view({'get': 'unread_count'})
notification_mark_all_read = NotificationViewSet.as_view({'post': 'mark_all_read'})
notification_clear_all = NotificationViewSet.as_view({'delete': 'clear_all'})

urlpatterns = [
    path('', notification_list, name='notification-list-short'),
    path('broadcast/', notification_broadcast, name='notification-broadcast-short'),
    path('unread_count/', notification_unread_count, name='notification-unread-count-short'),
    path('mark_all_read/', notification_mark_all_read, name='notification-mark-all-read-short'),
    path('clear_all/', notification_clear_all, name='notification-clear-all-short'),
    path('', include(router.urls)),
]
