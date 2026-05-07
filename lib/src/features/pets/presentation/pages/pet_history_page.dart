import 'package:flutter/material.dart';
import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/features/pets/data/pets_service.dart';

class PetHistoryPage extends StatefulWidget {
  const PetHistoryPage({
    super.key,
    required this.petId,
    required this.petName,
    required this.petsService,
  });

  final int petId;
  final String petName;
  final PetsService petsService;

  @override
  State<PetHistoryPage> createState() => _PetHistoryPageState();
}

class _PetHistoryPageState extends State<PetHistoryPage> {
  String _filter = 'TODOS';
  late Future<PetHistoryData> _future = _load();

  Future<PetHistoryData> _load() async {
    if (_filter == 'FINALIZADO') {
      return widget.petsService.getPetHistory(widget.petId, estado: 'COMPLETADA');
    }
    final data = await widget.petsService.getPetHistory(widget.petId);
    if (_filter == 'SEGUIMIENTO') {
      final filtered = data.items
          .where((item) => item.estado.toUpperCase() != 'COMPLETADA')
          .toList(growable: false);
      return PetHistoryData(items: filtered, total: filtered.length);
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<PetHistoryData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ClientException
                ? snapshot.error.toString()
                : 'No se pudo cargar el historial.';
            return _ErrorState(
              message: message,
              onRetry: () => setState(() => _future = _load()),
            );
          }

          final data = snapshot.data!;
          final items = List<PetHistoryItem>.from(data.items);
          items.sort((a, b) => b.fecha.compareTo(a.fecha));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Historial de ${widget.petName}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Servicios y atenciones recibidas',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              _FilterBar(
                current: _filter,
                onChanged: (next) {
                  setState(() {
                    _filter = next;
                    _future = _load();
                  });
                },
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const _EmptyState(text: 'Sin atenciones registradas')
              else
                ...items.map((item) => _HistoryCard(item: item)),
            ],
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.current,
    required this.onChanged,
  });

  final String current;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String code, String text) {
      final selected = current == code;
      return ChoiceChip(
        label: Text(text),
        selected: selected,
        onSelected: (_) => onChanged(code),
      );
    }

    return Wrap(
      spacing: 8,
      children: [
        chip('TODOS', 'Todos'),
        chip('FINALIZADO', 'Finalizado'),
        chip('SEGUIMIENTO', 'Seguimiento'),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});

  final PetHistoryItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.fecha,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A11CB),
              ),
            ),
            const SizedBox(height: 4),
            Text(item.tipoServicio, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (item.observaciones.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(item.observaciones),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _StatusBadge(status: item.estado),
                const SizedBox(width: 8),
                Text(item.modalidad),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isDone = status.toUpperCase() == 'COMPLETADA';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isDone ? 'Finalizado' : 'Seguimiento',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDone ? Colors.green.shade800 : Colors.orange.shade900,
          fontSize: 12,
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

