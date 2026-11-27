
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
    final controller = TextEditingController();

    final memberId = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Ajouter un membre'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'User UID',
              hintText: 'Saisir le UID du membre',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
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
        title: const Text(
          'Détails du groupe',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
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
                    // Informations du groupe
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDBEAFE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.groups_rounded,
                              size: 48,
                              color: Color(0xFF2563EB),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),

                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Total des dépenses
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF2563EB),
                            Color(0xFF1D4ED8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),

                          const SizedBox(width: 15),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total des dépenses',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${total.toStringAsFixed(2)} DT',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Membres
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Membres (${memberIds.length})',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),

                        if (isCreator)
                          IconButton(
                            onPressed: () => addMember(context),
                            tooltip: 'Ajouter un membre',
                            icon: const Icon(
                              Icons.person_add_alt_1,
                              color: Color(0xFF2563EB),
                            ),
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
                          color: Colors.white,
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFDBEAFE),
                              child: Icon(
                                Icons.person,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            title: Text(
                              isCurrentUser ? 'Vous' : 'Membre',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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

                    // Dépenses récentes
                    const Text(
                      'Dépenses récentes',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),

                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    if (expenses.isEmpty)
                      Card(
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const ListTile(
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
                        (expenseData['amount'] as num).toDouble();

                        final String date =
                        formatDate(expenseData['date']);

                        return Card(
                          color: Colors.white,
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            contentPadding:
                            const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
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
                            isThreeLine: description.isNotEmpty,
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
