import 'package:flutter/material.dart';
import 'package:pethome_app/src/features/appointments/data/appointments_service.dart';
import 'package:pethome_app/src/features/appointments/presentation/pages/citas_page.dart';
import 'package:pethome_app/src/features/auth/data/auth_service.dart';
import 'package:pethome_app/src/features/auth/domain/auth_user.dart';
import 'package:pethome_app/src/features/auth/presentation/pages/login_page.dart';
import 'package:pethome_app/src/features/chatbot/presentation/widgets/chat_fab.dart';
import 'package:pethome_app/src/core/features/compras/presentation/pages/carrito_temporal_page.dart';
import 'package:pethome_app/src/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:pethome_app/src/features/gestion_inventario_productos/catalogo/data/catalogo_service.dart';
import 'package:pethome_app/src/features/pets/data/adopciones_service.dart';
import 'package:pethome_app/src/features/pets/data/pets_service.dart';
import 'package:pethome_app/src/features/pets/presentation/pages/adopciones_page.dart';
import 'package:pethome_app/src/features/pets/presentation/pages/mascotas_page.dart';
import 'package:pethome_app/src/features/profile/data/profile_service.dart';
import 'package:pethome_app/src/features/profile/presentation/pages/perfil_page.dart';
import 'package:pethome_app/src/core/services/notification_service.dart';
import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/core/widgets/notification_bell.dart';

// Nuevos Imports
import 'package:pethome_app/src/features/admin_reports/presentation/pages/admin_dashboard_page.dart';
import 'package:pethome_app/src/features/admin_reports/presentation/pages/reports_page.dart';
import 'package:pethome_app/src/features/tracking/data/tracking_service.dart';
import 'package:pethome_app/src/features/tracking/presentation/pages/tracking_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.authService, this.initialUser});

  final AuthService authService;
  final AuthUser? initialUser;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<AuthSession> _sessionFuture = _loadSession();
  late final PetsService _petsService = PetsService(
    authService: widget.authService,
  );
  late final AdopcionesService _adopcionesService = AdopcionesService(
    authService: widget.authService,
  );
  late final AppointmentsService _appointmentsService = AppointmentsService(
    authService: widget.authService,
  );
  late final ProfileService _profileService = ProfileService(
    authService: widget.authService,
  );
  late final TrackingService _trackingService = TrackingService(
    authService: widget.authService,
  );
  late final CatalogoService _catalogoService = CatalogoService(
    authService: widget.authService,
  );
  int _currentIndex = 0;
  bool _isLoggingOut = false;
  late final NotificationService _notificationService;

  Future<AuthSession> _loadSession() async {
    final session = await widget.authService.getSession();

    _notificationService = NotificationService(
      apiClient: ApiClient(authService: widget.authService),
    );
    _notificationService.initialize();

    if (widget.initialUser == null) return session;

    return AuthSession(
      user: widget.initialUser!,
      context: session.context,
      componentesRaw: session.componentesRaw,
      permissions: session.permissions,
    );
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);

    try {
      await _notificationService.uninitialize();
    } catch (_) {}

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
    return FutureBuilder<AuthSession>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _logout,
                      child: const Text('Volver al login'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('No se pudo cargar la sesion.')),
          );
        }

        final session = snapshot.data!;
        final user = session.user;
        final permissions = session.permissions;
        final isSuperAdmin =
            user.roleNombre.trim().toUpperCase() == 'SUPERADMIN';

        // Detección del rol — separación total Admin vs Cliente
        final roleName = (user.roleNombre).toUpperCase();
        final isAdmin =
            roleName.contains('ADMIN') ||
            roleName.contains('VETERINARIO') ||
            roleName.contains('DUEÑO') ||
            roleName.contains('OWNER') ||
            permissions.canView('REPORTES');

        late final List<_NavEntry> visibleEntries;

        if (isAdmin) {
          // ────── VISTA ADMIN: solo módulos administrativos ──────
          visibleEntries = [
            _NavEntry(
              code: 'ADMIN_DASHBOARD',
              page: AdminDashboardPage(
                user: user,
                authService: widget.authService,
                onNavigateToReports: () {
                  final idx = visibleEntries.indexWhere(
                    (e) => e.code == 'REPORTES',
                  );
                  if (idx != -1) setState(() => _currentIndex = idx);
                },
              ),
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
            ),
            _NavEntry(
              code: 'REPORTES',
              page: ReportsPage(authService: widget.authService),
              icon: Icons.bar_chart_rounded,
              label: 'Reportes',
            ),
            _NavEntry(
              code: 'ADOPCIONES',
              page: AdopcionesPage(service: _adopcionesService),
              icon: Icons.volunteer_activism_outlined,
              label: 'Adopciones',
            ),
          ];
        } else {
          // ────── VISTA CLIENTE: solo módulos de cliente ──────
          visibleEntries = [
            _NavEntry(
              code: 'DASHBOARD',
              page: DashboardPage(
                user: user,
                petsService: _petsService,
                appointmentsService: _appointmentsService,
                catalogoService: _catalogoService,
              ),
              icon: Icons.home,
              label: 'Inicio',
            ),
            _NavEntry(
              code: 'MASCOTAS',
              page: MascotasPage(
                clientService: _petsService,
                appointmentsService: _appointmentsService,
                permissions: permissions,
              ),
              icon: Icons.pets,
              label: 'Mascotas',
            ),
            _NavEntry(
              code: 'ADOPCIONES',
              page: AdopcionesPage(service: _adopcionesService),
              icon: Icons.volunteer_activism_outlined,
              label: 'Adopciones',
            ),
            _NavEntry(
              code: 'CITAS',
              page: CitasPage(
                petsService: _petsService,
                appointmentsService: _appointmentsService,
                permissions: permissions,
              ),
              icon: Icons.calendar_today,
              label: 'Citas',
            ),
            // ── Seguimiento: visible para clientes, oculto para SuperAdmin ──
            if (!isSuperAdmin)
              _NavEntry(
                code: 'SEGUIMIENTO',
                page: TrackingPage(
                  authService: widget.authService,
                  roleNombre: user.roleNombre,
                  trackingService: _trackingService,
                ),
                icon: Icons.alt_route,
                label: 'Seguimiento',
              ),
            _NavEntry(
              code: 'PERFIL',
              page: PerfilPage(
                user: user,
                authService: widget.authService,
                clientService: _profileService,
                onLogout: _logout,
                isLoggingOut: _isLoggingOut,
                permissions: permissions,
              ),
              icon: Icons.person,
              label: 'Perfil',
            ),
          ];
        }

        if (visibleEntries.isEmpty) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tu cuenta no tiene modulos habilitados en movil.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _logout,
                      child: const Text('Volver al login'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (_currentIndex >= visibleEntries.length) {
          _currentIndex = 0;
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'PetHome',
              style: TextStyle(
                color: Color(0xFF6A11CB),
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Mi carrito',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CarritoTemporalPage()),
                  );
                },
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Color(0xFF6A11CB),
                ),
              ),
              const NotificationBell(),
              const SizedBox(width: 8),
            ],
          ),
          drawer: isAdmin
              ? Drawer(
                  child: Column(
                    children: [
                      UserAccountsDrawerHeader(
                        decoration: const BoxDecoration(
                          color: Color(0xFF6A11CB),
                        ),
                        accountName: Text(user.nombre ?? 'Administrador'),
                        accountEmail: Text(user.correo),
                        currentAccountPicture: const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.admin_panel_settings,
                            color: Color(0xFF6A11CB),
                            size: 40,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.dashboard_outlined),
                        title: const Text('Dashboard Principal'),
                        onTap: () {
                          Navigator.pop(context);
                          final idx = visibleEntries.indexWhere(
                            (e) => e.code == 'ADMIN_DASHBOARD',
                          );
                          if (idx != -1) setState(() => _currentIndex = idx);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.bar_chart_rounded),
                        title: const Text('Reportes IA'),
                        onTap: () {
                          Navigator.pop(context);
                          final idx = visibleEntries.indexWhere(
                            (e) => e.code == 'REPORTES',
                          );
                          if (idx != -1) setState(() => _currentIndex = idx);
                        },
                      ),
                      const Spacer(),
                      const Divider(),
                      ListTile(
                        leading: const Icon(
                          Icons.logout,
                          color: Colors.redAccent,
                        ),
                        title: const Text('Cerrar Sesión'),
                        onTap: _logout,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                )
              : null,
          body: visibleEntries[_currentIndex].page,
          floatingActionButton: const ChatFab(),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
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
                  items: List.generate(
                    visibleEntries.length,
                    (index) => _navItem(
                      visibleEntries[index].icon,
                      visibleEntries[index].label,
                      index,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  BottomNavigationBarItem _navItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;

    return BottomNavigationBarItem(
      label: label,
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6A11CB).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFF6A11CB) : Colors.grey,
        ),
      ),
    );
  }
}

class _NavEntry {
  const _NavEntry({
    required this.code,
    required this.page,
    required this.icon,
    required this.label,
  });

  final String code;
  final Widget page;
  final IconData icon;
  final String label;
}
