import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RemboursementsScreen extends StatefulWidget {
  const RemboursementsScreen({super.key});

  @override
  State<RemboursementsScreen> createState() =>
      _RemboursementsScreenState();
}

class _RemboursementsScreenState
    extends State<RemboursementsScreen> {
  bool isLoading = true;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> groups = [];
  String? selectedGroupId;
  String selectedGroupName = '';

  Map<String, String> memberNames = {};
  List<Map<String, dynamic>> suggestions = [];
  List<Map<String, dynamic>> history = [];

  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadGroups();
  }

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

  Map<String, int> calculateEqualShares(
      int amount,
      List<String> participants,
      ) {
    final Map<String, int> shares = {};

    if (participants.isEmpty) return shares;

    final baseShare = amount ~/ participants.length;
    final remainder = amount % participants.length;

    for (int i = 0; i < participants.length; i++) {
      shares[participants[i]] =
          baseShare + (i < remainder ? 1 : 0);
    }

    return shares;
  }

  String formatAmount(int millimes) {
    return '${(millimes / 1000).toStringAsFixed(3)} DT';
  }

  Future<String> getMemberName(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        return data['name'] ??
            data['displayName'] ??
            data['email'] ??
            uid;
      }
    } catch (_) {}

    return uid.length > 8 ? uid.substring(0, 8) : uid;
  }

  Future<void> loadGroups() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'Veuillez vous connecter';
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('memberIds', arrayContains: user.uid)
          .get();

      if (!mounted) return;

      setState(() {
        groups = snapshot.docs;
        isLoading = false;
      });

      if (groups.isNotEmpty) {
        await selectGroup(groups.first);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Erreur : $e';
        isLoading = false;
      });
    }
  }

  Future<void> selectGroup(
      QueryDocumentSnapshot<Map<String, dynamic>> group,
      ) async {
    setState(() {
      isLoading = true;
      selectedGroupId = group.id;
      selectedGroupName = group.data()['name'] ?? 'Sans nom';
      errorMessage = null;
    });

    try {
      final groupRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(group.id);

      final members =
      List<String>.from(group.data()['memberIds'] ?? []);

      final balances = <String, int>{
        for (final member in members) member: 0,
      };

      // Calculer les soldes à partir des dépenses.
      final expenses = await groupRef
          .collection('expenses')
          .get();

      for (final expense in expenses.docs) {
        final data = expense.data();
        final amount = getAmountMillimes(data);

        if (amount <= 0) continue;

        final payerId =
            data['payeur'] ?? data['createdBy'] ?? '';

        List<String> participants =
        List<String>.from(data['participants'] ?? []);

        if (participants.isEmpty) {
          participants = members;
        }

        final Map<String, int> shares = {};
        final savedParts = data['parts'];

        if (savedParts is Map && savedParts.isNotEmpty) {
          savedParts.forEach((key, value) {
            if (value is num) {
              shares[key.toString()] = value.round();
            }
          });
        } else {
          shares.addAll(
            calculateEqualShares(amount, participants),
          );
        }

        if (payerId.toString().isNotEmpty) {
          balances[payerId.toString()] =
              (balances[payerId.toString()] ?? 0) + amount;
        }

        for (final entry in shares.entries) {
          balances[entry.key] =
              (balances[entry.key] ?? 0) - entry.value;
        }
      }

      // Prendre en compte les remboursements déjà effectués.
      final reimbursements = await groupRef
          .collection('remboursements')
          .get();

      final historyList = <Map<String, dynamic>>[];

      for (final reimbursement in reimbursements.docs) {
        final data = reimbursement.data();

        final de = data['de']?.toString() ?? '';
        final a = data['a']?.toString() ?? '';
        final montant = data['montant'];

        if (de.isEmpty || a.isEmpty || montant is! num) {
          continue;
        }

        final amount = montant.round();

        balances[de] = (balances[de] ?? 0) + amount;
        balances[a] = (balances[a] ?? 0) - amount;

        historyList.add({
          'de': de,
          'a': a,
          'montant': amount,
          'date': data['date'],
        });
      }

      // Préparer les remboursements à effectuer.
      final debtors = <Map<String, dynamic>>[];
      final creditors = <Map<String, dynamic>>[];

      balances.forEach((uid, balance) {
        if (balance < 0) {
          debtors.add({'uid': uid, 'amount': -balance});
        } else if (balance > 0) {
          creditors.add({'uid': uid, 'amount': balance});
        }
      });

      final newSuggestions = <Map<String, dynamic>>[];

      int i = 0;
      int j = 0;

      while (i < debtors.length && j < creditors.length) {
        final debtor = debtors[i];
        final creditor = creditors[j];

        final amount = (debtor['amount'] as int) <
            (creditor['amount'] as int)
            ? debtor['amount'] as int
            : creditor['amount'] as int;

        if (amount > 0) {
          newSuggestions.add({
            'de': debtor['uid'],
            'a': creditor['uid'],
            'montant': amount,
          });
        }

        debtor['amount'] =
            (debtor['amount'] as int) - amount;
        creditor['amount'] =
            (creditor['amount'] as int) - amount;

        if (debtor['amount'] == 0) i++;
        if (creditor['amount'] == 0) j++;
      }

      final names = <String, String>{};

      for (final uid in balances.keys) {
        names[uid] = await getMemberName(uid);
      }

      if (!mounted) return;

      setState(() {
        memberNames = names;
        suggestions = newSuggestions;
        history = historyList;
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

  Future<void> recordReimbursement(
      Map<String, dynamic> reimbursement,
      ) async {
    if (selectedGroupId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(selectedGroupId)
          .collection('remboursements')
          .add({
        'de': reimbursement['de'],
        'a': reimbursement['a'],
        'montant': reimbursement['montant'],
        'date': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remboursement enregistré avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      final group = groups.firstWhere(
            (element) => element.id == selectedGroupId,
      );

      await selectGroup(group);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Mes remboursements'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: selectedGroupId == null
                ? null
                : () {
              final group = groups.firstWhere(
                    (element) => element.id == selectedGroupId,
              );
              selectGroup(group);
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : groups.isEmpty
          ? const Center(
        child: Text('Vous ne participez à aucun groupe'),
      )
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choisir un groupe',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedGroupId,
              isExpanded: true,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
              items: groups.map((group) {
                return DropdownMenuItem<String>(
                  value: group.id,
                  child: Text(
                    group.data()['name'] ?? 'Sans nom',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                final group = groups.firstWhere(
                      (element) => element.id == value,
                );

                selectGroup(group);
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Remboursements à effectuer - $selectedGroupName',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  if (suggestions.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Aucun remboursement à effectuer. Tout est réglé !',
                        ),
                      ),
                    ),
                  ...suggestions.map((item) {
                    final de = item['de'].toString();
                    final a = item['a'].toString();
                    final amount = item['montant'] as int;

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFEE2E2),
                          child: Icon(
                            Icons.payments,
                            color: Colors.red,
                          ),
                        ),
                        title: Text(
                          '${memberNames[de] ?? de} doit ${formatAmount(amount)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'à ${memberNames[a] ?? a}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 28,
                          ),
                          tooltip: 'Enregistrer',
                          onPressed: () {
                            recordReimbursement(item);
                          },
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  const Text(
                    'Historique des remboursements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (history.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Aucun remboursement enregistré',
                        ),
                      ),
                    ),
                  ...history.map((item) {
                    final de = item['de'].toString();
                    final a = item['a'].toString();
                    final amount = item['montant'] as int;

                    return Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        title: Text(
                          '${memberNames[de] ?? de} a remboursé ${formatAmount(amount)}',
                        ),
                        subtitle: Text(
                          'à ${memberNames[a] ?? a}',
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}