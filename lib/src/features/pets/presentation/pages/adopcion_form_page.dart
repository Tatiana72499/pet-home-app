import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/core/widgets/location_coordinate_picker.dart';
import 'package:pethome_app/src/features/pets/data/adopciones_service.dart';
import 'package:pethome_app/src/features/pets/data/pets_service.dart';
import 'package:pethome_app/src/features/pets/models/adopcion.dart';

class AdopcionFormPage extends StatefulWidget {
  const AdopcionFormPage({super.key, required this.service, this.adopcion});

  final AdopcionesService service;
  final Adopcion? adopcion;

  @override
  State<AdopcionFormPage> createState() => _AdopcionFormPageState();
}

class _AdopcionFormPageState extends State<AdopcionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _fotoController = TextEditingController();
  final _edadController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _referenciaController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _saludController = TextEditingController();

  final _imagePicker = ImagePicker();
  XFile? _selectedPhoto;

  late Future<void> _future = _loadCatalogs();
  List<PetSpecies> _species = [];
  List<PetBreed> _breeds = [];
  int? _speciesId;
  int? _breedId;
  String? _sexo;
  String? _tamano = 'Mediano';
  String _estado = 'disponible';
  String? _coordinates;
  bool _saving = false;
  String? _message;

  bool get _isEditing => widget.adopcion != null;

  @override
  void initState() {
    super.initState();
    final adopcion = widget.adopcion;
    if (adopcion != null) {
      _nombreController.text = adopcion.nombre;
      _telefonoController.text = adopcion.telefonoContacto;
      _fotoController.text = adopcion.foto ?? '';
      _edadController.text = adopcion.edadAproximada ?? '';
      _ubicacionController.text = adopcion.ubicacion;
      _referenciaController.text = adopcion.referenciaUbicacion ?? '';
      if (adopcion.latitud != null && adopcion.longitud != null) {
        _coordinates = LocationCoordinatePicker.formatCoordinates(
          LatLng(adopcion.latitud!, adopcion.longitud!),
        );
      }
      _descripcionController.text = adopcion.descripcion;
      _saludController.text = adopcion.estadoSalud;
      _speciesId = adopcion.especieId == 0 ? null : adopcion.especieId;
      _breedId = adopcion.razaId;
      _sexo = adopcion.sexo;
      _tamano = adopcion.tamano ?? 'Mediano';
      _estado = adopcion.estadoAdopcion;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _fotoController.dispose();
    _edadController.dispose();
    _ubicacionController.dispose();
    _referenciaController.dispose();
    _descripcionController.dispose();
    _saludController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalogs() async {
    _species = await widget.service.getSpecies();
    if (_speciesId != null) {
      _breeds = await widget.service.getBreeds(speciesId: _speciesId);
    }
  }

  Future<void> _loadBreeds(int id) async {
    setState(() {
      _breedId = null;
      _breeds = [];
    });
    final result = await widget.service.getBreeds(speciesId: id);
    if (!mounted) return;
    setState(() => _breeds = result);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (file == null || !mounted) return;
      setState(() {
        _selectedPhoto = file;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = 'No se pudo seleccionar la foto.');
      if (kDebugMode) {
        debugPrint('photo_pick_error=$error');
      }
    }
  }

  Future<void> _showPhotoOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) || _speciesId == null) {
      setState(() => _message = 'Completa nombre, especie y datos requeridos.');
      return;
    }
    setState(() {
      _saving = true;
      _message = null;
    });
    String? foto = _emptyToNull(_fotoController.text);
    try {
      if (_selectedPhoto != null) {
        final bytes = await _selectedPhoto!.readAsBytes();
        foto = await widget.service.uploadAdopcionFoto(
          bytes,
          _selectedPhoto!.name,
        );
        _fotoController.text = foto;
      }

      final request = AdopcionRequest(
        nombre: _nombreController.text.trim(),
        especieId: _speciesId!,
        razaId: _breedId,
        foto: foto,
        edadAproximada: _emptyToNull(_edadController.text),
        sexo: _sexo,
        tamano: _tamano,
        ubicacion: _ubicacionController.text.trim(),
        telefonoContacto: _telefonoController.text.trim(),
        referenciaUbicacion: _emptyToNull(_referenciaController.text),
        latitud: LocationCoordinatePicker.tryParseCoordinates(
          _coordinates,
        )?.latitude,
        longitud: LocationCoordinatePicker.tryParseCoordinates(
          _coordinates,
        )?.longitude,
        descripcion: _descripcionController.text.trim(),
        estadoSalud: _saludController.text.trim(),
        estadoAdopcion: _isEditing ? _estado : null,
      );
      if (_isEditing) {
        await widget.service.updateAdopcion(widget.adopcion!.id, request);
      } else {
        await widget.service.createAdopcion(request);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ClientException catch (error) {
      setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _photoPlaceholder() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(Icons.pets, color: Colors.black38, size: 36),
      ),
    );
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar adopcion' : 'Registrar adopcion'),
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<void>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_message != null)
                  Text(_message!, style: const TextStyle(color: Colors.red)),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Requerido'
                      : null,
                ),
                TextFormField(
                  controller: _telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Telefono de contacto',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Requerido'
                      : null,
                ),
                DropdownButtonFormField<int>(
                  initialValue: _speciesId,
                  decoration: const InputDecoration(labelText: 'Especie'),
                  items: _species
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _speciesId = value);
                    _loadBreeds(value);
                  },
                  validator: (value) => value == null ? 'Requerido' : null,
                ),
                DropdownButtonFormField<int>(
                  initialValue: _breedId,
                  decoration: const InputDecoration(labelText: 'Raza'),
                  items: _breeds
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _breedId = value),
                ),
                TextFormField(
                  controller: _edadController,
                  decoration: const InputDecoration(
                    labelText: 'Edad aproximada',
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _sexo,
                  decoration: const InputDecoration(labelText: 'Sexo'),
                  items: const [
                    DropdownMenuItem(value: 'MACHO', child: Text('Macho')),
                    DropdownMenuItem(value: 'HEMBRA', child: Text('Hembra')),
                  ],
                  onChanged: (value) => setState(() => _sexo = value),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _tamano,
                  decoration: const InputDecoration(labelText: 'Tamano'),
                  items: const [
                    DropdownMenuItem(value: 'Pequeno', child: Text('Pequeno')),
                    DropdownMenuItem(value: 'Mediano', child: Text('Mediano')),
                    DropdownMenuItem(value: 'Grande', child: Text('Grande')),
                  ],
                  onChanged: (value) => setState(() => _tamano = value),
                ),
                if (_isEditing)
                  DropdownButtonFormField<String>(
                    initialValue: _estado,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: const [
                      DropdownMenuItem(
                        value: 'disponible',
                        child: Text('Disponible'),
                      ),
                      DropdownMenuItem(
                        value: 'en_proceso',
                        child: Text('En proceso'),
                      ),
                      DropdownMenuItem(
                        value: 'adoptado',
                        child: Text('Adoptado'),
                      ),
                      DropdownMenuItem(
                        value: 'inactivo',
                        child: Text('Inactivo'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _estado = value ?? 'disponible'),
                  ),
                TextFormField(
                  controller: _ubicacionController,
                  decoration: const InputDecoration(
                    labelText: 'Ubicacion publica',
                    helperText:
                        'Usa una referencia general, no la direccion exacta.',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Requerido'
                      : null,
                ),
                TextFormField(
                  controller: _referenciaController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Referencia de ubicacion',
                    helperText:
                        'Punto de referencia visible para llegar con facilidad.',
                  ),
                ),
                const SizedBox(height: 12),
                LocationCoordinatePicker(
                  initialCoordinates: _coordinates,
                  buttonLabel: 'Usar mi ubicacion como referencia',
                  onChanged: (value) => setState(() => _coordinates = value),
                ),
                TextFormField(
                  controller: _fotoController,
                  decoration: const InputDecoration(
                    labelText: 'Foto (URL opcional)',
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _showPhotoOptions,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Agregar foto'),
                  ),
                ),
                if (_selectedPhoto != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: kIsWeb
                        ? Image.network(
                            _selectedPhoto!.path,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _photoPlaceholder(),
                          )
                        : Image.file(
                            File(_selectedPhoto!.path),
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Foto seleccionada: ${_selectedPhoto!.name}',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ] else if ((_fotoController.text).trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      _fotoController.text.trim(),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _photoPlaceholder(),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  _photoPlaceholder(),
                ],
                TextFormField(
                  controller: _descripcionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descripcion'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Requerido'
                      : null,
                ),
                TextFormField(
                  controller: _saludController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Estado de salud',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Requerido'
                      : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Guardar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
