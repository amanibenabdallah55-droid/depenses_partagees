import 'package:flutter/material.dart';

class CreateGroupScreen extends StatelessWidget {
  const CreateGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un groupe'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const SizedBox(height: 25),

            const Icon(
              Icons.group_add,
              size: 85,
              color: Color(0xFF2563EB),
            ),

            const SizedBox(height: 30),

            const TextField(
              decoration: InputDecoration(
                labelText: 'Nom du groupe',
                prefixIcon: Icon(Icons.groups),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const TextField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description du groupe',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
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
                child: const Text('Créer le groupe'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
