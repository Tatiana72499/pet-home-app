import 'package:flutter/material.dart';
import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/features/pets/data/pets_service.dart';
import 'package:pethome_app/src/features/pets/presentation/pages/clinical_history_page.dart';
import 'package:pethome_app/src/features/pets/presentation/pages/pet_addresses_page.dart';
import 'package:pethome_app/src/features/pets/presentation/pages/pet_history_page.dart';

class PetProfilePage extends StatefulWidget {
  const PetProfilePage({
    super.key,
    required this.pet,
    required this.petsService,
    required this.onUseAddressInAppointment,
  });

  final Pet pet;
  final PetsService petsService;
  final ValueChanged<String> onUseAddressInAppointment;

  @override
  State<PetProfilePage> createState() => _PetProfilePageState();
}

class _PetProfilePageState extends State<PetProfilePage> {
  late Future<PetProfileData> _future = widget.petsService.getPetProfile(widget.pet.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil mascota'),
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<PetProfileData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ClientException
                ? snapshot.error.toString()
                : 'No se pudo cargar el perfil de la mascota.';
            return _ErrorState(
              message: message,
              onRetry: () {
                setState(() {
                  _future = widget.petsService.getPetProfile(widget.pet.id);
                });
              },
            );
          }

          final profile = snapshot.data!;
          final pet = profile.pet;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                pet.name,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${pet.speciesName} - ${pet.breedName ?? 'No registrada'}',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informacion general',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Sexo: ${pet.sex ?? 'No registrado'}'),
                      Text('Color: ${pet.color ?? 'No registrado'}'),
                      Text('Fecha nac.: ${pet.birthDate ?? 'No registrada'}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _AccessCard(
                      title: 'Ver direcciones',
                      countLabel: '${profile.addresses.total} registradas',
                      color: const Color(0xFF6A11CB),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PetAddressesPage(
                              petName: pet.name,
                              addresses: profile.addresses,
                              onUseAddressInAppointment: widget.onUseAddressInAppointment,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AccessCard(
                      title: 'Ver historial',
                      countLabel: '${profile.historySummary.total} servicios',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PetHistoryPage(
                              petId: pet.id,
                              petName: pet.name,
                              petsService: widget.petsService,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _AccessCard(
                title: 'Ver historial clínico',
                countLabel: '${pet.name} en clínica',
                color: Colors.green,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ClinicalHistoryPage(
                        petId: pet.id,
                        petName: pet.name,
                        petsService: widget.petsService,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({
    required this.title,
    required this.countLabel,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String countLabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              countLabel,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

