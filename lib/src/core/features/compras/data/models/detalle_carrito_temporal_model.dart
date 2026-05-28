class DetalleCarritoTemporalModel {
  const DetalleCarritoTemporalModel({
    required this.idDetalleCarrito,
    required this.tipoItem,
    this.producto,
    this.productoNombre,
    this.servicio,
    this.servicioNombre,
    this.precioServicio,
    this.mascota,
    this.mascotaNombre,
    required this.descripcionItem,
    required this.cantidad,
    required this.precioUnitarioEstimado,
    required this.subtotalEstimado,
    this.observacion,
  });

  final int idDetalleCarrito;
  final String tipoItem;
  final int? producto;
  final String? productoNombre;
  final int? servicio;
  final String? servicioNombre;
  final int? precioServicio;
  final int? mascota;
  final String? mascotaNombre;
  final String descripcionItem;
  final double cantidad;
  final double precioUnitarioEstimado;
  final double subtotalEstimado;
  final String? observacion;

  bool get esProducto => tipoItem.toUpperCase() == 'PRODUCTO';
  bool get esServicio => tipoItem.toUpperCase() == 'SERVICIO';

  String get titulo {
    if (esProducto && productoNombre != null && productoNombre!.isNotEmpty) {
      return productoNombre!;
    }
    if (esServicio && servicioNombre != null && servicioNombre!.isNotEmpty) {
      return servicioNombre!;
    }
    if (descripcionItem.trim().isNotEmpty) return descripcionItem.trim();
    return 'Item';
  }

  factory DetalleCarritoTemporalModel.fromJson(Map<String, dynamic> json) {
    return DetalleCarritoTemporalModel(
      idDetalleCarrito: _asInt(json['id_detalle_carrito']),
      tipoItem: (json['tipo_item'] ?? '').toString(),
      producto: _asNullableInt(json['producto']),
      productoNombre: _asNullableString(json['producto_nombre']),
      servicio: _asNullableInt(json['servicio']),
      servicioNombre: _asNullableString(json['servicio_nombre']),
      precioServicio: _asNullableInt(json['precio_servicio']),
      mascota: _asNullableInt(json['mascota']),
      mascotaNombre: _asNullableString(json['mascota_nombre']),
      descripcionItem: (json['descripcion_item'] ?? '').toString(),
      cantidad: _asDouble(json['cantidad']),
      precioUnitarioEstimado: _asDouble(json['precio_unitario_estimado']),
      subtotalEstimado: _asDouble(json['subtotal_estimado']),
      observacion: _asNullableString(json['observacion']),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is String && value.trim().isEmpty) return null;
  return _asInt(value);
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.').trim()) ?? 0;
  }
  return 0;
}

String? _asNullableString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return null;
  return text;
}
