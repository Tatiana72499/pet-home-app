import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pethome_app/src/core/features/compras/data/services/pago_service.dart';

class PagoProvider extends ChangeNotifier {
  PagoProvider({
    required PagoService pagoService,
  }) : _pagoService = pagoService;

  final PagoService _pagoService;
  final _storage = const FlutterSecureStorage();

  bool isLoading = false;
  bool isPolling = false;
  String? errorMessage;
  String? infoMessage;

  Map<String, dynamic>? createdPedido;
  Map<String, dynamic>? pagoData;
  Map<String, dynamic>? comprobanteData;
  String? checkoutUrl;
  int? currentPagoId;
  bool autoConfirmed = false;

  Timer? _pollingTimer;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  /// Restablece el estado del proveedor.
  void reset() {
    isLoading = false;
    isPolling = false;
    errorMessage = null;
    infoMessage = null;
    createdPedido = null;
    pagoData = null;
    comprobanteData = null;
    checkoutUrl = null;
    currentPagoId = null;
    autoConfirmed = false;
    _pollingTimer?.cancel();
    notifyListeners();
  }

  /// Crea un pedido a partir del carrito.
  Future<bool> crearPedido({
    required String tipoEntrega,
    String? direccionEntrega,
    String? observacion,
    int? citaId,
  }) async {
    isLoading = true;
    errorMessage = null;
    infoMessage = null;
    notifyListeners();

    try {
      final res = await _pagoService.crearPedidoDesdeCarrito(
        tipoEntrega: tipoEntrega,
        direccionEntrega: direccionEntrega,
        observacion: observacion,
        citaId: citaId,
      );
      createdPedido = res;
      notifyListeners();
      return true;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('stock') || msg.contains('insuficiente') || msg.contains('disponibilidad')) {
        errorMessage = 'Stock insuficiente: Algunos productos del carrito superan el stock disponible en almacén principal.';
      } else {
        errorMessage = 'No se pudo generar el pedido. Intente nuevamente.';
      }
      notifyListeners();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Inicia el pago online con Stripe.
  Future<bool> iniciarPagoStripe({
    required String tipoReferencia,
    required int referenciaId,
  }) async {
    isLoading = true;
    errorMessage = null;
    infoMessage = null;
    checkoutUrl = null;
    currentPagoId = null;
    autoConfirmed = false;
    notifyListeners();

    try {
      final res = await _pagoService.iniciarPagoOnline(
        tipoReferencia: tipoReferencia,
        referenciaId: referenciaId,
      );
      currentPagoId = res['pago_id'] as int?;
      checkoutUrl = res['checkout_url'] as String?;
      autoConfirmed = res['auto_confirmed'] == true;
      if (currentPagoId != null) {
        await _storage.write(key: 'last_pending_pago_id', value: currentPagoId.toString());
      }

      // Temporal Sprint Demo: Si fue auto-confirmado, cargar comprobante de forma inmediata.
      if (autoConfirmed && currentPagoId != null) {
        try {
          final detail = await _pagoService.getPagoDetail(currentPagoId!);
          pagoData = detail;
          final comprobante = detail['comprobante'];
          if (comprobante != null && comprobante['id_comprobante'] != null) {
            final idComp = comprobante['id_comprobante'] as int;
            await cargarComprobante(idComp);
          }
        } catch (_) {}
      }

      notifyListeners();
      return true;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('recurso ya cuenta')) {
        errorMessage = 'Pago duplicado: Este recurso ya cuenta con un pago aprobado (PAGADO).';
      } else if (msg.contains('stock') || msg.contains('insuficiente')) {
        errorMessage = 'No se puede pagar: Stock insuficiente para procesar la transacción.';
      } else {
        errorMessage = 'Error al iniciar el pago con Stripe. Intente nuevamente.';
      }
      notifyListeners();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Restaura el ID de pago pendiente guardado en el almacenamiento seguro.
  Future<void> restorePendingPaymentId() async {
    final stored = await _storage.read(key: 'last_pending_pago_id');
    if (stored != null) {
      final idPago = int.tryParse(stored);
      if (idPago != null) {
        currentPagoId = idPago;
        notifyListeners();
      }
    }
  }

  /// Verifica el estado del pago de forma inmediata (por ejemplo al volver de un deep link).
  Future<void> checkPaymentStatus(
    int idPago, {
    required VoidCallback onSuccess,
    required VoidCallback onFailed,
  }) async {
    try {
      final pago = await _pagoService.getPagoDetail(idPago);
      pagoData = pago;
      final estado = pago['estado_pago'] as String?;
      print('[PagoProvider] Estado actual del pago=$estado');

      if (estado == 'PAGADO') {
        _pollingTimer?.cancel();
        isPolling = false;
        await _storage.delete(key: 'last_pending_pago_id');

        final refType = pago['tipo_referencia'] as String?;
        final refId = pago['referencia_id'] as int?;
        if (refType == 'PEDIDO_MOVIL' && refId != null) {
          try {
            final pedido = await _pagoService.getPedido(refId);
            final obs = pedido['observacion'] as String?;
            if (obs != null && obs.contains('REVISION ADMINISTRATIVA')) {
              infoMessage = 'Pago recibido. Tu pedido está en revisión por disponibilidad de stock.';
            }
          } catch (_) {}
        }
        
        final comprobante = pago['comprobante'];
        if (comprobante != null && comprobante['id_comprobante'] != null) {
          final idComp = comprobante['id_comprobante'] as int;
          await cargarComprobante(idComp);
        } else {
          errorMessage = 'Comprobante aún no disponible. Por favor, actualiza tu historial en unos instantes.';
        }
        notifyListeners();
        onSuccess();
      } else if (estado == 'FALLIDO') {
        _pollingTimer?.cancel();
        isPolling = false;
        await _storage.delete(key: 'last_pending_pago_id');
        errorMessage = 'Pago fallido: La transacción fue cancelada o rechazada en la pasarela.';
        notifyListeners();
        onFailed();
      }
    } catch (_) {}
  }

  /// Inicia el polling para verificar el estado de Stripe.
  void startPollingPayment({
    required int idPago,
    required VoidCallback onSuccess,
    required VoidCallback onFailed,
    VoidCallback? onStockRevision,
  }) {
    print('[PagoProvider] Iniciando polling para id_pago=$idPago');
    _pollingTimer?.cancel();
    isPolling = true;
    errorMessage = null;
    infoMessage = null;
    notifyListeners();

    int attempts = 0;
    const maxAttempts = 30; // 60 segundos total (cada 2 seg)

    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      attempts++;
      if (attempts > maxAttempts) {
        timer.cancel();
        isPolling = false;
        await _storage.delete(key: 'last_pending_pago_id');
        infoMessage = 'Webhook demorado: El pago se está procesando. Puedes verificar el estado final en tu historial en unos minutos.';
        notifyListeners();
        return;
      }

      try {
        final pago = await _pagoService.getPagoDetail(idPago);
        pagoData = pago;
        final estado = pago['estado_pago'] as String?;
        print('[PagoProvider] Estado actual del pago=$estado');

        if (estado == 'PAGADO') {
          timer.cancel();
          isPolling = false;
          await _storage.delete(key: 'last_pending_pago_id');

          final refType = pago['tipo_referencia'] as String?;
          final refId = pago['referencia_id'] as int?;
          if (refType == 'PEDIDO_MOVIL' && refId != null) {
            try {
              final pedido = await _pagoService.getPedido(refId);
              final obs = pedido['observacion'] as String?;
              if (obs != null && obs.contains('REVISION ADMINISTRATIVA')) {
                infoMessage = 'Pago recibido. Tu pedido está en revisión por disponibilidad de stock.';
              }
            } catch (_) {}
          }
          
          final comprobante = pago['comprobante'];
          if (comprobante != null && comprobante['id_comprobante'] != null) {
            final idComp = comprobante['id_comprobante'] as int;
            await cargarComprobante(idComp);
          } else {
            errorMessage = 'Comprobante aún no disponible. Por favor, actualiza tu historial en unos instantes.';
          }
          notifyListeners();
          onSuccess();
        } else if (estado == 'FALLIDO') {
          timer.cancel();
          isPolling = false;
          await _storage.delete(key: 'last_pending_pago_id');
          errorMessage = 'Pago fallido: La transacción fue cancelada o rechazada en la pasarela.';
          notifyListeners();
          onFailed();
        } else if (estado == 'RECHAZADO') {
          timer.cancel();
          isPolling = false;
          await _storage.delete(key: 'last_pending_pago_id');
          errorMessage = 'Pago rechazado: Fondos insuficientes o tarjeta denegada.';
          notifyListeners();
          onFailed();
        }
      } catch (e) {
        // Ignorar errores temporales de conexión durante el polling
      }
    });
  }

  /// Carga el comprobante manualmente.
  Future<void> cargarComprobante(int idComprobante) async {
    try {
      final comp = await _pagoService.getComprobante(idComprobante);
      comprobanteData = comp;
      notifyListeners();
    } catch (_) {
      errorMessage = 'Comprobante aún no disponible en el servidor.';
      notifyListeners();
    }
  }

  /// Cancela cualquier polling activo.
  void stopPolling() {
    _pollingTimer?.cancel();
    isPolling = false;
    notifyListeners();
  }
}
