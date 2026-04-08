import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/auth_user.dart';

class AuthService {
  AuthService({
    FlutterSecureStorage? storage,
    http.Client? client,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client();

  static const String _accessKey = 'access_token';
  static const String _refreshKey = 'refresh_token';

  final FlutterSecureStorage _storage;
  final http.Client _client;

  String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  Future<bool> hasSession() async {
    final accessToken = await _storage.read(key: _accessKey);
    return accessToken != null && accessToken.isNotEmpty;
  }

  Future<AuthUser> login({
    required String correo,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'correo': correo,
        'password': password,
      }),
    );

    final data = _decodeBody(response);

    if (response.statusCode != 200) {
      throw AuthException(_extractErrorMessage(data));
    }

    final tokens = data['tokens'] as Map<String, dynamic>;
    await _storage.write(key: _accessKey, value: tokens['access'] as String);
    await _storage.write(key: _refreshKey, value: tokens['refresh'] as String);

    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AuthUser> getProfile() async {
    var accessToken = await _storage.read(key: _accessKey);

    if (accessToken == null || accessToken.isEmpty) {
      throw const AuthException('No hay una sesion activa.');
    }

    var response = await _client.get(
      Uri.parse('$baseUrl/api/auth/me/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 401) {
      accessToken = await refreshToken();
      response = await _client.get(
        Uri.parse('$baseUrl/api/auth/me/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
    }

    final data = _decodeBody(response);

    if (response.statusCode != 200) {
      throw AuthException(_extractErrorMessage(data));
    }

    return AuthUser.fromJson(data);
  }

  Future<String> refreshToken() async {
    final refreshToken = await _storage.read(key: _refreshKey);

    if (refreshToken == null || refreshToken.isEmpty) {
      throw const AuthException('La sesion expiro. Inicia sesion otra vez.');
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );

    final data = _decodeBody(response);

    if (response.statusCode != 200) {
      await clearSession();
      throw const AuthException('No se pudo renovar la sesion.');
    }

    final newAccessToken = data['access'] as String;
    await _storage.write(key: _accessKey, value: newAccessToken);

    final rotatedRefresh = data['refresh'] as String?;
    if (rotatedRefresh != null && rotatedRefresh.isNotEmpty) {
      await _storage.write(key: _refreshKey, value: rotatedRefresh);
    }

    return newAccessToken;
  }

  Future<void> logout() async {
    final accessToken = await _storage.read(key: _accessKey);
    final refreshToken = await _storage.read(key: _refreshKey);

    if (accessToken != null && refreshToken != null) {
      try {
        await _client.post(
          Uri.parse('$baseUrl/api/auth/logout/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode({'refresh': refreshToken}),
        );
      } catch (_) {
        // La sesion local igual debe limpiarse si la peticion falla.
      }
    }

    await clearSession();
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _extractErrorMessage(Map<String, dynamic> data) {
    final detail = data['detail'];
    if (detail is String && detail.isNotEmpty) {
      return detail;
    }

    final nonFieldErrors = data['non_field_errors'];
    if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
      return nonFieldErrors.first.toString();
    }

    if (data.isNotEmpty) {
      return data.values.first.toString();
    }

    return 'Ocurrio un error al conectar con el servidor.';
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
