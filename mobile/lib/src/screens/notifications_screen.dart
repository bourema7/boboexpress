import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final notifications = await _apiService.getNotifications();
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'order_confirmed':
        return Icons.check_circle_outline;
      case 'order_cancelled':
        return Icons.cancel_outlined;
      case 'preparing':
        return Icons.restaurant_outlined;
      case 'order_ready':
        return Icons.inventory_2_outlined;
      case 'new_mission':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.celebration_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColor(String? type) {
    switch (type) {
      case 'order_confirmed':
        return Colors.green;
      case 'order_cancelled':
        return Colors.red;
      case 'preparing':
        return Colors.blue;
      case 'order_ready':
        return Colors.orange;
      case 'new_mission':
        return const Color(0xFFFA7456);
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: _loadNotifications),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: const Color(0xFFFA7456),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) =>
                        _buildNotifCard(_notifications[index]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Aucune notification',
              style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          const SizedBox(height: 8),
          Text('Vous serez alerté des mises à jour de vos commandes',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildNotifCard(dynamic n) {
    final type = n['notification_type'] as String?;
    final color = _getColor(type);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_getIcon(type), color: color, size: 22),
        ),
        title: Text(n['title'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(n['message'] ?? '',
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ),
        trailing: n['related_order'] != null
            ? TextButton(
                onPressed: () => Navigator.pushNamed(context, '/tracking',
                    arguments: {'orderId': n['related_order']}),
                child: const Text('VOIR',
                    style: TextStyle(
                        color: Color(0xFFFA7456),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              )
            : null,
      ),
    );
  }
}
