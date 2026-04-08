import 'package:flutter/material.dart';

import '../models/auth_user.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'mascotas_page.dart';
import 'citas_page.dart';
import 'perfil_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.authService,
    this.initialUser,
  });

  final AuthService authService;
  final AuthUser? initialUser;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<AuthUser> _profileFuture = _loadProfile();
  int _currentIndex = 0;
  bool _isLoggingOut = false;

  Future<AuthUser> _loadProfile() async {
    return widget.initialUser ?? widget.authService.getProfile();
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);

    await widget.authService.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginPage(authService: widget.authService),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthUser>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data!;

        final pages = [
          DashboardPage(user: user),
          const MascotasPage(),
          const CitasPage(),
          PerfilPage(
            user: user,
            onLogout: _logout,
            isLoggingOut: _isLoggingOut,
          ),
        ];

        return Scaffold(
          body: pages[_currentIndex],

          // 🔥 NAV PREMIUM
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i),
                  backgroundColor: Colors.white,
                  elevation: 0,
                  type: BottomNavigationBarType.fixed,

                  selectedItemColor: const Color(0xFF6A11CB),
                  unselectedItemColor: Colors.grey,

                  showUnselectedLabels: false,

                  items: [
                    _navItem(Icons.home, "Inicio", 0),
                    _navItem(Icons.pets, "Mascotas", 1),
                    _navItem(Icons.calendar_today, "Citas", 2),
                    _navItem(Icons.person, "Perfil", 3),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  BottomNavigationBarItem _navItem(
      IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;

    return BottomNavigationBarItem(
      label: label,
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6A11CB).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? const Color(0xFF6A11CB)
              : Colors.grey,
        ),
      ),
    );
  }
}
