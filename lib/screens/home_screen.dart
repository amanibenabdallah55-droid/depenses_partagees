
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'groups_screen.dart';
import 'expenses_screen.dart';
import 'balances_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<double> getTotalExpenses() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return 0;

    double total = 0;

    final groups = await FirebaseFirestore.instance
        .collection('groups')
        .where('memberIds', arrayContains: user.uid)
        .get();

    for (var group in groups.docs) {
      final expenses = await FirebaseFirestore.instance
          .collection('groups')
          .doc(group.id)
          .collection('expenses')
          .get();

      for (var expense in expenses.docs) {
        total += (expense.data()['amount'] as num).toDouble();
      }
    }

    return total;
  }

  Widget menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF2563EB),
            size: 27,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 15,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          'Dépenses Partagées',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 10),

            const Text(
              'Bienvenue ! 👋',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Gérez et suivez facilement vos dépenses.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 25),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2563EB),
                    Color(0xFF1D4ED8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.20),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total des dépenses',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  FutureBuilder<double>(
                    future: getTotalExpenses(),

                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const CircularProgressIndicator(
                          color: Colors.white,
                        );
                      }

                      if (snapshot.hasError) {
                        return const Text(
                          'Erreur de chargement',
                          style: TextStyle(color: Colors.white),
                        );
                      }

                      final total = snapshot.data ?? 0;

                      return Text(
                        '${total.toStringAsFixed(2)} DT',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Montant total de vos groupes',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Menu principal',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),

            const SizedBox(height: 15),

            menuCard(
              icon: Icons.groups_rounded,
              title: 'Mes groupes',
              subtitle: 'Gérer vos groupes',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GroupsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            menuCard(
              icon: Icons.receipt_long_rounded,
              title: 'Mes dépenses',
              subtitle: 'Consulter vos dépenses',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExpensesScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            menuCard(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Mes soldes',
              subtitle: 'Consulter vos dettes',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BalancesScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            menuCard(
              icon: Icons.person_rounded,
              title: 'Mon profil',
              subtitle: 'Gérer votre compte',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
