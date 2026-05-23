import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';
import '../screens/payment_screen.dart';
import '../services/location_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = 'cod';
  int? _selectedAddressId;
  List<dynamic> _addresses = [];
  bool _isLoading = false;
  bool _isCreatingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    final addresses = await ApiService().getAddresses();
    setState(() {
      _addresses = addresses;
      if (addresses.isNotEmpty) {
        final primary = addresses.firstWhere((a) => a['is_primary'] == true,
            orElse: () => addresses[0]);
        _selectedAddressId = primary['id'];
      }
      _isLoading = false;
    });
  }

  Future<void> _handlePlaceOrder() async {
    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner une adresse')));
      return;
    }

    final isMomo =
        _selectedPaymentMethod == 'orange' || _selectedPaymentMethod == 'moov';
    setState(() => _isCreatingOrder = true);
    final cartService = Provider.of<CartService>(context, listen: false);
    final cart = cartService.cart;

    if (cart == null ||
        cart['items'] == null ||
        (cart['items'] as List).isEmpty) {
      setState(() => _isCreatingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Votre panier est vide.')));
      return;
    }

    final List<dynamic> cartItems = cart['items'];
    final itemsInput = cartItems
        .map((item) => {
              'product_id': item[
                  'product'], // 'product' est déjà l'ID dans le sérialiseur
              'quantity': item['quantity'],
            })
        .toList();

    final orderData = {
      'address_id': _selectedAddressId,
      'payment_method': isMomo ? 'momo' : _selectedPaymentMethod,
      'delivery_type': 'standard',
      'items_input': itemsInput,
    };

    final result = await ApiService().createOrder(orderData);

    if (!mounted) return;
    setState(() => _isCreatingOrder = false);

    if (result['success']) {
      final order = result['data'];
      cartService.clearCart();

      if (isMomo) {
        final paymentResult = await ApiService()
            .initPayment(order['id'], momoType: _selectedPaymentMethod);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                  paymentData: paymentResult, orderId: order['id']),
            ),
          );
        }
      } else {
        Navigator.pushReplacementNamed(context, '/delivery-selection',
            arguments: {'orderId': order['id']});
      }
    } else {
      String errorMsg = result['message'] ?? 'Erreur inconnue';

      // Essayer de rendre le message plus lisible si c'est du JSON d'erreur DRF
      if (errorMsg.contains('items_input')) {
        errorMsg =
            'Un ou plusieurs articles posent problème (stock insuffisant ou produit indisponible).';
      } else if (errorMsg.contains('Stock insuffisant')) {
        // Déjà géré par le backend dans non_field_errors
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Commande impossible'),
          content: Text(errorMsg),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'))
          ],
        ),
      );
    }
  }

  Future<void> _showAddAddressDialog() async {
    final streetController = TextEditingController();
    final cityController = TextEditingController();
    final labelController = TextEditingController(text: 'Maison');
    double? lat;
    double? lng;
    bool isDetecting = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Nouvelle adresse'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: isDetecting
                      ? null
                      : () async {
                          setStateDialog(() => isDetecting = true);
                          try {
                            final data =
                                await LocationService.getCurrentLocationData();
                            if (data != null) {
                              String street = data['street'] ?? '';
                              String neighborhood = data['neighborhood'] ?? '';

                              if (street.isNotEmpty &&
                                  neighborhood.isNotEmpty) {
                                streetController.text =
                                    "$street, $neighborhood";
                              } else {
                                streetController.text =
                                    street.isNotEmpty ? street : neighborhood;
                              }

                              cityController.text =
                                  data['city'] ?? 'Bobo-Dioulasso';
                              lat = data['latitude'];
                              lng = data['longitude'];
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                  content: Text('Erreur: $e'),
                                  backgroundColor: Colors.red),
                            );
                          } finally {
                            setStateDialog(() => isDetecting = false);
                          }
                        },
                  icon: isDetecting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location, size: 18),
                  label: Text(
                      isDetecting ? 'Détection...' : 'Ma position actuelle'),
                  style: OutlinedButton.styleFrom(
                    primary: const Color(0xFFFA7456),
                    side: const BorderSide(color: Color(0xFFFA7456)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('OU REMPLIR MANUELLEMENT',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 8),
                TextField(
                    controller: labelController,
                    decoration: const InputDecoration(
                        labelText: 'Nom (ex: Maison, Bureau)')),
                TextField(
                    controller: streetController,
                    decoration:
                        const InputDecoration(labelText: 'Rue / Quartier')),
                TextField(
                    controller: cityController,
                    decoration: const InputDecoration(labelText: 'Ville')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (streetController.text.isEmpty ||
                    cityController.text.isEmpty) return;

                final response = await ApiService().post('/users/addresses/', {
                  'label': labelController.text,
                  'type': 'home',
                  'street': streetController.text,
                  'city': cityController.text,
                  'latitude': lat,
                  'longitude': lng,
                  'is_primary': _addresses.isEmpty,
                });

                if (response.statusCode == 201) {
                  Navigator.pop(this.context);
                  _loadAddresses();
                } else {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Erreur lors de l\'enregistrement: ${response.body}'),
                        backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final cart = cartService.cart;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Validation de commande',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAddressSection(),
                  _buildPaymentSection(),
                  _buildSummarySection(cart),
                  const SizedBox(height: 100),
                ],
              ),
            ),
      bottomSheet: _buildBottomButton(),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.location_on_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('Adresse de livraison',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              TextButton(
                  onPressed: () {},
                  child: const Text('Gérer',
                      style: TextStyle(
                          color: Color(0xFFFA7456),
                          fontWeight: FontWeight.bold))),
            ],
          ),
          const Divider(),
          if (_addresses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  const Text('Où devons-nous livrer ?',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddAddressDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter une adresse'),
                    style: ElevatedButton.styleFrom(
                      primary: const Color(0xFFFA7456),
                      onPrimary: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                ..._addresses.map((addr) {
                  final isSelected = _selectedAddressId == addr['id'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedAddressId = addr['id']),
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFA7456).withOpacity(0.05)
                            : Colors.transparent,
                        border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFA7456)
                                : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.radio_button_off,
                            color: isSelected
                                ? const Color(0xFFFA7456)
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(addr['label'] ?? 'Adresse',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text('${addr['street']}, ${addr['city']}',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _showAddAddressDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouvelle adresse',
                      style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(primary: Colors.grey.shade600),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.payment_outlined, size: 20),
              SizedBox(width: 8),
              Text('Mode de paiement',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          _buildPaymentTile('cod', 'Cash à la livraison', Icons.money_off),
          _buildPaymentTile('orange', 'Orange Money', Icons.phone_android,
              color: const Color(0xFFFF6600)),
          _buildPaymentTile('moov', 'Moov Money', Icons.phone_iphone,
              color: const Color(0xFF003399)),
          _buildPaymentTile('card', 'Carte bancaire', Icons.credit_card),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(String value, String title, IconData icon,
      {Color? color}) {
    final isSelected = _selectedPaymentMethod == value;
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = color ?? colorScheme.primary;

    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:
              isSelected ? activeColor.withOpacity(0.05) : Colors.transparent,
          border: Border.all(
              color: isSelected ? activeColor : Colors.grey.shade200,
              width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? activeColor : Colors.grey, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.black : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: activeColor, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(Map<String, dynamic>? cart) {
    if (cart == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Résumé de la commande',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildSummaryRow('Sous-total', '${cart['total']} XOF'),
          _buildSummaryRow('Frais de livraison', '500 XOF'),
          const Divider(height: 24),
          _buildSummaryRow('Total',
              '${(double.tryParse(cart['total'].toString()) ?? 0) + 500} XOF',
              isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.black : Colors.black54,
              )),
          Text(value,
              style: TextStyle(
                fontSize: isTotal ? 18 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? const Color(0xFFFA7456) : Colors.black,
              )),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -5),
              blurRadius: 10)
        ],
      ),
      child: ElevatedButton(
        onPressed: _isCreatingOrder ? null : _handlePlaceOrder,
        style: ElevatedButton.styleFrom(
          primary: const Color(0xFFFA7456),
          onPrimary: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isCreatingOrder
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text('Confirmer la commande',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
