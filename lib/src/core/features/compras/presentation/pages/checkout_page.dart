// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pethome_app/src/core/features/compras/data/services/pago_service.dart';
import 'package:pethome_app/src/core/features/compras/presentation/widgets/comprobante_pago_widget.dart';
import 'package:pethome_app/src/core/features/compras/providers/carrito_provider.dart';
import 'package:pethome_app/src/core/features/compras/providers/pago_provider.dart';
import 'package:pethome_app/src/core/widgets/location_coordinate_picker.dart';
import 'package:pethome_app/src/features/appointments/data/appointments_service.dart';
import 'package:pethome_app/src/features/auth/data/auth_service.dart';
import 'package:pethome_app/src/utils/open_external_link.dart';

enum CheckoutMode { PEDIDO_MOVIL, CITA_SERVICIO }

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({
    super.key,
    required this.mode,
    this.citaData,
  });

  final CheckoutMode mode;
  final Map<String, dynamic>? citaData;

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return ChangeNotifierProvider<PagoProvider>(
      create: (_) => PagoProvider(
        pagoService: PagoService(authService: authService),
      ),
      child: _CheckoutView(
        mode: mode,
        citaData: citaData,
        appointmentsService: AppointmentsService(authService: authService),
      ),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  const _CheckoutView({
    required this.mode,
    required this.appointmentsService,
    this.citaData,
  });

  final CheckoutMode mode;
  final Map<String, dynamic>? citaData;
  final AppointmentsService appointmentsService;

  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> with WidgetsBindingObserver {
  final _addressController = TextEditingController();
  final _obsController = TextEditingController();

  String _tipoEntrega = 'DOMICILIO';
  bool _orderPlaced = false;
  bool _paymentFinished = false;
  bool _paymentSuccess = false;
  bool _isUpdatingAppointmentAddress = false;
  int? _pedidoId;
  double? _pedidoTotal;
  int? _selectedDeliveryAppointmentId;

  bool get _isPedidoMode => widget.mode == CheckoutMode.PEDIDO_MOVIL;
  bool get _isCitaMode => widget.mode == CheckoutMode.CITA_SERVICIO;
  bool get _isCitaDomicilio =>
      _isCitaMode &&
      (widget.citaData?['modality']?.toString().toUpperCase() == 'DOMICILIO');
  bool get _requiresAddress =>
      (_isPedidoMode &&
              (_tipoEntrega == 'DOMICILIO' || _tipoEntrega == 'JUNTO_CITA')) ||
          _isCitaDomicilio;

  List<Appointment> get _pendingAppointmentsForDelivery {
    if (!_isPedidoMode) return const <Appointment>[];
    final provider = Provider.of<CarritoProvider>(context, listen: false);
    return provider.pendingAppointments
        .where((appointment) => appointment.status == 'PENDIENTE')
        .toList();
  }

  Appointment? get _selectedDeliveryAppointment {
    if (_selectedDeliveryAppointmentId == null) return null;
    for (final appointment in _pendingAppointmentsForDelivery) {
      if (appointment.id == _selectedDeliveryAppointmentId) return appointment;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_isCitaMode && widget.citaData != null) {
      _addressController.text = (widget.citaData!['address'] ?? '').toString();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isPedidoMode) {
        final appointments = _pendingAppointmentsForDelivery;
        if (appointments.isNotEmpty && mounted) {
          setState(() {
            _selectedDeliveryAppointmentId = appointments.first.id;
          });
        }
      }
      Provider.of<PagoProvider>(context, listen: false).restorePendingPaymentId();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _addressController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    final provider = Provider.of<PagoProvider>(context, listen: false);
    if (provider.currentPagoId == null || _paymentFinished) return;

    provider.checkPaymentStatus(
      provider.currentPagoId!,
      onSuccess: () {
        setState(() {
          _paymentFinished = true;
          _paymentSuccess = true;
        });
        if (_isPedidoMode) {
          try {
            final cartProvider = Provider.of<CarritoProvider>(context, listen: false);
            cartProvider.clearCarritoLocal();
            cartProvider.loadCarrito();
          } catch (_) {}
        }
      },
      onFailed: () {
        setState(() {
          _paymentFinished = true;
          _paymentSuccess = false;
        });
      },
    );
  }

  Future<bool> _persistAppointmentAddress() async {
    if (!_isCitaDomicilio || widget.citaData == null) return true;

    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la ubicacion de la cita para continuar.')),
      );
      return false;
    }

    if ((widget.citaData!['address'] ?? '').toString().trim() == address) {
      return true;
    }

    final citaId = widget.citaData!['id'] as int?;
    final petId = widget.citaData!['petId'] as int?;
    final serviceId = widget.citaData!['serviceId'] as int?;
    final priceId = widget.citaData!['priceId'] as int?;
    if (citaId == null || petId == null || serviceId == null || priceId == null) {
      return true;
    }

    setState(() => _isUpdatingAppointmentAddress = true);
    try {
      final updated = await widget.appointmentsService.replaceAppointment(
        citaId,
        AppointmentRequest(
          petId: petId,
          serviceId: serviceId,
          priceId: priceId,
          date: widget.citaData!['date']?.toString() ?? '',
          time: widget.citaData!['time']?.toString() ?? '',
          endTime: null,
          modality: widget.citaData!['modality']?.toString() ?? 'DOMICILIO',
          address: address,
          description: widget.citaData!['description']?.toString(),
        ),
      );
      widget.citaData!['address'] = updated.address ?? address;
      return true;
    } catch (_) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la direccion de la cita.')),
      );
      return false;
    } finally {
      if (mounted) {
        setState(() => _isUpdatingAppointmentAddress = false);
      }
    }
  }

  String _buildOrderObservation() {
    final base = _obsController.text.trim();
    if (_tipoEntrega != 'JUNTO_CITA') return base;

    final appointment = _selectedDeliveryAppointment;
    final citaNote = appointment == null
        ? 'Entregar junto a una cita pendiente.'
        : 'Entregar junto a la cita #${appointment.id} de ${appointment.date} a las ${appointment.time}.';

    if (base.isEmpty) return citaNote;
    return '$base | $citaNote';
  }

  Future<void> _handleConfirmOrder(PagoProvider provider) async {
    final effectiveAddress = _tipoEntrega == 'JUNTO_CITA'
        ? (_selectedDeliveryAppointment?.address ?? '').trim()
        : _addressController.text.trim();

    if ((_tipoEntrega == 'DOMICILIO' || _tipoEntrega == 'JUNTO_CITA') &&
        effectiveAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La direccion es obligatoria para envios a domicilio.')),
      );
      return;
    }

    final success = await provider.crearPedido(
      tipoEntrega: _tipoEntrega == 'JUNTO_CITA' ? 'DOMICILIO' : _tipoEntrega,
      direccionEntrega:
          (_tipoEntrega == 'DOMICILIO' || _tipoEntrega == 'JUNTO_CITA') ? effectiveAddress : null,
      observacion: _buildOrderObservation().isEmpty ? null : _buildOrderObservation(),
      citaId: _tipoEntrega == 'JUNTO_CITA' ? _selectedDeliveryAppointmentId : null,
    );

    if (!success || provider.createdPedido == null) return;

    final order = provider.createdPedido!;
    setState(() {
      _pedidoId = order['id_pedido'] as int?;
      _pedidoTotal = double.tryParse(order['total']?.toString() ?? '');
      _orderPlaced = true;
    });
  }

  Future<void> _handleStripePay(PagoProvider provider) async {
    if (_requiresAddress && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa la direccion antes de pagar.')),
      );
      return;
    }

    if (!await _persistAppointmentAddress()) return;

    final cartProvider = _isPedidoMode
        ? Provider.of<CarritoProvider>(context, listen: false)
        : null;
    final refId = _isPedidoMode ? _pedidoId : widget.citaData!['id'] as int?;
    final refType = _isPedidoMode ? 'PEDIDO_MOVIL' : 'CITA_SERVICIO';

    if (refId == null) return;

    final success = await provider.iniciarPagoStripe(
      tipoReferencia: refType,
      referenciaId: refId,
    );

    if (!success || provider.checkoutUrl == null) return;

    if (provider.autoConfirmed) {
      if (_isPedidoMode && cartProvider != null) {
        try {
          cartProvider.clearCarritoLocal();
          await cartProvider.loadCarrito();
        } catch (_) {}
      }

      setState(() {
        _paymentFinished = true;
        _paymentSuccess = true;
      });
      return;
    }

    await openExternalLink(provider.checkoutUrl!);
    provider.startPollingPayment(
      idPago: provider.currentPagoId!,
      onSuccess: () {
        setState(() {
          _paymentFinished = true;
          _paymentSuccess = true;
        });
        if (_isPedidoMode && cartProvider != null) {
          try {
            cartProvider.clearCarritoLocal();
            cartProvider.loadCarrito();
          } catch (_) {}
        }
      },
      onFailed: () {
        setState(() {
          _paymentFinished = true;
          _paymentSuccess = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PagoProvider>(context);

    if (provider.isPolling) return _buildPollingState(provider);
    if (_paymentFinished && _paymentSuccess) return _buildSuccessState(provider);
    if (_paymentFinished && !_paymentSuccess) return _buildFailedState(provider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1F2937), size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isPedidoMode ? 'Confirmar pedido' : 'Pago de cita',
          style: const TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 16),
            if (_isPedidoMode && !_orderPlaced) ...[
              _buildDeliveryCard(),
              const SizedBox(height: 16),
            ],
            if (_isCitaDomicilio) ...[
              _buildAppointmentAddressCard(),
              const SizedBox(height: 16),
            ],
            _buildAmountCard(),
            const SizedBox(height: 16),
            if (provider.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(
                  provider.errorMessage!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            if (provider.isLoading || _isUpdatingAppointmentAddress)
              const Center(child: CircularProgressIndicator(color: Color(0xFF6D28D9)))
            else if (_isPedidoMode && !_orderPlaced)
              FilledButton(
                onPressed: () => _handleConfirmOrder(provider),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6D28D9),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Continuar al pago'),
              )
            else
              FilledButton.icon(
                onPressed: () => _handleStripePay(provider),
                icon: const Icon(Icons.payment_rounded),
                label: const Text('Pagar con Stripe'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF635BFF),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollingState(PagoProvider provider) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 56,
                    width: 56,
                    child: CircularProgressIndicator(
                      color: Color(0xFF6D28D9),
                      strokeWidth: 4.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Procesando tu pago...',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No cierres esta pantalla mientras validamos la transaccion.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                  if (provider.infoMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      provider.infoMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState(PagoProvider provider) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Pago exitoso',
          style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle_rounded, size: 72, color: Color(0xFF10B981)),
            const SizedBox(height: 12),
            const Text(
              'Transaccion completada',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              provider.infoMessage ?? 'Tu pago fue validado correctamente.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            if (provider.comprobanteData != null)
              ComprobantePagoWidget(comprobante: provider.comprobanteData!)
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Comprobante emitido. Revisa tu historial para descargarlo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF4B5563), fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6D28D9),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedState(PagoProvider provider) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F5),
        elevation: 0,
        title: const Text('Pago fallido', style: TextStyle(color: Color(0xFF1F2937))),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'No se completo la transaccion',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.errorMessage ?? 'Ocurrio un error al procesar el pago.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            provider.reset();
                            setState(() {
                              _paymentFinished = false;
                              _paymentSuccess = false;
                            });
                          },
                          child: const Text('Reintentar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6D28D9)),
                          child: const Text('Cerrar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isPedidoMode ? 'Resumen del carrito' : 'Resumen de la cita',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            if (_isPedidoMode)
              Consumer<CarritoProvider>(
                builder: (context, cartProvider, _) {
                  if (cartProvider.carrito.detalles.isEmpty) {
                    return const Text('No hay items en el carrito.');
                  }

                  return Column(
                    children: cartProvider.carrito.detalles
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.titulo} x${item.cantidad.toStringAsFixed(item.cantidad % 1 == 0 ? 0 : 2)}',
                                    style: const TextStyle(
                                      color: Color(0xFF4B5563),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Bs. ${item.subtotalEstimado.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              )
            else ...[
              _buildSummaryRow('Servicio', widget.citaData?['serviceName']?.toString()),
              _buildSummaryRow('Mascota', widget.citaData?['petName']?.toString()),
              _buildSummaryRow(
                'Fecha y hora',
                '${widget.citaData?['date'] ?? '-'} a las ${widget.citaData?['time'] ?? '-'}',
              ),
              _buildSummaryRow('Modalidad', widget.citaData?['modality']?.toString()),
              if (_addressController.text.trim().isNotEmpty)
                _buildSummaryRow('Direccion', _addressController.text.trim()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entrega y observaciones',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_pendingAppointmentsForDelivery.isNotEmpty)
                  ChoiceChip(
                    label: const Text('Junto con cita'),
                    selected: _tipoEntrega == 'JUNTO_CITA',
                    onSelected: (value) {
                      if (!value) return;
                      final appointment = _selectedDeliveryAppointment ?? _pendingAppointmentsForDelivery.first;
                      setState(() {
                        _tipoEntrega = 'JUNTO_CITA';
                        _selectedDeliveryAppointmentId = appointment.id;
                        _addressController.text = appointment.address ?? '';
                      });
                    },
                  ),
                ChoiceChip(
                  label: const Text('A domicilio'),
                  selected: _tipoEntrega == 'DOMICILIO',
                  onSelected: (value) {
                    if (!value) return;
                    setState(() => _tipoEntrega = 'DOMICILIO');
                  },
                ),
                ChoiceChip(
                  label: const Text('Recojo en clinica'),
                  selected: _tipoEntrega == 'RECOJO',
                  onSelected: (value) {
                    if (!value) return;
                    setState(() => _tipoEntrega = 'RECOJO');
                  },
                ),
              ],
            ),
            if (_tipoEntrega == 'JUNTO_CITA') ...[
              const SizedBox(height: 16),
              const Text(
                'Selecciona la cita pendiente',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _selectedDeliveryAppointmentId,
                decoration: const InputDecoration(labelText: 'Cita pendiente'),
                items: _pendingAppointmentsForDelivery
                    .map(
                      (appointment) => DropdownMenuItem<int>(
                        value: appointment.id,
                        child: Text(
                          '${appointment.serviceName} - ${appointment.date} ${appointment.time}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  final selected = _pendingAppointmentsForDelivery
                      .where((appointment) => appointment.id == value)
                      .first;
                  setState(() {
                    _selectedDeliveryAppointmentId = value;
                    _addressController.text = selected.address ?? '';
                  });
                },
              ),
              const SizedBox(height: 12),
              if (_selectedDeliveryAppointment != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F5FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE9D5FF)),
                  ),
                  child: Text(
                    (_selectedDeliveryAppointment!.address ?? '').isEmpty
                        ? 'La cita seleccionada no tiene direccion registrada. Usa A domicilio o completa la direccion de esa cita.'
                        : 'Se entregara usando la direccion de la cita #${_selectedDeliveryAppointment!.id}.',
                    style: const TextStyle(color: Color(0xFF4B5563), fontSize: 12),
                  ),
                ),
            ] else if (_tipoEntrega == 'DOMICILIO') ...[
              const SizedBox(height: 16),
              const Text(
                'Direccion de entrega',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              LocationCoordinatePicker(
                initialCoordinates: _addressController.text.trim(),
                onChanged: (value) {
                  setState(() {
                    _addressController.text = value;
                  });
                },
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Observaciones',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _obsController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Ej: llamar antes de llegar.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentAddressCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ubicacion de la cita',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _addressController.text.trim().isEmpty
                  ? 'Esta cita no tiene direccion guardada todavia. Seleccionala en el mapa para continuar.'
                  : 'Usaremos la misma direccion registrada desde citas.',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
            const SizedBox(height: 12),
            LocationCoordinatePicker(
              initialCoordinates: _addressController.text.trim(),
              buttonLabel: 'Usar mi ubicacion actual',
              onChanged: (value) {
                setState(() {
                  _addressController.text = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isPedidoMode && !_orderPlaced
            ? Consumer<CarritoProvider>(
                builder: (context, cartProvider, _) {
                  return Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Total estimado',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        'Bs. ${cartProvider.carrito.totalEstimado.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF6D28D9),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  );
                },
              )
            : Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Total a pagar',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    _isPedidoMode
                        ? 'Bs. ${_pedidoTotal?.toStringAsFixed(2) ?? '0.00'}'
                        : 'Bs. ${double.tryParse(widget.citaData?['price']?.toString() ?? '')?.toStringAsFixed(2) ?? widget.citaData?['price'] ?? '0.00'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF6D28D9),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value == null || value.isEmpty ? '-' : value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
