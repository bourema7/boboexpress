from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Order, OrderStatusHistory
from notifications.models import NotificationLog

@receiver(post_save, sender=Order)
def order_status_notifications(sender, instance, created, **kwargs):
    if created:
        # Alerter le commerçant d'une nouvelle commande
        if instance.store and instance.store.owner:
            NotificationLog.objects.create(
                user=instance.store.owner.user,
                title='🔔 Nouvelle commande !',
                message=f'Vous avez reçu une nouvelle commande ({instance.tracking_code}) de {instance.buyer.username}.',
                notification_type='new_order',
                channel='inapp',
                related_order=instance
            )
    else:
        # Alerter le client du changement de statut
        # Note: Dans la version du matin, c'était géré ici
        pass

@receiver(post_save, sender=OrderStatusHistory)
def status_history_notifications(sender, instance, created, **kwargs):
    if created:
        order = instance.order
        NotificationLog.objects.create(
            user=order.buyer,
            title=f'📦 Commande {order.get_status_display()}',
            message=f'Votre commande {order.tracking_code} est maintenant : {order.get_status_display()}.',
            notification_type='status_update',
            channel='inapp',
            related_order=order
        )
