from django.db import models
from django.contrib.auth.models import User

from orders.models import Order
from stores.models import Store


class PaymentTransaction(models.Model):
    STATUS_CHOICES = [
        ('pending', 'En attente'),
        ('completed', 'Terminé'),
        ('failed', 'Échoué'),
        ('refunded', 'Remboursé'),
    ]
    METHOD_CHOICES = [
        ('momo', 'Mobile Money'),
        ('card', 'Carte bancaire'),
        ('cod', 'Cash à la livraison'),
        ('wallet', 'Wallet interne'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='payments')
    order = models.OneToOneField(Order, on_delete=models.CASCADE, related_name='payment')
    method = models.CharField(max_length=20, choices=METHOD_CHOICES)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    currency = models.CharField(max_length=10, default='XOF')
    transaction_id = models.CharField(max_length=140, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Transaction'
        verbose_name_plural = 'Transactions'

    def __str__(self):
        return f"{self.method} {self.amount} XOF ({self.status})"


class WalletTransaction(models.Model):
    TYPE_CHOICES = [
        ('credit', 'Crédit'),
        ('debit', 'Débit'),
    ]
    SOURCE_CHOICES = [
        ('order_payment', 'Paiement commande'),
        ('refund', 'Remboursement'),
        ('cashback', 'Cashback promo'),
        ('earning', 'Gain livraison'),
        ('withdrawal', 'Retrait'),
        ('top_up', 'Rechargement'),
        ('commission', 'Commission plateforme'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='wallet_transactions')
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    type = models.CharField(max_length=10, choices=TYPE_CHOICES)
    source = models.CharField(max_length=30, choices=SOURCE_CHOICES, default='order_payment')
    description = models.CharField(max_length=255)
    balance_after = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Transaction de wallet'
        verbose_name_plural = 'Transactions de wallet'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.type} {self.amount} XOF — {self.source}"


class StoreSettlement(models.Model):
    """Reversement financier à un commerçant."""
    STATUS_CHOICES = [
        ('pending', 'En attente'),
        ('processing', 'En traitement'),
        ('paid', 'Payé'),
        ('failed', 'Échoué'),
    ]
    PERIOD_CHOICES = [
        ('weekly', 'Hebdomadaire'),
        ('monthly', 'Mensuel'),
    ]

    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='settlements')
    period = models.CharField(max_length=10, choices=PERIOD_CHOICES, default='weekly')
    period_start = models.DateField()
    period_end = models.DateField()
    gross_amount = models.DecimalField(max_digits=12, decimal_places=2, help_text="Montant brut des ventes")
    commission_amount = models.DecimalField(max_digits=10, decimal_places=2, help_text="Commission plateforme")
    net_amount = models.DecimalField(max_digits=12, decimal_places=2, help_text="Montant net reversé")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    payment_reference = models.CharField(max_length=200, blank=True)
    paid_at = models.DateTimeField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Reversement boutique'
        verbose_name_plural = 'Reversements boutiques'
        ordering = ['-created_at']

    def __str__(self):
        return f"Reversement {self.store.name} — {self.period_start} → {self.period_end} ({self.get_status_display()})"


class PlatformRevenue(models.Model):
    """Traçabilité des revenus de la plateforme."""
    SOURCE_CHOICES = [
        ('commission', 'Commission commande'),
        ('delivery_fee', 'Frais de livraison'),
        ('ad', 'Publicité boutique'),
        ('subscription', 'Abonnement premium'),
        ('penalty', 'Pénalité'),
    ]

    source = models.CharField(max_length=30, choices=SOURCE_CHOICES)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    order = models.ForeignKey(Order, on_delete=models.SET_NULL, null=True, blank=True, related_name='platform_revenues')
    store = models.ForeignKey(Store, on_delete=models.SET_NULL, null=True, blank=True, related_name='platform_revenues')
    description = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Revenu plateforme'
        verbose_name_plural = 'Revenus plateforme'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.source} — {self.amount} XOF"


class StoreSubscription(models.Model):
    """Abonnement premium d'une boutique."""
    PLAN_CHOICES = [
        ('basic', 'Basic — Gratuit'),
        ('pro', 'Pro — 5000 XOF/mois'),
        ('enterprise', 'Enterprise — 15000 XOF/mois'),
    ]

    store = models.OneToOneField(Store, on_delete=models.CASCADE, related_name='subscription')
    plan = models.CharField(max_length=20, choices=PLAN_CHOICES, default='basic')
    is_active = models.BooleanField(default=True)
    start_date = models.DateField()
    end_date = models.DateField()
    amount_paid = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    renewed_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Abonnement boutique'
        verbose_name_plural = 'Abonnements boutiques'

    def __str__(self):
        return f"{self.store.name} — Plan {self.plan}"
