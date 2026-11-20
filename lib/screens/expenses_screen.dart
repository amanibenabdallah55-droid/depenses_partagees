import 'package:flutter/material.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Mes dépenses'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Liste des dépenses',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0E7FF),
                  child: Icon(
                    Icons.restaurant,
                    color: Color(0xFF2563EB),
                  ),
                ),
                title: const Text('Restaurant'),
                subtitle: const Text('Voyage entre amis'),
                trailing: const Text('25.00 DT'),
              ),
            ),

            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0E7FF),
                  child: Icon(
                    Icons.shopping_cart,
                    color: Color(0xFF2563EB),
                  ),
                ),
                title: const Text('Courses'),
                subtitle: const Text('Voyage entre amis'),
                trailing: const Text('40.00 DT'),
              ),
            ),

            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0E7FF),
                  child: Icon(
                    Icons.directions_car,
                    color: Color(0xFF2563EB),
                  ),
                ),
                title: const Text('Transport'),
                subtitle: const Text('Voyage entre amis'),
                trailing: const Text('15.00 DT'),
              ),
            ),

            const SizedBox(height: 15),
            const Center(
              child: Text(
                'Exemples de dépenses',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
