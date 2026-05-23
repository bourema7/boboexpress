import 'package:flutter/material.dart';

class DeliveryHistoryScreen extends StatelessWidget {
  const DeliveryHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique livraisons')),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            color: Colors.white10,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text('Livraison ${index + 1}'),
              subtitle: const Text('Terminé · 25 000 XOF'),
            ),
          );
        },
      ),
    );
  }
}
