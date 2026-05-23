import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';
import '../utils/cart_animation_helper.dart';
import 'main_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final int productId;

  const ProductDetailsScreen({Key? key, required this.productId})
      : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _product;
  bool _isLoading = true;
  bool _isAdding = false;
  int _quantity = 1;
  final GlobalKey _addButtonKey = GlobalKey();

  // Nouvelles variables pour les variantes
  String? _selectedColor;
  String? _selectedSize;
  Map<String, dynamic>? _selectedVariant;
  List<String> _availableColors = [];
  List<String> _availableSizes = [];

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final products = await _apiService.getProducts();
      final product = products.firstWhere((p) => p['id'] == widget.productId,
          orElse: () => null);

      if (product != null) {
        final List<dynamic> variants = product['variants'] ?? [];
        final colors = variants
            .map((v) => v['color']?.toString())
            .where((c) => c != null && c.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList();
        final sizes = variants
            .map((v) => v['size']?.toString())
            .where((s) => s != null && s.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList();

        setState(() {
          _product = product;
          _availableColors = colors;
          _availableSizes = sizes;

          // Sélectionner par défaut si disponible
          if (_availableColors.isNotEmpty) {
            _selectedColor = _availableColors.first;
          }
          if (_availableSizes.isNotEmpty) _selectedSize = _availableSizes.first;

          _updateSelectedVariant();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _updateSelectedVariant() {
    if (_product == null) return;
    final List<dynamic> variants = _product!['variants'] ?? [];

    try {
      _selectedVariant = variants.firstWhere((v) {
        bool matchColor =
            _selectedColor == null || v['color'] == _selectedColor;
        bool matchSize = _selectedSize == null || v['size'] == _selectedSize;
        return matchColor && matchSize;
      }, orElse: () => null);
    } catch (e) {
      _selectedVariant = null;
    }
  }

  bool _isSizeAvailable(String size) {
    if (_product == null) return true;
    final List<dynamic> variants = _product!['variants'] ?? [];

    var matchingVariants = variants.where((v) => v['size']?.toString() == size);
    if (_selectedColor != null) {
      matchingVariants =
          matchingVariants.where((v) => v['color'] == _selectedColor);
    }

    // Return true if at least one variant has stock > 0
    return matchingVariants.isEmpty ||
        matchingVariants.any((v) => (v['stock'] ?? 0) > 0);
  }

  Future<void> _addToCart() async {
    if (_product == null) return;
    setState(() => _isAdding = true);

    // Animation de vol avant l'appel API (plus réactif)
    CartAnimationHelper.runAddToCartAnimation(
      context: context,
      widgetKey: _addButtonKey,
      cartKey: MainScreen.cartKey,
      imageUrl: _product!['image'] ?? _product!['image_url'] ?? '',
      onComplete: () async {
        final cartService = Provider.of<CartService>(context, listen: false);
        bool success = true;

        for (int i = 0; i < _quantity; i++) {
          final res = await cartService.addToCart(widget.productId,
              variantId:
                  _selectedVariant != null ? _selectedVariant!['id'] : null);
          if (!res) success = false;
        }

        if (mounted) {
          setState(() => _isAdding = false);
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$_quantity${'product.added_plural'.tr()}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ),
            );
            _loadProduct();
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_product == null) {
      return Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('product.not_found'.tr())));
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 450,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product-${widget.productId}',
                child: Image.network(
                  (_product!['image'] != null && _product!['image'] != '')
                      ? _product!['image']
                      : (_product!['image_url'] != null &&
                              _product!['image_url'] != '')
                          ? _product!['image_url']
                          : 'https://picsum.photos/400/400?random=${widget.productId}',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.9),
                child: const BackButton(color: Colors.black),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: IconButton(
                    icon:
                        const Icon(Icons.favorite_border, color: Colors.black),
                    onPressed: () {},
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.black),
                    onPressed: () {},
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'product.official_store'.tr(),
                            style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${_product!['average_rating'] ?? 4.5}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              ' (128 ${'product.reviews'.tr()})',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _product!['name'],
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_product!['is_promo'] == true &&
                                _product!['discount_price'] != null &&
                                _selectedVariant == null) ...[
                              Text('${_product!['discount_price']} XOF',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.red)),
                              Text('${_product!['price']} XOF',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough)),
                            ] else
                              Text(
                                _selectedVariant != null
                                    ? '${_selectedVariant!['final_price']} XOF'
                                    : '${_product!['price']} XOF',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: colorScheme.primary),
                              ),
                          ],
                        ),
                        if (_selectedVariant != null &&
                            _selectedVariant!['stock'] <= 5)
                          Text(
                            '${'product.left'.tr()}${_selectedVariant!['stock']}!',
                            style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Sélecteur de couleur
                    if (_availableColors.isNotEmpty) ...[
                      Text('product.color'.tr(),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _availableColors.map((color) {
                          final isSelected = _selectedColor == color;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedColor = color;
                              _updateSelectedVariant();
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primary
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : const Color(
                                            0xFFFFB6C1)), // Couleur d'Alibaba
                              ),
                              child: Text(
                                color,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Sélecteur de taille
                    if (_availableSizes.isNotEmpty) ...[
                      Text('product.size'.tr(),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _availableSizes.map((size) {
                          final isSelected = _selectedSize == size;
                          final isAvailable = _isSizeAvailable(size);

                          return GestureDetector(
                            onTap: isAvailable
                                ? () => setState(() {
                                      _selectedSize = size;
                                      _updateSelectedVariant();
                                    })
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primary
                                    : (isAvailable
                                        ? Colors.white
                                        : Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : (isAvailable
                                          ? const Color(0xFFFFB6C1)
                                          : Colors.grey.shade300),
                                ),
                              ),
                              child: Text(
                                size,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isAvailable
                                          ? Colors.black87
                                          : Colors.grey),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  decoration: isAvailable
                                      ? TextDecoration.none
                                      : TextDecoration.lineThrough,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    Text('product.description'.tr(),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(
                      _product!['description'] ?? 'product.default_desc'.tr(),
                      style: TextStyle(
                          fontSize: 15, color: Colors.grey[600], height: 1.6),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Text('product.quantity'.tr(),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: _quantity > 1
                                    ? () => setState(() => _quantity--)
                                    : null,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _quantity <
                                        (_selectedVariant != null
                                            ? _selectedVariant!['stock']
                                            : (_product!['stock'] ?? 10))
                                    ? () => setState(() => _quantity++)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildReviewsSection(),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -10)),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 55,
              width: 55,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green.shade200),
                borderRadius: BorderRadius.circular(16),
                color: Colors.green.withOpacity(0.05),
              ),
              child: IconButton(
                icon: const Icon(Icons.whatsapp, color: Colors.green),
                onPressed: () async {
                  const String phoneNumber = "22667774512";
                  final String productName = _product!['name'];
                  final String message =
                      "Bonjour, je suis intéressé par le produit *$productName*. Pouvez-vous me donner plus d'informations ?";
                  final Uri whatsappUri = Uri.parse(
                      "https://wa.me/$phoneNumber?text=${Uri.encodeFull(message)}");

                  if (await canLaunchUrl(whatsappUri)) {
                    await launchUrl(whatsappUri,
                        mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                key: _addButtonKey,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isAdding ||
                          (_selectedVariant != null
                              ? _selectedVariant!['stock'] <= 0
                              : _product!['stock'] <= 0)
                      ? null
                      : _addToCart,
                  style: ElevatedButton.styleFrom(
                    primary: colorScheme.primary,
                    onPrimary: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isAdding
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          (_selectedVariant != null
                                  ? _selectedVariant!['stock'] <= 0
                                  : _product!['stock'] <= 0)
                              ? 'product.out_of_stock'.tr()
                              : 'product.add_to_cart'.tr().toUpperCase(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('product.customer_reviews'.tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _showReviewDialog,
          child: Text('product.leave_review'.tr()),
        ),
        const SizedBox(height: 16),
        // On pourrait lister les avis ici, mais pour faire simple on affiche juste le bouton
      ],
    );
  }

  void _showReviewDialog() {
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('product.your_review'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    5,
                    (index) => IconButton(
                          icon: Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: Colors.orange),
                          onPressed: () =>
                              setDialogState(() => rating = index + 1),
                        )),
              ),
              TextField(
                controller: commentController,
                decoration:
                    InputDecoration(hintText: 'product.your_comment'.tr()),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('product.cancel'.tr())),
            ElevatedButton(
              onPressed: () async {
                final success = await _apiService.postReview(
                    widget.productId, rating, commentController.text);
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('product.review_thanks'.tr())));
                  _loadProduct();
                }
              },
              child: Text('product.send'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
