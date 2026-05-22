import 'package:flutter/foundation.dart';

enum TipoMascotaCatalogo { perro, gato, ave, roedor, pez, otro }

enum TipoDescuentoCatalogo { porcentaje, montoFijo, precioEspecial }

class CatalogoProducto {
  const CatalogoProducto({
    required this.idProducto,
    required this.nombre,
    required this.descripcion,
    required this.precioVenta,
    this.precioCompra,
    this.imagen,
    required this.visibleCatalogo,
    required this.estado,
    required this.categoria,
    this.proveedor,
    this.tipoMascota,
    required this.destacado,
    this.novedadDesde,
    this.novedadHasta,
    required this.promocionActiva,
    this.tipoDescuento,
    this.porcentajeDescuento,
    this.montoDescuento,
    this.precioPromocional,
    this.promocionFechaInicio,
    this.promocionFechaFin,
  });

  final int idProducto;
  final String nombre;
  final String descripcion;
  final double precioVenta;
  final double? precioCompra;
  final String? imagen;
  final bool visibleCatalogo;
  final bool estado;
  final String categoria;
  final String? proveedor;
  final TipoMascotaCatalogo? tipoMascota;
  final bool destacado;
  final DateTime? novedadDesde;
  final DateTime? novedadHasta;
  final bool promocionActiva;
  final TipoDescuentoCatalogo? tipoDescuento;
  final double? porcentajeDescuento;
  final double? montoDescuento;
  final double? precioPromocional;
  final DateTime? promocionFechaInicio;
  final DateTime? promocionFechaFin;

  bool get esNovedadActiva {
    if (novedadDesde == null && novedadHasta == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final desdeOk =
        novedadDesde == null || !today.isBefore(_dateOnly(novedadDesde!));
    final hastaOk =
        novedadHasta == null || !today.isAfter(_dateOnly(novedadHasta!));
    return desdeOk && hastaOk;
  }

  bool get tienePromocionActiva {
    if (!promocionActiva) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final desdeOk =
        promocionFechaInicio == null ||
        !today.isBefore(_dateOnly(promocionFechaInicio!));
    final hastaOk =
        promocionFechaFin == null ||
        !today.isAfter(_dateOnly(promocionFechaFin!));
    return desdeOk && hastaOk;
  }

  double get precioVisible {
    if (tienePromocionActiva &&
        tipoDescuento == TipoDescuentoCatalogo.precioEspecial &&
        precioPromocional != null) {
      return precioPromocional!;
    }

    if (tienePromocionActiva &&
        tipoDescuento == TipoDescuentoCatalogo.porcentaje &&
        porcentajeDescuento != null) {
      return precioVenta * (1 - (porcentajeDescuento! / 100));
    }

    if (tienePromocionActiva &&
        tipoDescuento == TipoDescuentoCatalogo.montoFijo &&
        montoDescuento != null) {
      final discounted = precioVenta - montoDescuento!;
      return discounted > 0 ? discounted : 0;
    }

    return precioVenta;
  }

  String get etiquetaPromocion {
    if (!tienePromocionActiva) return '';

    switch (tipoDescuento) {
      case TipoDescuentoCatalogo.porcentaje:
        return porcentajeDescuento == null
            ? 'Promo'
            : '${porcentajeDescuento!.round()}% off';
      case TipoDescuentoCatalogo.montoFijo:
        return montoDescuento == null
            ? 'Promo'
            : '-Bs ${montoDescuento!.toStringAsFixed(0)}';
      case TipoDescuentoCatalogo.precioEspecial:
        return precioPromocional == null ? 'Promo' : 'Precio especial';
      case null:
        return 'Promo';
    }
  }

  factory CatalogoProducto.fromJson(
    Map<String, dynamic> json, {
    String? baseUrl,
  }) {
    final rawImage =
        json['imagen'] ??
        json['imagen_url'] ??
        json['imagenUrl'] ??
        json['imagen_producto'] ??
        json['imagenProducto'] ??
        json['foto'] ??
        json['foto_url'] ??
        json['fotoUrl'] ??
        json['image'] ??
        json['imageUrl'];
    final resolvedImage = _resolveImage(rawImage, baseUrl);

    if (kDebugMode) {
      debugPrint(
        '[CatalogoProducto] id=${json['id_producto'] ?? json['idProducto']} nombre=${json['nombre']} imagen=$rawImage resuelta=$resolvedImage',
      );
    }

    return CatalogoProducto(
      idProducto: _asInt(json['id_producto'] ?? json['idProducto']),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      precioVenta: _asDouble(json['precio_venta'] ?? json['precioVenta']),
      precioCompra: _asNullableDouble(
        json['precio_compra'] ?? json['precioCompra'],
      ),
      imagen: resolvedImage,
      visibleCatalogo: _asBool(
        json['visible_catalogo'] ?? json['visibleCatalogo'],
      ),
      estado: _readEstado(json['estado']),
      categoria:
          (json['categoria_nombre'] ??
                  json['categoria'] ??
                  json['categoriaProducto'] ??
                  'Producto')
              .toString(),
      proveedor: _emptyAsNull(json['proveedor_nombre'] ?? json['proveedor']),
      tipoMascota: _tipoMascotaFromJson(
        json['tipo_mascota'] ?? json['tipoMascota'],
      ),
      destacado: _asBool(json['destacado']),
      novedadDesde: _parseDate(json['novedad_desde'] ?? json['novedadDesde']),
      novedadHasta: _parseDate(json['novedad_hasta'] ?? json['novedadHasta']),
      promocionActiva: _asBool(
        json['tiene_promocion'] ??
            json['promocionActiva'] ??
            json['promocion_activa'],
      ),
      tipoDescuento: _tipoDescuentoFromJson(
        json['tipo_descuento'] ?? json['tipoDescuento'],
      ),
      porcentajeDescuento: _asNullableDouble(
        json['porcentaje_descuento'] ?? json['porcentajeDescuento'],
      ),
      montoDescuento: _asNullableDouble(
        json['monto_descuento'] ?? json['montoDescuento'],
      ),
      precioPromocional: _asNullableDouble(
        json['precio_promocional'] ?? json['precioPromocional'],
      ),
      promocionFechaInicio: _parseDate(
        json['promocion_fecha_inicio'] ?? json['promocionFechaInicio'],
      ),
      promocionFechaFin: _parseDate(
        json['promocion_fecha_fin'] ?? json['promocionFechaFin'],
      ),
    );
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String? _resolveImage(dynamic value, String? baseUrl) {
  final raw = _emptyAsNull(value);
  if (raw == null) return null;

  final lower = raw.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return _normalizeLocalImageHost(raw, baseUrl);
  }

  if (lower.startsWith('assets/') || lower.startsWith('asset:')) {
    return raw;
  }

  final cleanBase = baseUrl?.trim();
  if (cleanBase == null || cleanBase.isEmpty) return raw;

  final baseUri = Uri.tryParse(cleanBase);
  final originBase = baseUri == null
      ? cleanBase.endsWith('/')
          ? cleanBase.substring(0, cleanBase.length - 1)
          : cleanBase
      : '${baseUri.scheme}://${baseUri.authority}';

  final normalizedRaw = raw.startsWith('/') ? raw : '/$raw';

  if (normalizedRaw.startsWith('/media/') ||
      normalizedRaw.startsWith('/productos/')) {
    return '$originBase$normalizedRaw';
  }

  if (raw.startsWith('/')) return '$originBase$raw';
  return '$originBase/$raw';
}

String _normalizeLocalImageHost(String raw, String? baseUrl) {
  final base = _emptyAsNull(baseUrl);
  if (base == null) return raw;

  final imageUri = Uri.tryParse(raw);
  final baseUri = Uri.tryParse(base);
  if (imageUri == null || baseUri == null) return raw;

  final imageHost = imageUri.host.toLowerCase();
  final baseHost = baseUri.host.toLowerCase();
  final isLocalImage =
      imageHost == 'localhost' ||
      imageHost == '127.0.0.1' ||
      imageHost == '10.0.2.2';

  if (!isLocalImage || baseHost.isEmpty || imageHost == baseHost) {
    return raw;
  }

  final imageOrigin = '${imageUri.scheme}://${imageUri.authority}';
  final baseOrigin = '${baseUri.scheme}://${baseUri.authority}';
  return raw.replaceFirst(imageOrigin, baseOrigin);
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _asDouble(dynamic value) => _asNullableDouble(value) ?? 0;

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.replaceAll(',', '.'));
  return null;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'activo' ||
        normalized == 'si';
  }
  return false;
}

bool _readEstado(dynamic value) {
  if (value is bool) return value;
  if (value is String) return value.trim().toLowerCase() != 'inactivo';
  return true;
}

String? _emptyAsNull(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return null;
  return text;
}

DateTime? _parseDate(dynamic value) {
  final text = _emptyAsNull(value);
  if (text == null) return null;
  return DateTime.tryParse(text);
}

TipoMascotaCatalogo? _tipoMascotaFromJson(dynamic value) {
  final text = _emptyAsNull(value)?.toUpperCase();
  switch (text) {
    case 'PERRO':
      return TipoMascotaCatalogo.perro;
    case 'GATO':
      return TipoMascotaCatalogo.gato;
    case 'AVE':
      return TipoMascotaCatalogo.ave;
    case 'ROEDOR':
      return TipoMascotaCatalogo.roedor;
    case 'PEZ':
      return TipoMascotaCatalogo.pez;
    case 'OTRO':
      return TipoMascotaCatalogo.otro;
    default:
      return null;
  }
}

TipoDescuentoCatalogo? _tipoDescuentoFromJson(dynamic value) {
  final text = _emptyAsNull(value)?.toUpperCase();
  switch (text) {
    case 'PORCENTAJE':
      return TipoDescuentoCatalogo.porcentaje;
    case 'MONTO_FIJO':
      return TipoDescuentoCatalogo.montoFijo;
    case 'PRECIO_ESPECIAL':
      return TipoDescuentoCatalogo.precioEspecial;
    default:
      return null;
  }
}
