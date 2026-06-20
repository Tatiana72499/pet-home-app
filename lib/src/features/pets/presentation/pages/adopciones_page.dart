import 'package:flutter/material.dart';
import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/features/pets/data/adopciones_service.dart';
import 'package:pethome_app/src/features/pets/models/adopcion.dart';
import 'package:pethome_app/src/features/pets/presentation/pages/adopcion_detail_page.dart';
import 'package:pethome_app/src/features/pets/presentation/pages/adopcion_form_page.dart';

class AdopcionesPage extends StatefulWidget {
  const AdopcionesPage({super.key, required this.service});

  final AdopcionesService service;

  @override
  State<AdopcionesPage> createState() => _AdopcionesPageState();
}

class _AdopcionesPageState extends State<AdopcionesPage> {
  late Future<List<Adopcion>> _future = widget.service.getAdopciones();
  bool _mias = false;

  Future<void> _reload() async {
    setState(() {
      _future = widget.service.getAdopciones(mias: _mias);
    });
    await _future;
  }

  Future<void> _openForm([Adopcion? adopcion]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdopcionFormPage(
          service: widget.service,
          adopcion: adopcion,
        ),
      ),
    );
    if (changed == true) _reload();
  }

  Future<void> _delete(Adopcion adopcion) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactivar publicacion'),
        content: Text('La publicacion de ${adopcion.nombre} quedara inactiva.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Desactivar')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await widget.service.deleteAdopcion(adopcion.id);
      _reload();
    } on ClientException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adopciones'),
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              _mias = !_mias;
              _reload();
            },
            icon: Icon(_mias ? Icons.person : Icons.public),
            tooltip: _mias ? 'Mis publicaciones' : 'Publicas',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Publicar'),
      ),
      body: FutureBuilder<List<Adopcion>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString(), textAlign: TextAlign.center));
          }
          final adopciones = snapshot.data ?? [];
          if (adopciones.isEmpty) {
            return const Center(child: Text('No hay publicaciones de adopcion.'));
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: adopciones.length,
              itemBuilder: (context, index) {
                final adopcion = adopciones[index];
                return _AdopcionCard(
                  adopcion: adopcion,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdopcionDetailPage(adopcion: adopcion),
                    ),
                  ),
                  onEdit: adopcion.puedeEditar ? () => _openForm(adopcion) : null,
                  onDelete: adopcion.puedeEditar ? () => _delete(adopcion) : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AdopcionCard extends StatelessWidget {
  const _AdopcionCard({
    required this.adopcion,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final Adopcion adopcion;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.orange,
          backgroundImage: adopcion.foto == null || adopcion.foto!.isEmpty
              ? null
              : NetworkImage(adopcion.foto!),
          child: adopcion.foto == null || adopcion.foto!.isEmpty
              ? const Icon(Icons.pets, color: Colors.white)
              : null,
        ),
        title: Text(adopcion.nombre),
        subtitle: Text(
          '${adopcion.especieNombre} - ${adopcion.razaNombre ?? 'Sin raza'}\n'
          '${adopcion.ubicacion} - ${estadoAdopcionLabel(adopcion.estadoAdopcion)}',
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 4,
          children: [
            if (onEdit != null)
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit, color: Color(0xFF6A11CB))),
            if (onDelete != null)
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
