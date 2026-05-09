import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/features/auth/data/auth_service.dart';

class AppointmentsService {
  AppointmentsService({
    required AuthService authService,
    http.Client? client,
  }) : _apiClient = ApiClient(authService: authService, client: client);

  final ApiClient _apiClient;

  Future<List<ServiceItem>> getServices() async {
    final data = await _apiClient.getList('/api/gestion/servicios/');
    return data.map((item) => ServiceItem.fromJson(item)).toList();
  }

  Future<List<ServicePrice>> getPrices() async {
    final data =
        await _apiClient.getList('/api/gestion/servicios/precios-servicio/');
    return data.map((item) => ServicePrice.fromJson(item)).toList();
  }

  Future<List<Appointment>> getAppointments() async {
    final data = await _apiClient.getList('/api/gestion/servicios/citas/');
    return data.map((item) => Appointment.fromJson(item)).toList();
  }

  Future<void> createAppointment(AppointmentRequest request) async {
    await _apiClient.send(
      method: 'POST',
      path: '/api/gestion/servicios/citas/',
      body: request.toJson(),
    );
  }

  Future<void> updateAppointment(int id, AppointmentRequest request) async {
    final path = '/api/gestion/servicios/citas/$id/estado/';
    if (kDebugMode) {
      debugPrint('[AppointmentsService] PATCH $path');
    }
    await _apiClient.send(
      method: 'PATCH',
      path: path,
      body: request.toPatchJson(),
    );
  }

  Future<void> cancelAppointment(int id) async {
    await _apiClient.send(
      method: 'DELETE',
      path: '/api/gestion/servicios/citas/$id/',
    );
  }

  Future<List<AvailabilitySlot>> getAvailability({
    required int serviceId,
    required String date,
    required String modality,
  }) async {
    final safeDate = _normalizeDate(date);
    final safeModality = Uri.encodeQueryComponent(modality.trim().toUpperCase());
    final path =
        '/api/gestion/servicios/agenda/?fecha=$safeDate&servicio=$serviceId&modalidad=$safeModality';

    if (kDebugMode) {
      debugPrint('[AppointmentsService] GET $path');
    }

    final response = await _apiClient.send(method: 'GET', path: path);
    final decoded = _apiClient.decode(response);
    return AvailabilitySlot.fromAny(decoded);
  }
}

class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.name,
    required this.active,
    required this.homeAvailable,
  });

  final int id;
  final String name;
  final bool active;
  final bool homeAvailable;

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: _asInt(json['id_servicio']),
      name: json['nombre'] as String? ?? '',
      active: json['estado'] as bool? ?? false,
      homeAvailable: json['disponible_domicilio'] as bool? ?? false,
    );
  }
}

class ServicePrice {
  const ServicePrice({
    required this.id,
    required this.serviceId,
    required this.variation,
    required this.modality,
    required this.price,
    required this.active,
  });

  final int id;
  final int serviceId;
  final String variation;
  final String modality;
  final String price;
  final bool active;

  factory ServicePrice.fromJson(Map<String, dynamic> json) {
    return ServicePrice(
      id: _asInt(json['id_precio']),
      serviceId: _asInt(json['servicio']),
      variation: json['variacion'] as String? ?? '',
      modality: json['modalidad'] as String? ?? 'CLINICA',
      price: json['precio'].toString(),
      active: json['estado'] as bool? ?? false,
    );
  }
}

class Appointment {
  const Appointment({
    required this.id,
    required this.petId,
    required this.serviceId,
    required this.priceId,
    required this.petName,
    required this.serviceName,
    required this.date,
    required this.time,
    required this.modality,
    required this.status,
    this.address,
    this.description,
  });

  final int id;
  final int petId;
  final int serviceId;
  final int priceId;
  final String petName;
  final String serviceName;
  final String date;
  final String time;
  final String modality;
  final String status;
  final String? address;
  final String? description;

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: _asInt(json['id_cita']),
      petId: _asInt(json['mascota']),
      serviceId: _asInt(json['servicio']),
      priceId: _asInt(json['precio_servicio']),
      petName: json['mascota_nombre'] as String? ?? 'Mascota',
      serviceName: json['servicio_nombre'] as String? ?? 'Servicio',
      date: json['fecha_programada'] as String? ?? '',
      time: _shortTime(json['hora_inicio'] as String?),
      modality: json['modalidad'] as String? ?? 'CLINICA',
      status: json['estado'] as String? ?? 'PENDIENTE',
      address: json['direccion_cita'] as String?,
      description: json['descripcion'] as String?,
    );
  }
}

String _shortTime(String? value) {
  if (value == null || value.isEmpty) return '';
  return value.length >= 5 ? value.substring(0, 5) : value;
}

class AppointmentRequest {
  const AppointmentRequest({
    required this.petId,
    required this.serviceId,
    required this.priceId,
    required this.date,
    required this.time,
    this.endTime,
    required this.modality,
    this.estado,
    this.address,
    this.description,
  });

  final int petId;
  final int serviceId;
  final int priceId;
  final String date;
  final String time;
  final String? endTime;
  final String modality;
  final String? estado;
  final String? address;
  final String? description;

  Map<String, dynamic> toJson() => {
        'mascota': petId,
        'servicio': serviceId,
        'precio_servicio': priceId,
        'fecha_programada': _normalizeDate(date),
        'hora_inicio': _normalizeTime(time),
        'modalidad': modality,
        if (estado != null) 'estado': estado,
        'direccion_cita': modality == 'DOMICILIO' ? address : null,
        'descripcion': description,
      };

  Map<String, dynamic> toPatchJson() => {
        'fecha_programada': _normalizeDate(date),
        'hora_inicio': _normalizeTime(time),
        if (endTime != null && endTime!.trim().isNotEmpty)
          'hora_fin': _normalizeTime(endTime!),
      };
}

class AvailabilitySlot {
  const AvailabilitySlot({
    required this.time,
    required this.available,
    this.label,
  });

  final String time;
  final bool available;
  final String? label;

  static List<AvailabilitySlot> fromAny(Object decoded) {
    List<dynamic> raw = <dynamic>[];
    if (decoded is List) {
      raw = decoded;
    } else if (decoded is Map<String, dynamic>) {
      if (decoded['results'] is List) {
        raw = decoded['results'] as List;
      } else if (decoded['slots'] is List) {
        raw = decoded['slots'] as List;
      } else if (decoded['disponibilidad'] is List) {
        raw = decoded['disponibilidad'] as List;
      } else if (decoded['horarios_disponibles'] is List) {
        raw = decoded['horarios_disponibles'] as List;
      }
    }

    return raw.whereType<Map<String, dynamic>>().map((item) {
      final time = (item['hora'] ??
              item['inicio'] ??
              item['hora_inicio'] ??
              item['time'] ??
              item['slot'] ??
              '')
          .toString();
      final available = item.containsKey('inicio')
          ? true
          : _readBool(item['disponible'] ?? item['libre'] ?? item['available']);
      final label = item['etiqueta']?.toString() ??
          ((item['inicio'] != null && item['fin'] != null)
              ? '${item['inicio']} - ${item['fin']}'
              : null);
      return AvailabilitySlot(time: time, available: available, label: label);
    }).toList();
  }
}

bool _readBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return false;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String _normalizeDate(String value) {
  final raw = value.trim();
  if (raw.length >= 10) return raw.substring(0, 10);
  return raw;
}

String _normalizeTime(String value) {
  final raw = value.trim();
  if (raw.isEmpty) return raw;
  if (raw.length == 5) return '$raw:00';
  if (raw.length >= 8) return raw.substring(0, 8);
  return raw;
}
