from django.utils import timezone
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import NotificationLog
from .serializers import NotificationSerializer


class NotificationViewSet(viewsets.ReadOnlyModelViewSet):
    """Notifications de l'utilisateur connecté."""
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = NotificationLog.objects.filter(user=self.request.user)
        notif_type = self.request.query_params.get('type')
        unread_only = self.request.query_params.get('unread')
        if notif_type:
            qs = qs.filter(notification_type=notif_type)
        if unread_only and unread_only.lower() in ('true', '1'):
            qs = qs.filter(is_read=False)
        return qs

    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        """Marquer une notification comme lue."""
        notif = self.get_object()
        notif.is_read = True
        notif.read_at = timezone.now()
        notif.save(update_fields=['is_read', 'read_at'])
        return Response({'detail': 'Notification marquée comme lue.'})

    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        """Marquer toutes les notifications comme lues."""
        now = timezone.now()
        count = NotificationLog.objects.filter(user=request.user, is_read=False).update(
            is_read=True, read_at=now
        )
        return Response({'detail': f'{count} notification(s) marquée(s) comme lues.'})

    @action(detail=False, methods=['get'])
    def unread_count(self, request):
        """Nombre de notifications non lues."""
        count = NotificationLog.objects.filter(user=request.user, is_read=False).count()
        return Response({'unread_count': count})

    @action(detail=False, methods=['delete'])
    def clear_all(self, request):
        """Supprimer toutes les notifications lues."""
        deleted, _ = NotificationLog.objects.filter(user=request.user, is_read=True).delete()
        return Response({'detail': f'{deleted} notification(s) supprimée(s).'}, status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=['post'])
    def broadcast(self, request):
        """Admin: Envoyer une notification à tous les utilisateurs ou un groupe."""
        user = request.user
        profile = getattr(user, 'profile', None)
        if not user.is_staff and not (profile and profile.role == 'admin'):
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied('Réservé aux administrateurs.')
        
        title = request.data.get('title')
        message = request.data.get('message')
        target_role = request.data.get('target_role') # 'all', 'customer', 'seller', 'delivery'
        
        if not title or not message:
            return Response({'detail': 'Titre et message requis.'}, status=status.HTTP_400_BAD_REQUEST)
            
        from users.models import UserProfile
        
        if target_role and target_role != 'all':
            profiles = UserProfile.objects.filter(role=target_role)
        else:
            profiles = UserProfile.objects.all()
            
        notifications = []
        for p in profiles:
            notifications.append(NotificationLog(
                user=p.user,
                title=title,
                message=message,
                notification_type='info',
                channel='inapp'
            ))
            
        NotificationLog.objects.bulk_create(notifications)
        return Response({'detail': f'Notification envoyée à {len(notifications)} utilisateurs.'})
