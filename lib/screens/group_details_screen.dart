import 'package:flutter/material.dart';

class GroupDetailsScreen extends StatelessWidget {
  const GroupDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text('Détails du groupe'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(
                Icons.groups,
                size: 85,
                color: Color(0xFF2563EB),
              ),
            ),

            const SizedBox(height: 15),

            const Center(
              child: Text(
                'Voyage entre amis',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Center(
              child: Text(
                'Groupe de partage des dépenses',
                style: TextStyle(color: Colors.black54),
              ),
            ),

            const SizedBox(height: 25),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF2563EB),
                ),
                title: const Text('Total des dépenses'),
                subtitle: const Text('0.00 DT'),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Membres du groupe',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: const Text('Membre 1'),
                subtitle: const Text('Participant'),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Dépenses récentes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Card(
              child: ListTile(
                leading: Icon(
                  Icons.receipt_long,
                  color: Color(0xFF2563EB),
                ),
                title: Text('Aucune dépense'),
                subtitle: Text('Les dépenses apparaîtront ici'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
