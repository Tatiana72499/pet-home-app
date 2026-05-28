import 'package:http/http.dart' as http;
import 'package:pethome_app/src/core/features/compras/data/models/carrito_temporal_model.dart';
import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/features/auth/data/auth_service.dart';

class CarritoService {
  CarritoService({
    required AuthService authService,
    http.Client? client,
  }) : _apiClient = ApiClient(authService: authService, client: client);

  final ApiClient _apiClient;

  static const String _carritoPath = '/api/gestion/ventas-pagos/carrito/';

  Future<CarritoTemporalModel> getCarrito() async {
    final response = await _apiClient.send(method: 'GET', path: _carritoPath);
    final decoded = _apiClient.decode(response);
    final json = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};
    return CarritoTemporalModel.fromJson(json);
  }

  Future<CarritoTemporalModel> addProductoToCarrito({
    required int productoId,
    required String cantidad,
    String? observacion,
  }) async {
    final response = await _apiClient.send(
      method: 'POST',
      path: '${_carritoPath}items/',
      body: <String, dynamic>{
        'tipo_item': 'PRODUCTO',
        'producto': productoId,
        'cantidad': cantidad,
        if (observacion != null && observacion.trim().isNotEmpty)
          'observacion': observacion.trim(),
      },
    );
    final decoded = _apiClient.decode(response);
    final json = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};
    return CarritoTemporalModel.fromJson(json);
  }

  Future<CarritoTemporalModel> addServicioToCarrito({
    required int servicioId,
    required int precioServicioId,
    required int mascotaId,
    String cantidad = '1',
    String? observacion,
  }) async {
    final response = await _apiClient.send(
      method: 'POST',
      path: '${_carritoPath}items/',
      body: <String, dynamic>{
        'tipo_item': 'SERVICIO',
        'servicio': servicioId,
        'precio_servicio': precioServicioId,
        'mascota': mascotaId,
        'cantidad': cantidad,
        if (observacion != null && observacion.trim().isNotEmpty)
          'observacion': observacion.trim(),
      },
    );
    final decoded = _apiClient.decode(response);
    final json = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};
    return CarritoTemporalModel.fromJson(json);
  }

  Future<CarritoTemporalModel> updateCantidad({
    required int detalleId,
    required String cantidad,
  }) async {
    final response = await _apiClient.send(
      method: 'PATCH',
      path: '${_carritoPath}items/$detalleId/',
      body: <String, dynamic>{'cantidad': cantidad},
    );
    final decoded = _apiClient.decode(response);
    final json = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};
    return CarritoTemporalModel.fromJson(json);
  }

  Future<CarritoTemporalModel> removeItem({
    required int detalleId,
  }) async {
    final response = await _apiClient.send(
      method: 'DELETE',
      path: '${_carritoPath}items/$detalleId/',
    );
    final decoded = _apiClient.decode(response);
    final json = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};
    return CarritoTemporalModel.fromJson(json);
  }

  Future<void> clearCarrito() async {
    await _apiClient.send(
      method: 'DELETE',
      path: '${_carritoPath}vaciar/',
    );
  }
}
