import 'package:flutter/material.dart';
import 'package:pethome_app/src/features/pets/data/pets_service.dart';

class PetAddressesPage extends StatelessWidget {
  const PetAddressesPage({
    super.key,
    required this.petName,
    required this.addresses,
    required this.onUseAddressInAppointment,
  });

  final String petName;
  final PetAddressesData addresses;
  final ValueChanged<String> onUseAddressInAppointment;

  @override
  Widget build(BuildContext context) {
    final rows = {
      if (addresses.mainAddress != null) addresses.mainAddress!,
      ...addresses.history,
    }.toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Direcciones'),
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Direcciones de $petName',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const _EmptyState(text: 'Sin direcciones registradas')
          else ...[
            if (addresses.mainAddress != null)
              _AddressCard(
                title: 'Direccion principal',
                text: addresses.mainAddress!,
              ),
            const SizedBox(height: 12),
            const Text(
              'Historial de direcciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...addresses.history.map(
              (entry) => _AddressCard(title: 'Direccion', text: entry),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              final selected = addresses.mainAddress ??
                  (addresses.history.isNotEmpty ? addresses.history.first : '');
              onUseAddressInAppointment(selected);
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.calendar_today_outlined),
            label: const Text('Usar en proxima cita'),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(text),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(child: Text(text)),
    );
  }
}
