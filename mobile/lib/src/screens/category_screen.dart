import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({Key? key}) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final ApiService _apiService = ApiService();
  int _selectedCategoryId = -1; // -1 for "All" or "Pour Vous"
  List<dynamic> _categories = [];
  bool _isLoadingCategories = true;

  Future<void> _addToCart(int productId) async {
    final cartService = Provider.of<CartService>(context, listen: false);
    final success = await cartService.addToCart(productId);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit ajouté au panier !')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'ajout')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _apiService.getCategories();
      setState(() {
        _categories = cats;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: Row(
                children: [
                  _buildLeftSidebar(),
                  Expanded(
                    child: _buildRightContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.category_outlined, color: Colors.black),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: const [
                  SizedBox(width: 12),
                  Icon(Icons.search, color: Colors.grey, size: 18),
                  SizedBox(width: 8),
                  Text('Rechercher dans les catégories',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftSidebar() {
    if (_isLoadingCategories) {
      return Container(
          width: 100,
          color: const Color(0xFFF6F6F6),
          child: const Center(child: CircularProgressIndicator()));
    }

    return Container(
      width: 100,
      color: const Color(0xFFF6F6F6),
      child: ListView.builder(
        itemCount: _categories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final cat = isAll ? null : _categories[index - 1];
          final catId = isAll ? -1 : cat['id'];
          final isSelected = _selectedCategoryId == catId;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryId = catId;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                border: isSelected
                    ? const Border(
                        left: BorderSide(color: Colors.black, width: 4))
                    : null,
              ),
              child: Text(
                isAll ? 'Pour Vous' : cat['name'],
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.black : Colors.black87,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRightContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            _selectedCategoryId == -1
                ? 'Sélection Pour Vous'
                : _categories
                    .firstWhere((c) => c['id'] == _selectedCategoryId)['name'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            key: ValueKey(_selectedCategoryId),
            future: _apiService.getProducts(
                categoryId:
                    _selectedCategoryId == -1 ? null : _selectedCategoryId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erreur : ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Text('Aucun produit dans cette catégorie'));
              }

              final products = snapshot.data!;

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final p = products[index];
                  return _buildProductItem(p);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductItem(dynamic p) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/product',
          arguments: {'id': p['id']},
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (p['image'] != null && p['image'] != '')
                  ? Image.network(p['image'],
                      fit: BoxFit.cover, width: double.infinity)
                  : (p['image_url'] != null && p['image_url'] != '')
                      ? Image.network(p['image_url'],
                          fit: BoxFit.cover, width: double.infinity)
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image)),
            ),
          ),
          const SizedBox(height: 8),
          Text(p['name'],
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${p['price']} XOF',
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.red,
                      fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Text('Stock: ${p['stock']}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  IconButton(
                    onPressed: () => _addToCart(p['id']),
                    icon: const Icon(Icons.add_shopping_cart,
                        size: 16, color: Colors.black),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.only(left: 4),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
