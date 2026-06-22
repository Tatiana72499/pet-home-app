import 'package:flutter/material.dart';
import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/features/pets/data/pets_service.dart';

class PetPreventivePlanPage extends StatefulWidget {
  const PetPreventivePlanPage({
    super.key,
    required this.petId,
    required this.petName,
    required this.petsService,
  });

  final int petId;
  final String petName;
  final PetsService petsService;

  @override
  State<PetPreventivePlanPage> createState() => _PetPreventivePlanPageState();
}

class _PetPreventivePlanPageState extends State<PetPreventivePlanPage> {
  late Future<List<PreventivePlanItem>> _future =
      widget.petsService.getPreventivePlan(widget.petId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan sanitario'),
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<PreventivePlanItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ClientException
                ? snapshot.error.toString()
                : 'No se pudo cargar el plan sanitario.';
            return _ErrorState(
              message: message,
              onRetry: () {
                setState(() {
                  _future = widget.petsService.getPreventivePlan(widget.petId);
                });
              },
            );
          }

          final items = snapshot.data ?? const <PreventivePlanItem>[];
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No hay eventos preventivos programados para ${widget.petName}.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.orange.shade100),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            item.description,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _StatusChip(text: item.statusDisplay, status: item.status),
                          _OutlineChip(text: item.typeDisplay),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Fecha programada: ${_formatDate(item.scheduledDate)}',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      if ((item.observations ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.observations!,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, required this.status});

  final String text;
  final String status;

  @override
  Widget build(BuildContext context) {
    Color background;
    Color foreground;

    switch (status) {
      case 'REALIZADO':
        background = const Color(0xFFDCFCE7);
        foreground = const Color(0xFF166534);
        break;
      case 'VENCIDO':
        background = const Color(0xFFFEE2E2);
        foreground = const Color(0xFFB91C1C);
        break;
      case 'CANCELADO':
        background = const Color(0xFFE5E7EB);
        foreground = const Color(0xFF374151);
        break;
      default:
        background = const Color(0xFFFEF3C7);
        foreground = const Color(0xFF92400E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OutlineChip extends StatelessWidget {
  const _OutlineChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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

String _formatDate(DateTime? date) {
  if (date == null) return 'No registrada';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
