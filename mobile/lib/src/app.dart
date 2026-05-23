import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:easy_localization/easy_localization.dart';

import 'screens/admin_dashboard_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/delivery_dashboard_screen.dart';
import 'screens/delivery_history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/order_tracking_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/product_details_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/user_orders_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/delivery_selection_screen.dart';
import 'screens/receipt_screen.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/cart_service.dart';
import 'theme/app_theme.dart';

class BoboExpressApp extends StatelessWidget {
  const BoboExpressApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProvider<AuthService>(
            create: (_) => AuthService()..loadToken()),
        ChangeNotifierProvider<CartService>(
            create: (_) => CartService()..fetchCart()),
      ],
      child: MaterialApp(
        title: 'BoboExpress',
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        initialRoute: '/splash',
        routes: {
          '/main': (_) => const MainScreen(),
          '/splash': (_) => const OnboardingScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/home': (_) => const HomeScreen(),
          '/search': (_) => const SearchScreen(),
          '/cart': (_) => const CartScreen(),
          '/checkout': (_) => const CheckoutScreen(),
          '/receipt': (context) {
            final order = ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>;
            return ReceiptScreen(order: order);
          },
          '/delivery-selection': (context) {
            final args = ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>?;
            return DeliverySelectionScreen(orderId: args?['orderId'] ?? 0);
          },
          '/tracking': (context) {
            final args = ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>?;
            final orderId = args?['orderId'];
            return OrderTrackingScreen(orderId: orderId?.toString() ?? 'DEMO');
          },
          '/favorites': (_) => const FavoritesScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/settings': (_) => const SettingsScreen(),
          '/delivery-dashboard': (_) => const DeliveryDashboardScreen(),
          '/delivery-history': (_) => const DeliveryHistoryScreen(),
          '/admin-dashboard': (_) => const AdminDashboardScreen(),
          '/user-orders': (_) => const UserOrdersScreen(),
          '/notifications': (_) => const NotificationsScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/product') {
            final args = settings.arguments as Map<String, dynamic>?;
            final id = args?['id'] as int?;
            return MaterialPageRoute(
                builder: (_) => ProductDetailsScreen(productId: id ?? 0));
          }
          if (settings.name == '/chat') {
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
                builder: (_) =>
                    ChatScreen(recipientName: args?['name'] ?? 'Support'));
          }
          return null;
        },
      ),
    );
  }
}
