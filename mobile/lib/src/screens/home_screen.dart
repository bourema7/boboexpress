import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../utils/cart_animation_helper.dart';
import 'main_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _primaryColor = Color(0xFFFA7456);
  static const Color _lightText = Color(0xFFF9FAFB);
  static const Color _darkText = Color(0xFF111827);

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _categories = [];
  int? _selectedCategoryId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _activeFilterLabel = 'home.trending';
  final Map<int, GlobalKey> _productKeys = {};

  ColorScheme get colorScheme => Theme.of(context).colorScheme;

  Future<void> _loadCategories() async {
    final cats = await ApiService().getCategories();
    setState(() {
      _categories = cats;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _toggleFavorite(int productId) async {
    final success = await ApiService().toggleFavorite(productId);
    if (success) {
      setState(() {}); // Refresh current view to update icons if needed
    }
  }

  Future<void> _addToCart(int productId, String? imageUrl) async {
    final key = _productKeys[productId];
    if (key == null) return;

    CartAnimationHelper.runAddToCartAnimation(
      context: context,
      widgetKey: key,
      cartKey: MainScreen.cartKey,
      imageUrl: imageUrl ?? '',
      onComplete: () async {
        final cartService = Provider.of<CartService>(context, listen: false);
        final success = await cartService.addToCart(productId);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('home.product_added'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
    );
  }

  Future<void> _searchByImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text('home.visual_search_loading'.tr(),
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        // Simulation d'une recherche par IA
        await Future.delayed(const Duration(seconds: 3));

        setState(() {
          _searchController.text = 'home.visual_search'.tr();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('home.similar_products_found'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'home.camera_error'.tr()}$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final bool isAuthenticated = authService.isAuthenticated;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: _buildDrawer(context, authService),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              _buildCategoryTabs(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
                  child: Row(
                    children: [
                      Text('home.categories'.tr(),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Icon(Icons.tune,
                          color: Theme.of(context).colorScheme.primary,
                          size: 18),
                      const SizedBox(width: 4),
                      Text('Filtrer',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildFilterChips()),
              _buildProductGrid(),
            ],
          ),
          if (authService.isInitialized && !isAuthenticated)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildLoginOverlay(),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverAppBar(
      pinned: true,
      floating: true,
      expandedHeight: 60.0,
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      title: Container(
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.brightness == Brightness.light
              ? Colors.grey.shade100
              : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher vÃªtements, chaussures...',
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            prefixIcon:
                Icon(Icons.search, color: Colors.grey.shade400, size: 20),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.camera_alt_outlined,
                      color: Colors.grey.shade500, size: 20),
                  onPressed: _searchByImage,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    if (context.locale.languageCode == 'fr') {
                      context.setLocale(const Locale('en'));
                    } else {
                      context.setLocale(const Locale('fr'));
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      context.locale.languageCode.toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
            icon: Icon(Icons.search, color: colorScheme.onBackground),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recherche ouverte')))),
        IconButton(
          icon: Icon(Icons.favorite_border, color: colorScheme.onBackground),
          onPressed: () => Navigator.pushNamed(context, '/favorites'),
        ),
      ],
      leading: IconButton(
        icon: Icon(Icons.menu, color: colorScheme.onBackground),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildTab('home.all'.tr(), null),
                ..._categories.map((c) {
                  final keys = {
                    'Alimentation': 'categories.food',
                    'Beauté': 'categories.beauty',
                    'Beaute et Soins': 'categories.beauty_care',
                    'Bijoux': 'categories.jewelry',
                    'Bijoux et Accessoires': 'categories.jewelry_accessories',
                    'Chaussures': 'categories.shoes',
                    'Électronique': 'categories.electronics',
                    'Electronique': 'categories.electronics',
                    'Enfants': 'categories.kids',
                    'Hommes': 'categories.men',
                    'Femmes': 'categories.women',
                    'Mode': 'categories.fashion',
                    'Vêtements': 'categories.clothes',
                    'Informatique': 'categories.computers',
                    'Maison': 'categories.home',
                    'Sacs': 'categories.bags',
                    'Sport': 'categories.sports',
                    'Sport et Fitness': 'categories.sports_fitness',
                    'Accessoires': 'categories.accessories',
                    'Santé': 'categories.health',
                    'Automobile': 'categories.automotive',
                  };
                  String translatedName = keys[c['name']]?.tr() ?? c['name'];
                  return _buildTab(translatedName, c['id']);
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIconFor(String label) {
    final name = label.toLowerCase();
    if (name.contains('tout') || name.contains('all')) {
      return Icons.shopping_bag_outlined;
    }
    if (name.contains('aliment') || name.contains('food')) {
      return Icons.restaurant_outlined;
    }
    if (name.contains('beaut') || name.contains('soin')) {
      return Icons.face_retouching_natural_outlined;
    }
    if (name.contains('bijou') || name.contains('access')) {
      return Icons.diamond_outlined;
    }
    if (name.contains('chauss')) return Icons.directions_walk_outlined;
    if (name.contains('electron') || name.contains('informat')) {
      return Icons.devices_outlined;
    }
    if (name.contains('enfant')) return Icons.child_care_outlined;
    if (name.contains('homme')) return Icons.person_outline;
    if (name.contains('femme') || name.contains('mode')) {
      return Icons.checkroom_outlined;
    }
    if (name.contains('vet') || name.contains('vÃƒÂªt')) {
      return Icons.checkroom_outlined;
    }
    if (name.contains('maison')) return Icons.home_outlined;
    if (name.contains('sac')) return Icons.work_outline;
    if (name.contains('sport')) return Icons.fitness_center_outlined;
    if (name.contains('sant')) return Icons.health_and_safety_outlined;
    if (name.contains('auto')) return Icons.directions_car_outlined;
    return Icons.category_outlined;
  }

  Widget _buildTab(String label, int? id) {
    final bool isActive = _selectedCategoryId == id;
    final icon = _categoryIconFor(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryId = id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? _primaryColor : Colors.grey.shade200,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: _primaryColor.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : _darkText,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black87,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      'home.trending',
      'home.new_arrivals',
      'home.promotions',
      'home.for_you'
    ];
    return Container(
      height: 45,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _activeFilterLabel == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => _activeFilterLabel = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white70,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  filter.tr(),
                  style: TextStyle(
                    color: isSelected ? _darkText : _lightText,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    return FutureBuilder<List<dynamic>>(
        future: ApiService().getProducts(
          categoryId: _selectedCategoryId,
          isNew: _activeFilterLabel == 'home.new_arrivals' ? true : null,
          isPromo: _activeFilterLabel == 'home.promotions' ? true : null,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSkeletonGrid();
          }
          if (snapshot.hasError) {
            return SliverFillRemaining(
                child: Center(
                    child: Text('${'home.error'.tr()}${snapshot.error}')));
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return SliverFillRemaining(
                child: Center(child: Text('home.no_product_found'.tr())));
          }

          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final p = products[index];
                  final colorScheme = Theme.of(context).colorScheme;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/product',
                        arguments: {'id': p['id']},
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                  child: Image.network(
                                    (p['image'] != null && p['image'] != '')
                                        ? p['image']
                                        : (p['image_url'] != null &&
                                                p['image_url'] != '')
                                            ? p['image_url']
                                            : 'https://picsum.photos/200/300?random=$index',
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image,
                                          color: Colors.grey),
                                    ),
                                  ),
                                ),
                                if (p['is_promo'] == true)
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: const Text('PROMO',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => _toggleFavorite(p['id']),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        p['is_favorite'] == true
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: p['is_favorite'] == true
                                            ? colorScheme.primary
                                            : Colors.grey.shade400,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['name'],
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        color: Colors.amber, size: 14),
                                    const SizedBox(width: 2),
                                    Text(
                                      '4.5 (24 avis)', // Mock data
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (p['is_promo'] == true &&
                                            p['discount_price'] != null) ...[
                                          Text('${p['discount_price']} XOF',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Color(0xFFFA7456))),
                                          Text('${p['price']} XOF',
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey,
                                                  decoration: TextDecoration
                                                      .lineThrough)),
                                        ] else
                                          Text('${p['price']} XOF',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Colors.black)),
                                      ],
                                    ),
                                    Container(
                                      key: _productKeys.putIfAbsent(
                                          p['id'], () => GlobalKey()),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        onPressed: () => _addToCart(p['id'],
                                            p['image'] ?? p['image_url']),
                                        icon: const Icon(Icons.add,
                                            size: 20, color: Colors.white),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: products.length,
              ),
            ),
          );
        });
  }

  Widget _buildSkeletonGrid() {
    return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()));
  }

  Widget _buildDrawer(BuildContext context, AuthService authService) {
    final profile = authService.userProfile;
    final username = profile?['username'] ?? 'Invite';
    final email = profile?['email'] ?? 'Connectez-vous pour commander';
    final role = profile?['role']?.toString().toUpperCase() ?? 'CLIENT';
    return Drawer(
      backgroundColor: const Color(0xFF2F2F2F),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFA7456), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: (profile?['profile_image'] != null &&
                    profile?['profile_image'] != '')
                ? CircleAvatar(
                    backgroundImage: NetworkImage(profile?['profile_image']),
                  )
                : const CircleAvatar(
                    backgroundColor: Colors.white,
                    child:
                        Icon(Icons.person, color: Color(0xFF111827), size: 40),
                  ),
            accountName: Text(username,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            accountEmail:
                Text('$email • $role',
                    style: const TextStyle(color: Colors.white70)),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Accueil'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: const Text('Mes Commandes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/user-orders');
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('Favoris'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/favorites');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Aide & Support'),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Besoin d\'aide ?'),
                  content: const Text(
                    'Notre Ã©quipe support est disponible pour vous aider.\n\n'
                    'ðŸ“ž +226 67 77 45 12\n'
                    'ðŸ“§ support@boboexpress.bf',
                    style: TextStyle(height: 1.5),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        const String phoneNumber = "22667774512";
                        const String message =
                            "Bonjour l'Ã©quipe BoboExpress, j'ai besoin d'aide concernant : ";
                        final Uri whatsappUri = Uri.parse(
                            "https://wa.me/$phoneNumber?text=${Uri.encodeFull(message)}");

                        try {
                          await launchUrl(whatsappUri,
                              mode: LaunchMode.externalApplication);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Impossible d\'ouvrir WhatsApp')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.green, // Couleur WhatsApp
                        onPrimary: Colors.white,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.chat, size: 18),
                          SizedBox(width: 8),
                          Text('WhatsApp'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Ã€ propos'),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'BoboExpress',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.shopping_basket,
                    size: 40, color: Color(0xFFFA7456)),
                children: [
                  const Text(
                    'BoboExpress est la plateforme leader de livraison Ã  Bobo-Dioulasso.\n\n'
                    'DÃ©veloppÃ© avec â¤ï¸ par la Team BoboExpress.',
                  ),
                ],
              );
            },
          ),
          const Spacer(),
          if (authService.isAuthenticated)
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('DÃ©connexion',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                authService.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLoginOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Connectez-vous et profitez-en davantage',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              primary: Colors.white,
              onPrimary: Colors.black,
              elevation: 0,
            ),
            child: const Text('Connexion',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}


