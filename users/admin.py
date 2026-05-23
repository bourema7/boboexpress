from django.contrib import admin
from django.contrib.auth.models import User
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import UserProfile, Address, OTPCode


class UserProfileInline(admin.StackedInline):
    model = UserProfile
    can_delete = False
    verbose_name_plural = 'Profil'
    fields = ['role', 'phone', 'city', 'company_name', 'wallet_balance', 'is_verified', 'is_blocked', 'is_available', 'rating', 'total_deliveries']


class UserAdmin(BaseUserAdmin):
    inlines = [UserProfileInline]
    list_display = ['username', 'email', 'first_name', 'last_name', 'is_active', 'get_role']
    list_filter = ['is_active', 'profile__role', 'profile__is_verified', 'profile__is_blocked']

    def get_role(self, obj):
        return getattr(getattr(obj, 'profile', None), 'get_role_display', lambda: '—')()
    get_role.short_description = 'Rôle'


admin.site.unregister(User)
admin.site.register(User, UserAdmin)


@admin.register(Address)
class AddressAdmin(admin.ModelAdmin):
    list_display = ['user', 'label', 'type', 'city', 'is_primary']
    list_filter = ['type', 'is_primary']
    search_fields = ['user__username', 'city', 'street']


@admin.register(OTPCode)
class OTPCodeAdmin(admin.ModelAdmin):
    list_display = ['user', 'code', 'expires_at', 'is_used']
