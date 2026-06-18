// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pethome_app/src/core/features/compras/data/services/pago_service.dart';
import 'package:pethome_app/src/core/features/compras/presentation/widgets/comprobante_pago_widget.dart';
import 'package:pethome_app/src/core/features/compras/providers/pago_provider.dart';
import 'package:pethome_app/src/core/features/compras/providers/carrito_provider.dart';
import 'package:pethome_app/src/features/auth/data/auth_service.dart';
import 'package:pethome_app/src/utils/open_external_link.dart';

enum CheckoutMode { PEDIDO_MOVIL, CITA_SERVICIO }

class CheckoutPage extends StatelessWidget {
  final CheckoutMode mode;
  final Map<String, dynamic>? citaData;

  const CheckoutPage({
    super.key,
    required this.mode,
    this.citaData,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return ChangeNotifierProvider<PagoProvider>(
      create: (_) => PagoProvider(
        pagoService: PagoService(authService: authService),
      ),
      child: _CheckoutView(mode: mode, citaData: citaData),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  final CheckoutMode mode;
  final Map<String, dynamic>? citaData;

  const _CheckoutView({
    required this.mode,
    this.citaData,
  });

  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> with WidgetsBindingObserver {
  String _tipoEntrega = 'DOMICILIO';
  final _addressController = TextEditingController();
  final _obsController = TextEditingController();

  bool _orderPlaced = false;
  int? _pedidoId;
  double? _pedidoTotal;

  bool _paymentFinished = false;
  bool _paymentSuccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.mode == CheckoutMode.CITA_SERVICIO && widget.citaData != null) {
      _addressController.text = widget.citaData!['address'] ?? '';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    if (state == AppLifecycleState.resumed) {
      final provider = Provider.of<PagoProvider>(context, listen: false);
      if (provider.currentPagoId != null && !_paymentFinished) {
        provider.checkPaymentStatus(
          provider.currentPagoId!,
          onSuccess: () {
            setState(() {
              _paymentFinished = true;
              _paymentSuccess = true;
            });
            if (widget.mode == CheckoutMode.PEDIDO_MOVIL) {
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
    }
  }

  Future<void> _handleConfirmOrder(PagoProvider provider) async {
    if (_tipoEntrega == 'DOMICILIO' && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La dirección es obligatoria para envíos a domicilio.')),
      );
      return;
    }

    print('[Checkout] Iniciando creación de pedido desde carrito');
    final success = await provider.crearPedido(
      tipoEntrega: _tipoEntrega,
      direccionEntrega: _tipoEntrega == 'DOMICILIO' ? _addressController.text.trim() : null,
      observacion: _obsController.text.trim().isNotEmpty ? _obsController.text.trim() : null,
    );

    if (success && provider.createdPedido != null) {
      final order = provider.createdPedido!;
      final idPedido = order['id_pedido'];
      print('[Checkout] Pedido creado o recuperado id=$idPedido');
      setState(() {
        _pedidoId = idPedido as int?;
        _pedidoTotal = double.tryParse(order['total']?.toString() ?? '');
        _orderPlaced = true;
      });
    }
  }

  Future<void> _handleStripePay(PagoProvider provider) async {
    final cartProvider = widget.mode == CheckoutMode.PEDIDO_MOVIL
        ? Provider.of<CarritoProvider>(context, listen: false)
        : null;
    final refId = widget.mode == CheckoutMode.PEDIDO_MOVIL ? _pedidoId : widget.citaData!['id'] as int?;
    final refType = widget.mode == CheckoutMode.PEDIDO_MOVIL ? 'PEDIDO_MOVIL' : 'CITA_SERVICIO';

    if (refId == null) return;

    final success = await provider.iniciarPagoStripe(
      tipoReferencia: refType,
      referenciaId: refId,
    );

    if (success && provider.checkoutUrl != null) {
      print('[Checkout] Pago creado id_pago=${provider.currentPagoId}');

      if (provider.autoConfirmed) {
        // SOLUCIÓN TEMPORAL SPRINT DEMO: Confirmar pago automáticamente para presentación
        print('[DemoPayment] Confirmando pago automáticamente para presentación');
        print('[DemoPayment] Pago marcado como PAGADO');
        print('[DemoPayment] Pedido marcado como CONFIRMADO');
        print('[DemoPayment] Inventario actualizado');
        print('[DemoPayment] Carrito temporal vaciado');
        print('[DemoPayment] Comprobante generado');

        if (widget.mode == CheckoutMode.PEDIDO_MOVIL && cartProvider != null) {
          try {
            cartProvider.clearCarritoLocal();
            await cartProvider.loadCarrito();
          } catch (_) {}
        }

        setState(() {
          _paymentFinished = true;
          _paymentSuccess = true;
        });

        // Dar un pequeño delay de 1.5 segundos para que la UI se actualice a la pantalla de éxito y muestre el ticket de pago antes del redirect de Stripe.
        await Future.delayed(const Duration(milliseconds: 1500));

        print('[Checkout] Abriendo Stripe checkout_url=${provider.checkoutUrl}');
        await openExternalLink(provider.checkoutUrl!);
      } else {
        print('[Checkout] Abriendo Stripe checkout_url=${provider.checkoutUrl}');
        // Abre la URL en el navegador externo de forma asíncrona
        await openExternalLink(provider.checkoutUrl!);

        // Inicia el Polling
        provider.startPollingPayment(
          idPago: provider.currentPagoId!,
          onSuccess: () {
            setState(() {
              _paymentFinished = true;
              _paymentSuccess = true;
            });
            // Vacía el carrito localmente en el móvil si el pago del pedido es exitoso
            if (widget.mode == CheckoutMode.PEDIDO_MOVIL && cartProvider != null) {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PagoProvider>(context);

    // Pantalla de Polling/Procesamiento
    if (provider.isPolling) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F4F5),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 4,
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No cierres esta pantalla ni regreses atrás. Estamos validando la transacción con Stripe.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                    if (provider.infoMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        provider.infoMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFD97706),
                          fontWeight: FontWeight.w600,
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

    // Pantalla de Resultado Exitoso
    if (_paymentFinished && _paymentSuccess) {
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
            'Pago Exitoso',
            style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 72,
                color: Color(0xFF10B981),
              ),
              const SizedBox(height: 12),
              const Text(
                '¡Transacción Completada!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
               Text(
                provider.infoMessage ?? 'Tu pago ha sido validado correctamente. Aquí tienes tu comprobante:',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 24),
              if (provider.comprobanteData != null)
                ComprobantePagoWidget(comprobante: provider.comprobanteData!)
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Comprobante emitido. Verifica tu historial para descargarlo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF4B5563), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6D28D9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Volver al Inicio'),
              ),
            ],
          ),
        ),
      );
    }

    // Pantalla de Error / Intento Fallido
    if (_paymentFinished && !_paymentSuccess) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F4F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF4F4F5),
          elevation: 0,
          title: const Text('Pago Fallido', style: TextStyle(color: Color(0xFF1F2937))),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
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
                      'No se completó la transacción',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.errorMessage ?? 'Ocurrió un error al procesar el pago con Stripe.',
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

    // VISTA PRINCIPAL DE CHECKOUT
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
          widget.mode == CheckoutMode.PEDIDO_MOVIL ? 'Confirmar Pedido' : 'Pago de Servicio',
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Resumen de Cabecera
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.mode == CheckoutMode.PEDIDO_MOVIL ? 'Resumen del Pedido' : 'Detalles de la Cita',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (widget.mode == CheckoutMode.PEDIDO_MOVIL) ...[
                      // En PEDIDO_MOVIL, renderizamos una pequeña información informativa
                      const Row(
                        children: [
                          Icon(Icons.shopping_bag_outlined, color: Color(0xFF6D28D9), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Productos del Carrito',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // El desglose se muestra desde el carrito global
                      Consumer<CarritoProvider>(
                        builder: (context, cartProvider, _) {
                          if (cartProvider.carrito.detalles.isEmpty) {
                            return const Text('No hay items en el carrito.');
                          }
                          return Column(
                            children: cartProvider.carrito.detalles.map((item) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.titulo} x${item.cantidad.toInt()}',
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                                      ),
                                    ),
                                    Text(
                                      'Bs. ${(item.subtotalEstimado).toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ] else ...[
                      // En CITA_SERVICIO, renderizamos detalles de la cita
                      _buildSummaryRow('Servicio', widget.citaData!['serviceName']),
                      _buildSummaryRow('Mascota', widget.citaData!['petName']),
                      _buildSummaryRow('Fecha/Hora', '${widget.citaData!['date']} a las ${widget.citaData!['time']}'),
                      _buildSummaryRow('Modalidad', widget.citaData!['modality']),
                      if (widget.citaData!['address'] != null && widget.citaData!['address'].toString().isNotEmpty)
                        _buildSummaryRow('Dirección Cita', widget.citaData!['address']),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Selector de entrega y dirección (SOLO para PEDIDO_MOVIL y si no se ha confirmado aún)
            if (widget.mode == CheckoutMode.PEDIDO_MOVIL && !_orderPlaced) ...[
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Método de Entrega',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('A Domicilio')),
                              selected: _tipoEntrega == 'DOMICILIO',
                              onSelected: (val) {
                                if (val) setState(() => _tipoEntrega = 'DOMICILIO');
                              },
                              selectedColor: const Color(0xFFF0E7FF),
                              labelStyle: TextStyle(
                                color: _tipoEntrega == 'DOMICILIO' ? const Color(0xFF6D28D9) : const Color(0xFF4B5563),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Recojo en Clínica')),
                              selected: _tipoEntrega == 'RECOJO',
                              onSelected: (val) {
                                if (val) setState(() => _tipoEntrega = 'RECOJO');
                              },
                              selectedColor: const Color(0xFFF0E7FF),
                              labelStyle: TextStyle(
                                color: _tipoEntrega == 'RECOJO' ? const Color(0xFF6D28D9) : const Color(0xFF4B5563),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_tipoEntrega == 'DOMICILIO') ...[
                        const Text(
                          'Dirección de Entrega',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            hintText: 'Av. Las Palmas #456, entre 3er y 4to anillo',
                            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Text(
                        'Observaciones (Opcional)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _obsController,
                        decoration: InputDecoration(
                          hintText: 'Ej: Llamar antes de llegar.',
                          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        style: const TextStyle(fontSize: 13),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Resumen de montos (Validados por Backend)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (widget.mode == CheckoutMode.PEDIDO_MOVIL && !_orderPlaced) ...[
                      // Muestra el total estimado localmente del carrito antes de validar
                      Consumer<CarritoProvider>(
                        builder: (context, cartProvider, _) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Estimado (Carrito):', style: TextStyle(fontWeight: FontWeight.w500)),
                              Text(
                                'Bs. ${(cartProvider.carrito.totalEstimado).toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6D28D9)),
                              ),
                            ],
                          );
                        },
                      ),
                    ] else ...[
                      // Si el pedido ya fue colocado en backend o es cita, muestra el total oficial
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total a Pagar (Confirmado):',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.mode == CheckoutMode.PEDIDO_MOVIL
                                ? 'Bs. ${_pedidoTotal?.toStringAsFixed(2)}'
                                : 'Bs. ${double.tryParse(widget.citaData!['price'].toString())?.toStringAsFixed(2) ?? widget.citaData!['price']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF6D28D9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Errores
            if (provider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    border: Border.all(color: const Color(0xFFFEE2E2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            // Acciones del botón
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator(color: Color(0xFF6D28D9)))
            else if (widget.mode == CheckoutMode.PEDIDO_MOVIL && !_orderPlaced)
              FilledButton(
                onPressed: () => _handleConfirmOrder(provider),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6D28D9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Continuar al Pago', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            else
              FilledButton.icon(
                onPressed: () => _handleStripePay(provider),
                icon: const Icon(Icons.payment_rounded, size: 20),
                label: const Text('Pagar con Stripe', style: TextStyle(fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF635BFF), // Stripe Color
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          Text(value ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
