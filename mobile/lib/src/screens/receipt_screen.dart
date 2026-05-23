import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class ReceiptScreen extends StatelessWidget {
  static const Color _textColor = Color(0xFF111827);
  static const Color _mutedTextColor = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const MethodChannel _downloadChannel =
      MethodChannel('boboexpress/downloads');

  final Map<String, dynamic> order;
  const ReceiptScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = order['items'] as List<dynamic>? ?? [];
    final date = DateTime.tryParse(order['created_at'] ?? '') ?? DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Reçu de paiement',
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle,
                              color: Colors.green, size: 40),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Paiement Réussi',
                          style: TextStyle(
                              color: _textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${order['total_amount']} XOF',
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: colorScheme.primary),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildInfoRow('N° Commande',
                            order['tracking_code'] ?? '#${order['id']}'),
                        _buildInfoRow('Date', formattedDate),
                        _buildInfoRow(
                            'Méthode',
                            order['payment_method']?.toString().toUpperCase() ??
                                'MOMO'),
                        if (order['transaction_id'] != null)
                          _buildInfoRow(
                              'Transaction ID', order['transaction_id']),
                      ],
                    ),
                  ),

                  // Articles
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(24)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DÉTAILS DES ARTICLES',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _mutedTextColor,
                              letterSpacing: 1),
                        ),
                        const SizedBox(height: 16),
                        ...items.map((item) => _buildItemRow(item)).toList(),
                        const SizedBox(height: 16),
                        const Divider(color: _borderColor),
                        const SizedBox(height: 16),
                        _buildPriceRow(
                            'Sous-total', '${order['subtotal']} XOF'),
                        _buildPriceRow(
                            'Livraison', '${order['delivery_fee']} XOF'),
                        if (double.parse(
                                order['discount_amount']?.toString() ?? '0') >
                            0)
                          _buildPriceRow(
                              'Réduction', '-${order['discount_amount']} XOF',
                              isDiscount: true),
                        const SizedBox(height: 16),
                        _buildPriceRow('Total', '${order['total_amount']} XOF',
                            isTotal: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            TextButton.icon(
              onPressed: () => _downloadReceipt(context),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Telecharger le recu'),
              style: TextButton.styleFrom(primary: colorScheme.primary),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _downloadReceipt(context),
                icon: const Icon(Icons.download_outlined),
                label: const Text('TELECHARGER'),
                style: ElevatedButton.styleFrom(
                  primary: colorScheme.primary,
                  onPrimary: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadReceipt(BuildContext context) async {
    try {
      final fileName = _receiptFileName();
      final content = _receiptText();
      String savedPath;

      if (Platform.isAndroid) {
        savedPath = await _downloadChannel.invokeMethod<String>(
              'saveTextFile',
              {'fileName': fileName, 'content': content},
            ) ??
            'Telechargements/$fileName';
      } else {
        final file = File('${Directory.systemTemp.path}/$fileName');
        await file.writeAsString(content);
        savedPath = file.path;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recu telecharge. Notification envoyee. $savedPath'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de telecharger le recu : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _receiptFileName() {
    final rawCode = (order['tracking_code'] ?? order['id'] ?? 'commande')
        .toString()
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return 'recu_boboexpress_$rawCode.txt';
  }

  String _receiptText() {
    final items = order['items'] as List<dynamic>? ?? [];
    final date = DateTime.tryParse(order['created_at'] ?? '') ?? DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
    final buffer = StringBuffer()
      ..writeln('BOBOEXPRESS - RECU DE PAIEMENT')
      ..writeln('--------------------------------')
      ..writeln('Montant total : ${order['total_amount']} XOF')
      ..writeln('N commande : ${order['tracking_code'] ?? '#${order['id']}'}')
      ..writeln('Date : $formattedDate')
      ..writeln(
          'Methode : ${order['payment_method']?.toString().toUpperCase() ?? 'MOMO'}')
      ..writeln('Transaction ID : ${order['transaction_id'] ?? 'N/A'}')
      ..writeln()
      ..writeln('DETAILS DES ARTICLES');

    for (final item in items) {
      final product = item['product'] ?? {};
      final name = product['name'] ?? 'Article';
      final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      final price = double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0;
      buffer.writeln('- $name x$qty : ${(price * qty).toStringAsFixed(2)} XOF');
    }

    buffer
      ..writeln()
      ..writeln('Sous-total : ${order['subtotal']} XOF')
      ..writeln('Livraison : ${order['delivery_fee']} XOF')
      ..writeln('Total : ${order['total_amount']} XOF');

    return buffer.toString();
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: _mutedTextColor, fontSize: 13)),
          Text(value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: _textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildItemRow(dynamic item) {
    final product = item['product'] ?? {};
    final variant = item['variant'];
    final name = product['name'] ?? 'Article';
    final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
    final priceStr = item['unit_price']?.toString() ?? '0';
    final price = double.tryParse(priceStr) ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: _textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                if (variant != null)
                  Text(
                    '${variant['color'] ?? ''} ${variant['size'] ?? ''}'.trim(),
                    style: const TextStyle(
                        color: _mutedTextColor, fontSize: 12),
                  ),
              ],
            ),
          ),
          Text('x$qty',
              style: const TextStyle(color: _mutedTextColor, fontSize: 14)),
          const SizedBox(width: 16),
          Text('${(price * qty).toStringAsFixed(2)} F',
              style:
                  const TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value,
      {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.red : _textColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold,
              color: isDiscount
                  ? Colors.red
                  : _textColor,
            ),
          ),
        ],
      ),
    );
  }
}
