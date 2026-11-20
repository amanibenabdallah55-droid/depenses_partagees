import 'package:flutter/material.dart';

class BalancesScreen extends StatelessWidget {
  const BalancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Mes soldes'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Résumé des soldes',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFD1FAE5),
                  child: Icon(
                    Icons.arrow_downward,
                    color: Colors.green,
                  ),
                ),
                title: const Text('Vous devez'),
                subtitle: const Text('Montant à payer'),
                trailing: const Text(
                  '0.00 DT',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFDBEAFE),
                  child: Icon(
                    Icons.arrow_upward,
                    color: Color(0xFF2563EB),
                  ),
                ),
                title: const Text('On vous doit'),
                subtitle: const Text('Montant à recevoir'),
                trailing: const Text(
                  '0.00 DT',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Détails des soldes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            const Center(
              child: Text(
                'Aucun solde disponible',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
