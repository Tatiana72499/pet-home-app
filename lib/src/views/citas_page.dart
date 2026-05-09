import 'package:flutter/material.dart';

import '../services/client_service.dart';

class CitasPage extends StatefulWidget {
  const CitasPage({super.key, required this.clientService});

  final ClientService clientService;

  @override
  State<CitasPage> createState() => _CitasPageState();
}

class _CitasPageState extends State<CitasPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  late Future<void> _loadFuture = _loadData();
  List<Pet> _pets = [];
  List<ServiceItem> _services = [];
  List<ServicePrice> _prices = [];
  List<Appointment> _appointments = [];

  int? _selectedPetId;
  int? _selectedServiceId;
  int? _selectedPriceId;
  String _selectedModality = 'CLINICA';
  int? _editingAppointmentId;
  bool _isSaving = false;
  String? _message;

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      widget.clientService.getPets(),
      widget.clientService.getServices(),
      widget.clientService.getPrices(),
      widget.clientService.getAppointments(),
    ]);

    _pets = results[0] as List<Pet>;
    _services = (results[1] as List<ServiceItem>)
        .where((service) => service.active)
        .toList();
    _prices =
        (results[2] as List<ServicePrice>).where((price) => price.active).toList();
    _appointments = results[3] as List<Appointment>;
  }

  List<ServicePrice> get _availablePrices {
    return _prices
        .where(
          (price) =>
              (_selectedServiceId == null ||
                  price.serviceId == _selectedServiceId) &&
              _normalizeText(price.modality) == _normalizeText(_selectedModality),
        )
        .toList();
  }

  String _normalizeText(String value) {
    final normalized = value
        .trim()
        .toUpperCase()
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ü', 'U');

    if (normalized.contains('DOMICILIO')) return 'DOMICILIO';
    if (normalized.contains('CONSULTA') || normalized.contains('CLINICA')) {
      return 'CLINICA';
    }

    return normalized;
  }

  Future<void> _saveAppointment() async {
    if (!(_formKey.currentState?.validate() ?? false) ||
        _selectedPetId == null ||
        _selectedServiceId == null ||
        _selectedPriceId == null) {
      setState(() => _message = 'Completa los datos de la reserva.');
      return;
    }

    setState(() {
      _isSaving = true;
      _message = null;
    });

    final request = AppointmentRequest(
      petId: _selectedPetId!,
      serviceId: _selectedServiceId!,
      priceId: _selectedPriceId!,
      date: _dateController.text.trim(),
      time: _timeController.text.trim(),
      modality: _selectedModality,
      address: _addressController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    try {
      if (_editingAppointmentId == null) {
        await widget.clientService.createAppointment(request);
      } else {
        await widget.clientService.updateAppointment(_editingAppointmentId!, request);
      }

      _clearForm();
      await _loadData();
      if (!mounted) return;
      setState(() => _message = 'Reserva guardada correctamente.');
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _startEdit(Appointment appointment) {
    setState(() {
      _editingAppointmentId = appointment.id;
      _selectedPetId = appointment.petId;
      _selectedServiceId = appointment.serviceId;
      _selectedPriceId = appointment.priceId;
      _selectedModality = appointment.modality;
      _dateController.text = appointment.date;
      _timeController.text = appointment.time;
      _addressController.text = appointment.address ?? '';
      _descriptionController.text = appointment.description ?? '';
      _message = null;
    });
  }

  void _clearForm() {
    _editingAppointmentId = null;
    _selectedPetId = null;
    _selectedServiceId = null;
    _selectedPriceId = null;
    _selectedModality = 'CLINICA';
    _dateController.clear();
    _timeController.clear();
    _addressController.clear();
    _descriptionController.clear();
  }

  Future<void> _cancelAppointment(int appointmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Cita'),
        content: const Text('¿Estás seguro de que deseas cancelar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    setState(() => _isSaving = true);

    try {
      await widget.clientService.cancelAppointment(appointmentId);
      await _loadData();
      if (!mounted) return;
      setState(() => _message = 'Cita cancelada correctamente.');
    } catch (error) {
      setState(() => _message = 'Error al cancelar: ${error.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis reservas'),
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: () => setState(() => _loadFuture = _loadData()),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _loadData();
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildForm(),
                const SizedBox(height: 24),
                // Resumen de citas
                _buildSummary(),
                const SizedBox(height: 20),
                // Citas pendientes
                _buildCitasByStatus('PENDIENTE', 'En Espera de Confirmación'),
                _buildCitasByStatus('CONFIRMADA', 'Confirmadas'),
                _buildCitasByStatus('COMPLETADA', 'Completadas'),
                _buildCitasByStatus('CANCELADA', 'Canceladas'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummary() {
    final pendientes = _appointments.where((c) => c.status == 'PENDIENTE').length;
    final confirmadas = _appointments.where((c) => c.status == 'CONFIRMADA').length;

    return Card(
      color: const Color(0xFF6A11CB).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total', _appointments.length.toString(), Colors.grey),
            _buildStatItem('Pendientes', pendientes.toString(), Colors.orange),
            _buildStatItem('Confirmadas', confirmadas.toString(), Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCitasByStatus(String status, String title) {
    final citasDelEstado = _appointments.where((c) => c.status == status).toList();

    if (citasDelEstado.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${citasDelEstado.length})',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6A11CB),
          ),
        ),
        const SizedBox(height: 12),
        ...citasDelEstado.map(
          (appointment) => _AppointmentCard(
            appointment: appointment,
            onEdit: appointment.status == 'PENDIENTE'
                ? () => _startEdit(appointment)
                : null,
            onCancel: appointment.status == 'PENDIENTE'
                ? () => _cancelAppointment(appointment.id)
                : null,
          ),
        ).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildForm() {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _editingAppointmentId == null
                    ? 'Agregar cita o reserva'
                    : 'Modificar reserva',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedPetId,
                decoration: const InputDecoration(labelText: 'Mascota'),
                items: _pets
                    .map(
                      (pet) => DropdownMenuItem(
                        value: pet.id,
                        child: Text(pet.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedPetId = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedServiceId,
                decoration: const InputDecoration(labelText: 'Servicio'),
                items: _services
                    .map(
                      (service) => DropdownMenuItem(
                        value: service.id,
                        child: Text(service.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedServiceId = value;
                    _selectedPriceId = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedModality,
                decoration: const InputDecoration(labelText: 'Modalidad'),
                items: const [
                  DropdownMenuItem(value: 'CLINICA', child: Text('Clinica')),
                  DropdownMenuItem(value: 'DOMICILIO', child: Text('Domicilio')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedModality = value;
                    _selectedPriceId = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedPriceId,
                decoration: const InputDecoration(labelText: 'Precio'),
                items: _availablePrices
                    .map(
                      (price) => DropdownMenuItem(
                        value: price.id,
                        child: Text('${price.variation} - Bs. ${price.price}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedPriceId = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Fecha programada',
                  hintText: 'YYYY-MM-DD',
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Hora de inicio',
                  hintText: 'HH:MM',
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Requerido' : null,
              ),
              if (_selectedModality == 'DOMICILIO') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Direccion'),
                  validator: (value) {
                    if (_selectedModality != 'DOMICILIO') return null;
                    return (value == null || value.trim().isEmpty)
                        ? 'Requerido para domicilio'
                        : null;
                  },
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Descripcion'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveAppointment,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_editingAppointmentId == null
                        ? 'Crear reserva'
                        : 'Guardar cambios'),
              ),
              if (_editingAppointmentId != null) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => setState(_clearForm),
                  child: const Text('Cancelar edicion'),
                ),
              ],
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(_message!, style: const TextStyle(color: Colors.black54)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    this.onEdit,
    this.onCancel,
  });

  final Appointment appointment;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'CONFIRMADA':
        return Colors.green;
      case 'COMPLETADA':
        return Colors.blue;
      case 'CANCELADA':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'PENDIENTE':
        return 'Pendiente';
      case 'CONFIRMADA':
        return 'Confirmada';
      case 'COMPLETADA':
        return 'Completada';
      case 'CANCELADA':
        return 'Cancelada';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(appointment.status);
    final statusLabel = _getStatusLabel(appointment.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con servicio y estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    appointment.serviceName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Info row 1: Mascota y Fecha
            Row(
              children: [
                Expanded(
                  child: _infoItem('🐾', 'Mascota:', appointment.petName),
                ),
                Expanded(
                  child: _infoItem('📅', 'Fecha:', appointment.date),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Info row 2: Hora y Modalidad
            Row(
              children: [
                Expanded(
                  child: _infoItem('⏰', 'Hora:', appointment.time),
                ),
                Expanded(
                  child: _infoItem(
                    '📍',
                    'Modalidad:',
                    appointment.modality == 'CLINICA' ? 'Clínica' : 'Domicilio',
                  ),
                ),
              ],
            ),
            // Dirección si aplica
            if (appointment.modality == 'DOMICILIO' &&
                appointment.address != null &&
                appointment.address!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _infoItem('📬', 'Dirección:', appointment.address!),
            ],
            // Descripción si existe
            if (appointment.description != null &&
                appointment.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _infoItem('📝', 'Descripción:', appointment.description!),
            ],
            // Botones editar y cancelar si es pendiente
            if (onEdit != null || onCancel != null) ...[
              const SizedBox(height: 12),
              if (onEdit != null && onCancel != null)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Editar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A11CB),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: onEdit,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Cancelar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: onCancel,
                      ),
                    ),
                  ],
                )
              else if (onEdit != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar Cita'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A11CB),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onEdit,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String emoji, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$emoji $label',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
