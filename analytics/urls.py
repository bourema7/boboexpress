from django.urls import path
from .views import DashboardStatsAPIView, DriverStatsAPIView, RevenueChartAPIView

urlpatterns = [
    path('dashboard/', DashboardStatsAPIView.as_view(), name='dashboard-stats'),
    path('revenue-chart/', RevenueChartAPIView.as_view(), name='revenue-chart'),
    path('drivers/', DriverStatsAPIView.as_view(), name='driver-stats'),
]
