class SeguimientoItem {
  const SeguimientoItem({
    required this.idSeguimiento,
    required this.tipoSeguimiento,
    required this.estadoActual,
    required this.fechaHora,
    required this.visibleCliente,
    this.estadoAnterior,
    this.descripcion,
    this.usuario,
    this.cita,
    this.pedido,
  });

  final int idSeguimiento;
  final String tipoSeguimiento;
  final String? estadoAnterior;
  final String estadoActual;
  final String? descripcion;
  final String fechaHora;
  final bool visibleCliente;
  final SeguimientoUsuario? usuario;
  final SeguimientoCita? cita;
  final SeguimientoPedidoResumen? pedido;

  factory SeguimientoItem.fromJson(Map<String, dynamic> json) {
    return SeguimientoItem(
      idSeguimiento: _asInt(json['id_seguimiento']),
      tipoSeguimiento: _asString(json['tipo_seguimiento'], fallback: 'N/D'),
      estadoAnterior: _asNullableString(json['estado_anterior']),
      estadoActual: _asString(json['estado_actual'], fallback: 'N/D'),
      descripcion: _asNullableString(json['descripcion']),
      fechaHora: _asString(json['fecha_hora']),
      visibleCliente: _asBool(json['visible_cliente']),
      usuario: _asMap(json['usuario']) == null
          ? null
          : SeguimientoUsuario.fromJson(_asMap(json['usuario'])!),
      cita: _asMap(json['cita']) == null
          ? null
          : SeguimientoCita.fromJson(_asMap(json['cita'])!),
      pedido: _asMap(json['pedido']) == null
          ? null
          : SeguimientoPedidoResumen.fromJson(_asMap(json['pedido'])!),
    );
  }
}

class SeguimientoUsuario {
  const SeguimientoUsuario({
    required this.idUsuario,
    required this.correo,
    this.nombre,
  });

  final int idUsuario;
  final String correo;
  final String? nombre;

  factory SeguimientoUsuario.fromJson(Map<String, dynamic> json) {
    return SeguimientoUsuario(
      idUsuario: _asInt(json['id_usuario']),
      correo: _asString(json['correo']),
      nombre: _asNullableString(json['nombre']),
    );
  }
}

class SeguimientoCita {
  const SeguimientoCita({
    required this.idCita,
    required this.fechaProgramada,
    required this.horaInicio,
    required this.estado,
    this.horaFin,
    this.servicio,
  });

  final int idCita;
  final String fechaProgramada;
  final String horaInicio;
  final String? horaFin;
  final String estado;
  final SeguimientoServicioResumen? servicio;

  factory SeguimientoCita.fromJson(Map<String, dynamic> json) {
    return SeguimientoCita(
      idCita: _asInt(json['id_cita']),
      fechaProgramada: _asString(json['fecha_programada']),
      horaInicio: _asString(json['hora_inicio']),
      horaFin: _asNullableString(json['hora_fin']),
      estado: _asString(json['estado'], fallback: 'N/D'),
      servicio: _asMap(json['servicio']) == null
          ? null
          : SeguimientoServicioResumen.fromJson(_asMap(json['servicio'])!),
    );
  }
}

class SeguimientoServicioResumen {
  const SeguimientoServicioResumen({
    required this.idServicio,
    required this.nombre,
  });

  final int idServicio;
  final String nombre;

  factory SeguimientoServicioResumen.fromJson(Map<String, dynamic> json) {
    return SeguimientoServicioResumen(
      idServicio: _asInt(json['id_servicio']),
      nombre: _asString(json['nombre'], fallback: 'Servicio'),
    );
  }
}

class SeguimientoPedidoResumen {
  const SeguimientoPedidoResumen({
    required this.idPedido,
    required this.fechaPedido,
    required this.estadoPedido,
    required this.tipoEntrega,
    required this.total,
  });

  final int idPedido;
  final String fechaPedido;
  final String estadoPedido;
  final String tipoEntrega;
  final String total;

  factory SeguimientoPedidoResumen.fromJson(Map<String, dynamic> json) {
    return SeguimientoPedidoResumen(
      idPedido: _asInt(json['id_pedido']),
      fechaPedido: _asString(json['fecha_pedido']),
      estadoPedido: _asString(json['estado_pedido'], fallback: 'N/D'),
      tipoEntrega: _asString(json['tipo_entrega'], fallback: 'N/D'),
      total: _asString(json['total'], fallback: '0.00'),
    );
  }
}

class PedidoListItem {
  const PedidoListItem({
    required this.idPedido,
    required this.usuarioId,
    required this.usuarioCorreo,
    required this.fechaPedido,
    required this.tipoEntrega,
    required this.estadoPedido,
    required this.subtotal,
    required this.costoEnvio,
    required this.total,
    this.estadoPago,
    required this.estado,
    this.usuarioNombre,
    this.observacion,
    this.motivoCancelacion,
  });

  final int idPedido;
  final int usuarioId;
  final String usuarioCorreo;
  final String? usuarioNombre;
  final String fechaPedido;
  final String tipoEntrega;
  final String estadoPedido;
  final String subtotal;
  final String costoEnvio;
  final String total;
  final String? estadoPago;
  final String? observacion;
  final String? motivoCancelacion;
  final bool estado;

  factory PedidoListItem.fromJson(Map<String, dynamic> json) {
    return PedidoListItem(
      idPedido: _asInt(json['id_pedido']),
      usuarioId: _asInt(json['usuario_id']),
      usuarioCorreo: _asString(json['usuario_correo']),
      usuarioNombre: _asNullableString(json['usuario_nombre']),
      fechaPedido: _asString(json['fecha_pedido']),
      tipoEntrega: _asString(json['tipo_entrega'], fallback: 'N/D'),
      estadoPedido: _asString(json['estado_pedido'], fallback: 'N/D'),
      subtotal: _asString(json['subtotal'], fallback: '0.00'),
      costoEnvio: _asString(json['costo_envio'], fallback: '0.00'),
      total: _asString(json['total'], fallback: '0.00'),
      estadoPago: _asNullableString(json['estado_pago']),
      observacion: _asNullableString(json['observacion']),
      motivoCancelacion: _asNullableString(json['motivo_cancelacion']),
      estado: _asBool(json['estado'], fallback: true),
    );
  }
}

class PedidoDetail {
  const PedidoDetail({
    required this.idPedido,
    required this.usuarioId,
    required this.usuarioCorreo,
    required this.fechaPedido,
    required this.tipoEntrega,
    required this.estadoPedido,
    required this.subtotal,
    required this.costoEnvio,
    required this.total,
    this.estadoPago,
    required this.estado,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.detalles,
    required this.seguimientos,
    this.usuarioNombre,
    this.observacion,
    this.motivoCancelacion,
    this.direccionEntrega,
  });

  final int idPedido;
  final int usuarioId;
  final String usuarioCorreo;
  final String? usuarioNombre;
  final String fechaPedido;
  final String tipoEntrega;
  final String estadoPedido;
  final String subtotal;
  final String costoEnvio;
  final String total;
  final String? estadoPago;
  final String? observacion;
  final String? motivoCancelacion;
  final bool estado;
  final String? direccionEntrega;
  final String fechaCreacion;
  final String fechaActualizacion;
  final List<PedidoDetalleItem> detalles;
  final List<PedidoSeguimientoItem> seguimientos;

  factory PedidoDetail.fromJson(Map<String, dynamic> json) {
    return PedidoDetail(
      idPedido: _asInt(json['id_pedido']),
      usuarioId: _asInt(json['usuario_id']),
      usuarioCorreo: _asString(json['usuario_correo']),
      usuarioNombre: _asNullableString(json['usuario_nombre']),
      fechaPedido: _asString(json['fecha_pedido']),
      tipoEntrega: _asString(json['tipo_entrega'], fallback: 'N/D'),
      estadoPedido: _asString(json['estado_pedido'], fallback: 'N/D'),
      subtotal: _asString(json['subtotal'], fallback: '0.00'),
      costoEnvio: _asString(json['costo_envio'], fallback: '0.00'),
      total: _asString(json['total'], fallback: '0.00'),
      estadoPago: _asNullableString(json['estado_pago']),
      observacion: _asNullableString(json['observacion']),
      motivoCancelacion: _asNullableString(json['motivo_cancelacion']),
      estado: _asBool(json['estado'], fallback: true),
      direccionEntrega: _asNullableString(json['direccion_entrega']),
      fechaCreacion: _asString(json['fecha_creacion']),
      fechaActualizacion: _asString(json['fecha_actualizacion']),
      detalles: _asListOfMap(json['detalles'])
          .map((item) => PedidoDetalleItem.fromJson(item))
          .toList(),
      seguimientos: _asListOfMap(json['seguimientos'])
          .map((item) => PedidoSeguimientoItem.fromJson(item))
          .toList(),
    );
  }
}

class PedidoDetalleItem {
  const PedidoDetalleItem({
    required this.idDetallePedido,
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    required this.estado,
    this.observacion,
  });

  final int idDetallePedido;
  final int productoId;
  final String productoNombre;
  final int cantidad;
  final String precioUnitario;
  final String subtotal;
  final String? observacion;
  final bool estado;

  factory PedidoDetalleItem.fromJson(Map<String, dynamic> json) {
    return PedidoDetalleItem(
      idDetallePedido: _asInt(json['id_detalle_pedido']),
      productoId: _asInt(json['producto_id']),
      productoNombre: _asString(json['producto_nombre'], fallback: 'Producto'),
      cantidad: _asInt(json['cantidad']),
      precioUnitario: _asString(json['precio_unitario'], fallback: '0.00'),
      subtotal: _asString(json['subtotal'], fallback: '0.00'),
      observacion: _asNullableString(json['observacion']),
      estado: _asBool(json['estado'], fallback: true),
    );
  }
}

class PedidoSeguimientoItem {
  const PedidoSeguimientoItem({
    required this.idSeguimiento,
    required this.tipoSeguimiento,
    required this.estadoActual,
    required this.fechaHora,
    required this.visibleCliente,
    this.estadoAnterior,
    this.descripcion,
  });

  final int idSeguimiento;
  final String tipoSeguimiento;
  final String? estadoAnterior;
  final String estadoActual;
  final String? descripcion;
  final String fechaHora;
  final bool visibleCliente;

  factory PedidoSeguimientoItem.fromJson(Map<String, dynamic> json) {
    return PedidoSeguimientoItem(
      idSeguimiento: _asInt(json['id_seguimiento']),
      tipoSeguimiento: _asString(json['tipo_seguimiento'], fallback: 'N/D'),
      estadoAnterior: _asNullableString(json['estado_anterior']),
      estadoActual: _asString(json['estado_actual'], fallback: 'N/D'),
      descripcion: _asNullableString(json['descripcion']),
      fechaHora: _asString(json['fecha_hora']),
      visibleCliente: _asBool(json['visible_cliente']),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String? _asNullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return fallback;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  return null;
}

List<Map<String, dynamic>> _asListOfMap(dynamic value) {
  if (value is! List) return <Map<String, dynamic>>[];
  return value.whereType<Map<String, dynamic>>().toList(growable: false);
}
