import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'BoboExpress.settings')
django.setup()

from orders.models import Order, OrderItem, OrderStatusHistory
from delivery.models import DeliveryMission
from notifications.models import NotificationLog

def cleanup_orders():
    print("Starting order cleanup...")
    
    # Missions depend on orders
    mission_count = DeliveryMission.objects.all().count()
    DeliveryMission.objects.all().delete()
    print(f"Deleted {mission_count} delivery missions.")
    
    # Status history depends on orders
    history_count = OrderStatusHistory.objects.all().count()
    OrderStatusHistory.objects.all().delete()
    print(f"Deleted {history_count} status history entries.")
    
    # Order items depend on orders
    item_count = OrderItem.objects.all().count()
    OrderItem.objects.all().delete()
    print(f"Deleted {item_count} order items.")
    
    # Notifications related to orders
    notif_count = NotificationLog.objects.exclude(related_order__isnull=True).count()
    NotificationLog.objects.exclude(related_order__isnull=True).delete()
    print(f"Deleted {notif_count} order-related notifications.")
    
    # Finally orders
    order_count = Order.objects.all().count()
    Order.objects.all().delete()
    print(f"Deleted {order_count} orders.")
    
    print("Cleanup complete!")

if __name__ == "__main__":
    cleanup_orders()
