class ClinicalHistory {
  final int idHistorialClinico;
  final int mascotaId;
  final String mascotaNombre;
  final String mascotaEspecie;
  final String? mascotaRaza;
  final int propietarioId;
  final String propietarioNombre;
  final String? observacionesGenerales;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final bool estado;
  final List<ClinicalConsultation> consultasClinicas;

  const ClinicalHistory({
    required this.idHistorialClinico,
    required this.mascotaId,
    required this.mascotaNombre,
    required this.mascotaEspecie,
    this.mascotaRaza,
    required this.propietarioId,
    required this.propietarioNombre,
    this.observacionesGenerales,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.estado,
    required this.consultasClinicas,
  });

  factory ClinicalHistory.fromJson(Map<String, dynamic> json) {
    return ClinicalHistory(
      idHistorialClinico: _parseInt(json['id_historial_clinico']),
      mascotaId: _parseInt(json['mascota_id']),
      mascotaNombre: _parseString(json['mascota_nombre']) ?? 'Mascota',
      mascotaEspecie: _parseString(json['mascota_especie']) ?? 'Especie',
      mascotaRaza: _parseString(json['mascota_raza']),
      propietarioId: _parseInt(json['propietario_id']),
      propietarioNombre: _parseString(json['propietario_nombre']) ?? 'Propietario',
      observacionesGenerales: _parseString(json['observaciones_generales']),
      fechaCreacion: _parseDateTime(json['fecha_creacion']) ?? DateTime.now(),
      fechaActualizacion: _parseDateTime(json['fecha_actualizacion']) ?? DateTime.now(),
      estado: _parseBool(json['estado']),
      consultasClinicas: (json['consultas_clinicas'] as List<dynamic>?)
              ?.map((item) => ClinicalConsultation.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ClinicalConsultation {
  final int idConsultaClinica;
  final int historialClinicoId;
  final int? citaId;
  final String? veterinarioNombre;
  final String? motivo;
  final String? diagnostico;
  final String? observaciones;
  final DateTime? fechaConsulta;
  final double? peso;
  final double? temperatura;
  final int? frecuenciaCardiaca;
  final int? frecuenciaRespiratoria;
  final DateTime? proximaRevision;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final bool estado;
  final List<Treatment> tratamientos;
  final Recipe? receta;
  final List<AppliedVaccine> vacunasAplicadas;
  final List<ClinicalFile> archivosClinico;

  const ClinicalConsultation({
    required this.idConsultaClinica,
    required this.historialClinicoId,
    this.citaId,
    this.veterinarioNombre,
    this.motivo,
    this.diagnostico,
    this.observaciones,
    this.fechaConsulta,
    this.peso,
    this.temperatura,
    this.frecuenciaCardiaca,
    this.frecuenciaRespiratoria,
    this.proximaRevision,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.estado,
    required this.tratamientos,
    this.receta,
    required this.vacunasAplicadas,
    required this.archivosClinico,
  });

  factory ClinicalConsultation.fromJson(Map<String, dynamic> json) {
    return ClinicalConsultation(
      idConsultaClinica: _parseInt(json['id_consulta_clinica']),
      historialClinicoId: _parseInt(json['historial_clinico']),
      citaId: _parseNullableInt(json['cita']),
      veterinarioNombre: _parseString(json['veterinario_nombre']),
      motivo: _parseString(json['motivo_consulta']),
      diagnostico: _parseString(json['diagnostico']),
      observaciones: _parseString(json['observaciones']),
      fechaConsulta: _parseDateTime(json['fecha_consulta']),
      peso: _parseNullableDouble(json['peso']),
      temperatura: _parseNullableDouble(json['temperatura']),
      frecuenciaCardiaca: _parseNullableInt(json['frecuencia_cardiaca']),
      frecuenciaRespiratoria: _parseNullableInt(json['frecuencia_respiratoria']),
      proximaRevision: _parseDateTime(json['proxima_revision']),
      fechaCreacion: _parseDateTime(json['fecha_creacion']) ?? DateTime.now(),
      fechaActualizacion: _parseDateTime(json['fecha_actualizacion']) ?? DateTime.now(),
      estado: _parseBool(json['estado']),
      tratamientos: (json['tratamientos'] as List<dynamic>?)
              ?.map((item) => Treatment.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      receta: json['receta'] != null ? Recipe.fromJson(json['receta'] as Map<String, dynamic>) : null,
      vacunasAplicadas: (json['vacunas_aplicadas'] as List<dynamic>?)
              ?.map((item) => AppliedVaccine.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      archivosClinico: (json['archivos_clinicos'] as List<dynamic>?)
              ?.map((item) => ClinicalFile.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Treatment {
  final int idTratamiento;
  final String nombre;
  final String? descripcion;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final bool estado;

  const Treatment({
    required this.idTratamiento,
    required this.nombre,
    this.descripcion,
    this.fechaInicio,
    this.fechaFin,
    required this.estado,
  });

  factory Treatment.fromJson(Map<String, dynamic> json) {
    return Treatment(
      idTratamiento: _parseInt(json['id_tratamiento']),
      nombre: _parseString(json['tipo']) ?? _parseString(json['nombre']) ?? 'Tratamiento',
      descripcion: _parseString(json['descripcion']),
      fechaInicio: _parseDateTime(json['fecha_ini'] ?? json['fecha_inicio']),
      fechaFin: _parseDateTime(json['fecha_fin']),
      estado: _parseBool(json['estado']),
    );
  }
}

class Recipe {
  final int idReceta;
  final List<RecipeDetail> detalles;
  final String? observaciones;
  final DateTime? fechaExpiracion;

  const Recipe({
    required this.idReceta,
    required this.detalles,
    this.observaciones,
    this.fechaExpiracion,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      idReceta: _parseInt(json['id_receta']),
      detalles: (json['detalles'] as List<dynamic>?)
              ?.map((item) => RecipeDetail.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      observaciones: _parseString(json['observacion']) ?? _parseString(json['observaciones']),
      fechaExpiracion: _parseDateTime(json['fecha']) ?? _parseDateTime(json['fecha_expiracion']),
    );
  }
}

class RecipeDetail {
  final int idDetalleReceta;
  final String medicamento;
  final String? dosis;
  final String? frecuencia;
  final int? diasDuracion;

  const RecipeDetail({
    required this.idDetalleReceta,
    required this.medicamento,
    this.dosis,
    this.frecuencia,
    this.diasDuracion,
  });

  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    return RecipeDetail(
      idDetalleReceta: _parseInt(json['id_detalle_receta']),
      medicamento: json['medicamento'] as String,
      dosis: json['dosis'] as String?,
      frecuencia: json['frecuencia'] as String?,
      diasDuracion: _parseNullableInt(json['dias_duracion']),
    );
  }
}

class AppliedVaccine {
  final int idVacunaAplicada;
  final String nombreVacuna;
  final DateTime? fechaAplicacion;
  final String? proximaDosis;

  const AppliedVaccine({
    required this.idVacunaAplicada,
    required this.nombreVacuna,
    this.fechaAplicacion,
    this.proximaDosis,
  });

  factory AppliedVaccine.fromJson(Map<String, dynamic> json) {
    return AppliedVaccine(
      idVacunaAplicada: _parseInt(json['id_vacuna_aplicada']),
      nombreVacuna: _parseString(json['nombre_vacuna']) ?? 'Vacuna',
      fechaAplicacion: _parseDateTime(json['fecha_aplicada'] ?? json['fecha_aplicacion']),
      proximaDosis: _parseString(json['fecha_proxima']) ?? _parseString(json['proxima_dosis']),
    );
  }
}

class ClinicalFile {
  final int idArchivoClinico;
  final String nombre;
  final String? urlArchivo;
  final String? tipo;
  final DateTime? fechaCreacion;

  const ClinicalFile({
    required this.idArchivoClinico,
    required this.nombre,
    this.urlArchivo,
    this.tipo,
    this.fechaCreacion,
  });

  factory ClinicalFile.fromJson(Map<String, dynamic> json) {
    return ClinicalFile(
      idArchivoClinico: _parseInt(json['id_archivo_clinico']),
      nombre: _parseString(json['nombre_archivo']) ?? _parseString(json['nombre']) ?? 'Archivo',
      urlArchivo: _parseString(json['archivo']) ?? _parseString(json['url_archivo']),
      tipo: _parseString(json['tipo_archivo']) ?? _parseString(json['tipo']),
      fechaCreacion: _parseDateTime(json['fecha_subida'] ?? json['fecha_creacion']),
    );
  }
}

int _parseInt(Object? value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is num) return value.toInt();
  if (value is String) return int.parse(value);
  throw FormatException('No se pudo convertir a int: $value');
}

int? _parseNullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is num) return value.toInt();
  if (value is String) {
    if (value.trim().isEmpty) return null;
    return int.parse(value);
  }
  throw FormatException('No se pudo convertir a int: $value');
}

double? _parseNullableDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) {
    if (value.trim().isEmpty) return null;
    return double.parse(value);
  }
  throw FormatException('No se pudo convertir a double: $value');
}

bool _parseBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toUpperCase();
    return normalized == 'TRUE' ||
        normalized == '1' ||
        normalized == 'ACTIVO' ||
        normalized == 'ACTIVE';
  }
  return false;
}

String? _parseString(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

DateTime? _parseDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return DateTime.parse(text);
}