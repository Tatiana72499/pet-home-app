import 'package:flutter/material.dart';
import 'package:pethome_app/src/core/features/compras/data/models/carrito_temporal_model.dart';
import 'package:pethome_app/src/core/features/compras/data/services/carrito_service.dart';
import 'package:pethome_app/src/features/appointments/data/appointments_service.dart';
import 'package:pethome_app/src/features/pets/data/pets_service.dart';

class CarritoProvider extends ChangeNotifier {
  CarritoProvider({
    required CarritoService carritoService,
    required AppointmentsService appointmentsService,
    required PetsService petsService,
  })  : _carritoService = carritoService,
        _appointmentsService = appointmentsService,
        _petsService = petsService;

  final CarritoService _carritoService;
  final AppointmentsService _appointmentsService;
  final PetsService _petsService;
  AppointmentsService get appointmentsService => _appointmentsService;
  PetsService get petsService => _petsService;

  CarritoTemporalModel _carrito = CarritoTemporalModel.empty();
  CarritoTemporalModel get carrito => _carrito;
  List<Appointment> _pendingAppointments = <Appointment>[];
  List<Appointment> get pendingAppointments => _pendingAppointments;

  bool isLoading = false;
  bool isAddingProducto = false;
  bool isAddingServicio = false;
  bool isUpdatingCantidad = false;
  bool isRemovingItem = false;
  bool isClearing = false;
  bool isLoadingAppointments = false;

  String? errorMessage;

  Future<void> loadCarrito() async {
    isLoading = true;
    isLoadingAppointments = true;
    errorMessage = null;
    notifyListeners();

    try {
      _carrito = await _carritoService.getCarrito();
      print('[CarritoProvider] Carrito sincronizado con backend');
    } catch (_) {
      errorMessage = 'No se pudo cargar el carrito.';
    }

    try {
      final appointments = await _appointmentsService.getAppointments();
      _pendingAppointments = appointments
          .where((appointment) => appointment.status == 'PENDIENTE')
          .toList();
    } catch (_) {
      _pendingAppointments = <Appointment>[];
    } finally {
      isLoading = false;
      isLoadingAppointments = false;
      notifyListeners();
    }
  }

  void clearCarritoLocal() {
    _carrito = CarritoTemporalModel.empty();
    print('[CarritoProvider] Carrito local limpiado');
    notifyListeners();
  }

  Future<bool> addProducto({
    required int productoId,
    required String cantidad,
    String? observacion,
  }) async {
    final qty = double.tryParse(cantidad.replaceAll(',', '.')) ?? 0;
    if (productoId <= 0 || qty <= 0) {
      errorMessage = 'No se pudo agregar el producto.';
      notifyListeners();
      return false;
    }

    isAddingProducto = true;
    errorMessage = null;
    notifyListeners();

    try {
      _carrito = await _carritoService.addProductoToCarrito(
        productoId: productoId,
        cantidad: _cleanNumber(cantidad),
        observacion: observacion,
      );
      return true;
    } catch (error) {
      final text = error.toString().toLowerCase();
      if (text.contains('disponible')) {
        errorMessage = 'El producto ya no se encuentra disponible.';
      } else {
        errorMessage = 'No se pudo agregar el producto.';
      }
      return false;
    } finally {
      isAddingProducto = false;
      notifyListeners();
    }
  }

  Future<bool> addServicio({
    required int servicioId,
    required int precioServicioId,
    required int mascotaId,
    String cantidad = '1',
    String? observacion,
  }) async {
    final qty = double.tryParse(cantidad.replaceAll(',', '.')) ?? 0;
    if (servicioId <= 0 || precioServicioId <= 0 || mascotaId <= 0 || qty <= 0) {
      errorMessage = 'Debe seleccionar una mascota para este servicio.';
      notifyListeners();
      return false;
    }

    isAddingServicio = true;
    errorMessage = null;
    notifyListeners();

    try {
      _carrito = await _carritoService.addServicioToCarrito(
        servicioId: servicioId,
        precioServicioId: precioServicioId,
        mascotaId: mascotaId,
        cantidad: _cleanNumber(cantidad),
        observacion: observacion,
      );
      return true;
    } catch (error) {
      final text = error.toString().toLowerCase();
      if (text.contains('mascota')) {
        errorMessage = 'Debe seleccionar una mascota para este servicio.';
      } else if (text.contains('disponible')) {
        errorMessage = 'El servicio no se encuentra disponible.';
      } else {
        errorMessage = 'No se pudo agregar el servicio.';
      }
      return false;
    } finally {
      isAddingServicio = false;
      notifyListeners();
    }
  }

  Future<bool> updateCantidad({
    required int detalleId,
    required String cantidad,
  }) async {
    final qty = double.tryParse(cantidad.replaceAll(',', '.')) ?? 0;
    if (detalleId <= 0 || qty <= 0) {
      errorMessage = 'No se pudo actualizar la cantidad.';
      notifyListeners();
      return false;
    }

    isUpdatingCantidad = true;
    errorMessage = null;
    notifyListeners();

    try {
      _carrito = await _carritoService.updateCantidad(
        detalleId: detalleId,
        cantidad: _cleanNumber(cantidad),
      );
      return true;
    } catch (_) {
      errorMessage = 'No se pudo actualizar la cantidad.';
      return false;
    } finally {
      isUpdatingCantidad = false;
      notifyListeners();
    }
  }

  Future<bool> removeItem({required int detalleId}) async {
    if (detalleId <= 0) {
      errorMessage = 'No se pudo eliminar el item.';
      notifyListeners();
      return false;
    }

    isRemovingItem = true;
    errorMessage = null;
    notifyListeners();

    try {
      _carrito = await _carritoService.removeItem(detalleId: detalleId);
      return true;
    } catch (_) {
      errorMessage = 'No se pudo eliminar el item.';
      return false;
    } finally {
      isRemovingItem = false;
      notifyListeners();
    }
  }

  Future<bool> clearCarrito() async {
    isClearing = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _carritoService.clearCarrito();
      _carrito = _carrito.copyWith(
        subtotalEstimado: 0,
        totalEstimado: 0,
        detalles: const [],
      );
      return true;
    } catch (_) {
      errorMessage = 'No se pudo vaciar el carrito.';
      return false;
    } finally {
      isClearing = false;
      notifyListeners();
    }
  }

  Future<List<Pet>> getMascotas() async {
    return _petsService.getPets();
  }

  Future<List<ServiceItem>> getServiciosActivos() async {
    final services = await _appointmentsService.getServices();
    return services.where((service) => service.active).toList();
  }

  Future<List<ServicePrice>> getPreciosActivos({required int servicioId}) async {
    final prices = await _appointmentsService.getPrices();
    return prices
        .where((price) => price.active && price.serviceId == servicioId)
        .toList();
  }

  String _cleanNumber(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.').trim()) ?? 1;
    if (parsed % 1 == 0) return parsed.toInt().toString();
    return parsed.toString();
  }
}
