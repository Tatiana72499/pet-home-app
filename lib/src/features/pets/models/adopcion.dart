class Adopcion {
  const Adopcion({
    required this.id,
    required this.nombre,
    required this.ubicacion,
    required this.telefonoContacto,
    required this.estadoAdopcion,
    required this.descripcion,
    required this.estadoSalud,
    required this.especieId,
    required this.especieNombre,
    this.razaId,
    this.razaNombre,
    this.foto,
    this.edadAproximada,
    this.sexo,
    this.tamano,
    this.referenciaUbicacion,
    this.latitud,
    this.longitud,
    this.publicadoPor,
    this.puedeEditar = false,
  });

  final int id;
  final String nombre;
  final String ubicacion;
  final String telefonoContacto;
  final String estadoAdopcion;
  final String descripcion;
  final String estadoSalud;
  final int especieId;
  final String especieNombre;
  final int? razaId;
  final String? razaNombre;
  final String? foto;
  final String? edadAproximada;
  final String? sexo;
  final String? tamano;
  final String? referenciaUbicacion;
  final double? latitud;
  final double? longitud;
  final String? publicadoPor;
  final bool puedeEditar;

  factory Adopcion.fromJson(Map<String, dynamic> json) {
    final especie = json['especie'] as Map<String, dynamic>?;
    final raza = json['raza'] as Map<String, dynamic>?;
    final usuario = json['usuario'] as Map<String, dynamic>?;
    return Adopcion(
      id: _asInt(json['id_adopcion']),
      nombre: (json['nombre'] ?? '').toString(),
      ubicacion: (json['ubicacion'] ?? '').toString(),
      telefonoContacto: (json['telefono_contacto'] ?? '').toString(),
      estadoAdopcion: (json['estado_adopcion'] ?? 'disponible').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      estadoSalud: (json['estado_salud'] ?? '').toString(),
      especieId: _asInt(especie?['id_especie']),
      especieNombre: (especie?['nombre'] ?? 'Especie').toString(),
      razaId: raza?['id_raza'] == null ? null : _asInt(raza?['id_raza']),
      razaNombre: raza?['nombre']?.toString(),
      foto: json['foto']?.toString(),
      edadAproximada: json['edad_aproximada']?.toString(),
      sexo: json['sexo']?.toString(),
      tamano: json['tamano']?.toString(),
      referenciaUbicacion: json['referencia_ubicacion']?.toString(),
      latitud: _asDouble(json['latitud']),
      longitud: _asDouble(json['longitud']),
      publicadoPor: usuario?['nombre']?.toString(),
      puedeEditar: json['puede_editar'] == true,
    );
  }
}

class AdopcionRequest {
  const AdopcionRequest({
    required this.nombre,
    required this.especieId,
    required this.ubicacion,
    required this.telefonoContacto,
    required this.descripcion,
    required this.estadoSalud,
    this.razaId,
    this.foto,
    this.edadAproximada,
    this.sexo,
    this.tamano,
    this.referenciaUbicacion,
    this.latitud,
    this.longitud,
    this.estadoAdopcion,
  });

  final String nombre;
  final int especieId;
  final String ubicacion;
  final String telefonoContacto;
  final String descripcion;
  final String estadoSalud;
  final int? razaId;
  final String? foto;
  final String? edadAproximada;
  final String? sexo;
  final String? tamano;
  final String? referenciaUbicacion;
  final double? latitud;
  final double? longitud;
  final String? estadoAdopcion;

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'especie_id': especieId,
    'raza_id': razaId,
    'ubicacion': ubicacion,
    'telefono_contacto': telefonoContacto,
    'referencia_ubicacion': referenciaUbicacion,
    'latitud': latitud,
    'longitud': longitud,
    'descripcion': descripcion,
    'estado_salud': estadoSalud,
    'foto': foto,
    'edad_aproximada': edadAproximada,
    'sexo': sexo,
    'tamano': tamano,
    if (estadoAdopcion != null) 'estado_adopcion': estadoAdopcion,
  };
}

String estadoAdopcionLabel(String value) {
  switch (value) {
    case 'en_proceso':
      return 'En proceso';
    case 'adoptado':
      return 'Adoptado';
    case 'inactivo':
      return 'Inactivo';
    default:
      return 'Disponible';
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double? _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
