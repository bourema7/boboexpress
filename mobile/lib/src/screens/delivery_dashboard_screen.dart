import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryDashboardScreen> createState() =>
      _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _apiService.getOrders();
      setState(() {
        _orders = orders
            .where((o) => ['ready', 'shipping'].contains(o['status']))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int orderId, String action) async {
    setState(() => _isLoading = true);
    try {
      final response =
          await _apiService.post('/orders/orders/$orderId/$action/', {});
      if (response.statusCode == 200) {
        await _loadOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Impossible de mettre à jour le statut.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour.')));
    }
    setState(() => _isLoading = false);
  }

  void _showCelebrationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            TweenAnimationBuilder(
              duration: const Duration(seconds: 1),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                        color: Colors.green, shape: BoxShape.circle),
                    child:
                        const Icon(Icons.check, color: Colors.white, size: 50),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Félicitations !',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Livraison effectuée avec succès.\nVos gains ont été mis à jour.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  primary: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('CONTINUER',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyOtp(int orderId) async {
    final otpController = TextEditingController();

    Future<void> submitOtp() async {
      try {
        final response = await _apiService.post(
            '/orders/orders/$orderId/verify_otp/', {'otp': otpController.text});
        if (response.statusCode == 200) {
          Navigator.pop(context);
          _showCelebrationDialog();
          _loadOrders();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Code OTP incorrect.'),
              backgroundColor: Colors.red));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur de validation.')));
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Valider la livraison'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Demandez le code OTP au client pour confirmer la réception.'),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Code OTP (6 chiffres)',
                  border: OutlineInputBorder()),
              maxLength: 6,
              onSubmitted: (_) => submitOtp(),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ANNULER')),
          ElevatedButton(
            onPressed: submitOtp,
            child: const Text('VALIDER'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final profile = authService.userProfile;
    final bool isAvailable = profile?['is_available'] ?? true;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(profile, isAvailable, authService, colorScheme),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsRow(profile),
                    const SizedBox(height: 24),
                    Text(
                      _orders.isEmpty
                          ? 'Aucune livraison en cours'
                          : 'Vos livraisons actives',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverToBoxAdapter(
                  child: Center(
                      child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator())))
            else if (_orders.isEmpty)
              _buildEmptyState()
            else
              _buildMissionsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverToBoxAdapter(
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Vous n\'avez pas encore de mission.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(Map<String, dynamic>? profile, bool isAvailable,
      AuthService authService, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: colorScheme.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          isAvailable ? 'En ligne 🟢' : 'Hors ligne 🔴',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      actions: [
        Switch(
          value: isAvailable,
          onChanged: (val) => authService.updateAvailability(val),
          activeColor: Colors.white,
          activeTrackColor: Colors.greenAccent,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatsRow(Map<String, dynamic>? profile) {
    return Row(
      children: [
        _buildStatCard('Gains', '${profile?['wallet_balance'] ?? 0} F',
            Icons.account_balance_wallet, Colors.orange),
        const SizedBox(width: 12),
        _buildStatCard('Livraisons', '${profile?['total_deliveries'] ?? 0}',
            Icons.local_shipping, Colors.blue),
        const SizedBox(width: 12),
        _buildStatCard(
            'Note', '${profile?['rating'] ?? 5.0}', Icons.star, Colors.amber),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(title,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionsList(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final o = _orders[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.location_on, color: Colors.blue),
                  ),
                  title: Text('Commande #${o['id'] ?? '?'}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Client: ${o['user']?['username'] ?? 'Inconnu'}\n'
                    '${o['address']?['street'] ?? 'Adresse non spécifiée'}, ${o['address']?['city'] ?? 'Bobo'}',
                  ),
                  trailing: Text('${o['total_amount'] ?? 0} F',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      if (o['status'] == 'ready')
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                _updateStatus(o['id'], 'mark_shipping'),
                            style: ElevatedButton.styleFrom(
                                primary: Colors.orange,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            child: const Text('RÉCUPÉRER LE COLIS'),
                          ),
                        ),
                      if (o['status'] == 'shipping')
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _verifyOtp(o['id']),
                            style: ElevatedButton.styleFrom(
                                primary: const Color(0xFFFA7456),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            child: const Text('LIVRER (OTP)'),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.pushNamed(
                            context, '/tracking',
                            arguments: {'orderId': o['id']}),
                        icon:
                            const Icon(Icons.map_outlined, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        childCount: _orders.length,
      ),
    );
  }
}
