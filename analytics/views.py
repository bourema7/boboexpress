from django.db.models import Count, DecimalField, ExpressionWrapper, F, Sum, Avg
from django.utils import timezone
from rest_framework import permissions, views
from rest_framework.response import Response
import datetime

from delivery.models import DeliveryMission
from orders.models import Order
from payments.models import PaymentTransaction, PlatformRevenue, StoreSettlement
from products.models import Product
from stores.models import Store
from users.models import UserProfile


class DashboardStatsAPIView(views.APIView):
    """Tableau de bord principal — Admin uniquement."""
    permission_classes = [permissions.IsAdminUser]

    def get(self, request):
        today = timezone.now().date()
        start_of_day = timezone.make_aware(datetime.datetime.combine(today, datetime.time.min))
        start_of_week = start_of_day - datetime.timedelta(days=7)
        start_of_month = start_of_day - datetime.timedelta(days=30)

        # ── Commandes ────────────────────────────────────────────────────────
        orders_today = Order.objects.filter(created_at__gte=start_of_day)
        orders_week = Order.objects.filter(created_at__gte=start_of_week)
        orders_month = Order.objects.filter(created_at__gte=start_of_month)

        # ── Revenus ──────────────────────────────────────────────────────────
        revenue_today = orders_today.filter(status='delivered').aggregate(total=Sum('total_amount'))['total'] or 0
        revenue_week = orders_week.filter(status='delivered').aggregate(total=Sum('total_amount'))['total'] or 0
        revenue_month = orders_month.filter(status='delivered').aggregate(total=Sum('total_amount'))['total'] or 0
        total_revenue = Order.objects.filter(status='delivered').aggregate(total=Sum('total_amount'))['total'] or 0

        # ── Commission plateforme (Calcul d'origine) ───────────────────────────
        commission_today = orders_today.filter(status='delivered').annotate(
            comm=ExpressionWrapper(F('total_amount') * F('store__commission_rate') / 100, output_field=DecimalField())
        ).aggregate(total=Sum('comm'))['total'] or 0

        # ── Utilisateurs ─────────────────────────────────────────────────────
        total_users = UserProfile.objects.count()
        new_users_today = UserProfile.objects.filter(created_at__gte=start_of_day).count()
        users_by_role = {
            item['role']: item['count']
            for item in UserProfile.objects.values('role').annotate(count=Count('id'))
        }

        # ── Livreurs actifs ──────────────────────────────────────────────────
        active_drivers = DeliveryMission.objects.filter(
            status__in=['accepted', 'picking_up', 'picked_up', 'on_route']
        ).values('driver').distinct().count()
        available_drivers = UserProfile.objects.filter(role='delivery', is_available=True, is_blocked=False).count()

        # ── Boutiques ────────────────────────────────────────────────────────
        total_stores = Store.objects.count()
        active_stores = Store.objects.filter(is_active=True, is_approved=True).count()
        pending_stores = Store.objects.filter(is_approved=False).count()

        # ── Statuts commandes du jour ─────────────────────────────────────────
        order_status_today = {
            item['status']: item['count']
            for item in orders_today.values('status').annotate(count=Count('id'))
        }

        # ── Dernières commandes ──────────────────────────────────────────────
        recent_orders = list(Order.objects.order_by('-created_at').values(
            'id', 'tracking_code', 'status', 'total_amount', 'store__name', 'buyer__username', 'created_at'
        )[:10])

        # ── Zones populaires (par ville) ─────────────────────────────────────
        popular_zones = list(
            Order.objects.filter(status='delivered')
            .values('address__city')
            .annotate(order_count=Count('id'))
            .order_by('-order_count')[:5]
        )

        # ── Top boutiques (par revenus) ──────────────────────────────────────
        top_stores = list(
            Order.objects.filter(status='delivered')
            .values('store__id', 'store__name')
            .annotate(total_sales=Sum('subtotal'), order_count=Count('id'))
            .order_by('-total_sales')[:5]
        )

        # ── Top produits (par quantité vendue) ────────────────────────────────
        top_products = list(
            Order.objects.filter(status='delivered')
            .values('items__product__id', 'items__product__name')
            .annotate(sold=Sum('items__quantity'))
            .order_by('-sold')[:5]
        )

        # ── Revenus plateforme par source ─────────────────────────────────────
        platform_revenues = {
            item['source']: float(item['total'])
            for item in PlatformRevenue.objects.values('source').annotate(total=Sum('amount'))
        }

        return Response({
            'date': str(today),
            'orders': {
                'today': orders_today.count(),
                'week': orders_week.count(),
                'month': orders_month.count(),
                'status_today': order_status_today,
            },
            'revenue': {
                'today': float(revenue_today),
                'week': float(revenue_week),
                'month': float(revenue_month),
                'total': float(total_revenue),
                'commission_today': float(commission_today),
                'currency': 'XOF',
            },
            'users': {
                'total': total_users,
                'new_today': new_users_today,
                'by_role': users_by_role,
            },
            'delivery': {
                'active_drivers': active_drivers,
                'available_drivers': available_drivers,
            },
            'stores': {
                'total': total_stores,
                'active': active_stores,
                'pending_approval': pending_stores,
            },
            'recent_orders': recent_orders,
            'popular_zones': popular_zones,
            'top_stores': top_stores,
            'top_products': top_products,
            'platform_revenues': platform_revenues,
        })


class RevenueChartAPIView(views.APIView):
    """Données de graphique revenus sur N jours — Admin."""
    permission_classes = [permissions.IsAdminUser]

    def get(self, request):
        days = int(request.query_params.get('days', 30))
        today = timezone.now().date()
        data = []
        for i in range(days - 1, -1, -1):
            day = today - datetime.timedelta(days=i)
            start = timezone.make_aware(datetime.datetime.combine(day, datetime.time.min))
            end = timezone.make_aware(datetime.datetime.combine(day, datetime.time.max))
            revenue = Order.objects.filter(
                status='delivered',
                created_at__range=(start, end)
            ).aggregate(total=Sum('total_amount'))['total'] or 0
            orders_count = Order.objects.filter(created_at__range=(start, end)).count()
            data.append({
                'date': str(day),
                'revenue': float(revenue),
                'orders': orders_count,
            })
        return Response({'days': days, 'data': data, 'currency': 'XOF'})


class DriverStatsAPIView(views.APIView):
    """Statistiques des livreurs — Admin."""
    permission_classes = [permissions.IsAdminUser]

    def get(self, request):
        drivers = UserProfile.objects.filter(role='delivery').select_related('user')
        data = []
        for driver in drivers:
            missions = DeliveryMission.objects.filter(driver=driver)
            data.append({
                'id': driver.id,
                'name': driver.user.get_full_name() or driver.user.username,
                'phone': driver.phone,
                'rating': float(driver.rating),
                'total_deliveries': driver.total_deliveries,
                'wallet_balance': float(driver.wallet_balance),
                'is_available': driver.is_available,
                'is_blocked': driver.is_blocked,
                'active_missions': missions.filter(status__in=['assigned', 'accepted', 'picking_up', 'picked_up', 'on_route']).count(),
                'failed_missions': missions.filter(status='failed').count(),
            })
        return Response({'drivers': data, 'total': len(data)})
