import 'package:http/http.dart' as http;
import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/features/auth/data/auth_service.dart';

class ProfileService {
  ProfileService({
    required AuthService authService,
    http.Client? client,
  }) : _apiClient = ApiClient(authService: authService, client: client);

  final ApiClient _apiClient;

  Future<ClientProfile> getProfile() async {
    final response = await _apiClient.send(
      method: 'GET',
      path: '/api/gestion/clientes/me/',
    );
    return ClientProfile.fromJson(_apiClient.decode(response) as Map<String, dynamic>);
  }

  Future<ClientProfile> updateProfile(UpdateClientProfileRequest request) async {
    final response = await _apiClient.send(
      method: 'PATCH',
      path: '/api/gestion/clientes/me/',
      body: request.toJson(),
    );
    return ClientProfile.fromJson(_apiClient.decode(response) as Map<String, dynamic>);
  }
}

class ClientProfile {
  const ClientProfile({
    required this.id,
    required this.userId,
    required this.email,
    required this.name,
    this.phone,
    this.address,
    required this.active,
  });

  final int id;
  final int userId;
  final String email;
  final String name;
  final String? phone;
  final String? address;
  final bool active;

  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    return ClientProfile(
      id: json['id_perfil'] as int,
      userId: json['usuario'] as int,
      email: json['correo'] as String? ?? '',
      name: json['nombre'] as String? ?? '',
      phone: json['telefono'] as String?,
      address: json['direccion'] as String?,
      active: json['estado'] as bool? ?? false,
    );
  }
}

class UpdateClientProfileRequest {
  const UpdateClientProfileRequest({
    required this.name,
    this.phone,
    this.address,
  });

  final String name;
  final String? phone;
  final String? address;

  Map<String, dynamic> toJson() => {
        'nombre': name,
        'telefono': phone,
        'direccion': address,
      };
}
