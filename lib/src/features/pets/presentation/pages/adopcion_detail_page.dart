import 'package:flutter/material.dart';
import 'package:pethome_app/src/features/pets/models/adopcion.dart';
import 'package:pethome_app/src/utils/open_external_link.dart';

class AdopcionDetailPage extends StatelessWidget {
  const AdopcionDetailPage({super.key, required this.adopcion});

  final Adopcion adopcion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(adopcion.nombre),
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: adopcion.foto == null || adopcion.foto!.isEmpty
                ? Container(
                    height: 220,
                    color: Colors.orange.shade50,
                    child: const Icon(
                      Icons.pets,
                      size: 64,
                      color: Colors.orange,
                    ),
                  )
                : Image.network(
                    adopcion.foto!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 220,
                      color: Colors.orange.shade50,
                      child: const Icon(
                        Icons.pets,
                        size: 64,
                        color: Colors.orange,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(text: estadoAdopcionLabel(adopcion.estadoAdopcion)),
              _Chip(text: adopcion.especieNombre),
              if (adopcion.razaNombre != null)
                _Chip(text: adopcion.razaNombre!),
              if (adopcion.sexo != null) _Chip(text: adopcion.sexo!),
              if (adopcion.tamano != null) _Chip(text: adopcion.tamano!),
            ],
          ),
          const SizedBox(height: 18),
          _Info(
            label: 'Edad aproximada',
            value: adopcion.edadAproximada ?? '-',
          ),
          _Info(label: 'Ubicacion', value: adopcion.ubicacion),
          _Info(label: 'Telefono', value: adopcion.telefonoContacto),
          _Info(
            label: 'Referencia',
            value: adopcion.referenciaUbicacion ?? '-',
          ),
          _Info(
            label: 'Coordenadas',
            value: adopcion.latitud != null && adopcion.longitud != null
                ? '${adopcion.latitud!.toStringAsFixed(6)}, ${adopcion.longitud!.toStringAsFixed(6)}'
                : '-',
          ),
          _Info(label: 'Publicado por', value: adopcion.publicadoPor ?? '-'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (adopcion.telefonoContacto.trim().isNotEmpty)
                FilledButton.icon(
                  onPressed: () => openExternalLink(
                    'tel:${_sanitizePhone(adopcion.telefonoContacto)}',
                  ),
                  icon: const Icon(Icons.call),
                  label: const Text('Llamar'),
                ),
              if (adopcion.telefonoContacto.trim().isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => openExternalLink(
                    'https://wa.me/${_sanitizePhone(adopcion.telefonoContacto)}?text=${Uri.encodeComponent('Hola, vi la publicacion de adopcion de ${adopcion.nombre}.')}',
                  ),
                  icon: const Icon(Icons.chat),
                  label: const Text('WhatsApp'),
                ),
              if (adopcion.latitud != null && adopcion.longitud != null)
                OutlinedButton.icon(
                  onPressed: () => openExternalLink(
                    'https://www.google.com/maps/search/?api=1&query=${adopcion.latitud},${adopcion.longitud}',
                  ),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Ver mapa'),
                ),
            ],
          ),
          _Section(title: 'Descripcion', value: adopcion.descripcion),
          _Section(title: 'Estado de salud', value: adopcion.estadoSalud),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text),
      backgroundColor: const Color(0xFF6A11CB).withValues(alpha: 0.08),
      labelStyle: const TextStyle(color: Color(0xFF6A11CB)),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(value),
        ],
      ),
    );
  }
}

String _sanitizePhone(String value) {
  return value.replaceAll(RegExp(r'[^0-9+]'), '');
}

String _sanitizePhoneForWhatsApp(String value) {
  return value.replaceAll(RegExp(r'\D'), '');
}
