import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/features/auth/data/auth_service.dart';
import 'package:pethome_app/src/features/pets/data/pets_service.dart';
import 'package:pethome_app/src/features/pets/models/adopcion.dart';

class AdopcionesService {
  AdopcionesService({required AuthService authService, http.Client? client})
      : _authService = authService,
        _client = client ?? http.Client(),
        _apiClient = ApiClient(authService: authService, client: client),
        _petsService = PetsService(authService: authService, client: client);

  final AuthService _authService;
  final http.Client _client;
  final ApiClient _apiClient;
  final PetsService _petsService;

  Future<List<Adopcion>> getAdopciones({bool mias = false}) async {
    final query = mias ? '?mias=true' : '?publica=true';
    final data = await _apiClient.getList('/api/gestion/clientes/adopciones/$query');
    return data.map(Adopcion.fromJson).toList();
  }

  Future<List<PetSpecies>> getSpecies() => _petsService.getSpecies();

  Future<List<PetBreed>> getBreeds({int? speciesId}) {
    return _petsService.getBreeds(speciesId: speciesId);
  }

  Future<void> createAdopcion(AdopcionRequest request) async {
    await _apiClient.send(
      method: 'POST',
      path: '/api/gestion/clientes/adopciones/',
      body: request.toJson(),
    );
  }

  Future<void> updateAdopcion(int id, AdopcionRequest request) async {
    await _apiClient.send(
      method: 'PATCH',
      path: '/api/gestion/clientes/adopciones/$id/',
      body: request.toJson(),
    );
  }

  Future<void> deleteAdopcion(int id) async {
    await _apiClient.send(
      method: 'DELETE',
      path: '/api/gestion/clientes/adopciones/$id/',
    );
  }

  Future<String> uploadAdopcionFoto(
    List<int> bytes,
    String filename,
  ) async {
    var headers = await _authService.authorizedHeaders();
    headers.remove('Content-Type');
    final uri = Uri.parse(
      '${_authService.baseUrl}/api/gestion/clientes/adopciones/upload-foto/',
    );

    Future<http.StreamedResponse> runMultipart(
      Map<String, String> authHeaders,
    ) async {
      final multipart = http.MultipartRequest('POST', uri);
      multipart.headers.addAll(authHeaders);
      multipart.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
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
          '[AdopcionesService] HTTP ${response.statusCode} POST /upload-foto/ -> ${response.body}',
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

  Object _safeDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
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
}
