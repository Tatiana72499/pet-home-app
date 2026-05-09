import 'package:flutter/material.dart';
import 'package:pethome_app/src/features/pets/data/pets_service.dart';
import 'package:pethome_app/src/features/pets/models/clinical_history.dart';
import 'package:pethome_app/src/utils/open_external_link.dart';

class ClinicalHistoryPage extends StatefulWidget {
  const ClinicalHistoryPage({
    super.key,
    required this.petId,
    required this.petName,
    required this.petsService,
  });

  final int petId;
  final String petName;
  final PetsService petsService;

  @override
  State<ClinicalHistoryPage> createState() => _ClinicalHistoryPageState();
}

class _ClinicalHistoryPageState extends State<ClinicalHistoryPage> {
  late Future<ClinicalHistory> _future = widget.petsService.getClinicalHistory(widget.petId);

  String _resolveMediaUrl(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    final path = value.startsWith('/') ? value : '/$value';
    return '${widget.petsService.baseUrl}$path';
  }

  Future<void> _openFile(String? value) async {
    final resolvedUrl = _resolveMediaUrl(value);
    if (resolvedUrl.isEmpty) return;

    final launched = await openExternalLink(resolvedUrl);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el archivo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial clínico - ${widget.petName}'),
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<ClinicalHistory>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: () => setState(() {
                _future = widget.petsService.getClinicalHistory(widget.petId);
              }),
            );
          }

          final history = snapshot.data!;
          final consultations = List<ClinicalConsultation>.from(history.consultasClinicas)
            ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Historial clínico de ${history.mascotaNombre}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${history.mascotaEspecie}${history.mascotaRaza == null ? '' : ' - ${history.mascotaRaza}'}',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Información general',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Propietario', history.propietarioNombre),
                    _infoRow('Estado', history.estado ? 'Activo' : 'Inactivo'),
                    _infoRow('Creación', history.fechaCreacion.toIso8601String().split('T').first),
                    _infoRow('Actualización', history.fechaActualizacion.toIso8601String().split('T').first),
                  ],
                ),
              ),
              if ((history.observacionesGenerales ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Observaciones generales',
                  child: Text(history.observacionesGenerales!),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Consultas clínicas (${consultations.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (consultations.isEmpty)
                const _EmptyState(text: 'No hay consultas registradas')
              else
                ...consultations.map(_buildConsultationCard),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConsultationCard(ClinicalConsultation consultation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.grey.shade50,
      child: ExpansionTile(
        title: Text(
          consultation.fechaCreacion.toIso8601String().split('T').first,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          [
            consultation.veterinarioNombre ?? 'Veterinario no especificado',
            consultation.estado ? 'Activa' : 'Inactiva',
          ].join(' · '),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _SectionLabel('Resumen'),
          _MetaGrid(
            items: [
              _MetaItem(label: 'Consulta', value: _formatDateTime(consultation.fechaConsulta)),
              _MetaItem(label: 'Cita', value: consultation.citaId?.toString()),
              _MetaItem(label: 'Estado', value: consultation.estado ? 'Activa' : 'Inactiva'),
              _MetaItem(label: 'Creada', value: _formatDateTime(consultation.fechaCreacion)),
              _MetaItem(label: 'Actualizada', value: _formatDateTime(consultation.fechaActualizacion)),
            ],
          ),
          const SizedBox(height: 12),
          if ((consultation.motivo ?? '').trim().isNotEmpty) ...[
            _SectionLabel('Motivo'),
            Text(consultation.motivo!),
            const SizedBox(height: 10),
          ],
          if ((consultation.diagnostico ?? '').trim().isNotEmpty) ...[
            _SectionLabel('Diagnóstico'),
            Text(consultation.diagnostico!),
            const SizedBox(height: 10),
          ],
          if ((consultation.observaciones ?? '').trim().isNotEmpty) ...[
            _SectionLabel('Observaciones'),
            Text(consultation.observaciones!),
            const SizedBox(height: 10),
          ],
          if (consultation.peso != null ||
              consultation.temperatura != null ||
              consultation.frecuenciaCardiaca != null ||
              consultation.frecuenciaRespiratoria != null) ...[
            const Divider(),
            const SizedBox(height: 8),
            const Text('Signos vitales', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (consultation.peso != null) _infoRow('Peso', '${consultation.peso} kg'),
            if (consultation.temperatura != null) _infoRow('Temperatura', '${consultation.temperatura} °C'),
            if (consultation.frecuenciaCardiaca != null) _infoRow('Frecuencia cardiaca', '${consultation.frecuenciaCardiaca}'),
            if (consultation.frecuenciaRespiratoria != null) _infoRow('Frecuencia respiratoria', '${consultation.frecuenciaRespiratoria}'),
          ],
          if (consultation.proximaRevision != null) ...[
            const SizedBox(height: 8),
            _infoRow('Próxima revisión', consultation.proximaRevision!.toIso8601String().split('T').first),
          ],
          if (consultation.tratamientos.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),
            const Text('Tratamientos', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...consultation.tratamientos.map(
              (treatment) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _NestedItem(
                  title: treatment.nombre,
                  subtitle: [
                    treatment.descripcion,
                    treatment.fechaInicio == null ? null : 'Inicio: ${_formatDateTime(treatment.fechaInicio)}',
                    treatment.fechaFin == null ? null : 'Fin: ${_formatDateTime(treatment.fechaFin)}',
                    treatment.estado ? 'Activo' : 'Inactivo',
                  ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' · '),
                ),
              ),
            ),
          ],
          if (consultation.receta != null && consultation.receta!.detalles.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),
            const Text('Receta', style: TextStyle(fontWeight: FontWeight.bold)),
            if ((consultation.receta!.observaciones ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Observaciones: ${consultation.receta!.observaciones}'),
            ],
            if (consultation.receta!.fechaExpiracion != null) ...[
              const SizedBox(height: 4),
              Text('Vence: ${_formatDateTime(consultation.receta!.fechaExpiracion)}'),
            ],
            const SizedBox(height: 8),
            ...consultation.receta!.detalles.map(
              (detail) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _NestedItem(
                  title: detail.medicamento,
                  subtitle: [
                    detail.dosis,
                    detail.frecuencia,
                    detail.diasDuracion == null ? null : '${detail.diasDuracion} días',
                  ]
                      .whereType<String>()
                      .where((value) => value.trim().isNotEmpty)
                      .join(' · '),
                ),
              ),
            ),
          ],
          if (consultation.vacunasAplicadas.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),
            const Text('Vacunas aplicadas', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...consultation.vacunasAplicadas.map(
              (vaccine) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _NestedItem(
                  title: vaccine.nombreVacuna,
                  subtitle: [
                    vaccine.fechaAplicacion == null ? null : 'Aplicada: ${_formatDateTime(vaccine.fechaAplicacion)}',
                    vaccine.proximaDosis,
                  ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' · '),
                ),
              ),
            ),
          ],
          if (consultation.archivosClinico.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),
            const Text('Archivos clínicos', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...consultation.archivosClinico.map(
              (file) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(file.nombre),
                  subtitle: Text([
                    file.tipo ?? 'Archivo adjunto',
                    file.fechaCreacion == null ? null : _formatDateTime(file.fechaCreacion),
                  ].whereType<String>().join(' · ')),
                  trailing: TextButton.icon(
                    onPressed: () => _openFile(file.urlArchivo),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Ver/Descargar'),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'No registrada';
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _MetaGrid extends StatelessWidget {
  const _MetaGrid({required this.items});

  final List<_MetaItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .where((item) => item.value != null && item.value!.trim().isNotEmpty)
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.value!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MetaItem {
  const _MetaItem({required this.label, required this.value});

  final String label;
  final String? value;
}

class _NestedItem extends StatelessWidget {
  const _NestedItem({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
          ],
        ],
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
