
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  String formatDate(dynamic date) {
    if (date == null) return '';

    final DateTime expenseDate = (date as Timestamp).toDate();

    return '${expenseDate.day}/${expenseDate.month}/${expenseDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Veuillez vous connecter'),
        ),
      );
    }

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

            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .where(
                  'memberIds',
                  arrayContains: user.uid,
                )
                    .snapshots(),

                builder: (context, groupSnapshot) {
                  if (groupSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (groupSnapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erreur : ${groupSnapshot.error}',
                      ),
                    );
                  }

                  if (!groupSnapshot.hasData ||
                      groupSnapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Vous ne participez à aucun groupe',
                      ),
                    );
                  }

                  final groups = groupSnapshot.data!.docs;

                  return ListView(
                    children: groups.map((group) {
                      final groupName =
                          group.data()['name'] ?? 'Sans nom';

                      return StreamBuilder<
                          QuerySnapshot<Map<String, dynamic>>>(
                        stream: group.reference
                            .collection('expenses')
                            .orderBy(
                          'date',
                          descending: true,
                        )
                            .snapshots(),

                        builder: (context, expenseSnapshot) {
                          if (expenseSnapshot.hasError) {
                            return Card(
                              child: ListTile(
                                title: Text(
                                  'Erreur : ${expenseSnapshot.error}',
                                ),
                              ),
                            );
                          }

                          if (expenseSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(15),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final expenses =
                              expenseSnapshot.data?.docs ?? [];

                          if (expenses.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,

                            children: [
                              const SizedBox(height: 10),

                              Text(
                                groupName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),

                              const SizedBox(height: 8),

                              ...expenses.map((expense) {
                                final data = expense.data();

                                final String title =
                                    data['title'] ?? 'Sans titre';

                                final String description =
                                    data['description'] ?? '';

                                final double amount =
                                (data['amount'] as num)
                                    .toDouble();

                                final String date =
                                formatDate(data['date']);

                                return Card(
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor:
                                      Color(0xFFE0E7FF),
                                      child: Icon(
                                        Icons.receipt_long,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),

                                    title: Text(
                                      title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    subtitle: Text(
                                      description.isEmpty
                                          ? '$groupName\n$date'
                                          : '$groupName\n$description\n$date',
                                    ),

                                    isThreeLine: true,

                                    trailing: Text(
                                      '${amount.toStringAsFixed(2)} DT',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      );
                    }).toList(),
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
