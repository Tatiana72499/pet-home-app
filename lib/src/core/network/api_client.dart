import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pethome_app/src/features/auth/data/auth_service.dart';

class ApiClient {
  ApiClient({
    required AuthService authService,
    http.Client? client,
  })  : _authService = authService,
        _client = client ?? http.Client();

  final AuthService _authService;
  final http.Client _client;

  Future<List<Map<String, dynamic>>> getList(String path) async {
    final response = await send(method: 'GET', path: path);
    final decoded = _decode(response);

    if (decoded is List) return decoded.cast<Map<String, dynamic>>();

    if (decoded is Map<String, dynamic> && decoded['results'] is List) {
      return (decoded['results'] as List).cast<Map<String, dynamic>>();
    }

    return <Map<String, dynamic>>[];
  }

  Future<http.Response> send({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    var headers = await _authService.authorizedHeaders();
    var response =
        await _request(method: method, path: path, headers: headers, body: body);

    if (response.statusCode == 401) {
      await _authService.refreshToken();
      headers = await _authService.authorizedHeaders();
      response =
          await _request(method: method, path: path, headers: headers, body: body);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (kDebugMode) {
        debugPrint(
          '[ApiClient] HTTP ${response.statusCode} $method $path -> ${response.body}',
        );
      }
      throw ClientException(
        _extractErrorMessage(_decode(response)),
        statusCode: response.statusCode,
      );
    }

    return response;
  }

  Future<http.Response> _request({
    required String method,
    required String path,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) {
    final uri = Uri.parse('${_authService.baseUrl}$path');
    final encodedBody = body == null ? null : jsonEncode(body);

    switch (method) {
      case 'POST':
        return _client.post(uri, headers: headers, body: encodedBody);
      case 'PATCH':
        return _client.patch(uri, headers: headers, body: encodedBody);
      case 'DELETE':
        return _client.delete(uri, headers: headers, body: encodedBody);
      default:
        return _client.get(uri, headers: headers);
    }
  }

  Object decode(http.Response response) => _decode(response);

  Object _decode(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};
    return jsonDecode(response.body);
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

class ClientException implements Exception {
  const ClientException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isForbidden => statusCode == 403;

  @override
  String toString() => message;
}
