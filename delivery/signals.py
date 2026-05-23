from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import DeliveryMission
from notifications.models import NotificationLog

@receiver(post_save, sender=DeliveryMission)
def mission_status_notifications(sender, instance, created, **kwargs):
    order = instance.order
    if created:
        # Alerter le livreur qu'il a une nouvelle mission
        NotificationLog.objects.create(
            user=instance.driver.user,
            title='🚴 Nouvelle mission',
            message=f'Une nouvelle mission vous a été assignée pour la commande {order.tracking_code}.',
            notification_type='new_mission',
            channel='inapp',
            related_order=order
        )
    else:
        # Alerter le client de l'état de la livraison
        if instance.status == 'accepted':
            NotificationLog.objects.create(
                user=order.buyer,
                title='🛵 Livreur en route',
                message=f'Un livreur a accepté votre commande {order.tracking_code} et se dirige vers la boutique.',
                notification_type='accepted',
                channel='inapp',
                related_order=order
            )
        elif instance.status == 'picked_up':
            NotificationLog.objects.create(
                user=order.buyer,
                title='📦 Commande récupérée',
                message=f'Le livreur a récupéré votre colis {order.tracking_code}.',
                notification_type='picked_up',
                channel='inapp',
                related_order=order
            )
        elif instance.status == 'delivered':
            NotificationLog.objects.create(
                user=order.buyer,
                title='🏁 Commande livrée',
                message=f'Votre commande {order.tracking_code} a été livrée. Merci !',
                notification_type='delivered',
                channel='inapp',
                related_order=order
            )
