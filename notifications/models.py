from django.db import models
from django.contrib.auth.models import User


class NotificationTemplate(models.Model):
    channel = models.CharField(max_length=50)
    title = models.CharField(max_length=180)
    message = models.TextField()
    is_active = models.BooleanField(default=True)

    class Meta:
        verbose_name = 'Modèle de notification'
        verbose_name_plural = 'Modèles de notifications'

    def __str__(self):
        return self.title


class NotificationLog(models.Model):
    TYPE_CHOICES = [
        # Client
        ('order_received', 'Commande reçue'),
        ('order_confirmed', 'Commande confirmée'),
        ('order_cancelled', 'Commande annulée'),
        ('preparing', 'En préparation'),
        ('order_ready', 'Commande prête'),
        ('payment_validated', 'Paiement validé'),
        ('driver_assigned', 'Livreur assigné'),
        ('driver_en_route', 'Livreur en route'),
        ('picked_up', 'Colis récupéré'),
        ('delivered', 'Livrée'),
        ('delivery_failed', 'Livraison échouée'),
        # Livreur
        ('new_mission', 'Nouvelle mission'),
        ('mission_cancelled', 'Mission annulée'),
        ('earning_credited', 'Gain crédité'),
        ('pickup_ready', 'Prêt à récupérer'),
        # Commerçant
        ('new_order', 'Nouvelle commande'),
        ('payment_received', 'Paiement reçu'),
        # Admin
        ('settlement_ready', 'Reversement prêt'),
        # Général
        ('info', 'Information'),
        ('promo', 'Promotion'),
        ('bonus', 'Bonus'),
    ]

    CHANNEL_CHOICES = [
        ('inapp', 'In-App'),
        ('sms', 'SMS'),
        ('email', 'Email'),
        ('push', 'Push Notification'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=180)
    message = models.TextField()
    notification_type = models.CharField(max_length=30, choices=TYPE_CHOICES, default='info')
    channel = models.CharField(max_length=20, choices=CHANNEL_CHOICES, default='inapp')
    related_order = models.ForeignKey(
        'orders.Order', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='notifications'
    )
    is_read = models.BooleanField(default=False)
    read_at = models.DateTimeField(blank=True, null=True)
    sent_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Notification'
        verbose_name_plural = 'Notifications'
        ordering = ['-sent_at']

    def __str__(self):
        return f"[{self.notification_type}] {self.title} → {self.user.email}"
