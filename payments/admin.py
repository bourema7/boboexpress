from django.contrib import admin
from .models import PaymentTransaction, WalletTransaction, StoreSettlement, PlatformRevenue, StoreSubscription


@admin.register(PaymentTransaction)
class PaymentTransactionAdmin(admin.ModelAdmin):
    list_display = ['user', 'order', 'method', 'amount', 'currency', 'status', 'created_at']
    list_filter = ['method', 'status']
    search_fields = ['user__username', 'order__tracking_code', 'transaction_id']


@admin.register(WalletTransaction)
class WalletTransactionAdmin(admin.ModelAdmin):
    list_display = ['user', 'type', 'source', 'amount', 'balance_after', 'created_at']
    list_filter = ['type', 'source']
    search_fields = ['user__username']


@admin.register(StoreSettlement)
class StoreSettlementAdmin(admin.ModelAdmin):
    list_display = ['store', 'period', 'period_start', 'period_end', 'gross_amount', 'commission_amount', 'net_amount', 'status', 'paid_at']
    list_filter = ['status', 'period']
    search_fields = ['store__name']
    actions = ['mark_as_paid']

    def mark_as_paid(self, request, queryset):
        from django.utils import timezone
        queryset.update(status='paid', paid_at=timezone.now())
    mark_as_paid.short_description = 'Marquer comme payés'


@admin.register(PlatformRevenue)
class PlatformRevenueAdmin(admin.ModelAdmin):
    list_display = ['source', 'amount', 'store', 'created_at']
    list_filter = ['source']


@admin.register(StoreSubscription)
class StoreSubscriptionAdmin(admin.ModelAdmin):
    list_display = ['store', 'plan', 'is_active', 'start_date', 'end_date', 'amount_paid']
    list_filter = ['plan', 'is_active']
