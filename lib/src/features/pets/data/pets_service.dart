import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/features/auth/data/auth_service.dart';
import 'package:pethome_app/src/features/pets/models/clinical_history.dart';

class PetsService {
  PetsService({
    required AuthService authService,
    http.Client? client,
  })  : _authService = authService,
        _client = client ?? http.Client(),
        _apiClient = ApiClient(authService: authService, client: client);

  final AuthService _authService;
  final http.Client _client;
  final ApiClient _apiClient;

  String get baseUrl => _authService.baseUrl;

  Future<List<PetSpecies>> getSpecies() async {
    final data = await _getCatalogListWithFallback(
      primaryPath: '/api/gestion/servicios/especies/',
      fallbackPath: '/api/gestion/clientes/especies/', 
    );
    return data.whereType<Map<String, dynamic>>().map(PetSpecies.fromJson).toList();
  }

  Future<List<PetBreed>> getBreeds({int? speciesId}) async {
    final query = speciesId == null ? '' : '?especie_id=$speciesId';
    final path = '/api/gestion/servicios/razas/$query';
    if (kDebugMode) {
      debugPrint('breeds_url=$path');
    }

    final raw = await _getCatalogListWithFallback(
      primaryPath: path,
      fallbackPath: '/api/gestion/clientes/razas/$query', 
    );

    final breeds = raw
        .whereType<Map<String, dynamic>>()
        .map((item) => PetBreed.fromJson(item))
        .toList();

    if (kDebugMode) {
      debugPrint('breeds_parsed_count=${breeds.length}');
    }
    return breeds;
  }

  Future<List<dynamic>> _getCatalogListWithFallback({
    required String primaryPath,
    required String fallbackPath,
  }) async {
    final first = await _catalogGet(primaryPath);
    if (first.statusCode == 404) {
      final second = await _catalogGet(fallbackPath);
      return _extractCatalogList(second);
    }
    return _extractCatalogList(first);
  }

  Future<http.Response> _catalogGet(String path) async {
    var headers = await _authService.authorizedHeaders();
    final uri = Uri.parse('${_authService.baseUrl}$path');

    var response = await _client.get(uri, headers: headers);
    if (response.statusCode == 401) {
      await _authService.refreshToken();
      headers = await _authService.authorizedHeaders();
      response = await _client.get(uri, headers: headers);
    }
    return response;
  }

  List<dynamic> _extractCatalogList(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (_looksLikeHtml(response)) {
        throw ClientException(
          'Catalogo no disponible temporalmente. Intenta nuevamente en unos minutos.',
          statusCode: response.statusCode,
        );
      }
      throw ClientException(
        _extractErrorMessage(_safeDecode(response.body)),
        statusCode: response.statusCode,
      );
    }

    if (_looksLikeHtml(response)) {
      throw const ClientException(
        'Catalogo no disponible temporalmente. Intenta nuevamente en unos minutos.',
      );
    }

    final decoded = _safeDecode(response.body);
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic> && decoded['results'] is List) {
      return decoded['results'] as List;
    }
    return <dynamic>[];
  }

  Object _safeDecode(String body) {
    try {
      if (body.trim().isEmpty) return <String, dynamic>{};
      return jsonDecode(body);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  bool _looksLikeHtml(http.Response response) {
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    final body = response.body.trimLeft().toLowerCase();
    return contentType.contains('text/html') ||
        body.startsWith('<!doctype html') ||
        body.startsWith('<html');
  }

  Future<List<Pet>> getPets() async {
    final data = await _apiClient.getList('/api/gestion/clientes/mascotas/');
    if (kDebugMode && data.isNotEmpty) {
      debugPrint('[PetsService] getPets first payload: ${data.first}');
    }
    return data.map((item) => Pet.fromJson(item)).toList();
  }

  Future<PetProfileData> getPetProfile(int petId) async {
    final response = await _catalogGet('/api/gestion/clientes/mascotas/$petId/perfil/');
    final decoded = _extractJsonMapOrThrow(response);
    return PetProfileData.fromJson(decoded);
  }

  Future<PetHistoryData> getPetHistory(int petId, {String? estado}) async {
    final suffix = (estado == null || estado.trim().isEmpty)
        ? ''
        : '?estado=${Uri.encodeQueryComponent(estado.trim())}';
    final response = await _catalogGet(
      '/api/gestion/clientes/mascotas/$petId/historial/$suffix',
    );
    final decoded = _extractJsonMapOrThrow(response);
    return PetHistoryData.fromJson(decoded);
  }

  Future<ClinicalHistory> getClinicalHistory(int petId) async {
    final response = await _catalogGet('/api/gestion/clinica/mascotas/$petId/historial/');
    final decoded = _extractJsonMapOrThrow(response);
    return ClinicalHistory.fromJson(decoded);
  }

  Future<void> createPet(CreatePetRequest request) async {
    if (kDebugMode) {
      debugPrint('pet_create_payload=${request.toJson()}');
    }
    await _apiClient.send(
      method: 'POST',
      path: '/api/gestion/clientes/mascotas/',
      body: request.toJson(),
    );
  }

  Future<void> updatePet(int idMascota, CreatePetRequest request) async {
    if (kDebugMode) {
      debugPrint('pet_update_payload[id=$idMascota]=${request.toJson()}');
    }
    await _apiClient.send(
      method: 'PATCH',
      path: '/api/gestion/clientes/mascotas/$idMascota/',
      body: request.toJson(),
    );
  }

  Future<void> deletePet(int idMascota) async {
    await _apiClient.send(
      method: 'DELETE',
      path: '/api/gestion/clientes/mascotas/$idMascota/',
    );
  }

  Future<String> uploadPetPhoto(String filePath) async {
    var headers = await _authService.authorizedHeaders();
    headers.remove('Content-Type');
    final uri = Uri.parse(
      '${_authService.baseUrl}/api/gestion/clientes/mascotas/upload-foto/',
    );

    Future<http.StreamedResponse> runMultipart(
      Map<String, String> authHeaders,
    ) async {
      final multipart = http.MultipartRequest('POST', uri);
      multipart.headers.addAll(authHeaders);
      multipart.files.add(await http.MultipartFile.fromPath('file', filePath));
      return _client.send(multipart);
    }

    var streamed = await runMultipart(headers);
    var response = await http.Response.fromStream(streamed);

    if (response.statusCode == 401) {
      await _authService.refreshToken();
      headers = await _authService.authorizedHeaders();
      headers.remove('Content-Type');
      streamed = await runMultipart(headers);
      response = await http.Response.fromStream(streamed);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (kDebugMode) {
        debugPrint(
          '[PetsService] HTTP ${response.statusCode} POST /upload-foto/ -> ${response.body}',
        );
      }
      throw ClientException(
        _extractErrorMessage(_safeDecode(response.body)),
        statusCode: response.statusCode,
      );
    }

    final decoded = _safeDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final url = decoded['url']?.toString();
      if (url != null && url.isNotEmpty) return url;
    }
    throw const ClientException('No se recibio URL de la foto subida.');
  }

  String _extractErrorMessage(Object data) {
    if (data is Map<String, dynamic>) {
      final detail = data['detail'] ?? data['error'] ?? data['message'];
      if (detail is String && detail.isNotEmpty) return detail;
      if (detail is List && detail.isNotEmpty) return detail.first.toString();
      for (final value in data.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
    }
    return 'No se pudo completar la solicitud.';
  }

  Map<String, dynamic> _extractJsonMapOrThrow(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (_looksLikeHtml(response)) {
        throw ClientException(
          'Catalogo no disponible temporalmente. Intenta nuevamente en unos minutos.',
          statusCode: response.statusCode,
        );
      }
      throw ClientException(
        _extractErrorMessage(_safeDecode(response.body)),
        statusCode: response.statusCode,
      );
    }

    if (_looksLikeHtml(response)) {
      throw const ClientException(
        'Catalogo no disponible temporalmente. Intenta nuevamente en unos minutos.',
      );
    }

    final decoded = _safeDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }
}

class PetSpecies {
  const PetSpecies({required this.id, required this.name});

  final int id;
  final String name;

  factory PetSpecies.fromJson(Map<String, dynamic> json) {
    return PetSpecies(
      id: _asInt(json['id_especie']),
      name: (json['nombre'] ?? '').toString(),
    );
  }
}

class PetBreed {
  const PetBreed({required this.id, required this.name, required this.speciesId});

  final int id;
  final String name;
  final int speciesId;

  factory PetBreed.fromJson(Map<String, dynamic> json) {
    return PetBreed(
      id: _asInt(json['id_raza']),
      name: (json['nombre'] ?? json['name'] ?? '').toString(),
      speciesId: (json['especie'] is Map<String, dynamic>)
          ? _asInt((json['especie'] as Map<String, dynamic>)['id_especie'])
          : _asInt(json['especie'] ?? json['especie_id']),
    );
  }
}

class Pet {
  const Pet({
    required this.id,
    required this.name,
    required this.speciesId,
    required this.speciesName,
    this.breedId,
    this.breedName,
    this.sex,
    this.birthDate,
    this.weight,
    this.size,
    this.color,
    this.allergies,
    this.notes,
    this.photo,
    this.estado,
  });

  final int id;
  final String name;
  final int speciesId;
  final String speciesName;
  final int? breedId;
  final String? breedName;
  final String? sex;
  final String? birthDate;
  final num? weight;
  final String? size;
  final String? color;
  final String? allergies;
  final String? notes;
  final String? photo;
  final bool? estado;

  factory Pet.fromJson(Map<String, dynamic> json) {
    final especie = json['especie'] as Map<String, dynamic>?;
    final raza = json['raza'] as Map<String, dynamic>?;

    return Pet(
      id: _asInt(json['id_mascota']),
      name: (json['nombre'] ?? '').toString(),
      speciesId: _asInt(especie?['id_especie']),
      speciesName: (especie?['nombre'] ?? 'Especie').toString(),
      breedId: raza?['id_raza'] == null ? null : _asInt(raza?['id_raza']),
      breedName: raza?['nombre']?.toString(),
      sex: json['sexo']?.toString(),
      birthDate: (json['fecha_nac'] ?? json['fecha_nacimiento'])?.toString(),
      weight: _asNum(json['peso']),
      size: json['tamano']?.toString(),
      color: json['color']?.toString(),
      allergies: json['alergias']?.toString(),
      notes: json['notas_generales']?.toString(),
      photo: json['foto']?.toString(),
      estado: json['estado'] as bool?,
    );
  }
}

class CreatePetRequest {
  const CreatePetRequest({
    required this.name,
    required this.speciesId,
    this.breedId,
    this.sex,
    this.color,
    this.birthDate,
    this.size,
    this.weight,
    this.allergies,
    this.notes,
    this.photo,
    this.estado,
  });

  final String name;
  final int speciesId;
  final int? breedId;
  final String? sex;
  final String? color;
  final String? birthDate;
  final String? size;
  final num? weight;
  final String? allergies;
  final String? notes;
  final String? photo;
  final bool? estado;

  Map<String, dynamic> toJson() => {
        'nombre': name,
        'especie_id': speciesId,
        'raza_id': breedId,
        'sexo': sex,
        'color': color,
        'fecha_nac': birthDate,
        'tamano': size,
        'peso': weight,
        'alergias': allergies,
        'notas_generales': notes,
        'foto': photo,
        'estado': estado,
      };
}

class PetProfileData {
  const PetProfileData({
    required this.pet,
    required this.addresses,
    required this.historySummary,
  });

  final Pet pet;
  final PetAddressesData addresses;
  final PetHistorySummary historySummary;

  factory PetProfileData.fromJson(Map<String, dynamic> json) {
    return PetProfileData(
      pet: Pet.fromJson(
        (json['mascota'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      addresses: PetAddressesData.fromJson(
        (json['direcciones'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      historySummary: PetHistorySummary.fromJson(
        (json['historial'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
    );
  }
}

class PetAddressesData {
  const PetAddressesData({
    required this.mainAddress,
    required this.history,
    required this.total,
  });

  final String? mainAddress;
  final List<String> history;
  final int total;

  factory PetAddressesData.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['historial'];
    return PetAddressesData(
      mainAddress: (json['principal'] ?? '').toString().trim().isEmpty
          ? null
          : json['principal'].toString().trim(),
      history: rawHistory is List
          ? rawHistory
              .map((item) => item.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList()
          : <String>[],
      total: _asInt(json['total']),
    );
  }
}

class PetHistorySummary {
  const PetHistorySummary({
    required this.total,
    required this.finalized,
    required this.followUp,
  });

  final int total;
  final int finalized;
  final int followUp;

  factory PetHistorySummary.fromJson(Map<String, dynamic> json) {
    return PetHistorySummary(
      total: _asInt(json['total']),
      finalized: _asInt(json['finalizado']),
      followUp: _asInt(json['seguimiento']),
    );
  }
}

class PetHistoryData {
  const PetHistoryData({
    required this.items,
    required this.total,
  });

  final List<PetHistoryItem> items;
  final int total;

  factory PetHistoryData.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final list = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(PetHistoryItem.fromJson)
            .toList()
        : <PetHistoryItem>[];
    return PetHistoryData(items: list, total: _asInt(json['total']));
  }
}

class PetHistoryItem {
  const PetHistoryItem({
    required this.idCita,
    required this.fecha,
    required this.tipoServicio,
    required this.observaciones,
    required this.estado,
    required this.modalidad,
    required this.direccionCita,
  });

  final int idCita;
  final String fecha;
  final String tipoServicio;
  final String observaciones;
  final String estado;
  final String modalidad;
  final String? direccionCita;

  factory PetHistoryItem.fromJson(Map<String, dynamic> json) {
    return PetHistoryItem(
      idCita: _asInt(json['id_cita']),
      fecha: (json['fecha'] ?? '').toString(),
      tipoServicio: (json['tipo_servicio'] ?? 'Servicio').toString(),
      observaciones: (json['observaciones'] ?? '').toString(),
      estado: (json['estado'] ?? '').toString(),
      modalidad: (json['modalidad'] ?? '').toString(),
      direccionCita: json['direccion_cita']?.toString(),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

num? _asNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) {
    final normalized = value.trim().replaceAll(',', '.');
    return num.tryParse(normalized);
  }
  return null;
}
