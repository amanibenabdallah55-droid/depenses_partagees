
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BalancesScreen extends StatefulWidget {
  const BalancesScreen({super.key});

  @override
  State<BalancesScreen> createState() => _BalancesScreenState();
}

class _BalancesScreenState extends State<BalancesScreen> {
  double amountToPay = 0;
  double amountToReceive = 0;

  List<Map<String, dynamic>> groupBalances = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadBalances();
  }

  // Convert an amount to integer millimes.
  int getAmountMillimes(Map<String, dynamic> data) {
    final value = data['amountMillimes'];

    if (value is num) {
      return value.round();
    }

    final oldAmount = data['amount'];

    if (oldAmount is num) {
      return (oldAmount * 1000).round();
    }

    return 0;
  }

  // Calculate equal shares without losing millimes.
  Map<String, int> calculateEqualShares(
      int amount,
      List<String> participants,
      ) {
    final Map<String, int> shares = {};

    if (participants.isEmpty) return shares;

    final baseShare = amount ~/ participants.length;
    final remainder = amount % participants.length;

    for (int i = 0; i < participants.length; i++) {
      shares[participants[i]] = baseShare + (i < remainder ? 1 : 0);
    }

    return shares;
  }

  Future<void> loadBalances() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Veuillez vous connecter';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final groupsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('memberIds', arrayContains: user.uid)
          .get();

      int totalToPayMillimes = 0;
      int totalToReceiveMillimes = 0;

      List<Map<String, dynamic>> results = [];

      for (final group in groupsSnapshot.docs) {
        final groupData = group.data();

        final String groupName = groupData['name'] ?? 'Sans nom';

        final List<String> members =
        List<String>.from(groupData['memberIds'] ?? []);

        if (members.isEmpty) continue;

        final expensesSnapshot =
        await group.reference.collection('expenses').get();

        int groupBalanceMillimes = 0;

        for (final expense in expensesSnapshot.docs) {
          final expenseData = expense.data();

          final int amount = getAmountMillimes(expenseData);

          if (amount <= 0) continue;

          // The person who paid.
          final String payerId =
              expenseData['payeur'] ?? expenseData['createdBy'] ?? '';

          // Get the participants of this expense.
          List<String> participants =
          List<String>.from(expenseData['participants'] ?? []);

          // Compatibility with old expenses.
          if (participants.isEmpty) {
            participants = members;
          }

          // Get each participant's share.
          Map<String, int> shares = {};

          final savedParts = expenseData['parts'];

          if (savedParts is Map && savedParts.isNotEmpty) {
            savedParts.forEach((key, value) {
              if (value is num) {
                shares[key.toString()] = value.round();
              }
            });
          } else {
            // Old expenses or expenses without saved shares.
            shares = calculateEqualShares(amount, participants);
          }

          // Add the amount paid by the current user.
          if (payerId == user.uid) {
            groupBalanceMillimes += amount;
          }

          // Subtract the current user's share.
          groupBalanceMillimes -= shares[user.uid] ?? 0;
        }

        if (groupBalanceMillimes < 0) {
          totalToPayMillimes += groupBalanceMillimes.abs();
        } else if (groupBalanceMillimes > 0) {
          totalToReceiveMillimes += groupBalanceMillimes;
        }

        results.add({
          'name': groupName,
          'balance': groupBalanceMillimes / 1000,
        });
      }

      if (!mounted) return;

      setState(() {
        amountToPay = totalToPayMillimes / 1000;
        amountToReceive = totalToReceiveMillimes / 1000;
        groupBalances = results;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Erreur : $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Mes soldes'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: loadBalances,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : Padding(
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
                  backgroundColor: Color(0xFFFEE2E2),
                  child: Icon(
                    Icons.arrow_downward,
                    color: Colors.red,
                  ),
                ),
                title: const Text('Vous devez'),
                subtitle: const Text('Montant à payer'),
                trailing: Text(
                  '${amountToPay.toStringAsFixed(3)} DT',
                  style: const TextStyle(
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
                  backgroundColor: Color(0xFFD1FAE5),
                  child: Icon(
                    Icons.arrow_upward,
                    color: Colors.green,
                  ),
                ),
                title: const Text('On vous doit'),
                subtitle: const Text('Montant à recevoir'),
                trailing: Text(
                  '${amountToReceive.toStringAsFixed(3)} DT',
                  style: const TextStyle(
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

            Expanded(
              child: groupBalances.isEmpty
                  ? const Center(
                child: Text(
                  'Aucun solde disponible',
                  style: TextStyle(color: Colors.black54),
                ),
              )
                  : ListView.builder(
                itemCount: groupBalances.length,
                itemBuilder: (context, index) {
                  final item = groupBalances[index];

                  final String name = item['name'];
                  final double balance = item['balance'];

                  final bool receives = balance > 0.0001;
                  final bool pays = balance < -0.0001;

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: receives
                            ? const Color(0xFFD1FAE5)
                            : pays
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFE0E7FF),
                        child: Icon(
                          receives
                              ? Icons.arrow_upward
                              : pays
                              ? Icons.arrow_downward
                              : Icons.check,
                          color: receives
                              ? Colors.green
                              : pays
                              ? Colors.red
                              : const Color(0xFF2563EB),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        receives
                            ? 'On vous doit'
                            : pays
                            ? 'Vous devez'
                            : 'Tout est réglé',
                      ),
                      trailing: Text(
                        '${balance.abs().toStringAsFixed(3)} DT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: receives
                              ? Colors.green
                              : pays
                              ? Colors.red
                              : Colors.black54,
                        ),
                      ),
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
