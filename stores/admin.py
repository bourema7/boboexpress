from django.contrib import admin
from .models import Store, StoreCategory, Promotion


@admin.register(StoreCategory)
class StoreCategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'slug']
    prepopulated_fields = {'slug': ('name',)}


@admin.register(Store)
class StoreAdmin(admin.ModelAdmin):
    list_display = ['name', 'owner', 'type', 'category', 'city', 'is_active', 'is_approved', 'is_premium']
    list_filter = ['type', 'is_active', 'is_approved', 'is_premium', 'city']
    search_fields = ['name', 'description', 'owner__user__username']
    prepopulated_fields = {'slug': ('name',)}
    readonly_fields = ['average_rating', 'total_orders']
    actions = ['approve_stores', 'reject_stores']

    def approve_stores(self, request, queryset):
        queryset.update(is_approved=True)
    approve_stores.short_description = 'Approuver les boutiques sélectionnées'

    def reject_stores(self, request, queryset):
        queryset.update(is_approved=False)
    reject_stores.short_description = 'Rejeter les boutiques sélectionnées'


@admin.register(Promotion)
class PromotionAdmin(admin.ModelAdmin):
    list_display = ['title', 'store', 'discount_percent', 'is_active', 'start_date', 'end_date']
    list_filter = ['is_active']
    search_fields = ['title', 'store__name']
