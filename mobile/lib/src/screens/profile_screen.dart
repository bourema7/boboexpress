import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/auth_service.dart';
import 'super_admin_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _pageColor = Color(0xFFF3F4F6);
  static const Color _surfaceColor = Color(0xFFFFFFFF);
  static const Color _textColor = Color(0xFF111827);
  static const Color _mutedTextColor = Color(0xFF4B5563);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _primaryColor = Color(0xFFFA7456);
  static const Color _accentColor = Color(0xFF6D35C5);

  bool _isUploading = false;

  Future<void> _pickImage(AuthService authService) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _isUploading = true);
      final bytes = await image.readAsBytes();
      final result = await authService.updateProfileImage(image.path, bytes);
      setState(() => _isUploading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final profile = authService.userProfile;
    final bool isAuthenticated = authService.isAuthenticated;

    return Scaffold(
      backgroundColor: _pageColor,
      appBar: AppBar(
        title: Text('profile.title'.tr(),
            style: const TextStyle(
                color: _textColor, fontWeight: FontWeight.bold)),
        backgroundColor: _surfaceColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _textColor),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, profile, isAuthenticated, authService),
            const SizedBox(height: 24),
            _buildMenuSection(context, authService),
            const SizedBox(height: 32),
            if (isAuthenticated) _buildLogoutButton(context, authService),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic>? profile,
      bool isAuthenticated, AuthService authService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: const BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _accentColor.withOpacity(0.28), width: 2),
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: const Color(0xFFF3F4F6),
                  backgroundImage: (profile?['profile_image'] != null &&
                          profile?['profile_image'] != '')
                      ? NetworkImage(profile?['profile_image'])
                      : null,
                  child: _isUploading
                      ? const CircularProgressIndicator()
                      : (profile?['profile_image'] == null ||
                              profile?['profile_image'] == '')
                          ? const Icon(Icons.person,
                              size: 60, color: _mutedTextColor)
                          : null,
                ),
              ),
              if (isAuthenticated)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _pickImage(authService),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                          color: _accentColor, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            isAuthenticated
                ? (profile?['username'] ?? 'Utilisateur')
                : 'profile.welcome'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isAuthenticated
                ? (profile?['email'] ?? '')
                : 'profile.login_prompt'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: _mutedTextColor),
          ),
          if (isAuthenticated) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                profile?['role']?.toString().toUpperCase() ?? 'CLIENT',
                style: const TextStyle(
                    color: _accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11),
              ),
            ),
          ] else ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                primary: _accentColor,
                onPrimary: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
              child: Text('profile.login_btn'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, AuthService authService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (authService.isDelivery)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SwitchListTile(
                title: Text('profile.delivery_status'.tr(),
                    style: const TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.bold,
                    )),
                subtitle: Text(authService.userProfile?['is_available'] == true
                    ? 'profile.online'.tr()
                    : 'profile.offline'.tr(),
                    style: const TextStyle(color: _mutedTextColor)),
                value: authService.userProfile?['is_available'] == true,
                activeColor: Colors.green,
                onChanged: (val) => authService.updateAvailability(val),
                secondary: Icon(Icons.delivery_dining,
                    color: authService.userProfile?['is_available'] == true
                        ? Colors.green
                        : Colors.grey),
              ),
            ),
          if (authService.isSeller)
            _buildMenuItem(
              icon: Icons.admin_panel_settings_outlined,
              title: 'profile.merchant_space'.tr(),
              subtitle: 'profile.merchant_desc'.tr(),
              onTap: () => Navigator.pushNamed(context, '/admin-dashboard'),
              iconColor: _primaryColor,
            ),
          if (authService.isAdmin)
            _buildMenuItem(
              icon: Icons.security,
              title: 'profile.super_admin'.tr(),
              subtitle: 'profile.super_admin_desc'.tr(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SuperAdminDashboardScreen()),
                );
              },
              iconColor: _accentColor,
            ),
          _buildMenuItem(
            icon: Icons.shopping_bag_outlined,
            title: 'profile.my_orders'.tr(),
            subtitle: 'profile.my_orders_desc'.tr(),
            onTap: () => Navigator.pushNamed(context, '/user-orders'),
          ),
          _buildMenuItem(
            icon: Icons.location_on_outlined,
            title: 'profile.my_addresses'.tr(),
            subtitle: 'profile.my_addresses_desc'.tr(),
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.favorite_border,
            title: 'profile.my_favorites'.tr(),
            subtitle: 'profile.my_favorites_desc'.tr(),
            onTap: () => Navigator.pushNamed(context, '/favorites'),
          ),
          _buildMenuItem(
            icon: Icons.notifications_none,
            title: 'profile.notifications'.tr(),
            subtitle: 'profile.notifications_desc'.tr(),
            onTap: () => Navigator.pushNamed(context, '/notifications'),
          ),
          _buildMenuItem(
            icon: Icons.email_outlined,
            title: 'profile.change_email'.tr(),
            subtitle: 'profile.change_email_desc'.tr(),
            onTap: () => _showChangeEmailDialog(context, authService),
          ),
          _buildMenuItem(
            icon: Icons.lock_outline,
            title: 'profile.change_password'.tr(),
            subtitle: 'profile.change_password_desc'.tr(),
            onTap: () => _showChangePasswordDialog(context, authService),
          ),
          _buildMenuItem(
            icon: Icons.language,
            title: 'profile.language'.tr(),
            subtitle: 'profile.language_desc'.tr(),
            onTap: () {
              if (context.locale.languageCode == 'fr') {
                context.setLocale(const Locale('en'));
              } else {
                context.setLocale(const Locale('fr'));
              }
            },
            iconColor: Colors.blue,
          ),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'profile.support'.tr(),
            subtitle: 'profile.support_desc'.tr(),
            onTap: () async {
              const String phoneNumber = "22667774512";
              const String message =
                  "Bonjour, j'ai besoin d'aide avec l'application BoboExpress.";
              final Uri whatsappUri = Uri.parse(
                  "https://wa.me/$phoneNumber?text=${Uri.encodeFull(message)}");

              if (await canLaunchUrl(whatsappUri)) {
                await launchUrl(whatsappUri,
                    mode: LaunchMode.externalApplication);
              }
            },
            iconColor: Colors.green,
            isLast: true,
          ),
        ],
      ),
    );
  }

  void _showChangeEmailDialog(BuildContext context, AuthService authService) {
    final emailCtrl =
        TextEditingController(text: authService.userProfile?['email'] ?? '');
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Modifier l\'email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Nouvel email'),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isUpdating ? null : () => Navigator.pop(ctx),
              child: const Text('ANNULER'),
            ),
            ElevatedButton(
              onPressed: isUpdating
                  ? null
                  : () async {
                      if (emailCtrl.text.isEmpty) return;
                      setStateDialog(() => isUpdating = true);
                      final result = await authService.updateProfile(
                          email: emailCtrl.text);
                      setStateDialog(() => isUpdating = false);
                      if (result['success']) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(result['message']),
                              backgroundColor: Colors.green),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(result['message']),
                              backgroundColor: Colors.red),
                        );
                      }
                    },
              child: isUpdating
                  ? const CircularProgressIndicator()
                  : const Text('ENREGISTRER'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(
      BuildContext context, AuthService authService) {
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Changer le mot de passe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordCtrl,
                decoration:
                    const InputDecoration(labelText: 'Ancien mot de passe'),
                obscureText: true,
              ),
              TextField(
                controller: newPasswordCtrl,
                decoration:
                    const InputDecoration(labelText: 'Nouveau mot de passe'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isUpdating ? null : () => Navigator.pop(ctx),
              child: const Text('ANNULER'),
            ),
            ElevatedButton(
              onPressed: isUpdating
                  ? null
                  : () async {
                      if (oldPasswordCtrl.text.isEmpty ||
                          newPasswordCtrl.text.isEmpty) return;
                      setStateDialog(() => isUpdating = true);
                      final result = await authService.changePassword(
                          oldPasswordCtrl.text, newPasswordCtrl.text);
                      setStateDialog(() => isUpdating = false);
                      if (result['success']) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(result['message']),
                              backgroundColor: Colors.green),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(result['message']),
                              backgroundColor: Colors.red),
                        );
                      }
                    },
              child: isUpdating
                  ? const CircularProgressIndicator()
                  : const Text('MODIFIER'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.grey).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor ?? Colors.black87, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: _textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: _mutedTextColor, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: _mutedTextColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthService authService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton.icon(
        onPressed: () {
          authService.logout();
          Navigator.pushReplacementNamed(context, '/login');
        },
        icon: const Icon(Icons.logout, color: Colors.red),
        label: Text('profile.logout'.tr(),
            style: const TextStyle(
                color: Colors.red, fontWeight: FontWeight.bold)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          backgroundColor: Colors.red.withOpacity(0.05),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
