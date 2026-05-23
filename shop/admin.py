from django.contrib import admin

from .models import (
    Address,
    Category,
    DeliveryMission,
    Order,
    OrderItem,
    Product,
    Profile,
    Review,
    Store,
    WishlistItem,
)


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'slug']
    prepopulated_fields = {'slug': ('name',)}


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'role', 'city', 'is_verified', 'created_at']
    list_filter = ['role', 'is_verified', 'city']
    search_fields = ['user__username', 'user__email']


@admin.register(Store)
class StoreAdmin(admin.ModelAdmin):
    list_display = ['name', 'owner', 'category', 'city', 'is_active', 'is_approved']
    list_filter = ['is_active', 'is_approved', 'city']
    search_fields = ['name', 'description']
    prepopulated_fields = {'slug': ('name',)}


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ['name', 'store', 'category', 'price', 'stock', 'is_active', 'created_at']
    list_filter = ['store', 'category', 'is_active']
    search_fields = ['name', 'description']
    prepopulated_fields = {'slug': ('name',)}


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ['id', 'buyer', 'store', 'total_amount', 'payment_method', 'delivery_type', 'status', 'created_at']
    list_filter = ['payment_method', 'delivery_type', 'status', 'created_at']
    search_fields = ['buyer__username', 'store__name']
    inlines = [OrderItemInline]


@admin.register(Address)
class AddressAdmin(admin.ModelAdmin):
    list_display = ['user', 'label', 'city', 'is_primary']
    list_filter = ['city', 'is_primary']
    search_fields = ['user__username', 'street']


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ['product', 'user', 'rating', 'created_at']
    list_filter = ['rating', 'created_at']
    search_fields = ['product__name', 'user__username']


@admin.register(WishlistItem)
class WishlistItemAdmin(admin.ModelAdmin):
    list_display = ['user', 'product', 'created_at']
    search_fields = ['user__username', 'product__name']


@admin.register(DeliveryMission)
class DeliveryMissionAdmin(admin.ModelAdmin):
    list_display = ['id', 'driver', 'order', 'status', 'assigned_at', 'delivered_at']
    list_filter = ['status', 'assigned_at']
    search_fields = ['driver__user__username', 'order__buyer__username']
