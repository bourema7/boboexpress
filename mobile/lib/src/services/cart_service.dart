import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';

class CartService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _cart;
  bool _isLoading = false;

  final _itemAddedController = StreamController<void>.broadcast();
  Stream<void> get itemAddedStream => _itemAddedController.stream;

  Map<String, dynamic>? get cart => _cart;
  bool get isLoading => _isLoading;

  int get itemCount {
    if (_cart == null || _cart!['items'] == null) return 0;
    final items = _cart!['items'] as List<dynamic>;
    int total = 0;
    for (var item in items) {
      total += (item['quantity'] as num).toInt();
    }
    return total;
  }

  Future<void> fetchCart() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _apiService.getCart();
      _cart = data;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToCart(int productId,
      {int quantity = 1, int? variantId}) async {
    final success = await _apiService.addToCart(productId,
        quantity: quantity, variantId: variantId);
    if (success) {
      _itemAddedController.add(null);
      await fetchCart();
    }
    return success;
  }

  Future<bool> removeItem(int itemId) async {
    final success = await _apiService.removeFromCart(itemId);
    if (success) {
      await fetchCart();
    }
    return success;
  }

  void clearCart() {
    _cart = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _itemAddedController.close();
    super.dispose();
  }
}
