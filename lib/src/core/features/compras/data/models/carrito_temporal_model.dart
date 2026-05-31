import 'detalle_carrito_temporal_model.dart';

class CarritoTemporalModel {
  const CarritoTemporalModel({
    required this.idCarrito,
    required this.estadoCarrito,
    required this.subtotalEstimado,
    required this.totalEstimado,
    this.fechaActualizacion,
    required this.detalles,
  });

  final int idCarrito;
  final String estadoCarrito;
  final double subtotalEstimado;
  final double totalEstimado;
  final DateTime? fechaActualizacion;
  final List<DetalleCarritoTemporalModel> detalles;

  int get cantidadItems => detalles.length;

  factory CarritoTemporalModel.fromJson(Map<String, dynamic> json) {
    final rawDetalles = json['detalles'];
    final detalles = rawDetalles is List
        ? rawDetalles
              .whereType<Map<String, dynamic>>()
              .map(DetalleCarritoTemporalModel.fromJson)
              .toList()
        : <DetalleCarritoTemporalModel>[];

    return CarritoTemporalModel(
      idCarrito: _asInt(json['id_carrito']),
      estadoCarrito: _asString(json['estado_carrito'], fallback: 'ACTIVO'),
      subtotalEstimado: _asDouble(json['subtotal_estimado']),
      totalEstimado: _asDouble(json['total_estimado']),
      fechaActualizacion: _asDateTime(json['fecha_actualizacion']),
      detalles: detalles,
    );
  }

  CarritoTemporalModel copyWith({
    int? idCarrito,
    String? estadoCarrito,
    double? subtotalEstimado,
    double? totalEstimado,
    DateTime? fechaActualizacion,
    List<DetalleCarritoTemporalModel>? detalles,
  }) {
    return CarritoTemporalModel(
      idCarrito: idCarrito ?? this.idCarrito,
      estadoCarrito: estadoCarrito ?? this.estadoCarrito,
      subtotalEstimado: subtotalEstimado ?? this.subtotalEstimado,
      totalEstimado: totalEstimado ?? this.totalEstimado,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      detalles: detalles ?? this.detalles,
    );
  }

  static CarritoTemporalModel empty() {
    return const CarritoTemporalModel(
      idCarrito: 0,
      estadoCarrito: 'ACTIVO',
      subtotalEstimado: 0,
      totalEstimado: 0,
      detalles: <DetalleCarritoTemporalModel>[],
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.').trim()) ?? 0;
  }
  return 0;
}

String _asString(dynamic value, {required String fallback}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return fallback;
  return text;
}

DateTime? _asDateTime(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return null;
  return DateTime.tryParse(text);
}
