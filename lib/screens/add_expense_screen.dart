
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddExpenseScreen extends StatefulWidget {
  final String groupId;

  const AddExpenseScreen({
    super.key,
    required this.groupId,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  DateTime selectedDate = DateTime.now();

  bool isLoading = false;
  bool isLoadingMembers = true;

  List<String> memberIds = [];
  Set<String> selectedParticipants = {};

  String? selectedPayer;
  String selectedCategory = 'Autre';
  String sharingType = 'equal';

  final Map<String, TextEditingController> shareControllers = {};

  final List<String> categories = [
    'Restaurant',
    'Courses',
    'Transport',
    'Logement',
    'Loisirs',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    loadMembers();
  }

  Future<void> loadMembers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (!snapshot.exists) {
        throw Exception('Groupe introuvable');
      }

      final data = snapshot.data()!;

      final members = List<String>.from(
        data['memberIds'] ?? [],
      );

      final user = FirebaseAuth.instance.currentUser;

      if (user != null && members.contains(user.uid)) {
        setState(() {
          memberIds = members;
          selectedPayer = user.uid;
          selectedParticipants = members.toSet();

          for (final id in members) {
            shareControllers[id] = TextEditingController();
          }

          isLoadingMembers = false;
        });
      } else {
        setState(() {
          isLoadingMembers = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingMembers = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    descriptionController.dispose();

    for (final controller in shareControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  String memberLabel(String id) {
    final user = FirebaseAuth.instance.currentUser;

    if (id == user?.uid) {
      return 'Vous';
    }

    return 'Membre (${id.substring(0, id.length > 6 ? 6 : id.length)})';
  }

  Future<void> selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  int getAmountInMillimes() {
    final text = amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(text);

    if (amount == null || amount <= 0) {
      return 0;
    }

    return (amount * 1000).round();
  }

  Future<void> saveExpense() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    final amountMillimes = getAmountInMillimes();

    final user = FirebaseAuth.instance.currentUser;

    if (title.isEmpty || amountMillimes <= 0) {
      showMessage('Veuillez saisir un titre et un montant valide');
      return;
    }

    if (user == null) {
      showMessage('Veuillez vous connecter');
      return;
    }

    if (selectedPayer == null) {
      showMessage('Veuillez choisir le payeur');
      return;
    }

    if (selectedParticipants.isEmpty) {
      showMessage('Veuillez choisir au moins un participant');
      return;
    }

    Map<String, int> parts = {};

    if (sharingType == 'equal') {
      final participants = selectedParticipants.toList();

      final baseShare =
          amountMillimes ~/ participants.length;

      final remainder =
          amountMillimes % participants.length;

      for (int i = 0; i < participants.length; i++) {
        parts[participants[i]] =
            baseShare + (i < remainder ? 1 : 0);
      }
    } else {
      int totalShares = 0;

      for (final id in selectedParticipants) {
        final text = shareControllers[id]!.text
            .trim()
            .replaceAll(',', '.');

        final value = double.tryParse(text);

        if (value == null || value < 0) {
          showMessage('Veuillez saisir des parts valides');
          return;
        }

        final millimes = (value * 1000).round();

        parts[id] = millimes;
        totalShares += millimes;
      }

      if (totalShares != amountMillimes) {
        showMessage(
          'La somme des parts doit être égale au montant total',
        );
        return;
      }
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('expenses')
          .add({
        'title': title,
        'amount': amountMillimes / 1000,
        'amountMillimes': amountMillimes,
        'description': description,
        'date': Timestamp.fromDate(selectedDate),

        // Auteur de la dépense
        'createdBy': user.uid,

        // Personne qui a payé
        'payeur': selectedPayer,

        // Membres concernés
        'participants': selectedParticipants.toList(),

        // Parts en millimes
        'parts': parts,

        // Type de partage
        'sharingType': sharingType,

        // Catégorie
        'category': selectedCategory,

        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dépense enregistrée avec succès !'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      showMessage('Erreur : $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF2563EB),
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF2563EB),
          width: 1.5,
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Ajouter une dépense',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: isLoadingMembers
          ? const Center(child: CircularProgressIndicator())
          : memberIds.isEmpty
          ? const Center(
        child: Text('Aucun membre trouvé dans ce groupe'),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(
                Icons.receipt_long_rounded,
                size: 75,
                color: Color(0xFF2563EB),
              ),
            ),

            const SizedBox(height: 15),

            const Center(
              child: Text(
                'Nouvelle dépense',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),

            const SizedBox(height: 25),

            sectionTitle('Titre de la dépense'),

            TextField(
              controller: titleController,
              decoration: inputDecoration(
                'Ex : Restaurant',
                Icons.edit_outlined,
              ),
            ),

            const SizedBox(height: 20),

            sectionTitle('Montant (DT)'),

            TextField(
              controller: amountController,
              keyboardType:
              const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: inputDecoration(
                'Ex : 40.000',
                Icons.payments_outlined,
              ),
            ),

            const SizedBox(height: 20),

            sectionTitle('Description'),

            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: inputDecoration(
                'Ajoutez une description...',
                Icons.description_outlined,
              ),
            ),

            const SizedBox(height: 20),

            sectionTitle('Catégorie'),

            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: inputDecoration(
                'Choisir une catégorie',
                Icons.category_outlined,
              ),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedCategory = value;
                  });
                }
              },
            ),

            const SizedBox(height: 20),

            sectionTitle('Date de la dépense'),

            InkWell(
              onTap: selectDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    ),
                    const Spacer(),
                    const Icon(Icons.keyboard_arrow_down),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            sectionTitle('Payeur'),

            DropdownButtonFormField<String>(
              value: selectedPayer,
              decoration: inputDecoration(
                'Qui a payé ?',
                Icons.person_outline,
              ),
              items: memberIds.map((id) {
                return DropdownMenuItem(
                  value: id,
                  child: Text(memberLabel(id)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPayer = value;
                });
              },
            ),

            const SizedBox(height: 25),

            sectionTitle('Participants'),

            const Text(
              'Choisissez les membres concernés par cette dépense.',
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 10),

            ...memberIds.map((id) {
              return CheckboxListTile(
                value: selectedParticipants.contains(id),
                activeColor: const Color(0xFF2563EB),
                title: Text(memberLabel(id)),
                controlAffinity:
                ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedParticipants.add(id);
                    } else {
                      selectedParticipants.remove(id);
                    }
                  });
                },
              );
            }),

            const SizedBox(height: 20),

            sectionTitle('Type de partage'),

            RadioListTile<String>(
              value: 'equal',
              groupValue: sharingType,
              activeColor: const Color(0xFF2563EB),
              title: const Text('Partage égal'),
              subtitle: const Text(
                'Répartir le montant également',
              ),
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  sharingType = value!;
                });
              },
            ),

            RadioListTile<String>(
              value: 'custom',
              groupValue: sharingType,
              activeColor: const Color(0xFF2563EB),
              title: const Text('Partage personnalisé'),
              subtitle: const Text(
                'Définir le montant de chaque participant',
              ),
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  sharingType = value!;
                });
              },
            ),

            if (sharingType == 'custom') ...[
              const SizedBox(height: 10),

              sectionTitle('Parts de chaque participant'),

              ...selectedParticipants.map((id) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: shareControllers[id],
                    keyboardType:
                    const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: inputDecoration(
                      'Montant en DT',
                      Icons.person_outline,
                    ).copyWith(
                      labelText: memberLabel(id),
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : const Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_outlined),
                    SizedBox(width: 10),
                    Text(
                      'Enregistrer la dépense',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
