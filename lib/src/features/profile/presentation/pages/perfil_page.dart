import 'package:flutter/material.dart';
import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/features/auth/data/auth_service.dart';
import 'package:pethome_app/src/features/auth/domain/auth_user.dart';
import 'package:pethome_app/src/features/profile/data/profile_service.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({
    super.key,
    required this.user,
    required this.authService,
    required this.clientService,
    required this.onLogout,
    required this.isLoggingOut,
    required this.permissions,
  });

  final AuthUser user;
  final AuthService authService;
  final ProfileService clientService;
  final VoidCallback onLogout;
  final bool isLoggingOut;
  final PermissionsHelper permissions;

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  late Future<ClientProfile> _profileFuture = _loadProfile();
  late PermissionsHelper _runtimePermissions = widget.permissions;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _message;

  bool get _canEditProfile =>
      _runtimePermissions.canEdit('MOVIL_MI_PERFIL') ||
      _runtimePermissions.canView('MOVIL_MI_PERFIL') ||
      _runtimePermissions.canEdit('PERFIL');

  bool get _canAttemptEdit => true;

  @override
  void initState() {
    super.initState();
    _refreshPermissionsFromSession();
    _debugPermissions(source: 'cache-initial');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<ClientProfile> _loadProfile() async {
    final profile = await widget.clientService.getProfile();
    _nameController.text = profile.name;
    _phoneController.text = profile.phone ?? '';
    _addressController.text = profile.address ?? '';
    return profile;
  }

  Future<void> _refreshPermissionsFromSession() async {
    try {
      final session = await widget.authService.getMe();
      if (!mounted) return;
      setState(() {
        _runtimePermissions = session.permissions;
      });
      _debugPermissions(source: 'fresh-/auth/me/');
    } catch (_) {
      if (mounted) {
        _debugPermissions(source: 'cache-fallback');
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _message = null;
    });

    try {
      final profile = await widget.clientService.updateProfile(
        UpdateClientProfileRequest(
          name: _nameController.text.trim(),
          phone: _emptyToNull(_phoneController.text),
          address: _emptyToNull(_addressController.text),
        ),
      );

      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _message = 'Perfil actualizado correctamente.';
        _profileFuture = Future.value(profile);
      });
    } on ClientException catch (error) {
      setState(() => _message = error.toString());
      assert(() {
        debugPrint(
          '[PerfilPage] updateProfile failed status=${error.statusCode} message=${error.message}',
        );
        return true;
      }());
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _message = null;
                _isEditing = !_isEditing;
              });
              if (!_canEditProfile && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Permiso local no confirmado. Se validara al guardar.',
                    ),
                  ),
                );
              }
            },
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
          ),
        ],
      ),
      body: FutureBuilder<ClientProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(snapshot.error.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () =>
                          setState(() => _profileFuture = _loadProfile()),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final profile = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _profileFuture = _loadProfile());
              await _profileFuture;
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    profile.email.isNotEmpty ? profile.email : widget.user.correo,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                Center(
                  child: Text(
                    widget.user.roleNombre,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),
                if (!_isEditing)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() {
                        _message = null;
                        _isEditing = true;
                      }),
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar perfil'),
                    ),
                  ),
                if (!_isEditing) const SizedBox(height: 12),
                _isEditing ? _buildEditForm() : _buildProfileInfo(profile),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(_message!, style: const TextStyle(color: Colors.black54)),
                ],
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: widget.isLoggingOut ? null : widget.onLogout,
                  child: widget.isLoggingOut
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Cerrar sesion'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileInfo(ClientProfile profile) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow(Icons.badge, 'Nombre', profile.name),
            _infoRow(Icons.phone, 'Telefono', profile.phone ?? 'Sin telefono'),
            _infoRow(Icons.home, 'Direccion', profile.address ?? 'Sin direccion'),
            _infoRow(
              Icons.verified_user,
              'Estado',
              profile.active ? 'Activo' : 'Inactivo',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefono'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Direccion'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSaving || !_canAttemptEdit ? null : _saveProfile,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6A11CB)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _debugPermissions({required String source}) {
    if (!mounted) return;
    assert(() {
      debugPrint(
        '[PerfilPage][$source] '
        'MOVIL_MI_PERFIL(view=${_runtimePermissions.canView('MOVIL_MI_PERFIL')}, edit=${_runtimePermissions.canEdit('MOVIL_MI_PERFIL')}), '
        'CLI_CLIENTES(view=${_runtimePermissions.canView('CLI_CLIENTES')}, edit=${_runtimePermissions.canEdit('CLI_CLIENTES')})',
      );
      return true;
    }());
  }
}
