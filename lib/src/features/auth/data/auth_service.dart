import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:pethome_app/src/features/auth/domain/auth_user.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  AuthService({FlutterSecureStorage? storage, http.Client? client})
    : _storage = storage ?? const FlutterSecureStorage(),
      _client = client ?? http.Client();

  static const String _accessKey = 'access_token';
  static const String _refreshKey = 'refresh_token';
  static const String _sessionUserKey = 'session_user_json';
  static const String _sessionContextKey = 'session_context_json';
  static const String _sessionComponentsKey = 'session_components_json';
  static const String _selectedVetSlugKey = 'selected_veterinaria_slug';

  final FlutterSecureStorage _storage;
  final http.Client _client;

  String get baseUrl {
    final envBaseUrl = dotenv.env['API_URL'];
    if (envBaseUrl != null && envBaseUrl.trim().isNotEmpty) {
      final configuredBaseUrl = envBaseUrl.trim();

      if (kIsWeb) {
        if (configuredBaseUrl.contains('10.0.2.2')) {
          return configuredBaseUrl.replaceAll('10.0.2.2', '127.0.0.1');
        }

        return configuredBaseUrl;
      }

      if (Platform.isAndroid &&
          (configuredBaseUrl.contains('127.0.0.1') ||
              configuredBaseUrl.contains('localhost'))) {
        return configuredBaseUrl
            .replaceAll('127.0.0.1', '10.0.2.2')
            .replaceAll('localhost', '10.0.2.2');
      }

      return configuredBaseUrl;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    return Platform.isAndroid
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000';
  }

  Future<bool> hasSession() async {
    final accessToken = await _storage.read(key: _accessKey);
    return accessToken != null && accessToken.isNotEmpty;
  }

  Future<List<PublicVeterinaria>> getPublicVeterinarias() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/public/veterinarias/'),
      headers: {'Content-Type': 'application/json'},
    );

    final data = _decodeBody(response);
    if (response.statusCode != 200) {
      throw AuthException(_extractErrorMessage(data));
    }

    List<dynamic> raw = <dynamic>[];
    if (data is List) {
      raw = data;
    } else if (data is Map<String, dynamic> && data['results'] is List) {
      raw = data['results'] as List;
    }

    return raw
        .whereType<Map<String, dynamic>>()
        .map(PublicVeterinaria.fromJson)
        .where((item) => item.slug.isNotEmpty)
        .toList();
  }

  Future<List<String>> getComponentesMovil() async {
    final accessToken = await _storage.read(key: _accessKey);
    if (accessToken == null || accessToken.isEmpty) {
      return <String>[];
    }

    final response = await _client.get(
      Uri.parse('$baseUrl/api/auth/componentes/?plataforma=MOVIL'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 200) {
      return <String>[];
    }

    final data = _decodeBody(response);
    List<dynamic> raw = <dynamic>[];
    if (data is List) {
      raw = data;
    } else if (data is Map<String, dynamic> && data['results'] is List) {
      raw = data['results'] as List;
    } else if (data is Map<String, dynamic> && data['componentes'] is List) {
      raw = data['componentes'] as List;
    }

    return raw.map((item) => item.toString()).toList();
  }

  Future<AuthSession> login({
    required String correo,
    required String password,
    required String slugVeterinaria,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/mobile/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'correo': correo,
        'password': password,
        'slug_veterinaria': slugVeterinaria,
      }),
    );

    final data = _decodeBody(response);

    if (response.statusCode != 200) {
      throw AuthException(
        _extractErrorMessage(data),
        statusCode: response.statusCode,
      );
    }

    await _persistSession(data, selectedSlug: slugVeterinaria);
    return getMe();
  }

  Future<AuthSession> registerMobile({
    required String slugVeterinaria,
    required String nombre,
    required String correo,
    required String password,
    String? telefono,
    String? direccion,
  }) async {
    final registerUrl = '$baseUrl/api/auth/mobile/register/';
    debugPrint('[registerMobile] url=$registerUrl');

    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(registerUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'slug_veterinaria': slugVeterinaria,
              'nombre': nombre.trim(),
              'correo': correo.trim(),
              'password': password,
              'telefono': (telefono ?? '').trim(),
              'direccion': (direccion ?? '').trim(),
            }),
          )
          .timeout(const Duration(seconds: 20));
    } on SocketException {
      throw const AuthException(
        'No se pudo conectar. Revisa tu conexion e intentalo otra vez.',
      );
    } on TimeoutException {
      throw const AuthException(
        'No se pudo conectar. Revisa tu conexion e intentalo otra vez.',
      );
    }

    debugPrint('[registerMobile] statusCode=${response.statusCode}');
    final data = _decodeBody(response);
    final isSuccess201 = response.statusCode == 201;
    final isSuccess200 = response.statusCode == 200;
    if (!isSuccess201 && !isSuccess200) {
      throw AuthException(
        _extractErrorMessage(data),
        statusCode: response.statusCode,
      );
    }

    final tokens = _extractTokens(data);
    final hasAccess = (tokens['access'] ?? '').isNotEmpty;
    final hasRefresh = (tokens['refresh'] ?? '').isNotEmpty;
    debugPrint(
      '[registerMobile] tokens extracted access=$hasAccess refresh=$hasRefresh',
    );
    if (!hasAccess || !hasRefresh) {
      throw const AuthException(
        'La cuenta se creo, pero faltan credenciales de sesion en la respuesta.',
      );
    }
    debugPrint('[registerMobile] tokens extraidos OK');

    await _persistSession(data, selectedSlug: slugVeterinaria);
    debugPrint('[registerMobile] sesion guardada OK');
    return AuthSession.fromJson(data);
  }

  Future<AuthSession> register({
    required String correo,
    required String password,
    required String slugVeterinaria,
  }) {
    return registerMobile(
      slugVeterinaria: slugVeterinaria,
      nombre: correo,
      correo: correo,
      password: password,
    );
  }

  Future<AuthUser> getProfile() async {
    final session = await getSession();
    return session.user;
  }

  Future<AuthSession> getSession() async {
    final cached = await _readSessionFromStorage();
    if (cached != null) return cached;

    return getMe();
  }

  Future<AuthSession> getMe() async {
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
      throw AuthException(
        _extractErrorMessage(data),
        statusCode: response.statusCode,
      );
    }

    final slug = await _storage.read(key: _selectedVetSlugKey);
    await _persistSession(data, selectedSlug: slug);
    return AuthSession.fromJson(data);
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

  Future<Map<String, String>> authorizedHeaders() async {
    final accessToken = await _storage.read(key: _accessKey);

    if (accessToken == null || accessToken.isEmpty) {
      throw const AuthException('No hay una sesion activa.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
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
    await _storage.delete(key: _sessionUserKey);
    await _storage.delete(key: _sessionContextKey);
    await _storage.delete(key: _sessionComponentsKey);
    await _storage.delete(key: _selectedVetSlugKey);
  }

  Future<String> forgotPassword({required String correo}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/forgot-password/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'correo': correo}),
    );

    final data = _decodeBody(response);
    if (response.statusCode != 200) {
      throw AuthException(
        _extractErrorMessage(data),
        statusCode: response.statusCode,
      );
    }

    return (data['detail'] ??
            'Si el correo existe, se enviara un enlace de recuperacion.')
        .toString();
  }

  Future<String> resetPassword({
    required String token,
    required String nuevaPassword,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/reset-password/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'nueva_password': nuevaPassword}),
    );

    final data = _decodeBody(response);
    if (response.statusCode != 200) {
      throw AuthException(
        _extractErrorMessage(data),
        statusCode: response.statusCode,
      );
    }

    return (data['detail'] ?? 'La contrasena fue restablecida correctamente.')
        .toString();
  }

  Future<String> changePassword({
    required String passwordActual,
    required String nuevaPassword,
  }) async {
    final headers = await authorizedHeaders();
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/change-password/'),
      headers: headers,
      body: jsonEncode({
        'password_actual': passwordActual,
        'nueva_password': nuevaPassword,
      }),
    );

    final data = _decodeBody(response);
    if (response.statusCode != 200) {
      throw AuthException(
        _extractErrorMessage(data),
        statusCode: response.statusCode,
      );
    }

    return (data['detail'] ?? 'La contrasena fue actualizada correctamente.')
        .toString();
  }

  Future<void> _persistSession(
    Map<String, dynamic> data, {
    String? selectedSlug,
  }) async {
    await _storage.delete(key: _sessionUserKey);
    await _storage.delete(key: _sessionContextKey);
    await _storage.delete(key: _sessionComponentsKey);

    final tokens = _extractTokens(data);
    final access = tokens['access'];
    final refresh = tokens['refresh'];

    if (access != null && access.isNotEmpty) {
      await _storage.write(key: _accessKey, value: access);
    }
    if (refresh != null && refresh.isNotEmpty) {
      await _storage.write(key: _refreshKey, value: refresh);
    }

    final userMap = (data['user'] is Map<String, dynamic>)
        ? data['user'] as Map<String, dynamic>
        : data;
    await _storage.write(key: _sessionUserKey, value: jsonEncode(userMap));

    final contextMap =
        (data['context'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    await _storage.write(
      key: _sessionContextKey,
      value: jsonEncode(contextMap),
    );

    final componentes = contextMap['componentes'] is List
        ? contextMap['componentes'] as List
        : <dynamic>[];
    await _storage.write(
      key: _sessionComponentsKey,
      value: jsonEncode(componentes),
    );

    if (selectedSlug != null && selectedSlug.isNotEmpty) {
      await _storage.write(key: _selectedVetSlugKey, value: selectedSlug);
    }
  }

  Map<String, String?> _extractTokens(Map<String, dynamic> data) {
    final tokensMap = data['tokens'] as Map<String, dynamic>?;
    final access = (data['access'] ?? tokensMap?['access'])?.toString();
    final refresh = (data['refresh'] ?? tokensMap?['refresh'])?.toString();

    return {'access': access, 'refresh': refresh};
  }

  Future<AuthSession?> _readSessionFromStorage() async {
    final rawUser = await _storage.read(key: _sessionUserKey);
    if (rawUser == null || rawUser.isEmpty) return null;

    final rawContext = await _storage.read(key: _sessionContextKey);
    final rawComponents = await _storage.read(key: _sessionComponentsKey);

    final userMap = jsonDecode(rawUser) as Map<String, dynamic>;
    final contextMap = rawContext == null || rawContext.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(rawContext) as Map<String, dynamic>;
    final componentes = rawComponents == null || rawComponents.isEmpty
        ? <dynamic>[]
        : jsonDecode(rawComponents) as List;

    return AuthSession(
      user: AuthUser.fromJson(userMap),
      context: AuthSessionContext.fromJson({
        ...contextMap,
        'componentes': componentes,
      }),
      componentesRaw: componentes.whereType<Map<String, dynamic>>().toList(
        growable: false,
      ),
      permissions: PermissionsHelper.fromComponentes(
        componentes.whereType<Map<String, dynamic>>().toList(growable: false),
      ),
    );
  }

  dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }
    return jsonDecode(response.body);
  }

  String _extractErrorMessage(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return 'Ocurrio un error al conectar con el servidor.';
    }

    final detail = data['detail'];
    if (detail is String && detail.isNotEmpty) {
      return detail;
    }

    final nonFieldErrors = data['non_field_errors'];
    if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
      return nonFieldErrors.first.toString();
    }

    if (data.isNotEmpty) {
      final friendly = <String>[];
      data.forEach((key, value) {
        if (value == null) return;
        if (value is String && value.isNotEmpty) {
          friendly.add(value);
          return;
        }
        if (value is List && value.isNotEmpty) {
          friendly.add(value.first.toString());
          return;
        }
        if (value is Map<String, dynamic> && value.isNotEmpty) {
          final nested = value.values.first;
          if (nested is List && nested.isNotEmpty) {
            friendly.add(nested.first.toString());
          } else {
            friendly.add(nested.toString());
          }
          return;
        }
        friendly.add(value.toString());
      });
      if (friendly.isNotEmpty) {
        return friendly.join('\n');
      }
    }

    return 'Ocurrio un error al conectar con el servidor.';
  }
}

class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isForbidden => statusCode == 403;

  @override
  String toString() => message;
}
