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
    final roleRaw = json['role'] ?? json['rol'];
    final role = roleRaw is Map<String, dynamic> ? roleRaw : null;
    final roleNombre = role?['nombre']?.toString() ??
        (roleRaw is String ? roleRaw : 'Sin rol');
    final correo =
        (json['correo'] ?? json['email'] ?? json['username'] ?? '') as String;

    return AuthUser(
      idUsuario: (json['id_usuario'] ?? json['id'] ?? 0) as int,
      correo: correo,
      roleNombre: roleNombre,
      isActive: json['is_active'] as bool? ?? false,
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.user,
    required this.context,
    required this.componentesRaw,
    required this.permissions,
  });

  final AuthUser user;
  final AuthSessionContext context;
  final List<Map<String, dynamic>> componentesRaw;
  final PermissionsHelper permissions;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final userData = (json['user'] is Map<String, dynamic>)
        ? json['user'] as Map<String, dynamic>
        : json;
    final contextData = (json['context'] as Map<String, dynamic>?) ??
        <String, dynamic>{};

    final componentesDynamic = contextData['componentes'];
    final componentes = componentesDynamic is List
        ? componentesDynamic
            .whereType<Map<String, dynamic>>()
            .toList(growable: false)
        : <Map<String, dynamic>>[];

    return AuthSession(
      user: AuthUser.fromJson(userData),
      context: AuthSessionContext.fromJson(contextData),
      componentesRaw: componentes,
      permissions: PermissionsHelper.fromComponentes(componentes),
    );
  }
}

class AuthSessionContext {
  const AuthSessionContext({
    this.usuario,
    this.veterinaria,
    this.plan,
  });

  final Map<String, dynamic>? usuario;
  final Map<String, dynamic>? veterinaria;
  final Map<String, dynamic>? plan;

  factory AuthSessionContext.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? asMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      return null;
    }

    return AuthSessionContext(
      usuario: asMap(json['usuario']),
      veterinaria: asMap(json['veterinaria']),
      plan: asMap(json['plan']),
    );
  }
}

class PublicVeterinaria {
  const PublicVeterinaria({
    required this.slug,
    required this.nombre,
  });

  final String slug;
  final String nombre;

  factory PublicVeterinaria.fromJson(Map<String, dynamic> json) {
    return PublicVeterinaria(
      slug: (json['slug'] ?? '').toString(),
      nombre: (json['nombre'] ?? json['name'] ?? 'Veterinaria').toString(),
    );
  }
}

class PermissionNode {
  const PermissionNode({
    required this.codigo,
    required this.canView,
    required this.canCreate,
    required this.canEdit,
    required this.canDelete,
    required this.canExport,
    required this.canExecute,
  });

  final String codigo;
  final bool canView;
  final bool canCreate;
  final bool canEdit;
  final bool canDelete;
  final bool canExport;
  final bool canExecute;
}

class PermissionsHelper {
  const PermissionsHelper(this._permissionsByCode);

  final Map<String, PermissionNode> _permissionsByCode;

  static const PermissionsHelper empty = PermissionsHelper(<String, PermissionNode>{});

  factory PermissionsHelper.fromComponentes(List<Map<String, dynamic>> componentes) {
    final map = <String, PermissionNode>{};

    void walk(List<dynamic> nodes) {
      for (final raw in nodes) {
        if (raw is! Map<String, dynamic>) continue;
        final codigoRaw = raw['codigo'];
        final codigo = codigoRaw == null ? '' : codigoRaw.toString();
        final key = _normalize(codigo);

        final permisosRaw = raw['permisos'];
        final permisos = permisosRaw is Map<String, dynamic>
            ? permisosRaw
            : <String, dynamic>{};

        final current = map[key];
        final next = PermissionNode(
          codigo: codigo,
          canView: _readBool(permisos['ver']),
          canCreate: _readBool(permisos['crear']),
          canEdit: _readBool(permisos['editar']),
          canDelete: _readBool(permisos['eliminar']),
          canExport: _readBool(permisos['exportar']),
          canExecute: _readBool(permisos['ejecutar']),
        );

        if (current == null) {
          map[key] = next;
        } else {
          map[key] = PermissionNode(
            codigo: current.codigo,
            canView: current.canView || next.canView,
            canCreate: current.canCreate || next.canCreate,
            canEdit: current.canEdit || next.canEdit,
            canDelete: current.canDelete || next.canDelete,
            canExport: current.canExport || next.canExport,
            canExecute: current.canExecute || next.canExecute,
          );
        }

        final children = raw['children'];
        if (children is List) {
          walk(children);
        }
      }
    }

    walk(componentes);
    return PermissionsHelper(map);
  }

  bool canView(String codigo) => _resolve(codigo, (p) => p.canView);
  bool canCreate(String codigo) => _resolve(codigo, (p) => p.canCreate);
  bool canEdit(String codigo) => _resolve(codigo, (p) => p.canEdit);
  bool canDelete(String codigo) => _resolve(codigo, (p) => p.canDelete);
  bool canExport(String codigo) => _resolve(codigo, (p) => p.canExport);
  bool canExecute(String codigo) => _resolve(codigo, (p) => p.canExecute);

  bool _resolve(String codigo, bool Function(PermissionNode node) selector) {
    final direct = _permissionsByCode[_normalize(codigo)];
    if (direct != null) return selector(direct);

    final target = _normalize(codigo);
    for (final entry in _permissionsByCode.entries) {
      if (entry.key.contains(target) || target.contains(entry.key)) {
        return selector(entry.value);
      }
    }
    return false;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  static String _normalize(String value) {
    return value.trim().toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');
  }
}
