import 'package:flutter/material.dart';
import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/features/auth/data/auth_service.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final ApiClient _apiClient = ApiClient(authService: AuthService());
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final List<dynamic> history = await _apiClient.getList(
        '/api/gestion/notificaciones/historial/',
      );

      if (mounted) {
        setState(() {
          _notifications = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      await _apiClient.send(
        method: 'POST',
        path: '/api/gestion/notificaciones/historial/$id/marcar-leida/',
      );
      _fetchNotifications(); // Recargar
    } catch (e) {
      // Error silencioso
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? const Center(
              child: Text(
                'No tienes notificaciones aún',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              child: ListView.separated(
                itemCount: _notifications.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _notifications[index];
                  final bool isUnread = item['estado'] != 'LEIDA';
                  final DateTime date = DateTime.parse(item['fecha_creacion']);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isUnread
                          ? const Color(0xFF6A11CB)
                          : Colors.grey[200],
                      child: Icon(
                        _getIcon(item['tipo']),
                        color: isUnread ? Colors.white : Colors.grey,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item['titulo'] ?? 'Sin título',
                      style: TextStyle(
                        fontWeight: isUnread
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isUnread ? Colors.black : Colors.grey[700],
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(item['mensaje'] ?? ''),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    tileColor: isUnread
                        ? const Color(0xFF6A11CB).withValues(alpha: 0.05)
                        : null,
                    onTap: () {
                      if (isUnread) _markAsRead(item['id_notificacion']);

                      final String? link = item['link'];
                      if (link != null && link.isNotEmpty) {
                        // Aquí puedes implementar la navegación según tu Router
                        // Por ejemplo, si usas Navigator simple:
                        if (link.contains('/citas/')) {
                          final parts = link.split('/');
                          final id = parts.last;
                          ('Navegando a cita ID: $id');
                          // Navigator.push(context, MaterialPageRoute(...));
                        }
                      }
                    },
                  );
                },
              ),
            ),
    );
  }

  IconData _getIcon(String? tipo) {
    switch (tipo) {
      case 'CITA':
        return Icons.calendar_today;
      case 'VACUNA':
        return Icons.medical_services;
      case 'AVISO':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
  }
}
