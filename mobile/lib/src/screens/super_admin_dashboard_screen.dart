import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  static const Color _dashboardTextColor = Color(0xFF111827);
  static const Color _dashboardMutedTextColor = Color(0xFF4B5563);
  static const Color _dashboardBorderColor = Color(0xFFE5E7EB);

  int _currentIndex = 0;
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await _apiService.getDashboardStats();
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  void _onMenuTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    Navigator.pop(context); // Close drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1),
        ),
        backgroundColor: const Color(0xFFFA7456),
        elevation: 0,
        centerTitle: true,
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Admin Dashboard';
      case 1:
        return 'Utilisateurs';
      case 2:
        return 'Catalogue';
      case 3:
        return 'Commandes';
      case 4:
        return 'Livreurs';
      case 5:
        return 'Notifications';
      default:
        return 'Admin Panel';
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFF1E212D),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 60, bottom: 20),
              width: double.infinity,
              color: const Color(0xFF282C3A),
              child: Column(
                children: const [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFFFA7456),
                    child: Icon(Icons.admin_panel_settings,
                        size: 40, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text('SUPER ADMIN',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Text('BoboExpress',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(Icons.dashboard, 'Dashboard', 0),
                  _buildDrawerItem(Icons.people, 'Utilisateurs', 1),
                  _buildDrawerItem(Icons.inventory_2, 'Catalogue', 2),
                  _buildDrawerItem(Icons.receipt_long, 'Commandes', 3),
                  _buildDrawerItem(Icons.delivery_dining, 'Livreurs', 4),
                  _buildDrawerItem(
                      Icons.notifications_active, 'Notifications', 5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final isSelected = _currentIndex == index;
    return ListTile(
      leading: Icon(icon,
          color: isSelected ? const Color(0xFFFA7456) : Colors.grey[400]),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[400],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFFFA7456).withOpacity(0.1),
      onTap: () => _onMenuTap(index),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildUsersTab();
      case 2:
        return _buildCatalogueTab(); // Not implemented here, use AdminDashboardScreen for now
      case 3:
        return _OrdersView(apiService: _apiService);
      case 4:
        return _DriversView(apiService: _apiService);
      case 5:
        return _buildNotificationsTab();
      default:
        return const Center(child: Text('Work in progress...'));
    }
  }

  Widget _buildDashboardTab() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFA7456)));
    }
    if (_stats == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Impossible de charger les statistiques'),
            TextButton(onPressed: _loadStats, child: const Text('RÉESSAYER')),
          ],
        ),
      );
    }

    final rev = _stats!['revenue'] ?? {};
    final ord = _stats!['orders'] ?? {};
    final usr = _stats!['users'] ?? {};

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Revenus',
              style: TextStyle(
                  color: _dashboardTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard('Aujourd\'hui', '${rev['today']} XOF',
                      Icons.attach_money, Colors.green)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard('Total', '${rev['total']} XOF',
                      Icons.account_balance, Colors.blue)),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Commandes',
              style: TextStyle(
                  color: _dashboardTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard('Jour', '${ord['today']}',
                      Icons.shopping_bag, Colors.orange)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard('Mois', '${ord['month']}',
                      Icons.assessment, Colors.purple)),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Utilisateurs',
              style: TextStyle(
                  color: _dashboardTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      'Total', '${usr['total']}', Icons.people, Colors.teal)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard('Nouveaux', '${usr['new_today']}',
                      Icons.person_add, Colors.indigo)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _dashboardBorderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _dashboardTextColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(
                  fontSize: 14, color: _dashboardMutedTextColor)),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return _UsersView(apiService: _apiService);
  }

  Widget _buildCatalogueTab() {
    return _CatalogueView(apiService: _apiService);
  }

  Widget _buildNotificationsTab() {
    return _NotificationsBroadcastView(apiService: _apiService);
  }
}

class _UsersView extends StatefulWidget {
  final ApiService apiService;
  const _UsersView({Key? key, required this.apiService}) : super(key: key);

  @override
  State<_UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<_UsersView> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await widget.apiService.getUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  Future<void> _changeRole(int userId, String newRole) async {
    final success = await widget.apiService.updateUserRole(userId, newRole);
    if (success) {
      _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Rôle mis à jour'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur'), backgroundColor: Colors.red));
    }
  }

  Future<void> _toggleBlock(int userId, bool isBlocked) async {
    final success = await widget.apiService.blockUser(userId, !isBlocked);
    if (success) {
      _loadUsers();
    }
  }

  void _showCreateUserDialog() {
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String selectedRole = 'customer';
    bool isCreating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Nouvel Utilisateur'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: usernameCtrl,
                        decoration: const InputDecoration(
                            labelText: "Nom d'utilisateur")),
                    TextField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email')),
                    TextField(
                        controller: passwordCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Mot de passe'),
                        obscureText: true),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Rôle'),
                      items: const [
                        DropdownMenuItem(
                            value: 'customer', child: Text('Client')),
                        DropdownMenuItem(
                            value: 'seller', child: Text('Vendeur')),
                        DropdownMenuItem(
                            value: 'delivery', child: Text('Livreur')),
                        DropdownMenuItem(
                            value: 'admin', child: Text('Administrateur')),
                      ],
                      onChanged: (v) => setStateDialog(() => selectedRole = v!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isCreating ? null : () => Navigator.pop(ctx),
                  child: const Text('ANNULER'),
                ),
                ElevatedButton(
                  onPressed: isCreating
                      ? null
                      : () async {
                          if (usernameCtrl.text.isEmpty ||
                              emailCtrl.text.isEmpty ||
                              passwordCtrl.text.isEmpty) return;
                          setStateDialog(() => isCreating = true);
                          final result = await widget.apiService
                              .adminCreateUser(
                                  usernameCtrl.text,
                                  emailCtrl.text,
                                  passwordCtrl.text,
                                  selectedRole);
                          setStateDialog(() => isCreating = false);
                          if (result['success'] == true) {
                            Navigator.pop(ctx);
                            _loadUsers();
                            ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Utilisateur créé avec succès !'),
                                    backgroundColor: Colors.green));
                          } else {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                    content: Text(result['message'] ??
                                        'Erreur lors de la création'),
                                    backgroundColor: Colors.red));
                          }
                        },
                  child: isCreating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('CRÉER'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditUserDialog(dynamic user) {
    final emailCtrl = TextEditingController(text: user['email']);
    final usernameCtrl = TextEditingController(text: user['username']);
    String selectedRole = user['role'] ?? 'customer';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Modifier ${user['username']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: usernameCtrl,
                    decoration:
                        const InputDecoration(labelText: "Nom d'utilisateur")),
                TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email')),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'Rôle'),
                  items: const [
                    DropdownMenuItem(value: 'customer', child: Text('Client')),
                    DropdownMenuItem(value: 'seller', child: Text('Vendeur')),
                    DropdownMenuItem(value: 'delivery', child: Text('Livreur')),
                    DropdownMenuItem(
                        value: 'admin', child: Text('Administrateur')),
                  ],
                  onChanged: (v) => setStateDialog(() => selectedRole = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ANNULER')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setStateDialog(() => isSaving = true);
                      final result =
                          await widget.apiService.adminUpdateUser(user['id'], {
                        'username': usernameCtrl.text,
                        'email': emailCtrl.text,
                        'role': selectedRole,
                      });
                      setStateDialog(() => isSaving = false);
                      if (result['success']) {
                        Navigator.pop(ctx);
                        _loadUsers();
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Utilisateur mis à jour'),
                                backgroundColor: Colors.green));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(result['message']),
                            backgroundColor: Colors.red));
                      }
                    },
              child: isSaving
                  ? const CircularProgressIndicator()
                  : const Text('ENREGISTRER'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUserDialog,
        backgroundColor: const Color(0xFFFA7456),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final u = _users[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      onTap: () => _showEditUserDialog(u),
                      leading: CircleAvatar(
                        backgroundColor: u['is_blocked']
                            ? Colors.red[100]
                            : Colors.blue[100],
                        child: Icon(Icons.person,
                            color: u['is_blocked'] ? Colors.red : Colors.blue),
                      ),
                      title: Text(u['full_name'] ?? u['username'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${u['email']} • ${u['role']}',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                size: 20, color: Colors.grey),
                            onPressed: () => _showEditUserDialog(u),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'block') {
                                _toggleBlock(u['id'], u['is_blocked']);
                              } else {
                                _changeRole(u['id'], val);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                  value: 'block',
                                  child: Text(
                                      u['is_blocked'] ? 'Débloquer' : 'Bloquer',
                                      style: TextStyle(
                                          color: u['is_blocked']
                                              ? Colors.green
                                              : Colors.red))),
                              const PopupMenuItem(
                                  value: 'customer',
                                  child: Text('Rôle: Client')),
                              const PopupMenuItem(
                                  value: 'seller',
                                  child: Text('Rôle: Vendeur')),
                              const PopupMenuItem(
                                  value: 'delivery',
                                  child: Text('Rôle: Livreur')),
                              const PopupMenuItem(
                                  value: 'admin', child: Text('Rôle: Admin')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _NotificationsBroadcastView extends StatefulWidget {
  final ApiService apiService;
  const _NotificationsBroadcastView({Key? key, required this.apiService})
      : super(key: key);

  @override
  State<_NotificationsBroadcastView> createState() =>
      _NotificationsBroadcastViewState();
}

class _NotificationsBroadcastViewState
    extends State<_NotificationsBroadcastView> {
  static const Color _pageColor = Color(0xFFF4F6F9);
  static const Color _surfaceColor = Color(0xFFFFFFFF);
  static const Color _textColor = Color(0xFF111827);
  static const Color _mutedTextColor = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _primaryColor = Color(0xFFFA7456);

  final _titleController = TextEditingController();
  final _msgController = TextEditingController();
  String _targetRole = 'all';
  bool _isSending = false;

  Future<void> _send() async {
    if (_titleController.text.isEmpty || _msgController.text.isEmpty) return;
    setState(() => _isSending = true);
    final success = await widget.apiService
        .sendBroadcast(_titleController.text, _msgController.text, _targetRole);
    setState(() => _isSending = false);

    if (success) {
      _titleController.clear();
      _msgController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Notification envoyée avec succès'),
          backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erreur lors de l\'envoi'),
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Envoyer une notification',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: _textColor),
              decoration: _inputDecoration('Titre'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _msgController,
              style: const TextStyle(color: _textColor),
              maxLines: 4,
              decoration: _inputDecoration('Message'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _targetRole,
              dropdownColor: _surfaceColor,
              style: const TextStyle(color: _textColor, fontSize: 16),
              iconEnabledColor: _mutedTextColor,
              decoration: _inputDecoration('Cible'),
              items: const [
                DropdownMenuItem(
                    value: 'all', child: Text('Tous les utilisateurs')),
                DropdownMenuItem(
                    value: 'customer', child: Text('Clients uniquement')),
                DropdownMenuItem(
                    value: 'seller', child: Text('Vendeurs uniquement')),
                DropdownMenuItem(
                    value: 'delivery', child: Text('Livreurs uniquement')),
              ],
              onChanged: (v) => setState(() => _targetRole = v!),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSending ? null : _send,
                style: ElevatedButton.styleFrom(
                  primary: _primaryColor,
                  onPrimary: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ENVOYER',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _mutedTextColor),
      floatingLabelStyle: const TextStyle(color: _textColor),
      filled: true,
      fillColor: _pageColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryColor, width: 1.5),
      ),
    );
  }
}

class _OrdersView extends StatefulWidget {
  final ApiService apiService;
  const _OrdersView({Key? key, required this.apiService}) : super(key: key);

  @override
  State<_OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<_OrdersView> {
  List<dynamic> _orders = [];
  List<dynamic> _drivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final orders = await widget.apiService.getOrders();
    final driverStats = await widget.apiService.getDriverStats();
    setState(() {
      _orders = orders;
      if (driverStats != null && driverStats['drivers'] != null) {
        _drivers = driverStats['drivers'];
      }
      _isLoading = false;
    });
  }

  Future<void> _assignDriver(int orderId, int driverId) async {
    setState(() => _isLoading = true);
    final success = await widget.apiService.assignDriver(orderId, driverId);
    if (success) {
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Livreur assigné'), backgroundColor: Colors.green));
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erreur lors de l\'assignation'),
          backgroundColor: Colors.red));
    }
  }

  void _showAssignDialog(int orderId) {
    showDialog(
      context: context,
      builder: (context) {
        final availableDrivers = _drivers
            .where((d) => d['is_available'] == true && d['is_blocked'] == false)
            .toList();
        return AlertDialog(
          title: const Text('Assigner un livreur'),
          content: availableDrivers.isEmpty
              ? const Text('Aucun livreur disponible.')
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableDrivers.length,
                    itemBuilder: (context, index) {
                      final d = availableDrivers[index];
                      return ListTile(
                        leading: const Icon(Icons.delivery_dining),
                        title: Text(d['name']),
                        subtitle:
                            Text('Missions actives: ${d['active_missions']}'),
                        onTap: () {
                          Navigator.pop(context);
                          _assignDriver(orderId, d['id']);
                        },
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ANNULER')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _orders.isEmpty
          ? const Center(child: Text('Aucune commande trouvée'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final o = _orders[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text('Commande #${o['id']} • ${o['status_display']}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Montant: ${o['total_amount']} XOF'),
                        Text(
                            'Boutique: ${o['store'] != null ? o['store']['name'] : 'Inconnue'}'),
                        const SizedBox(height: 8),
                        if (o['status'] == 'ready' ||
                            o['status'] == 'preparing' ||
                            o['status'] == 'confirmed')
                          ElevatedButton.icon(
                            onPressed: () => _showAssignDialog(o['id']),
                            icon: const Icon(Icons.motorcycle, size: 16),
                            label: const Text('Assigner Livreur'),
                            style: ElevatedButton.styleFrom(
                              primary: const Color(0xFFFA7456),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _DriversView extends StatefulWidget {
  final ApiService apiService;
  const _DriversView({Key? key, required this.apiService}) : super(key: key);

  @override
  State<_DriversView> createState() => _DriversViewState();
}

class _DriversViewState extends State<_DriversView> {
  List<dynamic> _drivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() => _isLoading = true);
    final stats = await widget.apiService.getDriverStats();
    setState(() {
      if (stats != null && stats['drivers'] != null) {
        _drivers = stats['drivers'];
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadDrivers,
      child: _drivers.isEmpty
          ? const Center(child: Text('Aucun livreur trouvé'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _drivers.length,
              itemBuilder: (context, index) {
                final d = _drivers[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: d['is_available']
                          ? Colors.green[100]
                          : Colors.orange[100],
                      child: Icon(Icons.delivery_dining,
                          color:
                              d['is_available'] ? Colors.green : Colors.orange),
                    ),
                    title: Text(d['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        'Solde: ${d['wallet_balance']} XOF • Note: ${d['rating']}⭐'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Missions',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600])),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(10)),
                          child: Text('${d['active_missions']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _CatalogueView extends StatelessWidget {
  final ApiService apiService;
  const _CatalogueView({Key? key, required this.apiService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Color(0xFFFA7456),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFFA7456),
            tabs: [
              Tab(text: 'CATÉGORIES', icon: Icon(Icons.category_outlined)),
              Tab(text: 'PRODUITS', icon: Icon(Icons.inventory_2_outlined)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _CategoriesTab(apiService: apiService),
                _ProductsTab(apiService: apiService),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesTab extends StatefulWidget {
  final ApiService apiService;
  const _CategoriesTab({Key? key, required this.apiService}) : super(key: key);

  @override
  State<_CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<_CategoriesTab> {
  List<dynamic> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final cats = await widget.apiService.getCategories();
    setState(() {
      _categories = cats;
      _isLoading = false;
    });
  }

  void _showCategoryDialog([dynamic category]) {
    final nameCtrl = TextEditingController(text: category?['name'] ?? '');
    final descCtrl =
        TextEditingController(text: category?['description'] ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(
              category == null ? 'Nouvelle Catégorie' : 'Modifier Catégorie'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nom')),
                TextField(
                    controller: descCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Description')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ANNULER')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameCtrl.text.isEmpty) return;
                      setStateDialog(() => isSaving = true);
                      bool success;
                      if (category == null) {
                        success = await widget.apiService
                            .createCategory(nameCtrl.text, descCtrl.text, null);
                      } else {
                        success = await widget.apiService.updateCategory(
                            category['id'], nameCtrl.text, descCtrl.text, null);
                      }
                      if (success) {
                        Navigator.pop(ctx);
                        _loadCategories();
                      }
                      setStateDialog(() => isSaving = false);
                    },
              child: isSaving
                  ? const CircularProgressIndicator()
                  : const Text('ENREGISTRER'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCategory(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text('Voulez-vous supprimer cette catégorie ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('NON')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('OUI', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final success = await widget.apiService.deleteCategory(id);
      if (success) _loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        backgroundColor: const Color(0xFFFA7456),
        mini: true,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCategories,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  return Card(
                    child: ListTile(
                      leading: SizedBox(
                        width: 40,
                        height: 40,
                        child: (cat['image_url'] != null &&
                                cat['image_url'] != '')
                            ? Image.network(cat['image_url'], fit: BoxFit.cover)
                            : const Icon(Icons.category),
                      ),
                      title: Text(cat['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(cat['description'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _showCategoryDialog(cat)),
                          IconButton(
                              icon: const Icon(Icons.delete,
                                  size: 20, color: Colors.red),
                              onPressed: () => _deleteCategory(cat['id'])),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _ProductsTab extends StatefulWidget {
  final ApiService apiService;
  const _ProductsTab({Key? key, required this.apiService}) : super(key: key);

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  List<dynamic> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final prods = await widget.apiService.getProducts();
    setState(() {
      _products = prods;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final p = _products[index];
          return Card(
            child: ListTile(
              leading: SizedBox(
                width: 40,
                height: 40,
                child: (p['image'] != null && p['image'] != '')
                    ? Image.network(p['image'], fit: BoxFit.cover)
                    : const Icon(Icons.inventory_2),
              ),
              title: Text(p['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${p['price']} XOF • Stock: ${p['stock']}'),
              trailing: const Icon(Icons.chevron_right),
            ),
          );
        },
      ),
    );
  }
}
