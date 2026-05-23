from django.contrib.auth.models import User
from django.db import models

from users.models import UserProfile


class StoreCategory(models.Model):
    name = models.CharField(max_length=120)
    slug = models.SlugField(max_length=140, unique=True)
    icon_url = models.URLField(blank=True)

    class Meta:
        verbose_name = 'Catégorie de boutique'
        verbose_name_plural = 'Catégories de boutiques'
        ordering = ['name']

    def __str__(self):
        return self.name


class Store(models.Model):
    TYPE_CHOICES = [
        ('restaurant', 'Restaurant'),
        ('supermarket', 'Supermarché'),
        ('pharmacy', 'Pharmacie'),
        ('clothing', 'Vêtements'),
        ('package', 'Colis / Coursier'),
        ('other', 'Divers'),
    ]

    owner = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name='stores')
    name = models.CharField(max_length=250)
    slug = models.SlugField(max_length=260, unique=True)
    description = models.TextField(blank=True)
    type = models.CharField(max_length=20, choices=TYPE_CHOICES, default='other')
    category = models.ForeignKey(StoreCategory, on_delete=models.SET_NULL, null=True, blank=True, related_name='stores')
    city = models.CharField(max_length=120)
    address = models.CharField(max_length=300, blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True)
    phone = models.CharField(max_length=30, blank=True)
    logo_url = models.URLField(blank=True)
    cover_url = models.URLField(blank=True)
    opening_hours = models.JSONField(
        default=dict, blank=True,
        help_text='Ex: {"lun": "08:00-20:00", "mar": "08:00-20:00", "dim": "fermé"}'
    )
    is_active = models.BooleanField(default=True)
    is_approved = models.BooleanField(default=False)
    is_premium = models.BooleanField(default=False)
    premium_expires_at = models.DateTimeField(blank=True, null=True)
    commission_rate = models.DecimalField(max_digits=5, decimal_places=2, default=5.0)
    
    # Payment info
    MOMO_CHOICES = [
        ('orange', 'Orange Money'),
        ('moov', 'Moov Money'),
    ]
    momo_type = models.CharField(max_length=20, choices=MOMO_CHOICES, default='orange')
    momo_number = models.CharField(max_length=30, blank=True, help_text="Numéro pour recevoir les paiements")
    
    average_rating = models.DecimalField(max_digits=3, decimal_places=2, default=0)
    total_orders = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Boutique'
        verbose_name_plural = 'Boutiques'
        ordering = ['-is_premium', '-created_at']

    def __str__(self):
        return self.name


class Promotion(models.Model):
    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='promotions')
    title = models.CharField(max_length=180)
    description = models.TextField(blank=True)
    discount_percent = models.PositiveIntegerField(default=10)
    min_order_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    is_active = models.BooleanField(default=True)
    start_date = models.DateTimeField()
    end_date = models.DateTimeField()
    banner_url = models.URLField(blank=True)

    class Meta:
        verbose_name = 'Promotion'
        verbose_name_plural = 'Promotions'

    def __str__(self):
        return f"{self.title} ({self.store.name})"
