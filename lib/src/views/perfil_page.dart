import 'package:flutter/material.dart';
import '../models/auth_user.dart';

class PerfilPage extends StatelessWidget {
  const PerfilPage({
    super.key,
    required this.user,
    required this.onLogout,
    required this.isLoggingOut,
  });

  final AuthUser user;
  final VoidCallback onLogout;
  final bool isLoggingOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil"),
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            const CircleAvatar(
              radius: 45,
              backgroundColor: Colors.orange,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),

            const SizedBox(height: 20),

            Text(
              user.correo,
              style: const TextStyle(fontSize: 18),
            ),

            Text(
              user.roleNombre,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: isLoggingOut ? null : onLogout,
              child: isLoggingOut
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Cerrar sesión"),
            ),
          ],
        ),
      ),
    );
  }
}

