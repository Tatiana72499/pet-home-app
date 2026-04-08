class AuthUser {
  const AuthUser({
    required this.idUsuario,
    required this.correo,
    required this.roleNombre,
    required this.isActive,
  });

  final int idUsuario;
  final String correo;
  final String roleNombre;
  final bool isActive;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as Map<String, dynamic>?;

    return AuthUser(
      idUsuario: json['id_usuario'] as int,
      correo: json['correo'] as String,
      roleNombre: role?['nombre'] as String? ?? 'Sin rol',
      isActive: json['is_active'] as bool? ?? false,
    );
  }
}
