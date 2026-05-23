import random
import string

from django.db import models
from django.contrib.auth.models import User
from django.db.models.signals import post_save
from django.dispatch import receiver

from products.models import Product, ProductVariant, PromoCode
from stores.models import Store
from users.models import Address


class Order(models.Model):
    PAYMENT_METHODS = [
        ('momo', 'Mobile Money'),
        ('card', 'Carte bancaire'),
        ('cod', 'Cash à la livraison'),
        ('wallet', 'Wallet interne'),
    ]
    PAYMENT_STATUS_CHOICES = [
        ('unpaid', 'Non payé'),
        ('pending', 'En attente'),
        ('paid', 'Payé'),
        ('failed', 'Échec'),
        ('refunded', 'Remboursé'),
    ]
    DELIVERY_TYPES = [
        ('standard', 'Standard'),
        ('express', 'Express'),
    ]
    STATUS_CHOICES = [
        ('pending', 'En attente'),
        ('confirmed', 'Confirmée'),
        ('preparing', 'En préparation'),
        ('ready', 'Prête'),
        ('shipping', 'En livraison'),
        ('delivered', 'Livrée'),
        ('cancelled', 'Annulée'),
    ]

    buyer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='orders')
    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='orders')
    address = models.ForeignKey(Address, on_delete=models.SET_NULL, null=True, related_name='orders')
    total_amount = models.DecimalField(max_digits=12, decimal_places=2)
    delivery_fee = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    subtotal = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    discount_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    cashback_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    promo_code = models.ForeignKey(PromoCode, on_delete=models.SET_NULL, null=True, blank=True, related_name='orders')
    
    # Payment fields
    payment_method = models.CharField(max_length=20, choices=PAYMENT_METHODS)
    payment_status = models.CharField(max_length=20, choices=PAYMENT_STATUS_CHOICES, default='unpaid')
    transaction_id = models.CharField(max_length=100, blank=True, null=True)
    
    # Delivery tracking fields
    delivery_type = models.CharField(max_length=20, choices=DELIVERY_TYPES, default='standard')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    tracking_code = models.CharField(max_length=80, blank=True, unique=True)
    payment_otp = models.CharField(max_length=6, blank=True, help_text="Code OTP pour valider le paiement")
    delivery_otp = models.CharField(max_length=6, blank=True, help_text="Code OTP de confirmation de livraison")
    deliverer = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='deliveries')
    
    # GPS Tracking
    current_latitude = models.DecimalField(max_digits=12, decimal_places=9, null=True, blank=True)
    current_longitude = models.DecimalField(max_digits=12, decimal_places=9, null=True, blank=True)
    
    note = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Commande'
        verbose_name_plural = 'Commandes'
        ordering = ['-created_at']

    def __str__(self):
        return f"Commande {self.tracking_code} - {self.buyer.username}"

    def generate_tracking_code(self):
        from django.utils import timezone
        year = timezone.now().year
        suffix = ''.join(random.choices(string.digits, k=5))
        return f"CMD-{year}-{suffix}"

    def generate_otp(self):
        return ''.join(random.choices(string.digits, k=6))

    def save(self, *args, **kwargs):
        if not self.tracking_code:
            code = self.generate_tracking_code()
            while Order.objects.filter(tracking_code=code).exists():
                code = self.generate_tracking_code()
            self.tracking_code = code
        if not self.delivery_otp:
            self.delivery_otp = self.generate_otp()
        if not self.payment_otp:
            self.payment_otp = self.generate_otp()
        super().save(*args, **kwargs)


class OrderItem(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey(Product, on_delete=models.SET_NULL, null=True, related_name='order_items')
    variant = models.ForeignKey(ProductVariant, on_delete=models.SET_NULL, null=True, blank=True, related_name='order_items')
    quantity = models.PositiveIntegerField(default=1)
    unit_price = models.DecimalField(max_digits=12, decimal_places=2)
    special_instructions = models.CharField(max_length=500, blank=True)

    class Meta:
        verbose_name = 'Article de commande'
        verbose_name_plural = 'Articles de commande'

    def __str__(self):
        name = self.product.name if self.product else 'Produit supprimé'
        variant = f' ({self.variant.name})' if self.variant else ''
        return f"{self.quantity} x {name}{variant}"

    @property
    def line_total(self):
        return self.unit_price * self.quantity


class OrderStatusHistory(models.Model):
    """Historique des changements de statut d'une commande."""
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='status_history')
    status = models.CharField(max_length=20, choices=Order.STATUS_CHOICES)
    note = models.CharField(max_length=255, blank=True)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Historique de statut'
        verbose_name_plural = 'Historiques de statuts'
        ordering = ['created_at']

    def __str__(self):
        return f"{self.order.tracking_code} → {self.status}"
