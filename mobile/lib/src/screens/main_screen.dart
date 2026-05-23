import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/cart_service.dart';

import 'cart_screen.dart';
import 'category_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'admin_dashboard_screen.dart';
import 'super_admin_dashboard_screen.dart';
import 'delivery_dashboard_screen.dart';
import '../services/auth_service.dart';

class MainScreen extends StatefulWidget {
  static final GlobalKey cartKey = GlobalKey();
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _cartAnimController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _cartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: -5.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
        parent: _cartAnimController, curve: const Interval(0.0, 0.5)));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
        parent: _cartAnimController, curve: const Interval(0.5, 1.0)));

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      final cartService = Provider.of<CartService>(context, listen: false);
      cartService.itemAddedStream.listen((_) {
        _triggerCartAnimation();
      });
    });
  }

  void _triggerCartAnimation() async {
    _cartAnimController.forward(from: 0);
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 50);
      }
    } catch (e) {
      // Ignorer si échec vibration (ex: chrome)
    }
  }

  @override
  void dispose() {
    _cartAnimController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final cartService = Provider.of<CartService>(context);

    // Définition dynamique des pages selon le rôle
    final List<Map<String, dynamic>> navItems = [
      {'page': const HomeScreen(), 'label': 'nav.home'.tr(), 'icon': '🏠'},
    ];

    if (authService.isDelivery && !authService.isAdmin) {
      navItems.add({
        'page': const DeliveryDashboardScreen(),
        'label': 'nav.deliveries'.tr(),
        'icon': '🚚'
      });
    } else if (authService.isSeller && !authService.isAdmin) {
      navItems.add({
        'page': const AdminDashboardScreen(),
        'label': 'nav.shop'.tr(),
        'icon': '🏪'
      });
    } else if (authService.isAdmin) {
      navItems.add({
        'page': const SuperAdminDashboardScreen(),
        'label': 'nav.admin'.tr(),
        'icon': '🛡️'
      });
    } else {
      navItems.add({
        'page': const CategoryScreen(),
        'label': 'nav.categories'.tr(),
        'icon': '📂'
      });
      navItems.add({
        'page': const SearchScreen(),
        'label': 'nav.search'.tr(),
        'icon': '🔎'
      });
    }

    navItems.add({
      'page': const CartScreen(),
      'label': 'nav.cart'.tr(),
      'icon': '🛒',
      'isCart': true
    });
    navItems.add({
      'page': const ProfileScreen(),
      'label': 'nav.account'.tr(),
      'icon': '👤'
    });

    // Ajuster l'index si nécessaire (ex: après un changement de rôle)
    if (_selectedIndex >= navItems.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: navItems[_selectedIndex]['page'],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey.shade400,
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: navItems.map((item) {
            final bool isCart = item['isCart'] ?? false;

            if (isCart) {
              return BottomNavigationBarItem(
                icon: _buildCartIcon(cartService, isSelected: false),
                activeIcon: _buildCartIcon(cartService, isSelected: true),
                label: item['label'],
              );
            }

            return BottomNavigationBarItem(
              icon: Icon(_iconForNavItem(item, active: false), size: 24),
              activeIcon: Icon(_iconForNavItem(item, active: true), size: 26),
              label: item['label'],
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _iconForNavItem(Map<String, dynamic> item, {required bool active}) {
    final page = item['page'];
    if (page is HomeScreen) return active ? Icons.home : Icons.home_outlined;
    if (page is DeliveryDashboardScreen) {
      return active ? Icons.local_shipping : Icons.local_shipping_outlined;
    }
    if (page is AdminDashboardScreen) {
      return active ? Icons.storefront : Icons.storefront_outlined;
    }
    if (page is SuperAdminDashboardScreen) {
      return active
          ? Icons.admin_panel_settings
          : Icons.admin_panel_settings_outlined;
    }
    if (page is CategoryScreen) {
      return active ? Icons.category : Icons.category_outlined;
    }
    if (page is SearchScreen) return active ? Icons.search : Icons.search;
    if (page is ProfileScreen) return active ? Icons.person : Icons.person_outline;
    return active ? Icons.apps : Icons.apps_outlined;
  }

  Widget _buildCartIcon(CartService cartService, {required bool isSelected}) {
    final count = cartService.itemCount;
    final iconSize = isSelected ? 26.0 : 22.0;

    Widget icon = Stack(
      key: isSelected ? MainScreen.cartKey : null,
      clipBehavior: Clip.none,
      children: [
        Icon(
          isSelected ? Icons.shopping_cart : Icons.shopping_cart_outlined,
          size: iconSize,
        ),
        Text('🛒', style: TextStyle(fontSize: iconSize)),
        Icon(
          isSelected ? Icons.shopping_cart : Icons.shopping_cart_outlined,
          size: iconSize,
        ),
        if (count > 0)
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$count',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );

    if (isSelected) {
      return AnimatedBuilder(
        animation: _cartAnimController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: icon,
            ),
          );
        },
      );
    }

    return icon;
  }
}
