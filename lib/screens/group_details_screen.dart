
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'add_expense_screen.dart';

class GroupDetailsScreen extends StatelessWidget {
  final String groupId;

  const GroupDetailsScreen({
    super.key,
    required this.groupId,
  });

  // Ajouter un membre
  Future<void> addMember(BuildContext context) async {
    final controller = TextEditingController(
      text: 'ga2KIW2J1BYQaVDqgkazPivBfoF3',
    );

    final memberId = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ajouter un membre'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'User UID',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (memberId == null || memberId.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    try {
      final groupRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId);

      final groupSnapshot = await groupRef.get();

      if (!groupSnapshot.exists) return;

      final data = groupSnapshot.data()!;

      if (data['createdBy'] != currentUser.uid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Seul le créateur peut ajouter un membre',
            ),
          ),
        );
        return;
      }

      final List<String> members =
      List<String>.from(data['memberIds'] ?? []);

      if (members.contains(memberId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ce membre existe déjà dans le groupe',
            ),
          ),
        );
        return;
      }

      await groupRef.update({
        'memberIds': FieldValue.arrayUnion([memberId]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Membre ajouté avec succès !'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  // Formater la date
  String formatDate(dynamic date) {
    if (date == null) return '';

    final DateTime expenseDate =
    (date as Timestamp).toDate();

    return '${expenseDate.day}/${expenseDate.month}/${expenseDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text('Détails du groupe'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
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
              child: Text('Erreur : ${groupSnapshot.error}'),
            );
          }

          if (!groupSnapshot.hasData ||
              !groupSnapshot.data!.exists) {
            return const Center(
              child: Text('Groupe introuvable'),
            );
          }

          final data = groupSnapshot.data!.data()!;

          final String name = data['name'] ?? 'Sans nom';
          final String description =
              data['description'] ?? '';

          final List<String> memberIds =
          List<String>.from(data['memberIds'] ?? []);

          final bool isCreator =
              data['createdBy'] == currentUser?.uid;

          return StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('groups')
                .doc(groupId)
                .collection('expenses')
                .orderBy('date', descending: true)
                .snapshots(),

            builder: (context, expenseSnapshot) {
              if (expenseSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Erreur des dépenses : ${expenseSnapshot.error}',
                  ),
                );
              }

              if (expenseSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final expenses =
                  expenseSnapshot.data?.docs ?? [];

              double total = 0;

              for (final expense in expenses) {
                final amount = expense.data()['amount'];

                if (amount is num) {
                  total += amount.toDouble();
                }
              }

              return SingleChildScrollView(
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

                    Center(
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Center(
                      child: Text(
                        description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.account_balance_wallet,
                          color: Color(0xFF2563EB),
                        ),
                        title: const Text(
                          'Total des dépenses',
                        ),
                        subtitle: Text(
                          '${total.toStringAsFixed(2)} DT',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Membres du groupe (${memberIds.length})',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        if (isCreator)
                          IconButton(
                            onPressed: () => addMember(context),
                            icon: const Icon(
                              Icons.person_add,
                              color: Color(0xFF2563EB),
                            ),
                            tooltip: 'Ajouter un membre',
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    if (memberIds.isEmpty)
                      const Card(
                        child: ListTile(
                          title: Text('Aucun membre'),
                        ),
                      )
                    else
                      ...memberIds.map((memberId) {
                        final bool isCurrentUser =
                            memberId == currentUser?.uid;

                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(
                              isCurrentUser ? 'Vous' : 'Membre',
                            ),
                            subtitle: Text(
                              isCurrentUser
                                  ? 'Créateur / Participant'
                                  : 'Participant',
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 25),

                    const Text(
                      'Dépenses récentes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddExpenseScreen(
                                    groupId: groupId,
                                  ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text(
                          'Ajouter une dépense',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (expenses.isEmpty)
                      const Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.receipt_long,
                            color: Color(0xFF2563EB),
                          ),
                          title: Text('Aucune dépense'),
                          subtitle: Text(
                            'Les dépenses apparaîtront ici',
                          ),
                        ),
                      )
                    else
                      ...expenses.map((expense) {
                        final expenseData = expense.data();

                        final String title =
                            expenseData['title'] ?? '';

                        final String description =
                            expenseData['description'] ?? '';

                        final double amount =
                        (expenseData['amount'] as num)
                            .toDouble();

                        final String date =
                        formatDate(expenseData['date']);

                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor:
                              Color(0xFFEFF6FF),
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
                                  ? date
                                  : '$description\n$date',
                            ),
                            isThreeLine:
                            description.isNotEmpty,
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
