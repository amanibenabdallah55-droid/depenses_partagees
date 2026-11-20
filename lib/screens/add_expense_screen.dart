import 'package:flutter/material.dart';

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une dépense'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Icon(
              Icons.receipt_long,
              size: 85,
              color: Color(0xFF2563EB),
            ),

            const SizedBox(height: 30),

            const TextField(
              decoration: InputDecoration(
                labelText: 'Titre de la dépense',
                prefixIcon: Icon(Icons.edit),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Montant (DT)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const TextField(
              decoration: InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Date de la dépense',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Enregistrer la dépense'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
