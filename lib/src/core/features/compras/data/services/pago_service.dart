import 'package:http/http.dart' as http;
import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/features/auth/data/auth_service.dart';

class PagoService {
  PagoService({
    required AuthService authService,
    http.Client? client,
  }) : _apiClient = ApiClient(authService: authService, client: client);

  final ApiClient _apiClient;

  static const String _pagosPath = '/api/gestion/ventas-pagos/pagos/';
  static const String _comprobantesPath = '/api/gestion/ventas-pagos/comprobantes/';
  static const String _pedidosPath = '/api/gestion/notificaciones/pedidos/';

  /// Inicia una sesión de Stripe para realizar un pago online.
  Future<Map<String, dynamic>> iniciarPagoOnline({
    required String tipoReferencia,
    required int referenciaId,
  }) async {
    final response = await _apiClient.send(
      method: 'POST',
      path: '${_pagosPath}checkout-session/',
      body: <String, dynamic>{
        'tipo_referencia': tipoReferencia,
        'referencia_id': referenciaId,
        'metodo_pago': 'STRIPE',
        'origen': 'MOBILE',
      },
    );
    final decoded = _apiClient.decode(response);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw Exception('Respuesta no válida del servidor al iniciar pago.');
  }

  /// Registra un pago manual en caja (Efectivo/Transferencia/QR).
  Future<Map<String, dynamic>> registrarPagoManual({
    required String tipoReferencia,
    required int referenciaId,
    required String metodoPago,
    String? observacion,
  }) async {
    final response = await _apiClient.send(
      method: 'POST',
      path: '${_pagosPath}confirmar-manual/',
      body: <String, dynamic>{
        'tipo_referencia': tipoReferencia,
        'referencia_id': referenciaId,
        'metodo_pago': metodoPago,
        'observacion': observacion,
      },
    );
    final decoded = _apiClient.decode(response);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw Exception('Respuesta no válida del servidor al registrar pago.');
  }

  /// Obtiene los detalles de un pago específico (para hacer polling de su estado).
  Future<Map<String, dynamic>> getPagoDetail(int idPago) async {
    final response = await _apiClient.send(
      method: 'GET',
      path: '$_pagosPath$idPago/',
    );
    final decoded = _apiClient.decode(response);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw Exception('Error al obtener los detalles del pago.');
  }

  /// Obtiene un comprobante de pago por su ID.
  Future<Map<String, dynamic>> getComprobante(int idComprobante) async {
    final response = await _apiClient.send(
      method: 'GET',
      path: '$_comprobantesPath$idComprobante/',
    );
    final decoded = _apiClient.decode(response);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw Exception('Error al obtener el comprobante.');
  }

  /// Crea un pedido desde el contenido actual del carrito de compras.
  /// Retorna los detalles del pedido creado o del pedido pendiente existente.
  Future<Map<String, dynamic>> crearPedidoDesdeCarrito({
    required String tipoEntrega,
    String? direccionEntrega,
    String? observacion,
  }) async {
    final response = await _apiClient.send(
      method: 'POST',
      path: _pedidosPath,
      body: <String, dynamic>{
        'tipo_entrega': tipoEntrega,
        'direccion_entrega': direccionEntrega,
        'observacion': observacion,
      },
    );
    final decoded = _apiClient.decode(response);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw Exception('Error al crear el pedido.');
  }

  /// Obtiene los detalles de un pedido específico.
  Future<Map<String, dynamic>> getPedido(int idPedido) async {
    final response = await _apiClient.send(
      method: 'GET',
      path: '$_pedidosPath$idPedido/',
    );
    final decoded = _apiClient.decode(response);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw Exception('Error al obtener los detalles del pedido.');
  }
}

