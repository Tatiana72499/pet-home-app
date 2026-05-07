import 'package:flutter/material.dart';
import 'package:pethome_app/src/features/appointments/data/appointments_service.dart';
import 'package:pethome_app/src/features/auth/domain/auth_user.dart';
import 'package:pethome_app/src/features/pets/data/pets_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.user,
    required this.petsService,
    required this.appointmentsService,
  });

  final AuthUser user;
  final PetsService petsService;
  final AppointmentsService appointmentsService;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<_DashboardSummary> _summaryFuture = _loadSummary();
  bool _autoRetriedAfterError = false;

  Future<_DashboardSummary> _loadSummary() async {
    List<Pet> pets = <Pet>[];
    List<Appointment> appointments = <Appointment>[];

    try {
      pets = await widget.petsService.getPets();
    } catch (_) {
      // No tumbar resumen completo por una sola fuente.
    }

    try {
      appointments = await widget.appointmentsService.getAppointments();
    } catch (_) {
      // No tumbar resumen completo por una sola fuente.
    }

    final upcoming = appointments
        .where((appointment) =>
            appointment.status == 'PENDIENTE' ||
            appointment.status == 'CONFIRMADA')
        .length;

    return _DashboardSummary(
      pets: pets.length,
      appointments: appointments.length,
      upcoming: upcoming,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF8E2DE2)],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() => _summaryFuture = _loadSummary());
            try {
              await _summaryFuture;
            } catch (_) {
              // El error se representa en la UI del FutureBuilder.
            }
          },
          child: FutureBuilder<_DashboardSummary>(
            future: _summaryFuture,
            builder: (context, snapshot) {
              final summary = snapshot.data;

              if (snapshot.hasError && !_autoRetriedAfterError) {
                _autoRetriedAfterError = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  setState(() => _summaryFuture = _loadSummary());
                });
              }

              if (snapshot.hasData) {
                _autoRetriedAfterError = false;
              }

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Hola, ${widget.user.correo}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Este es el resumen de tus mascotas y reservas.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
                  else if (snapshot.hasError)
                    _card(
                      'No se pudo cargar',
                      '${snapshot.error}\nDesliza hacia abajo para intentar de nuevo',
                      Icons.error_outline,
                    )
                  else ...[
                    _card(
                      'Mascotas',
                      '${summary?.pets ?? 0} registradas',
                      Icons.pets,
                    ),
                    _card(
                      'Citas proximas',
                      '${summary?.upcoming ?? 0} pendientes o confirmadas',
                      Icons.calendar_today,
                    ),
                    _card(
                      'Historial de reservas',
                      '${summary?.appointments ?? 0} reservas en total',
                      Icons.check_circle,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _card(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6A11CB)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSummary {
  const _DashboardSummary({
    required this.pets,
    required this.appointments,
    required this.upcoming,
  });

  final int pets;
  final int appointments;
  final int upcoming;
}
