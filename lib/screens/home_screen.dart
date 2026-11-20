import 'package:flutter/material.dart';
import 'groups_screen.dart';
import 'expenses_screen.dart';
import 'balances_screen.dart';
import 'profile_screen.dart';
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text('Dépenses Partagées'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'Bienvenue ! 👋',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Voici un aperçu de vos dépenses.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 25),

            Card(
              color: const Color(0xFF2563EB),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total des dépenses',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),

                    SizedBox(height: 12),

                    Text(
                      '0.00 DT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Menu principal',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.groups,
                  color: Color(0xFF2563EB),
                  size: 35,
                ),
                title: const Text('Mes groupes'),
                subtitle: const Text('Gérer vos groupes'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GroupsScreen(),
                    ),
                  );
                },
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.receipt_long,
                  color: Color(0xFF2563EB),
                  size: 35,
                ),
                title: const Text('Mes dépenses'),
                subtitle: const Text('Consulter vos dépenses'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExpensesScreen(),
                    ),
                  );
                },
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF2563EB),
                  size: 35,
                ),
                title: const Text('Mes soldes'),
                subtitle: const Text('Consulter vos dettes'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BalancesScreen(),
                    ),
                  );
                },
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.person,
                  color: Color(0xFF2563EB),
                  size: 35,
                ),
                title: const Text('Mon profil'),
                subtitle: const Text('Gérer votre compte'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
