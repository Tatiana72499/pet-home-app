import 'package:flutter/material.dart';
import '../models/clinical_history.dart';
import '../services/client_service.dart';
import '../utils/open_external_link.dart';

class HistorialClinicoPage extends StatefulWidget {
  const HistorialClinicoPage({
    super.key,
    required this.petId,
    required this.petName,
    required this.clientService,
  });

  final int petId;
  final String petName;
  final ClientService clientService;

  @override
  State<HistorialClinicoPage> createState() => _HistorialClinicoPageState();
}

class _HistorialClinicoPageState extends State<HistorialClinicoPage> {
  late Future<ClinicalHistory> _historialFuture;

  String _resolveMediaUrl(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    final path = value.startsWith('/') ? value : '/$value';
    return '${widget.clientService.baseUrl}$path';
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
  void initState() {
    super.initState();
    _historialFuture = widget.clientService.getClinicalHistory(widget.petId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial Clínico - ${widget.petName}'),
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<ClinicalHistory>(
        future: _historialFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar historial: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('Sin datos disponibles'),
            );
          }

          final historial = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card de información general
                _buildGeneralInfoCard(historial),
                const SizedBox(height: 20),
                // Observaciones generales
                if (historial.observacionesGenerales != null)
                  _buildObservacionesCard(historial.observacionesGenerales!),
                const SizedBox(height: 20),
                // Consultas clínicas
                Text(
                  'Consultas Clínicas (${historial.consultasClinicas.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A11CB),
                  ),
                ),
                const SizedBox(height: 12),
                if (historial.consultasClinicas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'No hay consultas registradas',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: historial.consultasClinicas.length,
                    itemBuilder: (context, index) {
                      final consulta = historial.consultasClinicas[index];
                      return _buildConsultationCard(consulta);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGeneralInfoCard(ClinicalHistory historial) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información General',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A11CB),
              ),
            ),
            const SizedBox(height: 12),
            _infoRow('Especie:', historial.mascotaEspecie),
            _infoRow('Raza:', historial.mascotaRaza ?? 'No especificada'),
            _infoRow('Propietario:', historial.propietarioNombre),
            _infoRow('Fecha de Creación:', _formatDate(historial.fechaCreacion)),
            _infoRow(
              'Última Actualización:',
              _formatDate(historial.fechaActualizacion),
            ),
            _infoRow(
              'Estado:',
              historial.estado ? 'Activo' : 'Inactivo',
              valueColor: historial.estado ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservacionesCard(String observaciones) {
    return Card(
      elevation: 2,
      color: const Color(0xFF6A11CB).withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Observaciones Generales',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A11CB),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              observaciones,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationCard(ClinicalConsultation consulta) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: ExpansionTile(
        title: Text(
          'Consulta del ${_formatDate(consulta.fechaCreacion)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(consulta.veterinarioNombre ?? 'Veterinario no especificado'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (consulta.motivo != null) ...[
                  _buildSectionTitle('Motivo de Consulta'),
                  Text(consulta.motivo!),
                  const SizedBox(height: 12),
                ],
                if (consulta.diagnostico != null) ...[
                  _buildSectionTitle('Diagnóstico'),
                  Text(consulta.diagnostico!),
                  const SizedBox(height: 12),
                ],
                if (consulta.observaciones != null) ...[
                  _buildSectionTitle('Observaciones'),
                  Text(consulta.observaciones!),
                  const SizedBox(height: 12),
                ],
                // Signos vitales
                if (consulta.peso != null ||
                    consulta.temperatura != null ||
                    consulta.frecuenciaCardiaca != null ||
                    consulta.frecuenciaRespiratoria != null) ...[
                  _buildSectionTitle('Signos Vitales'),
                  if (consulta.peso != null) _infoRow('Peso:', '${consulta.peso} kg'),
                  if (consulta.temperatura != null)
                    _infoRow('Temperatura:', '${consulta.temperatura}°C'),
                  if (consulta.frecuenciaCardiaca != null)
                    _infoRow('Frecuencia Cardíaca:', '${consulta.frecuenciaCardiaca} bpm'),
                  if (consulta.frecuenciaRespiratoria != null)
                    _infoRow('Frecuencia Respiratoria:', '${consulta.frecuenciaRespiratoria}'),
                  const SizedBox(height: 12),
                ],
                if (consulta.proximaRevision != null) ...[
                  _buildSectionTitle('Próxima Revisión'),
                  Text(_formatDate(consulta.proximaRevision!)),
                  const SizedBox(height: 12),
                ],
                // Tratamientos
                if (consulta.tratamientos.isNotEmpty) ...[
                  _buildSectionTitle(
                    'Tratamientos (${consulta.tratamientos.length})',
                  ),
                  ...consulta.tratamientos.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildTreatmentTile(t),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Receta
                if (consulta.receta != null) ...[
                  _buildSectionTitle('Receta'),
                  _buildRecipeTile(consulta.receta!),
                  const SizedBox(height: 12),
                ],
                // Vacunas
                if (consulta.vacunasAplicadas.isNotEmpty) ...[
                  _buildSectionTitle(
                    'Vacunas Aplicadas (${consulta.vacunasAplicadas.length})',
                  ),
                  ...consulta.vacunasAplicadas.map(
                    (v) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildVaccineTile(v),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Archivos clínicos
                if (consulta.archivosClinico.isNotEmpty) ...[
                  _buildSectionTitle(
                    'Archivos Clínicos (${consulta.archivosClinico.length})',
                  ),
                  ...consulta.archivosClinico.map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildFileTile(a),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6A11CB),
        ),
      ),
    );
  }

  Widget _buildTreatmentTile(Treatment treatment) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            treatment.nombre,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          if (treatment.descripcion != null) ...[
            const SizedBox(height: 4),
            Text(
              treatment.descripcion!,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
          if (treatment.fechaInicio != null) ...[
            const SizedBox(height: 4),
            Text(
              'Desde: ${_formatDate(treatment.fechaInicio!)}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
          if (treatment.fechaFin != null) ...[
            Text(
              'Hasta: ${_formatDate(treatment.fechaFin!)}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecipeTile(Recipe recipe) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medicamentos: ${recipe.detalles.length}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          ...recipe.detalles.map(
            (d) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '• ${d.medicamento}${d.dosis != null ? ' - ${d.dosis}' : ''}${d.frecuencia != null ? ' (${d.frecuencia})' : ''}',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
          if (recipe.observaciones != null) ...[
            const SizedBox(height: 4),
            Text(
              recipe.observaciones!,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVaccineTile(AppliedVaccine vaccine) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vaccine.nombreVacuna,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          if (vaccine.fechaAplicacion != null) ...[
            const SizedBox(height: 4),
            Text(
              'Aplicada: ${_formatDate(vaccine.fechaAplicacion!)}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
          if (vaccine.proximaDosis != null) ...[
            Text(
              'Próxima: ${vaccine.proximaDosis}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileTile(ClinicalFile file) {
    final fileUrl = _resolveMediaUrl(file.urlArchivo);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.file_present, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.nombre,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (file.fechaCreacion != null)
                  Text(
                    _formatDate(file.fechaCreacion!),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                if (fileUrl.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () => _openFile(file.urlArchivo),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Ver/Descargar'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: Colors.deepOrange,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
