import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'admin_product_form_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _products = [];
  List<dynamic> _orders = [];
  bool _isLoadingProducts = true;
  bool _isLoadingOrders = true;
  bool _isUpdatingStatus = false;

  bool _isNewDriver(dynamic createdAt) {
    if (createdAt == null || createdAt is! String) return false;
    try {
      final date = DateTime.parse(createdAt);
      final difference = DateTime.now().difference(date);
      return difference.inDays >= 0 && difference.inDays < 3;
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadOrders();
  }

  Future<void> _cancelOrder(int orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la commande ?'),
        content: const Text(
            'Voulez-vous vraiment annuler cette commande ? Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('RETOUR')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('ANNULER', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isUpdatingStatus = true);
    try {
      final response =
          await _apiService.post('/orders/orders/$orderId/cancel/', {});
      if (response.statusCode == 200) {
        _loadOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de l\'annulation.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Erreur de connexion.')));
    } finally {
      setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _loadProducts() async {
    try {
      setState(() => _isLoadingProducts = true);
      final prods = await _apiService.getProducts();
      setState(() {
        _products = prods;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _loadOrders() async {
    try {
      setState(() => _isLoadingOrders = true);
      final ords = await _apiService.getOrders();
      setState(() {
        _orders = ords;
        _isLoadingOrders = false;
      });
    } catch (e) {
      setState(() => _isLoadingOrders = false);
    }
  }

  Future<void> _updateOrderStatus(int orderId, String action) async {
    try {
      setState(() => _isUpdatingStatus = true);
      final response =
          await _apiService.post('/orders/orders/$orderId/$action/', {});

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _loadOrders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Action réussie : $action'),
                backgroundColor: Colors.green),
          );
        }
      } else {
        String errorMsg = 'Erreur lors de l\'action';
        try {
          final data = jsonDecode(response.body);
          errorMsg = data['detail'] ?? data['message'] ?? response.body;
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur de connexion: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Espace Marchand',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            labelColor: const Color(0xFFFA7456),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFFA7456),
            labelStyle:
                const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            tabs: [
              const Tab(
                  text: 'PRODUITS', icon: Icon(Icons.inventory_2_outlined)),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('COMMANDES'),
                    if (_orders
                        .where((o) => o['status'] == 'pending')
                        .isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        child: Text(
                          _orders
                              .where((o) => o['status'] == 'pending')
                              .length
                              .toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                icon: const Icon(Icons.receipt_long_outlined),
              ),
              const Tab(text: 'PERFORM.', icon: Icon(Icons.bar_chart_rounded)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: () {
                _loadProducts();
                _loadOrders();
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildProductsTab(),
            _buildOrdersTab(),
            _buildPerformanceTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRevenueCard(),
          const SizedBox(height: 24),
          const Text('Ventes par jour',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildCustomBarChart(),
          const SizedBox(height: 24),
          const Text('Top Produits',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildTopProductsList(),
        ],
      ),
    );
  }

  Widget _buildRevenueCard() {
    double total7Days = 0;
    int ordersCount = 0;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    for (var o in _orders) {
      if (o['status'] == 'delivered' && o['created_at'] != null) {
        try {
          final date = DateTime.parse(o['created_at']);
          if (date.isAfter(sevenDaysAgo)) {
            total7Days +=
                double.tryParse(o['total_amount']?.toString() ?? '0') ?? 0;
            ordersCount++;
          }
        } catch (_) {}
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFA7456), Color(0xFFFF9E80)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFFA7456).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chiffre d\'affaires (7j)',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('${total7Days.toStringAsFixed(0)} XOF',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('$ordersCount commandes livrées',
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCustomBarChart() {
    final now = DateTime.now();
    List<double> dailyTotals = List.filled(7, 0.0);
    List<String> days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    List<String> last7DaysLabels = [];
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      last7DaysLabels.add(days[d.weekday - 1]);
    }

    double maxTotal = 0.0;
    for (var o in _orders) {
      if (o['status'] == 'delivered' && o['created_at'] != null) {
        try {
          final date = DateTime.parse(o['created_at']);
          final difference = now.difference(date).inDays;
          if (difference >= 0 && difference < 7) {
            final idx = 6 - difference;
            dailyTotals[idx] +=
                double.tryParse(o['total_amount']?.toString() ?? '0') ?? 0;
            if (dailyTotals[idx] > maxTotal) maxTotal = dailyTotals[idx];
          }
        } catch (_) {}
      }
    }

    List<double> values =
        dailyTotals.map((e) => maxTotal > 0 ? (e / maxTotal) : 0.0).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                height: 120 * values[index],
                width: 25,
                decoration: BoxDecoration(
                  color:
                      index == 6 ? const Color(0xFFFA7456) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Text(last7DaysLabels[index],
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTopProductsList() {
    if (_products.isEmpty) return const Text('Aucun produit');

    Map<int, int> productSales = {};
    for (var p in _products) {
      productSales[p['id']] = 0;
    }

    for (var o in _orders) {
      if (o['status'] != 'cancelled' && o['status'] != 'failed') {
        final List items =
            (o['items'] != null && o['items'] is List) ? o['items'] : [];
        for (var item in items) {
          final int productId = item['product']?['id'] ?? 0;
          final int qty = item['quantity'] ?? 1;
          if (productSales.containsKey(productId)) {
            productSales[productId] = productSales[productId]! + qty;
          }
        }
      }
    }

    final sortedProducts = List.from(_products)
      ..sort((a, b) {
        final salesA = productSales[a['id']] ?? 0;
        final salesB = productSales[b['id']] ?? 0;
        return salesB.compareTo(salesA);
      });

    final topProds = sortedProducts.take(5).toList();

    return Column(
      children: topProds
          .map((p) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const CircleAvatar(
                        backgroundColor: Color(0xFFFA7456), radius: 4),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(p['name'] ?? 'Produit',
                            style:
                                const TextStyle(fontWeight: FontWeight.w500))),
                    Text('${productSales[p['id']] ?? 0} commandes',
                        style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildProductsTab() {
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        _buildStatsRow(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminProductFormScreen()),
              ).then((_) => _loadProducts());
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('AJOUTER UN PRODUIT',
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              primary: const Color(0xFFFA7456),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        Expanded(
          child: _products.isEmpty
              ? _buildEmptyState('Aucun produit')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _products.length,
                  itemBuilder: (context, index) =>
                      _buildProductCard(_products[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab() {
    if (_isLoadingOrders) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_orders.isEmpty) {
      return _buildEmptyState('Aucune commande');
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: const Color(0xFFFA7456),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _orders.length,
        itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
      ),
    );
  }

  Widget _buildStatsRow() {
    final pendingCount = _orders.where((o) => o['status'] == 'pending').length;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCircle(
              'Produits', _products.length.toString(), Colors.blue),
          _buildStatCircle(
              'En attente', pendingCount.toString(), Colors.orange),
          _buildStatCircle(
              'Total Cmd', _orders.length.toString(), Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatCircle(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Center(
              child: Text(value,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18))),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildProductCard(dynamic p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 50,
            height: 50,
            child: (p['image'] != null && p['image'] != '')
                ? Image.network(p['image'], fit: BoxFit.cover)
                : (p['image_url'] != null && p['image_url'] != '')
                    ? Image.network(p['image_url'], fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey)),
          ),
        ),
        title: Text(p['name'],
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text('${p['price']} XOF • Stock: ${p['stock']}',
            style: const TextStyle(color: Color(0xFFFA7456))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon:
                  const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AdminProductFormScreen(product: p)),
                ).then((_) => _loadProducts());
              },
            ),
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => _deleteProduct(p['id']),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProduct(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text('Voulez-vous vraiment supprimer ce produit ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ANNULER')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('SUPPRIMER', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoadingProducts = true);
    final response = await _apiService.delete('/products/products/$id/');
    if (response.statusCode == 204) {
      _loadProducts();
    } else {
      setState(() => _isLoadingProducts = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Erreur lors de la suppression'),
            backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildOrderCard(dynamic o) {
    try {
      final int id = o['id'] ?? 0;
      final String status = o['status'] ?? 'unknown';
      final String statusDisplay = o['status_display'] ?? status;
      final String trackingCode = o['tracking_code'] ?? 'N/A';
      final String total = (o['total_amount'] ?? 0).toString();
      final List items =
          (o['items'] != null && o['items'] is List) ? o['items'] : [];

      return Card(
        key: ValueKey('order_${id}_$status'),
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
                left: BorderSide(color: _getStatusColor(status), width: 4)),
          ),
          child: Column(
            children: [
              ListTile(
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Cmd #$id',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        statusDisplay,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  '$total XOF • $statusDisplay',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black87, fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat,
                          color: Colors.green, size: 20),
                      onPressed: () async {
                        final String phone = o['user_phone'] ??
                            o['buyer_phone'] ??
                            "22667774512";
                        final String msg =
                            "Bonjour, je suis le marchand BoboExpress pour la commande #$id.";
                        final Uri uri = Uri.parse(
                            "https://wa.me/$phone?text=${Uri.encodeFull(msg)}");
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                    SizedBox(
                      width: 112,
                      child: Text(
                        trackingCode,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ...items.map((item) {
                      final prodName = (item['product'] != null)
                          ? (item['product']['name'] ?? 'Produit')
                          : 'Produit';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item['quantity'] ?? 1}x $prodName',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.black87, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('${item['line_total'] ?? 0} XOF',
                                style: const TextStyle(
                                    color: Colors.black87, fontSize: 12)),
                          ],
                        ),
                      );
                    }).toList(),
                    if (items.isEmpty)
                      const Text('Pas de détails articles',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const Divider(),
                    if (_isUpdatingStatus)
                      const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator())
                    else
                      _buildActionButtons(o),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return Card(
        color: Colors.red.shade50,
        margin: const EdgeInsets.only(bottom: 16),
        child: ListTile(
          leading: const Icon(Icons.error_outline, color: Colors.red),
          title: const Text('Erreur d\'affichage',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          subtitle: Text(e.toString(), style: const TextStyle(fontSize: 10)),
        ),
      );
    }
  }

  void _showDelivererPicker(dynamic order) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choisir un livreur disponible',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              FutureBuilder<List<dynamic>>(
                future: _apiService.getAvailableDrivers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator()));
                  }
                  final drivers = snapshot.data ?? [];
                  if (drivers.isEmpty) {
                    return const Center(
                        child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('Aucun livreur en ligne actuellement.',
                                style: TextStyle(color: Colors.grey))));
                  }
                  return Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: drivers.length,
                      itemBuilder: (context, index) {
                        final d = drivers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: (d['profile_image'] != null)
                                ? NetworkImage(d['profile_image'])
                                : null,
                            child: (d['profile_image'] == null)
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(d['username'] ?? 'Livreur',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              if (_isNewDriver(d['created_at']))
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(4)),
                                  child: const Text('NOUVEAU',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          subtitle: Text(
                              'Note: ${d['rating'] ?? 5.0} ⭐ • ${d['total_deliveries'] ?? 0} livraisons'),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              setState(() => _isUpdatingStatus = true);
                              final success = await _apiService.assignDriver(
                                  order['id'], d['id']);
                              if (success) {
                                _loadOrders();
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Livreur ${d['username']} assigné !'),
                                        backgroundColor: Colors.green));
                              }
                              setState(() => _isUpdatingStatus = false);
                            },
                            style: ElevatedButton.styleFrom(
                                primary: const Color(0xFFFA7456)),
                            child: const Text('CHOISIR'),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActionButtons(dynamic o) {
    if (o['status'] == 'pending') {
      return Column(
        children: [
          ElevatedButton(
            onPressed: () => _updateOrderStatus(o['id'], 'accept'),
            style: ElevatedButton.styleFrom(
                primary: Colors.green,
                minimumSize: const Size(double.infinity, 40)),
            child: const Text('ACCEPTER LA COMMANDE'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _cancelOrder(o['id']),
            style: TextButton.styleFrom(primary: Colors.red),
            child: const Text('ANNULER LA COMMANDE'),
          ),
        ],
      );
    }

    // Si la commande est confirmée et n'a pas encore de livreur
    if (o['status'] == 'confirmed' && o['deliverer'] == null) {
      return Column(
        children: [
          ElevatedButton(
            onPressed: () => _showDelivererPicker(o),
            style: ElevatedButton.styleFrom(
                primary: Colors.deepPurple,
                minimumSize: const Size(double.infinity, 40)),
            child: const Text('CHOISIR UN LIVREUR'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _updateOrderStatus(o['id'], 'mark_preparing'),
            style: ElevatedButton.styleFrom(
                primary: Colors.blue,
                minimumSize: const Size(double.infinity, 40)),
            child: const Text('LANCER LA PRÉPARATION'),
          ),
        ],
      );
    }

    if (o['status'] == 'confirmed' || o['status'] == 'preparing') {
      return Column(
        children: [
          if (o['deliverer_profile'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.delivery_dining,
                      size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('Livreur : ${o['deliverer_profile']['username']}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green)),
                  const Spacer(),
                  TextButton(
                      onPressed: () => _showDelivererPicker(o),
                      child: const Text('Changer',
                          style: TextStyle(fontSize: 12))),
                ],
              ),
            ),
          if (o['status'] == 'confirmed')
            ElevatedButton(
              onPressed: () => _updateOrderStatus(o['id'], 'mark_preparing'),
              style: ElevatedButton.styleFrom(
                  primary: Colors.blue,
                  minimumSize: const Size(double.infinity, 40)),
              child: const Text('LANCER LA PRÉPARATION'),
            ),
          if (o['status'] == 'preparing')
            ElevatedButton(
              onPressed: () => _updateOrderStatus(o['id'], 'mark_ready'),
              style: ElevatedButton.styleFrom(
                  primary: Colors.orange,
                  minimumSize: const Size(double.infinity, 40)),
              child: const Text('COLIS PRÊT'),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _cancelOrder(o['id']),
            style: TextButton.styleFrom(primary: Colors.red),
            child: const Text('ANNULER LA COMMANDE'),
          ),
        ],
      );
    }

    if (o['status'] == 'ready') {
      return Column(
        children: [
          if (o['deliverer_profile'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.delivery_dining,
                      size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                      'Livreur assigné : ${o['deliverer_profile']['username']}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
          ElevatedButton(
            onPressed: () => _updateOrderStatus(o['id'], 'mark_shipping'),
            style: ElevatedButton.styleFrom(
              primary: const Color(0xFFFA7456),
              minimumSize: const Size(double.infinity, 44),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.delivery_dining, color: Colors.white),
                SizedBox(width: 8),
                Text('EXPÉDIER LE COLIS',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _cancelOrder(o['id']),
            style: TextButton.styleFrom(primary: Colors.red),
            child: const Text('ANNULER LA COMMANDE'),
          ),
        ],
      );
    }

    if (o['status'] == 'shipping') {
      final otpController = TextEditingController();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFA7456).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: const Color(0xFFFA7456).withOpacity(0.3)),
            ),
            child: Row(
              children: const [
                Icon(Icons.lock_outline, color: Color(0xFFFA7456), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Demandez le code OTP affiché sur l\'écran du client et saisissez-le ci-dessous pour confirmer la livraison.',
                    style: TextStyle(fontSize: 11, color: Color(0xFFFA7456)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: otpController,
                  decoration: const InputDecoration(
                    hintText: 'Code OTP du client',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    prefixIcon: Icon(Icons.pin, color: Colors.grey),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  buildCounter: (_,
                          {required currentLength,
                          required isFocused,
                          maxLength}) =>
                      null,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () async {
                  final otp = otpController.text.trim();
                  if (otp.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Veuillez saisir le code OTP'),
                          backgroundColor: Colors.orange),
                    );
                    return;
                  }
                  setState(() => _isUpdatingStatus = true);
                  final resp = await _apiService.post(
                      '/orders/orders/${o['id']}/verify_otp/', {'otp': otp});
                  if (resp.statusCode == 200) {
                    await _loadOrders();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('✅ Livraison confirmée avec succès !'),
                            backgroundColor: Colors.green),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                '❌ Code OTP incorrect. Vérifiez avec le client.'),
                            backgroundColor: Colors.red),
                      );
                    }
                  }
                  setState(() => _isUpdatingStatus = false);
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('VALIDER',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.orange;
      case 'shipping':
        return const Color(0xFFFA7456);
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
