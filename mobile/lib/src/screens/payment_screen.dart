import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:async';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> paymentData;
  final int orderId;

  const PaymentScreen(
      {Key? key, required this.paymentData, required this.orderId})
      : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  bool _showPushSimulation = false;
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Simuler l'arrivée du push après 2 secondes
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showPushSimulation = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handlePayment() async {
    setState(() {
      _isProcessing = true;
      _showPushSimulation = false;
    });

    try {
      final result = await ApiService().confirmPayment(widget.orderId, "");

      if (mounted) setState(() => _isProcessing = false);

      if (result['status'] == 'success') {
        _showCelebrationDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(result['message'] ?? 'Erreur lors de la validation')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOrange = widget.paymentData['merchant_momo_type'] == 'orange';
    final Color operatorColor =
        isOrange ? const Color(0xFFFF6600) : const Color(0xFF003399);
    final String operatorName = isOrange ? 'Orange Money' : 'Moov Money';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(operatorName,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: operatorColor,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: operatorColor,
                  padding:
                      const EdgeInsets.only(bottom: 40, left: 24, right: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        '${widget.paymentData['amount'] ?? '0'} XOF',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Montant à payer',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildRow(
                            'Boutique',
                            widget.paymentData['merchant_name'] ??
                                'BoboExpress'),
                        const Divider(height: 32),
                        _buildRow('Compte marchand',
                            widget.paymentData['merchant_momo'] ?? ''),
                        const Divider(height: 32),
                        _buildRow('ID Transaction',
                            widget.paymentData['transaction_id'] ?? ''),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.grey, size: 20),
                      const SizedBox(height: 12),
                      Text(
                        'Veuillez confirmer le débit de ${widget.paymentData['amount']} XOF sur votre compte ${widget.paymentData['customer_phone']}.\n\nTemps restant : ${_secondsLeft}s',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: Colors.grey.shade600, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_isProcessing)
                  const CircularProgressIndicator()
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _handlePayment,
                        style: ElevatedButton.styleFrom(
                          primary: operatorColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('J\'AI VALIDÉ SUR MON TÉLÉPHONE',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler le paiement',
                      style: TextStyle(color: Colors.red.shade400)),
                ),
              ],
            ),
          ),

          // Simulation du Push Prompt
          if (_showPushSimulation)
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - value) * -100),
                    child: Opacity(
                      opacity: value,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10)
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: operatorColor, shape: BoxShape.circle),
                              child: const Icon(Icons.payment,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(operatorName,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  const Text(
                                      'Tapez votre code secret pour payer BoboExpress',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() => _showPushSimulation = false);
                                _handlePayment();
                              },
                              child: const Text('PAYER',
                                  style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  void _showCelebrationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.check_circle,
                    color: Colors.green, size: 80),
              ),
              const SizedBox(height: 24),
              const Text('Paiement Réussi !',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'Votre commande est maintenant confirmée. Le marchand commence la préparation.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacementNamed(
                        context, '/delivery-selection',
                        arguments: {'orderId': widget.orderId});
                  },
                  style: ElevatedButton.styleFrom(
                    primary: const Color(0xFFFA7456),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('CHOISIR MON LIVREUR',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
