from django.contrib.auth.models import User
from django.db import models

from stores.models import Store


class Category(models.Model):
    name = models.CharField(max_length=140)
    slug = models.SlugField(max_length=160, unique=True)
    icon_url = models.URLField(blank=True)
    description = models.CharField(max_length=255, blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        verbose_name = 'Catégorie'
        verbose_name_plural = 'Catégories'
        ordering = ['name']

    def __str__(self):
        return self.name


class Product(models.Model):
    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='products')
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, related_name='products')
    name = models.CharField(max_length=250)
    slug = models.SlugField(max_length=260, unique=True)
    description = models.TextField(blank=True)
    price = models.DecimalField(max_digits=12, decimal_places=2)
    stock = models.PositiveIntegerField(default=0)
    image_url = models.URLField(blank=True)
    image = models.ImageField(upload_to='products/', blank=True, null=True)
    is_active = models.BooleanField(default=True)
    is_new = models.BooleanField(default=False, verbose_name="Nouveauté")
    is_promo = models.BooleanField(default=False, verbose_name="En Promotion")
    discount_price = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True, verbose_name="Prix réduit")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Produit'
        verbose_name_plural = 'Produits'
        ordering = ['-created_at']

    def __str__(self):
        return self.name

    @property
    def average_rating(self):
        reviews = self.reviews.all()
        if not reviews:
            return 5.0
        return round(sum(r.rating for r in reviews) / reviews.count(), 1)


class ProductVariant(models.Model):
    """Variante d'un produit : taille, couleur, option, etc."""
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='variants')
    name = models.CharField(max_length=120, help_text="Ex: Taille XL, Couleur Rouge")
    color = models.CharField(max_length=50, blank=True, null=True, help_text="Ex: Rouge, #FF0000")
    size = models.CharField(max_length=50, blank=True, null=True, help_text="Ex: XL, 42, 128GB")
    sku = models.CharField(max_length=100, blank=True)
    price_extra = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    stock = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)

    class Meta:
        verbose_name = 'Variante'
        verbose_name_plural = 'Variantes'

    def __str__(self):
        return f"{self.product.name} - {self.name}"

    @property
    def final_price(self):
        return self.product.price + self.price_extra


class PromoCode(models.Model):
    code = models.CharField(max_length=50, unique=True)
    discount_percent = models.PositiveIntegerField(default=0)
    discount_fixed = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    cashback_percent = models.PositiveIntegerField(default=0)
    min_order_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    max_discount_amount = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    active = models.BooleanField(default=True)
    free_delivery = models.BooleanField(default=False)
    used_count = models.PositiveIntegerField(default=0)

    class Meta:
        verbose_name = 'Code promo'
        verbose_name_plural = 'Codes promo'

    def __str__(self):
        return self.code


class Favorite(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='favorites')
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='favorited_by')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'product')
        verbose_name = 'Favori'
        verbose_name_plural = 'Favoris'


class Review(models.Model):
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='reviews')
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='reviews')
    username = models.CharField(max_length=180, blank=True)
    rating = models.PositiveSmallIntegerField(default=5)
    comment = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Avis'
        verbose_name_plural = 'Avis'
        ordering = ['-created_at']


class Cart(models.Model):
    """Panier persistant par utilisateur."""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='cart')
    store = models.ForeignKey(Store, on_delete=models.SET_NULL, null=True, blank=True,
                                help_text="Un panier appartient à une seule boutique à la fois")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Panier'
        verbose_name_plural = 'Paniers'

    def __str__(self):
        return f"Panier de {self.user.username}"

    @property
    def total(self):
        return sum(item.line_total for item in self.items.all())


class CartItem(models.Model):
    """Ligne dans un panier."""
    cart = models.ForeignKey(Cart, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    variant = models.ForeignKey(ProductVariant, on_delete=models.SET_NULL, null=True, blank=True)
    quantity = models.PositiveIntegerField(default=1)
    special_instructions = models.CharField(max_length=500, blank=True)

    class Meta:
        verbose_name = 'Article du panier'
        verbose_name_plural = 'Articles du panier'
        unique_together = [['cart', 'product', 'variant']]

    def __str__(self):
        return f"{self.quantity}x {self.product.name}"

    @property
    def unit_price(self):
        if self.variant:
            return self.variant.final_price
        return self.product.price

    @property
    def line_total(self):
        return self.unit_price * self.quantity
