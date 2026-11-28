
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool isLoading = true;
  String? errorMessage;

  int totalExpenses = 0;
  int expensesCount = 0;
  List<Map<String, dynamic>> recentExpenses = [];
  List<Map<String, dynamic>> monthlyStats = [];

  @override
  void initState() {
    super.initState();
    loadStatistics();
  }

  int getAmountMillimes(Map<String, dynamic> data) {
    final value = data['amountMillimes'];

    if (value is num) {
      return value.round();
    }

    final amount = data['amount'];

    if (amount is num) {
      return (amount * 1000).round();
    }

    return 0;
  }

  DateTime? getExpenseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  String formatAmount(int millimes) {
    return '${(millimes / 1000).toStringAsFixed(3)} DT';
  }

  Future<void> loadStatistics() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'Utilisateur non connecté.';
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

      int total = 0;
      int count = 0;

      List<Map<String, dynamic>> allExpenses = [];

      for (final group in groupsSnapshot.docs) {
        final groupData = group.data();

        final groupName =
            groupData['name']?.toString() ?? 'Groupe sans nom';

        final expensesSnapshot = await group.reference
            .collection('expenses')
            .get();

        for (final expense in expensesSnapshot.docs) {
          final data = expense.data();

          final amount = getAmountMillimes(data);

          total += amount;
          count++;

          allExpenses.add({
            'amount': amount,
            'description': data['description'] ??
                data['titre'] ??
                data['title'] ??
                'Dépense',
            'groupName': groupName,
            'date': getExpenseDate(
              data['date'] ?? data['createdAt'],
            ),
          });
        }
      }

      allExpenses.sort((a, b) {
        final dateA = a['date'] as DateTime?;
        final dateB = b['date'] as DateTime?;

        if (dateA == null) return 1;
        if (dateB == null) return -1;

        return dateB.compareTo(dateA);
      });

      final now = DateTime.now();

      List<Map<String, dynamic>> months = [];

      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);

        int monthTotal = 0;

        for (final expense in allExpenses) {
          final date = expense['date'] as DateTime?;

          if (date != null &&
              date.year == month.year &&
              date.month == month.month) {
            monthTotal += expense['amount'] as int;
          }
        }

        months.add({
          'month': month,
          'total': monthTotal,
        });
      }

      if (!mounted) return;

      setState(() {
        totalExpenses = total;
        expensesCount = count;
        recentExpenses = allExpenses.take(5).toList();
        monthlyStats = months;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Erreur lors du chargement des statistiques.';
        isLoading = false;
      });
    }
  }

  String monthName(DateTime date) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];

    return months[date.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final average = expensesCount == 0
        ? 0
        : (totalExpenses / expensesCount).round();

    final maxMonth = monthlyStats.isEmpty
        ? 0
        : monthlyStats
        .map((e) => e['total'] as int)
        .reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: loadStatistics,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorMessage!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: loadStatistics,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: loadStatistics,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Résumé général',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      size: 35,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 10),
                    const Text('Total des dépenses'),
                    const SizedBox(height: 8),
                    Text(
                      formatAmount(totalExpenses),
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'Nombre de dépenses',
                    expensesCount.toString(),
                    Icons.receipt_long,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    'Moyenne',
                    formatAmount(average),
                    Icons.analytics,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            const Text(
              'Dépenses par mois',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: monthlyStats.map((stat) {
                    final month =
                    stat['month'] as DateTime;
                    final amount = stat['total'] as int;

                    final progress = maxMonth == 0
                        ? 0.0
                        : amount / maxMonth;

                    return Padding(
                      padding:
                      const EdgeInsets.only(bottom: 18),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${monthName(month)} ${month.year}',
                              ),
                              Text(
                                formatAmount(amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 9,
                            backgroundColor: Colors.grey[200],
                            color: const Color(0xFF2563EB),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Dernières dépenses',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (recentExpenses.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text('Aucune dépense trouvée.'),
                  ),
                ),
              ),

            ...recentExpenses.map((expense) {
              final date =
              expense['date'] as DateTime?;

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Icon(
                      Icons.receipt,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  title: Text(
                    expense['description'].toString(),
                  ),
                  subtitle: Text(
                    '${expense['groupName']}'
                        '${date == null ? '' : ' • ${date.day}/${date.month}/${date.year}'}',
                  ),
                  trailing: Text(
                    formatAmount(expense['amount'] as int),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF2563EB),
              size: 28,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
