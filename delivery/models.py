from django.db import models
from django.utils import timezone

from orders.models import Order
from users.models import UserProfile


class DeliveryMission(models.Model):
    STATUS_CHOICES = [
        ('assigned', 'Assignée'),
        ('accepted', 'Acceptée'),
        ('picking_up', 'En route vers boutique'),
        ('picked_up', 'Colis récupéré'),
        ('on_route', 'En route vers client'),
        ('delivered', 'Livrée'),
        ('failed', 'Échouée'),
        ('cancelled', 'Annulée'),
    ]

    driver = models.ForeignKey(
        UserProfile, limit_choices_to={'role': 'delivery'},
        on_delete=models.CASCADE, related_name='missions'
    )
    order = models.OneToOneField(Order, on_delete=models.CASCADE, related_name='delivery_mission')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='assigned')

    # Coordonnées GPS
    pickup_lat = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True)
    pickup_lng = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True)
    dropoff_lat = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True)
    dropoff_lng = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True)
    current_lat = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True)
    current_lng = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True)

    # Financier
    driver_earning = models.DecimalField(
        max_digits=10, decimal_places=2, default=0,
        help_text="Gain du livreur pour cette mission en XOF"
    )

    # Preuve de livraison
    proof_photo_url = models.URLField(blank=True, help_text="Photo de remise de la commande")
    proof_photo = models.ImageField(upload_to='delivery_proofs/', blank=True, null=True)
    signature_data = models.TextField(blank=True, help_text="Signature numérique encodée base64")

    # Métriques
    estimated_duration = models.PositiveIntegerField(default=0, help_text="Durée estimée en minutes")
    distance_km = models.DecimalField(max_digits=7, decimal_places=2, default=0)

    # Timestamps
    assigned_at = models.DateTimeField(auto_now_add=True)
    accepted_at = models.DateTimeField(blank=True, null=True)
    picked_up_at = models.DateTimeField(blank=True, null=True)
    delivered_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        verbose_name = 'Mission de livraison'
        verbose_name_plural = 'Missions de livraison'
        ordering = ['-assigned_at']

    def __str__(self):
        return f"Mission #{self.id} — {self.order.tracking_code} ({self.get_status_display()})"

    def calculate_earning(self):
        """Calcule le gain livreur : base + bonus distance."""
        base = 500  # XOF
        distance_bonus = float(self.distance_km) * 50  # 50 XOF/km
        return round(base + distance_bonus, 2)
