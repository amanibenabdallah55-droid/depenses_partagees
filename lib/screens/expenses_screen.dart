
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
        title: const Text(
          'Mes dépenses',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Toutes vos dépenses',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Consultez les dépenses de vos groupes.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                      child: CircularProgressIndicator(
                        color: Color(0xFF2563EB),
                      ),
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
                                child: CircularProgressIndicator(
                                  color: Color(0xFF2563EB),
                                ),
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
                              const SizedBox(height: 15),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.groups_rounded,
                                    color: Color(0xFF2563EB),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),

                                  Expanded(
                                    child: Text(
                                      groupName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),

                                  Text(
                                    '${expenses.length} dépense(s)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              ...expenses.map((expense) {
                                final data = expense.data();

                                final String title =
                                    data['title'] ?? 'Sans titre';

                                final String description =
                                    data['description'] ?? '';

                                final double amount =
                                (data['amount'] as num).toDouble();

                                final String date =
                                formatDate(data['date']);

                                return Card(
                                  color: Colors.white,
                                  elevation: 2,
                                  shadowColor: Colors.black12,
                                  margin: const EdgeInsets.only(
                                    bottom: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(16),
                                  ),

                                  child: Padding(
                                    padding: const EdgeInsets.all(12),

                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE0E7FF),
                                            borderRadius:
                                            BorderRadius.circular(14),
                                          ),
                                          child: const Icon(
                                            Icons.receipt_long_rounded,
                                            color: Color(0xFF2563EB),
                                            size: 25,
                                          ),
                                        ),

                                        const SizedBox(width: 12),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight:
                                                  FontWeight.bold,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),

                                              if (description.isNotEmpty)
                                                Padding(
                                                  padding:
                                                  const EdgeInsets.only(
                                                    top: 4,
                                                  ),
                                                  child: Text(
                                                    description,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),

                                              const SizedBox(height: 5),

                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.calendar_today,
                                                    size: 12,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    date,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(width: 8),

                                        Text(
                                          '${amount.toStringAsFixed(2)} DT',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                      ],
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
