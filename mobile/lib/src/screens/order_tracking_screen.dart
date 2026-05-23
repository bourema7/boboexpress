import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({Key? key, required this.orderId})
      : super(key: key);

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  int _currentStep = 0; // 0: Confirmée, 1: Préparation, 2: Livraison, 3: Livrée

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Commande Confirmée',
      'desc': 'Votre commande a été reçue',
      'icon': Icons.check_circle_outline
    },
    {
      'title': 'En Préparation',
      'desc': 'Le marchand prépare vos articles',
      'icon': Icons.inventory_2_outlined
    },
    {
      'title': 'En Cours de Livraison',
      'desc': 'Le livreur est en route vers vous',
      'icon': Icons.delivery_dining_outlined
    },
    {
      'title': 'Livrée',
      'desc': 'Profitez de vos achats !',
      'icon': Icons.home_outlined
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final id = int.tryParse(widget.orderId);
      if (id != null) {
        final order = await ApiService().getOrderById(id);
        if (order != null) {
          setState(() {
            _order = order;
            _currentStep = _mapStatusToStep(order['status']);
          });
        }
      }
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int _mapStatusToStep(String? status) {
    switch (status) {
      case 'pending':
      case 'confirmed':
        return 0;
      case 'preparing':
      case 'ready':
        return 1;
      case 'shipping':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Suivi de commande')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Suivi de commande')),
        body: const Center(
            child: Text('Impossible de charger les détails de la commande.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Suivi Commande #${widget.orderId}',
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrderDetails,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatusHeader(colorScheme),
            _buildOtpCard(colorScheme),
            _buildTrackingTimeline(colorScheme),
            const SizedBox(height: 24),
            if (_order!['deliverer_profile'] != null)
              _buildDeliveryInfo(colorScheme, _order!['deliverer_profile']),
            const SizedBox(height: 40),
            if (_order!['deliverer_profile'] != null)
              _buildContactButtons(colorScheme, _order!['deliverer_profile']),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/receipt', arguments: _order),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('VOIR LE REÇU DE PAIEMENT'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: colorScheme.primary, shape: BoxShape.circle),
            child:
                const Icon(Icons.local_shipping, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Statut actuel',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  _order!['status_display'] ?? 'Chargement...',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingTimeline(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: List.generate(_steps.length, (index) {
          final bool isCompleted = index < _currentStep;
          final bool isCurrent = index == _currentStep;
          final bool isLast = index == _steps.length - 1;

          return IntrinsicHeight(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isCompleted || isCurrent
                            ? colorScheme.primary
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : _steps[index]['icon'],
                        color: isCompleted || isCurrent
                            ? Colors.white
                            : Colors.grey,
                        size: 16,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isCompleted
                              ? colorScheme.primary
                              : Colors.grey.shade200,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        _steps[index]['title'],
                        style: TextStyle(
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                          fontSize: 16,
                          color: isCurrent || isCompleted
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                      Text(
                        _steps[index]['desc'],
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDeliveryInfo(
      ColorScheme colorScheme, Map<String, dynamic> driver) {
    final String fullName =
        "${driver['first_name'] ?? ''} ${driver['last_name'] ?? ''}".trim();
    final String displayName =
        fullName.isNotEmpty ? fullName : (driver['username'] ?? 'Livreur');
    final String? imageUrl = driver['profile_image'];
    final double rating =
        double.tryParse(driver['rating']?.toString() ?? '5.0') ?? 5.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Votre Livreur',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage:
                    imageUrl != null ? NetworkImage(imageUrl) : null,
                child: imageUrl == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(driver['city'] ?? 'Bobo-Dioulasso',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(rating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButtons(
      ColorScheme colorScheme, Map<String, dynamic> driver) {
    final String? phone = driver['phone'];
    if (phone == null || phone.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final String cleanPhone =
                    phone.replaceAll(RegExp(r'[^0-9]'), '');
                final String message =
                    "Bonjour, je vous contacte pour ma commande BoboExpress #${widget.orderId}.";
                final Uri whatsappUri = Uri.parse(
                    "https://wa.me/$cleanPhone?text=${Uri.encodeFull(message)}");

                if (await canLaunchUrl(whatsappUri)) {
                  await launchUrl(whatsappUri,
                      mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Impossible d\'ouvrir WhatsApp')),
                  );
                }
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('WhatsApp'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final Uri launchUri = Uri(scheme: 'tel', path: phone);
                if (await canLaunchUrl(launchUri)) {
                  await launchUrl(launchUri);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Impossible de lancer l\'appel')),
                  );
                }
              },
              icon: const Icon(Icons.phone_outlined),
              label: const Text('Appeler'),
              style: ElevatedButton.styleFrom(
                primary: colorScheme.primary,
                onPrimary: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpCard(ColorScheme colorScheme) {
    if (_order == null ||
        _order!['delivery_otp'] == null ||
        _order!['status'] == 'delivered' ||
        _order!['status'] == 'cancelled') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'CODE DE CONFIRMATION',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.vpn_key_outlined, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                _order!['delivery_otp'].toString(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'À donner au livreur pour valider la réception',
            style: TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
