import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _cart;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      setState(() => _isLoading = true);
      final cartData = await _apiService.getCart();
      setState(() {
        _cart = cartData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeItem(int itemId) async {
    final success = await _apiService.removeFromCart(itemId);
    if (success) {
      _loadCart();
      Provider.of<CartService>(context, listen: false)
          .fetchCart(); // Update badge
    }
  }

  Future<void> _updateQuantity(int itemId, int newQuantity) async {
    if (newQuantity <= 0) {
      _removeItem(itemId);
      return;
    }
    final success = await _apiService.updateCartItem(itemId, newQuantity);
    if (success) {
      _loadCart();
      Provider.of<CartService>(context, listen: false)
          .fetchCart(); // Update badge
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _cart?['items'] as List<dynamic>? ?? [];
    final total = _cart?['total']?.toString() ?? '0';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('cart.title'.tr()),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : items.isEmpty
              ? _buildEmptyCart()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _buildCartItem(item);
                        },
                      ),
                    ),
                    _buildCheckoutSection(total),
                  ],
                ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text('cart.empty'.tr(),
              style: const TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCartItem(dynamic item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                image: (item['product_image'] != null &&
                        item['product_image'] != '')
                    ? DecorationImage(
                        image: NetworkImage(item['product_image']),
                        fit: BoxFit.cover)
                    : null,
              ),
              child:
                  (item['product_image'] == null || item['product_image'] == '')
                      ? const Icon(Icons.image, color: Colors.grey)
                      : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['product_name'] ?? 'cart.product'.tr(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('${item['unit_price']} XOF',
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  Row(
                    children: [
                      _buildQtyBtn(
                          Icons.remove,
                          () => _updateQuantity(
                              item['id'], item['quantity'] - 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('${item['quantity']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      _buildQtyBtn(
                          Icons.add,
                          () => _updateQuantity(
                              item['id'], item['quantity'] + 1)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Colors.red.shade400, size: 22),
                  onPressed: () => _removeItem(item['id']),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 8),
                Text(
                  '${item['line_total']} XOF',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 15),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child:
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Widget _buildCheckoutSection(String total) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5)),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('cart.total_to_pay'.tr(),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
              Text('$total XOF',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/checkout'),
            child: Text('cart.checkout'.tr()),
          ),
        ],
      ),
    );
  }
}
