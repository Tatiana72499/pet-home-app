import 'package:flutter/material.dart';
import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/features/auth/data/auth_service.dart';
import 'package:pethome_app/src/features/tracking/data/tracking_service.dart';
import 'package:pethome_app/src/features/tracking/models/tracking_models.dart';

enum TrackingSection {
  seguimientos,
  pedidos,
}

class TrackingController extends ChangeNotifier {
  TrackingController({required TrackingService service}) : _service = service;

  final TrackingService _service;

  TrackingSection _section = TrackingSection.seguimientos;
  String _search = '';
  bool _isLoadingSeguimientos = false;
  bool _isLoadingPedidos = false;
  String? _seguimientosError;
  String? _pedidosError;
  int? _seguimientosErrorCode;
  int? _pedidosErrorCode;
  bool _loadedAtLeastOnce = false;

  List<SeguimientoItem> _seguimientos = <SeguimientoItem>[];
  List<PedidoListItem> _pedidos = <PedidoListItem>[];

  String? seguimientoTipo;
  String? seguimientoEstado;
  DateTime? seguimientoFechaDesde;
  DateTime? seguimientoFechaHasta;

  String? pedidoEstado;
  String? pedidoTipoEntrega;
  DateTime? pedidoFechaDesde;
  DateTime? pedidoFechaHasta;

  TrackingSection get section => _section;
  String get search => _search;
  bool get isLoadingSeguimientos => _isLoadingSeguimientos;
  bool get isLoadingPedidos => _isLoadingPedidos;
  bool get isLoadingCurrent =>
      _section == TrackingSection.seguimientos ? _isLoadingSeguimientos : _isLoadingPedidos;
  bool get loadedAtLeastOnce => _loadedAtLeastOnce;
  String? get currentError =>
      _section == TrackingSection.seguimientos ? _seguimientosError : _pedidosError;
  int? get currentErrorCode =>
      _section == TrackingSection.seguimientos ? _seguimientosErrorCode : _pedidosErrorCode;

  List<SeguimientoItem> get seguimientosVisible {
    final normalizedSearch = _search.trim().toLowerCase();
    final visibleOnly = _seguimientos.where((item) => item.visibleCliente);
    if (normalizedSearch.isEmpty) return visibleOnly.toList(growable: false);

    return visibleOnly.where((item) {
      final source = <String>[
        item.tipoSeguimiento,
        item.estadoActual,
        item.descripcion ?? '',
        item.cita?.servicio?.nombre ?? '',
        item.pedido == null ? '' : 'Pedido #${item.pedido!.idPedido}',
      ].join(' ').toLowerCase();
      return source.contains(normalizedSearch);
    }).toList(growable: false);
  }

  List<PedidoListItem> get pedidosVisible {
    final normalizedSearch = _search.trim().toLowerCase();
    if (normalizedSearch.isEmpty) return _pedidos;

    return _pedidos.where((item) {
      final source = <String>[
        'Pedido #${item.idPedido}',
        item.estadoPedido,
        item.tipoEntrega,
        item.total,
      ].join(' ').toLowerCase();
      return source.contains(normalizedSearch);
    }).toList(growable: false);
  }

  Future<void> loadInitial() async {
    if (_isLoadingSeguimientos || _isLoadingPedidos) return;
    await Future.wait([
      refreshSeguimientos(),
      refreshPedidos(),
    ]);
    _loadedAtLeastOnce = true;
    notifyListeners();
  }

  void setSection(TrackingSection value) {
    if (_section == value) return;
    _section = value;
    _search = '';
    notifyListeners();
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void setSeguimientoTipo(String? value) {
    seguimientoTipo = _normalizeNullable(value);
    notifyListeners();
  }

  void setSeguimientoEstado(String? value) {
    seguimientoEstado = _normalizeNullable(value);
    notifyListeners();
  }

  void setSeguimientoDesde(DateTime? value) {
    seguimientoFechaDesde = value;
    notifyListeners();
  }

  void setSeguimientoHasta(DateTime? value) {
    seguimientoFechaHasta = value;
    notifyListeners();
  }

  void setPedidoEstado(String? value) {
    pedidoEstado = _normalizeNullable(value);
    notifyListeners();
  }

  void setPedidoTipoEntrega(String? value) {
    pedidoTipoEntrega = _normalizeNullable(value);
    notifyListeners();
  }

  void setPedidoDesde(DateTime? value) {
    pedidoFechaDesde = value;
    notifyListeners();
  }

  void setPedidoHasta(DateTime? value) {
    pedidoFechaHasta = value;
    notifyListeners();
  }

  Future<void> applySeguimientosFilters() async {
    final validationError = _validateDateRange(
      seguimientoFechaDesde,
      seguimientoFechaHasta,
    );
    if (validationError != null) {
      _seguimientosErrorCode = 400;
      _seguimientosError = validationError;
      notifyListeners();
      return;
    }
    await refreshSeguimientos();
  }

  Future<void> clearSeguimientosFilters() async {
    seguimientoTipo = null;
    seguimientoEstado = null;
    seguimientoFechaDesde = null;
    seguimientoFechaHasta = null;
    _seguimientosError = null;
    _seguimientosErrorCode = null;
    notifyListeners();
    await refreshSeguimientos();
  }

  Future<void> applyPedidosFilters() async {
    final validationError = _validateDateRange(pedidoFechaDesde, pedidoFechaHasta);
    if (validationError != null) {
      _pedidosErrorCode = 400;
      _pedidosError = validationError;
      notifyListeners();
      return;
    }
    await refreshPedidos();
  }

  Future<void> clearPedidosFilters() async {
    pedidoEstado = null;
    pedidoTipoEntrega = null;
    pedidoFechaDesde = null;
    pedidoFechaHasta = null;
    _pedidosError = null;
    _pedidosErrorCode = null;
    notifyListeners();
    await refreshPedidos();
  }

  Future<void> refreshCurrent() {
    if (_section == TrackingSection.seguimientos) {
      return refreshSeguimientos();
    }
    return refreshPedidos();
  }

  Future<void> refreshSeguimientos() async {
    _isLoadingSeguimientos = true;
    _seguimientosError = null;
    _seguimientosErrorCode = null;
    notifyListeners();

    try {
      final items = await _service.getSeguimientos(
        filters: SeguimientoFilters(
          tipoSeguimiento: seguimientoTipo,
          estadoActual: seguimientoEstado,
          visibleCliente: true,
          fechaDesde: seguimientoFechaDesde,
          fechaHasta: seguimientoFechaHasta,
        ),
      );
      final sorted = items.where((item) => item.visibleCliente).toList();
      sorted.sort(
        (a, b) => _parseIsoDate(b.fechaHora).compareTo(_parseIsoDate(a.fechaHora)),
      );
      _seguimientos = sorted;
    } on ClientException catch (error) {
      _seguimientosErrorCode = error.statusCode;
      _seguimientosError = _mapErrorMessage(
        statusCode: error.statusCode,
        fallback: error.message,
        forDetail: false,
        resourceName: 'seguimientos',
      );
    } on AuthException catch (error) {
      _seguimientosErrorCode = error.statusCode;
      _seguimientosError = _mapErrorMessage(
        statusCode: error.statusCode,
        fallback: error.message,
        forDetail: false,
        resourceName: 'seguimientos',
      );
    } catch (_) {
      _seguimientosErrorCode = 500;
      _seguimientosError = 'No se pudo cargar el seguimiento en este momento.';
    } finally {
      _isLoadingSeguimientos = false;
      notifyListeners();
    }
  }

  Future<void> refreshPedidos() async {
    _isLoadingPedidos = true;
    _pedidosError = null;
    _pedidosErrorCode = null;
    notifyListeners();

    try {
      _pedidos = await _service.getPedidos(
        filters: PedidoFilters(
          estadoPedido: pedidoEstado,
          tipoEntrega: pedidoTipoEntrega,
          fechaDesde: pedidoFechaDesde,
          fechaHasta: pedidoFechaHasta,
        ),
      );
      _pedidos = _pedidos.toList()
        ..sort(
          (a, b) => _parseIsoDate(b.fechaPedido).compareTo(_parseIsoDate(a.fechaPedido)),
        );
    } on ClientException catch (error) {
      _pedidosErrorCode = error.statusCode;
      _pedidosError = _mapErrorMessage(
        statusCode: error.statusCode,
        fallback: error.message,
        forDetail: false,
        resourceName: 'pedidos',
      );
    } on AuthException catch (error) {
      _pedidosErrorCode = error.statusCode;
      _pedidosError = _mapErrorMessage(
        statusCode: error.statusCode,
        fallback: error.message,
        forDetail: false,
        resourceName: 'pedidos',
      );
    } catch (_) {
      _pedidosErrorCode = 500;
      _pedidosError = 'No se pudieron cargar los pedidos en este momento.';
    } finally {
      _isLoadingPedidos = false;
      notifyListeners();
    }
  }

  static String mapDetailErrorMessage({
    required int? statusCode,
    required String fallback,
    required String resourceName,
  }) {
    return _mapErrorMessage(
      statusCode: statusCode,
      fallback: fallback,
      forDetail: true,
      resourceName: resourceName,
    );
  }

  static String _mapErrorMessage({
    required int? statusCode,
    required String fallback,
    required bool forDetail,
    required String resourceName,
  }) {
    switch (statusCode) {
      case 400:
        return 'Filtros invalidos. Verifica el rango de fechas o los campos seleccionados.';
      case 401:
        return 'Tu sesion vencio. Inicia sesion nuevamente.';
      case 403:
        return 'Sin permisos para acceder a este modulo.';
      case 404:
        if (forDetail) {
          return '${_capitalized(resourceName)} no encontrado.';
        }
        return 'No se encontraron datos para la consulta actual.';
      default:
        if (fallback.trim().isNotEmpty) return fallback;
        return 'No se pudo completar la solicitud.';
    }
  }

  static String? _validateDateRange(DateTime? desde, DateTime? hasta) {
    if (desde == null || hasta == null) return null;
    final fromDate = DateUtils.dateOnly(desde);
    final toDate = DateUtils.dateOnly(hasta);
    if (fromDate.isAfter(toDate)) {
      return 'Rango de fechas invalido: fecha desde no puede ser mayor a fecha hasta.';
    }
    return null;
  }

  static String? _normalizeNullable(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null || cleaned.isEmpty) return null;
    return cleaned;
  }

  static String _capitalized(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return value;
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
  }

  static DateTime _parseIsoDate(String raw) {
    return DateTime.tryParse(raw)?.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}
