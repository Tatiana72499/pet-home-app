import 'package:flutter/material.dart';
import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/core/widgets/location_coordinate_picker.dart';
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
  static const _purple = Color(0xFF6A11CB);
  static const _softPurple = Color(0xFFF3E9FF);
  static const _orange = Color(0xFFFF9800);
  static const List<String> _weekdaysShort = <String>[
    'Lun',
    'Mar',
    'Mie',
    'Jue',
    'Vie',
    'Sab',
    'Dom',
  ];
  static const List<String> _monthsShort = <String>[
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  late Future<void> _loadFuture = _loadData();
  List<Pet> _pets = <Pet>[];
  List<ServiceItem> _services = <ServiceItem>[];
  List<ServicePrice> _prices = <ServicePrice>[];
  List<Appointment> _appointments = <Appointment>[];
  List<AvailabilitySlot> _availability = <AvailabilitySlot>[];

  int? _selectedPetId;
  int? _selectedServiceId;
  int? _selectedPriceId;
  String _selectedModality = 'CLINICA';
  bool _isSaving = false;
  bool _isLoadingAvailability = false;
  String? _message;

  bool _showWizard = false;
  int _wizardStep = 1;
  bool _showSuccess = false;
  Appointment? _lastCreatedAppointment;

  String _friendlyError(ClientException error) {
    if (error.statusCode == 403) {
      return 'No tienes permisos para realizar esta accion.';
    }
    return error.toString();
  }

  bool get _canViewReservations =>
      widget.permissions.canView('MOVIL_MIS_RESERVAS') ||
      widget.permissions.canView('SERV_CITAS') ||
      widget.permissions.canView('CITAS');

  bool get _canManageReservations =>
      widget.permissions.canEdit('MOVIL_MIS_RESERVAS') ||
      widget.permissions.canExecute('MOVIL_MIS_RESERVAS') ||
      widget.permissions.canEdit('SERV_CITAS') ||
      widget.permissions.canExecute('SERV_CITAS') ||
      widget.permissions.canExecute('MOVIL_CANCELAR_RESERVA') ||
      widget.permissions.canEdit('CITAS') ||
      widget.permissions.canExecute('CITAS');

  bool get _canCreateAppointment =>
      widget.permissions.canCreate('SERV_CITAS') ||
      widget.permissions.canExecute('SERV_CITAS') ||
      widget.permissions.canCreate('CITAS') ||
      widget.permissions.canExecute('CITAS');

  bool get _canEditAppointment =>
      widget.permissions.canEdit('SERV_CITAS') ||
      widget.permissions.canExecute('SERV_CITAS') ||
      widget.permissions.canEdit('CITAS') ||
      widget.permissions.canExecute('CITAS');

  bool get _canCancelAppointment =>
      widget.permissions.canExecute('MOVIL_CANCELAR_RESERVA') ||
      widget.permissions.canEdit('SERV_CITAS') ||
      widget.permissions.canExecute('SERV_CITAS') ||
      widget.permissions.canDelete('CITAS') ||
      widget.permissions.canExecute('CITAS');

  List<DateTime> get _nextTenDays {
    final today = DateUtils.dateOnly(DateTime.now());
    return List<DateTime>.generate(
      10,
      (index) => today.add(Duration(days: index)),
    );
  }

  List<ServiceItem> get _availableServices {
    return _filteredServicesByModalidad(_selectedModality);
  }

  List<ServicePrice> get _availablePrices {
    return _filteredPreciosByServicioYModalidad(
      serviceId: _selectedServiceId,
      modalidad: _selectedModality,
    );
  }

  List<ServiceItem> _filteredServicesByModalidad(String modalidad) {
    final filtered = _services.where((service) {
      final hasPriceForModality = _prices.any(
        (price) =>
            price.active &&
            price.serviceId == service.id &&
            price.modality == modalidad,
      );
      if (modalidad == 'DOMICILIO') {
        return service.active && service.homeAvailable && hasPriceForModality;
      }
      return service.active && hasPriceForModality;
    }).toList();
    assert(() {
      debugPrint(
        '[CitasPage] modalidad=$modalidad services_filtered=${filtered.length}',
      );
      return true;
    }());
    return filtered;
  }

  List<ServicePrice> _filteredPreciosByServicioYModalidad({
    required int? serviceId,
    required String modalidad,
  }) {
    if (serviceId == null) return <ServicePrice>[];
    final filtered = _prices
        .where(
          (price) =>
              price.active &&
              price.serviceId == serviceId &&
              price.modality == modalidad,
        )
        .toList();
    assert(() {
      debugPrint(
        '[CitasPage] modalidad=$modalidad service_selected=$serviceId prices_filtered=${filtered.length}',
      );
      return true;
    }());
    return filtered;
  }

  void _onModalityChanged(String modalidad) {
    setState(() {
      _selectedModality = modalidad;
      _selectedServiceId = null;
      _selectedPriceId = null;
      _message = null;
      _availability = <AvailabilitySlot>[];
      _timeController.clear();
      if (modalidad == 'CLINICA') {
        _addressController.clear();
      }
    });
  }

  void _onServiceChanged(int? serviceId) {
    assert(() {
      debugPrint('[CitasPage] service_selected=$serviceId');
      return true;
    }());
    setState(() {
      _selectedServiceId = serviceId;
      _selectedPriceId = null;
      _message = null;
    });
    _loadAvailability();
  }

  bool get _hasServicesForCurrentModality => _availableServices.isNotEmpty;

  bool get _hasValidPriceForSelectedService => _availablePrices.isNotEmpty;

  bool get _isDateTimeFuture {
    final dateRaw = _dateController.text.trim();
    final timeRaw = _timeController.text.trim();
    if (dateRaw.isEmpty || timeRaw.isEmpty) return false;
    final parsedDate = DateTime.tryParse(dateRaw);
    if (parsedDate == null) return false;
    final parts = timeRaw.split(':');
    if (parts.length < 2) return false;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return false;
    final dt = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, hour, minute);
    return dt.isAfter(DateTime.now());
  }

  bool get _isSelectedTimeAvailable {
    final selected = _timeController.text.trim();
    if (selected.isEmpty) return false;
    if (_availability.isEmpty) return true;
    final matches = _availability.where((slot) => slot.time == selected);
    if (matches.isEmpty) return false;
    return matches.any((slot) => slot.available);
  }

  bool _canContinueStep() {
    if (_wizardStep == 1) {
      return _selectedPetId != null &&
          _selectedServiceId != null &&
          _selectedPriceId != null &&
          _hasServicesForCurrentModality &&
          _hasValidPriceForSelectedService;
    }
    if (_wizardStep == 2) {
      return _dateController.text.trim().isNotEmpty &&
          _timeController.text.trim().isNotEmpty &&
          _isDateTimeFuture &&
          _isSelectedTimeAvailable;
    }
    if (_wizardStep == 3) {
      if (_selectedModality == 'DOMICILIO' &&
          _addressController.text.trim().isEmpty) {
        return false;
      }
      return _canCreateAppointment;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _debugPermissions();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final canCreateOrManage = _canCreateAppointment || _canManageReservations;
    final canViewOrManageReservations = _canViewReservations || _canManageReservations;

    _pets = canCreateOrManage ? await widget.petsService.getPets() : <Pet>[];
    _services = canCreateOrManage
      ? (await widget.appointmentsService.getServices())
        .where((service) => service.active)
        .toList()
      : <ServiceItem>[];
    _prices = canCreateOrManage
      ? (await widget.appointmentsService.getPrices())
        .where((price) => price.active)
        .toList()
      : <ServicePrice>[];
    _appointments = canViewOrManageReservations
      ? await widget.appointmentsService.getAppointments()
      : <Appointment>[];
  }

  Future<void> _loadAvailability() async {
    if (_dateController.text.trim().isEmpty) {
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
        _message = _friendlyError(error);
        _availability = <AvailabilitySlot>[];
      });
    } finally {
      if (mounted) setState(() => _isLoadingAvailability = false);
    }
  }

  Future<void> _createAppointment() async {
    if (_selectedPetId == null || _selectedServiceId == null || _selectedPriceId == null) {
      setState(() => _message = 'Completa mascota, servicio y precio.');
      return;
    }
    if (_dateController.text.trim().isEmpty || _timeController.text.trim().isEmpty) {
      setState(() => _message = 'Fecha y hora son obligatorias.');
      return;
    }
    if (_selectedModality == 'DOMICILIO' && _addressController.text.trim().isEmpty) {
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
      endTime: null,
      modality: _selectedModality,
      address: _addressController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    try {
      await widget.appointmentsService.createAppointment(request);
      await _loadData();
      _lastCreatedAppointment = _appointments.isNotEmpty ? _appointments.first : null;
      setState(() {
        _showSuccess = true;
        _showWizard = false;
      });
      if (!mounted) return;
      setState(() => _message = 'Cita solicitada correctamente.');
    } on ClientException catch (error) {
      setState(() => _message = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _reprogramAppointment(Appointment appointment) async {
    final dateCtrl = TextEditingController(text: appointment.date);
    final timeCtrl = TextEditingController(text: appointment.time);

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reprogramar reserva'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateCtrl,
              decoration: const InputDecoration(labelText: 'Nueva fecha (YYYY-MM-DD)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: timeCtrl,
              decoration: const InputDecoration(labelText: 'Nueva hora (HH:MM)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );

    if (ok != true) return;

    setState(() {
      _isSaving = true;
      _message = null;
    });

    try {
      final req = AppointmentRequest(
        petId: appointment.petId,
        serviceId: appointment.serviceId,
        priceId: appointment.priceId,
        date: dateCtrl.text.trim(),
        time: timeCtrl.text.trim(),
        endTime: null,
        modality: appointment.modality,
        address: appointment.address,
        description: appointment.description,
      );
      await widget.appointmentsService.updateAppointment(appointment.id, req);
      await _loadData();
      if (!mounted) return;
      setState(() => _message = 'Reserva reprogramada correctamente.');
    } on ClientException catch (error) {
      setState(() => _message = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
      dateCtrl.dispose();
      timeCtrl.dispose();
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: const Text('¿Confirmas que deseas cancelar esta reserva?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No, volver')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí, cancelar')),
        ],
      ),
    );

    if (ok != true) return;

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
      setState(() => _message = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetWizard() {
    _showWizard = false;
    _wizardStep = 1;
    _showSuccess = false;
    _lastCreatedAppointment = null;
    _selectedPetId = null;
    _selectedServiceId = null;
    _selectedPriceId = null;
    _selectedModality = 'CLINICA';
    _dateController.clear();
    _timeController.clear();
    _addressController.clear();
    _descriptionController.clear();
    _availability = <AvailabilitySlot>[];
    _dateController.text = _formatApiDate(_nextTenDays.first);
    _message = null;
  }

  String _formatApiDate(DateTime date) {
    final normalized = DateUtils.dateOnly(date);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatShortDate(DateTime date) {
    final normalized = DateUtils.dateOnly(date);
    final today = DateUtils.dateOnly(DateTime.now());
    if (normalized == today) {
      return 'Hoy';
    }
    if (normalized == today.add(const Duration(days: 1))) {
      return 'Manana';
    }
    return _weekdaysShort[normalized.weekday - 1];
  }

  String _formatLongDate(DateTime date) {
    return '${date.day} ${_monthsShort[date.month - 1]}';
  }

  Future<void> _selectDate(DateTime date) async {
    setState(() {
      _dateController.text = _formatApiDate(date);
      _timeController.clear();
      _availability = <AvailabilitySlot>[];
      _message = null;
    });
    await _loadAvailability();
  }

  void _selectTime(String time) {
    setState(() {
      _timeController.text = time;
      _message = null;
    });
  }

  bool _isEditableStatus(String status) {
    return status == 'PENDIENTE' || status == 'CONFIRMADA';
  }

  bool _isConfirmableStatus(String status) {
    return status == 'PENDIENTE';
  }

  bool _isFinalizableStatus(String status) {
    return status == 'CONFIRMADA';
  }

  Future<void> _setAppointmentStatus(
    Appointment appointment,
    String estado,
  ) async {
    setState(() {
      _isSaving = true;
      _message = null;
    });

    try {
      final request = AppointmentRequest(
        petId: appointment.petId,
        serviceId: appointment.serviceId,
        priceId: appointment.priceId,
        date: appointment.date,
        time: appointment.time,
        endTime: null,
        modality: appointment.modality,
        estado: estado,
        address: appointment.address,
        description: appointment.description,
      );

      await widget.appointmentsService.updateAppointment(appointment.id, request);
      await _loadData();
      if (!mounted) return;

      final message = estado == 'CONFIRMADA'
          ? 'Reserva confirmada correctamente.'
          : 'Reserva finalizada correctamente.';
      setState(() => _message = message);
    } on ClientException catch (error) {
      setState(() => _message = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showDetail(Appointment appointment) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final editable = _isEditableStatus(appointment.status);
        final canConfirm = _canEditAppointment && _isConfirmableStatus(appointment.status);
        final canFinalize = _canEditAppointment && _isFinalizableStatus(appointment.status);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appointment.serviceName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Mascota: ${appointment.petName}'),
              Text('Fecha: ${appointment.date}'),
              Text('Hora: ${appointment.time}'),
              Text('Estado: ${appointment.status}'),
              if ((appointment.address ?? '').isNotEmpty)
                Text('Direccion: ${appointment.address}'),
              const SizedBox(height: 12),
              if (editable || canConfirm || canFinalize)
                Column(
                  children: [
                    if (canConfirm || canFinalize)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _canEditAppointment
                              ? () {
                                  Navigator.pop(context);
                                  _setAppointmentStatus(
                                    appointment,
                                    canConfirm ? 'CONFIRMADA' : 'COMPLETADA',
                                  );
                                }
                              : null,
                          child: Text(canConfirm ? 'Confirmar' : 'Marcar como finalizada'),
                        ),
                      ),
                    if (canConfirm || canFinalize) const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _canEditAppointment
                                ? () {
                                    Navigator.pop(context);
                                    _reprogramAppointment(appointment);
                                  }
                                : null,
                            child: const Text('Reprogramar'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _canCancelAppointment
                                ? () {
                                    Navigator.pop(context);
                                    _cancelAppointment(appointment);
                                  }
                                : null,
                            child: const Text('Cancelar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                const Text('Reserva en solo lectura.'),
            ],
          ),
        );
      },
    );
  }

  void _debugPermissions() {
    assert(() {
      debugPrint(
        '[CitasPage] '
        'MOVIL_MIS_RESERVAS(view=${widget.permissions.canView('MOVIL_MIS_RESERVAS')}, '
        'edit=${widget.permissions.canEdit('MOVIL_MIS_RESERVAS')}, '
        'exec=${widget.permissions.canExecute('MOVIL_MIS_RESERVAS')}), '
        'SERV_CITAS(view=${widget.permissions.canView('SERV_CITAS')}, '
        'edit=${widget.permissions.canEdit('SERV_CITAS')}, '
        'exec=${widget.permissions.canExecute('SERV_CITAS')}), '
        'MOVIL_CANCELAR_RESERVA(view=${widget.permissions.canView('MOVIL_CANCELAR_RESERVA')}, '
        'edit=${widget.permissions.canEdit('MOVIL_CANCELAR_RESERVA')}, '
        'exec=${widget.permissions.canExecute('MOVIL_CANCELAR_RESERVA')})',
      );
      return true;
    }());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis reservas'),
        backgroundColor: _purple,
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
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mis reservas',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Proximas citas y estado de atencion',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.black54,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (_canManageReservations)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () => setState(() {
                          if (_showWizard) {
                            _resetWizard();
                          } else {
                            _showWizard = true;
                            _showSuccess = false;
                            _wizardStep = 1;
                            _dateController.text = _formatApiDate(_nextTenDays.first);
                            _timeController.clear();
                            _availability = <AvailabilitySlot>[];
                            _message = null;
                          }
                        }),
                        child: Text(_showWizard ? 'Cerrar' : '+ Solicitar'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_showWizard) _buildWizard(),
                if (_showSuccess) _buildSuccessCard(),
                if (_message != null) ...[
                  const SizedBox(height: 8),
                  Text(_message!, style: const TextStyle(color: Colors.black54)),
                ],
                const SizedBox(height: 12),
                if (!_canViewReservations)
                  const _EmptyState(text: 'No tienes permiso para consultar tus reservas.')
                else if (_appointments.isEmpty)
                  const _EmptyState(text: 'Aun no tienes reservas.')
                else
                  ..._appointments.map(
                    (appointment) => _AppointmentCard(
                      appointment: appointment,
                      onTap: () => _showDetail(appointment),
                      onEdit: (_canEditAppointment && _isEditableStatus(appointment.status))
                          ? () => _reprogramAppointment(appointment)
                          : null,
                      onCancel: (_canCancelAppointment && _isEditableStatus(appointment.status))
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

  Widget _buildWizard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStepHeader(),
            const SizedBox(height: 10),
            Text('Paso $_wizardStep de 3', style: const TextStyle(color: _purple, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              _wizardStep == 1
                  ? 'Mascota, servicio y modalidad'
                  : _wizardStep == 2
                      ? 'Calendario y horario'
                      : 'Direccion y resumen',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_wizardStep == 1) ...[
              const Text('Modalidad', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _selectedModality == 'CLINICA' ? _softPurple : null,
                        side: BorderSide(
                          color: _selectedModality == 'CLINICA' ? _purple : Colors.grey.shade300,
                        ),
                      ),
                      onPressed: () => _onModalityChanged('CLINICA'),
                      child: const Text('Clinica'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _selectedModality == 'DOMICILIO' ? const Color(0xFFFFF1E6) : null,
                        side: BorderSide(
                          color: _selectedModality == 'DOMICILIO' ? Colors.orange : Colors.grey.shade300,
                        ),
                      ),
                      onPressed: () => _onModalityChanged('DOMICILIO'),
                      child: const Text('Domicilio'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!_hasServicesForCurrentModality)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'No hay servicios disponibles para esta modalidad.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              const Text('Mascota', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _pets.map((pet) {
                  final selected = _selectedPetId == pet.id;
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _selectedPetId = pet.id),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 120),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? _softPurple : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? _purple : Colors.grey.shade300,
                          width: selected ? 1.6 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: _orange,
                            child: const Icon(Icons.pets, size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              pet.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: _selectedServiceId,
                decoration: const InputDecoration(labelText: 'Servicio activo'),
                items: _availableServices
                    .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                    .toList(),
                onChanged: _hasServicesForCurrentModality ? _onServiceChanged : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: _selectedPriceId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Precio'),
                items: _availablePrices
                    .map((price) => DropdownMenuItem(
                          value: price.id,
                          child: Text(
                            '${price.variation} - Bs. ${price.price}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: _selectedServiceId == null
                    ? null
                    : (v) => setState(() => _selectedPriceId = v),
              ),
              if (_selectedServiceId != null && !_hasValidPriceForSelectedService)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Este servicio no tiene precio activo para la modalidad seleccionada.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
            ],
            if (_wizardStep == 2) ...[
              const Text(
                'Selecciona un dia dentro de los proximos 10 dias',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _nextTenDays.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final day = _nextTenDays[index];
                    final dayValue = _formatApiDate(day);
                    final selected = _dateController.text == dayValue;
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _selectDate(day),
                      child: Container(
                        width: 84,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? _softPurple : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selected ? _purple : Colors.grey.shade300,
                            width: selected ? 1.6 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatShortDate(day),
                              style: TextStyle(
                                color: selected ? _purple : Colors.black87,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatLongDate(day),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.event_available, size: 18, color: _purple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Fecha elegida: ${_dateController.text}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Horarios disponibles para ese dia',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              if (_dateController.text.trim().isNotEmpty &&
                  _timeController.text.trim().isNotEmpty &&
                  !_isDateTimeFuture)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'La fecha y hora deben ser futuras.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              const SizedBox(height: 10),
              if (_isLoadingAvailability)
                const LinearProgressIndicator()
              else if (_selectedServiceId == null)
                const Text(
                  'Selecciona mascota, servicio y precio en el paso anterior para consultar horarios.',
                )
              else if (_availability.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availability
                      .map(
                        (slot) {
                          final selected = _timeController.text.trim() == slot.time;
                          return ChoiceChip(
                            selected: selected,
                            selectedColor: _softPurple,
                            backgroundColor: slot.available
                                ? const Color(0xFFE4F7EC)
                                : const Color(0xFFFFECEC),
                            side: BorderSide(
                              color: selected
                                  ? _purple
                                  : (slot.available ? Colors.green.shade200 : Colors.red.shade200),
                            ),
                            label: Text(slot.label ?? slot.time),
                            onSelected: slot.available ? (_) => _selectTime(slot.time) : null,
                          );
                        },
                      )
                      .toList(),
                )
              else
                const Text(
                  'No hay horarios disponibles para este dia. Elige otra fecha.',
                ),
              if (_timeController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Hora elegida: ${_timeController.text}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
              if (_availability.isNotEmpty &&
                  _timeController.text.trim().isNotEmpty &&
                  !_isSelectedTimeAvailable)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'El horario seleccionado no esta disponible.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
            ],
	            if (_wizardStep == 3) ...[
	              if (_selectedModality == 'DOMICILIO') ...[
	                LocationCoordinatePicker(
	                  initialCoordinates: _addressController.text,
	                  onChanged: (value) {
	                    _addressController.text = value;
	                    setState(() => _message = null);
	                  },
	                ),
	                const SizedBox(height: 10),
	              ],
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Descripcion'),
              ),
              const SizedBox(height: 12),
              _buildSummary(),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                if (_wizardStep > 1)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _wizardStep--),
                      child: const Text('Atras'),
                    ),
                  ),
                if (_wizardStep > 1) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving || !_canContinueStep()
                        ? null
                        : () {
                            if (_wizardStep < 3) {
                              setState(() => _wizardStep++);
                            } else {
                              _createAppointment();
                            }
                          },
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_wizardStep < 3 ? 'Continuar' : 'Solicitar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    Pet? pet;
    ServiceItem? service;
    ServicePrice? price;
    for (final item in _pets) {
      if (item.id == _selectedPetId) {
        pet = item;
        break;
      }
    }
    for (final item in _services) {
      if (item.id == _selectedServiceId) {
        service = item;
        break;
      }
    }
    for (final item in _prices) {
      if (item.id == _selectedPriceId) {
        price = item;
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _softPurple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumen de solicitud', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Mascota: ${pet?.name ?? '-'}'),
          Text('Servicio: ${service?.name ?? '-'}'),
          Text('Modalidad: $_selectedModality'),
          Text('Fecha y hora: ${_dateController.text} ${_timeController.text}'),
          if (_selectedModality == 'DOMICILIO') Text('Direccion: ${_addressController.text}'),
          if (price != null)
            Text(
              'Total: Bs. ${price.price}',
              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    final labels = <String>[
      'Mascota y servicio',
      'Calendario',
      'Confirmar',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List<Widget>.generate(labels.length, (index) {
          final isActive = _wizardStep == index + 1;
          return Padding(
            padding: EdgeInsets.only(right: index == labels.length - 1 ? 0 : 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? _softPurple : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${index + 1}. ${labels[index]}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? _purple : Colors.black54,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSuccessCard() {
    final appointment = _lastCreatedAppointment;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFFE4F7EC),
              child: Icon(Icons.check, color: Colors.green),
            ),
            const SizedBox(height: 10),
            const Text(
              'Cita solicitada',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Registrada con estado pendiente.'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _softPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                appointment == null
                    ? 'Detalle no disponible.'
                    : 'Mascota: ${appointment.petName}\n'
                        'Servicio: ${appointment.serviceName}\n'
                        'Fecha: ${appointment.date} ${appointment.time}\n'
                        'Estado: ${appointment.status}',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(_resetWizard),
                child: const Text('Ver mis citas'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.onTap,
    this.onEdit,
    this.onCancel,
  });

  final Appointment appointment;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: Colors.orange,
                child: Icon(Icons.calendar_today, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${appointment.serviceName} - ${appointment.petName}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text('${appointment.date} ${appointment.time}'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(appointment.modality),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: appointment.status == 'CONFIRMADA'
                                ? const Color(0xFFE4F7EC)
                                : appointment.status == 'PENDIENTE'
                                    ? const Color(0xFFFFF1E6)
                                    : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            appointment.status,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (onEdit != null || onCancel != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (onEdit != null)
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.edit, color: Color(0xFF6A11CB)),
                              onPressed: onEdit,
                            ),
                          if (onEdit != null) const SizedBox(width: 8),
                          if (onCancel != null)
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                              onPressed: onCancel,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
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
