import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Mon profil'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 25),

            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFFDBEAFE),
              child: Icon(
                Icons.person,
                size: 60,
                color: Color(0xFF2563EB),
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'Nom de l’utilisateur',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Text(
              'utilisateur@email.com',
              style: TextStyle(
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 30),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF2563EB),
                ),
                title: const Text('Informations personnelles'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.settings,
                  color: Color(0xFF2563EB),
                ),
                title: const Text('Paramètres'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
                title: const Text('Déconnexion'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
