import 'package:flutter/material.dart';
import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/features/appointments/data/appointments_service.dart';
import 'package:pethome_app/src/features/auth/domain/auth_user.dart';
import 'package:pethome_app/src/features/pets/data/pets_service.dart';

class CitasPage extends StatefulWidget {
  const CitasPage({
    super.key,
    required this.petsService,
    required this.appointmentsService,
    required this.permissions,
  });

  final PetsService petsService;
  final AppointmentsService appointmentsService;
  final PermissionsHelper permissions;

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
  List<AvailabilitySlot> _availability = [];

  int? _selectedPetId;
  int? _selectedServiceId;
  int? _selectedPriceId;
  String _selectedModality = 'CLINICA';
  int? _editingAppointmentId;
  bool _isSaving = false;
  bool _isLoadingAvailability = false;
  String? _message;

  bool get _canCreateAppointment =>
      widget.permissions.canCreate('CITAS') ||
      widget.permissions.canExecute('CITAS');

  bool get _canEditAppointment => widget.permissions.canEdit('CITAS');
  bool get _canDeleteAppointment => widget.permissions.canDelete('CITAS');

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
      widget.petsService.getPets(),
      widget.appointmentsService.getServices(),
      widget.appointmentsService.getPrices(),
      widget.appointmentsService.getAppointments(),
    ]);

    _pets = results[0] as List<Pet>;
    _services = (results[1] as List<ServiceItem>)
        .where((service) => service.active)
        .toList();
    _prices =
        (results[2] as List<ServicePrice>).where((price) => price.active).toList();
    _appointments = results[3] as List<Appointment>;
  }

  List<ServiceItem> get _availableServices {
    if (_selectedModality == 'DOMICILIO') {
      return _services.where((service) => service.homeAvailable).toList();
    }
    return _services;
  }

  List<ServicePrice> get _availablePrices {
    return _prices
        .where(
          (price) =>
              (_selectedServiceId == null ||
                  price.serviceId == _selectedServiceId) &&
              price.modality == _selectedModality,
        )
        .toList();
  }

  Future<void> _loadAvailability() async {
    if (_selectedServiceId == null || _dateController.text.trim().isEmpty) {
      setState(() => _availability = <AvailabilitySlot>[]);
      return;
    }

    setState(() {
      _isLoadingAvailability = true;
      _message = null;
    });

    try {
      final slots = await widget.appointmentsService.getAvailability(
        serviceId: _selectedServiceId!,
        date: _dateController.text.trim(),
        modality: _selectedModality,
      );
      if (!mounted) return;
      setState(() => _availability = slots);
    } on ClientException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.isForbidden
            ? 'No tienes permiso para consultar disponibilidad.'
            : error.toString();
        _availability = <AvailabilitySlot>[];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingAvailability = false);
      }
    }
  }

  Future<void> _saveAppointment() async {
    if (!(_formKey.currentState?.validate() ?? false) ||
        _selectedPetId == null ||
        _selectedServiceId == null ||
        _selectedPriceId == null) {
      setState(() => _message = 'Completa los datos de la reserva.');
      return;
    }

    if (_selectedModality == 'DOMICILIO' &&
        _addressController.text.trim().isEmpty) {
      setState(() => _message = 'La direccion es obligatoria para domicilio.');
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
        await widget.appointmentsService.createAppointment(request);
      } else {
        await widget.appointmentsService
            .updateAppointment(_editingAppointmentId!, request);
      }

      _clearForm();
      await _loadData();
      if (!mounted) return;
      setState(() => _message = 'Reserva guardada correctamente.');
    } on ClientException catch (error) {
      final message = error.isForbidden
          ? 'No tienes permiso para gestionar reservas.'
          : error.toString();
      setState(() => _message = message);
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    setState(() {
      _isSaving = true;
      _message = null;
    });

    try {
      await widget.appointmentsService.cancelAppointment(appointment.id);
      await _loadData();
      if (!mounted) return;
      setState(() => _message = 'Reserva cancelada correctamente.');
    } on ClientException catch (error) {
      setState(() {
        _message = error.isForbidden
            ? 'No tienes permiso para cancelar reservas.'
            : error.toString();
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
    _loadAvailability();
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
    _availability = <AvailabilitySlot>[];
  }

  String _friendlyError(Object? error) {
    if (error is ClientException && error.isForbidden) {
      return 'No tienes permiso para consultar reservas.';
    }
    return error.toString();
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
              message: _friendlyError(snapshot.error),
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
                if (_canCreateAppointment || _canEditAppointment)
                  _buildForm()
                else
                  const Text(
                    'No tienes permiso para gestionar reservas.',
                    style: TextStyle(color: Colors.black54),
                  ),
                const SizedBox(height: 20),
                Text(
                  'Reservas registradas',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (_appointments.isEmpty)
                  const _EmptyState(text: 'Aun no tienes reservas.')
                else
                  ..._appointments.map(
                    (appointment) => _AppointmentCard(
                      appointment: appointment,
                      onEdit: _canEditAppointment &&
                              appointment.status == 'PENDIENTE'
                          ? () => _startEdit(appointment)
                          : null,
                      onCancel: _canDeleteAppointment &&
                              appointment.status == 'PENDIENTE'
                          ? () => _cancelAppointment(appointment)
                          : null,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
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
                initialValue: _selectedPetId,
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
                initialValue: _selectedServiceId,
                decoration: const InputDecoration(labelText: 'Servicio'),
                items: _availableServices
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
                  _loadAvailability();
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedModality,
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
                    _selectedServiceId = null;
                  });
                  _loadAvailability();
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _selectedPriceId,
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
                onChanged: (_) => _loadAvailability(),
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
              const SizedBox(height: 12),
              _buildAvailabilityPanel(),
              if (_selectedModality == 'DOMICILIO') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Direccion'),
                  validator: (value) {
                    if (_selectedModality != 'DOMICILIO') return null;
                    return (value == null || value.trim().isEmpty)
                        ? 'La direccion es obligatoria para domicilio'
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
                onPressed: _isSaving ||
                        (_editingAppointmentId == null
                            ? !_canCreateAppointment
                            : !_canEditAppointment)
                    ? null
                    : _saveAppointment,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_editingAppointmentId == null
                        ? 'Crear reserva'
                        : 'Guardar cambios'),
              ),
              if (_editingAppointmentId != null) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _canEditAppointment ? () => setState(_clearForm) : null,
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

  Widget _buildAvailabilityPanel() {
    if (_isLoadingAvailability) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }

    if (_availability.isEmpty) {
      return const Text(
        'Sin horarios consultados.',
        style: TextStyle(color: Colors.black54),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Disponibilidad',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availability.map((slot) {
            final label = slot.label ?? slot.time;
            return Chip(
              label: Text(label),
              backgroundColor:
                  slot.available ? Colors.green.shade50 : Colors.red.shade50,
            );
          }).toList(),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.calendar_today, color: Colors.white),
        ),
        title: Text('${appointment.serviceName} - ${appointment.petName}'),
        subtitle: Text(
          '${appointment.date} ${appointment.time}\n${appointment.modality} - ${appointment.status}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF6A11CB)),
                onPressed: onEdit,
              ),
            if (onCancel != null)
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                onPressed: onCancel,
              ),
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
