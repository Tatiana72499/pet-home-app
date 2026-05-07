import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pethome_app/src/features/appointments/data/appointments_service.dart';
import 'package:pethome_app/src/features/appointments/presentation/pages/citas_page.dart';
import 'package:pethome_app/src/core/network/api_client.dart';
import 'package:pethome_app/src/features/auth/domain/auth_user.dart';
import 'package:pethome_app/src/features/pets/data/pets_service.dart';
import 'package:pethome_app/src/features/pets/presentation/pages/pet_profile_page.dart';

class MascotasPage extends StatefulWidget {
  const MascotasPage({
    super.key,
    required this.clientService,
    required this.appointmentsService,
    required this.permissions,
  });

  final PetsService clientService;
  final AppointmentsService appointmentsService;
  final PermissionsHelper permissions;

  @override
  State<MascotasPage> createState() => _MascotasPageState();
}

class _MascotasPageState extends State<MascotasPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _colorController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _sizeController = TextEditingController();
  final _weightController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _notesController = TextEditingController();
  final _photoController = TextEditingController();
  final _searchController = TextEditingController();
  final _imagePicker = ImagePicker();

  late Future<void> _loadFuture = _loadData();
  List<Pet> _pets = [];
  List<PetSpecies> _species = [];
  List<PetBreed> _breeds = [];
  int? _selectedSpeciesId;
  int? _selectedBreedId;
  String? _selectedSex;
  int? _filterSpeciesId;
  int? _editingPetId;
  String? _selectedPhotoPath;
  bool _showForm = false;
  bool _isSaving = false;
  bool _catalogsReady = false;
  bool _catalogsForbidden = false;
  bool _breedQueryDone = false;
  String? _message;

  bool get _hasCreatePermission =>
      widget.permissions.canCreate('MASCOTAS') ||
      widget.permissions.canExecute('MASCOTAS') ||
      widget.permissions.canCreate('CLI_MASCOTAS') ||
      widget.permissions.canExecute('CLI_MASCOTAS') ||
      widget.permissions.canCreate('MOVIL_CREAR_MASCOTA') ||
      widget.permissions.canExecute('MOVIL_CREAR_MASCOTA');

  bool get _hasEditPermission =>
      widget.permissions.canEdit('MASCOTAS') ||
      widget.permissions.canEdit('CLI_MASCOTAS');
  bool get _hasDeletePermission =>
      widget.permissions.canDelete('MASCOTAS') ||
      widget.permissions.canDelete('CLI_MASCOTAS');

  bool get _canCreatePet => _hasCreatePermission && _catalogsReady;
  bool get _isEditing => _editingPetId != null;

  List<Pet> get _filteredPets {
    final query = _searchController.text.trim().toLowerCase();

    return _pets.where((pet) {
      final matchesName = query.isEmpty || pet.name.toLowerCase().contains(query);
      final matchesSpecies = _filterSpeciesId == null || pet.speciesId == _filterSpeciesId;
      return matchesName && matchesSpecies;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _debugPermissions();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    _birthDateController.dispose();
    _sizeController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    _notesController.dispose();
    _photoController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _pets = await widget.clientService.getPets();
    await _loadCatalogs();
  }

  Future<void> _loadCatalogs() async {
    try {
      _species = await widget.clientService.getSpecies();
      _catalogsReady = true;
      _catalogsForbidden = false;
    } on ClientException catch (error) {
      if (error.isForbidden) {
        _species = <PetSpecies>[];
        _catalogsReady = false;
        _catalogsForbidden = true;
        if (_message == null || _message!.isEmpty) {
          _message =
              'Puedes ver tus mascotas, pero no tienes permiso para registrar nuevas.';
        }
        return;
      }
      rethrow;
    }
  }

  Future<void> _retryCatalogs() async {
    setState(() {
      _message = null;
    });
    try {
      await _loadCatalogs();
    } catch (error) {
      setState(() => _message = error.toString());
      return;
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadBreeds(int speciesId) async {
    setState(() {
      _selectedBreedId = null;
      _breedQueryDone = false;
      _breeds = <PetBreed>[];
    });

    try {
      final breeds = await widget.clientService.getBreeds(speciesId: speciesId);
      if (!mounted) return;
      setState(() {
        final uniqueById = <int, PetBreed>{};
        for (final breed in breeds) {
          uniqueById[breed.id] = breed;
        }
        _breeds = uniqueById.values.toList();
        _breedQueryDone = true;
        if (_breeds.isEmpty) {
          _message = 'No hay razas para esta especie.';
        }
      });
    } on ClientException catch (error) {
      if (!mounted) return;
      setState(() {
        _breedQueryDone = true;
        _message = error.isForbidden
            ? 'No tienes permiso para consultar razas.'
            : 'No se pudo cargar la lista de razas.';
      });
    }
  }

  Future<void> _savePet() async {
    if (!(_formKey.currentState?.validate() ?? false) || _selectedSpeciesId == null) {
      setState(() => _message = 'Completa nombre y especie.');
      return;
    }

    final weight = _parseWeight(_weightController.text);
    if (_weightController.text.trim().isNotEmpty && weight == null) {
      setState(() => _message = 'Peso debe ser numerico.');
      return;
    }

    setState(() {
      _isSaving = true;
      _message = null;
    });

    final request = CreatePetRequest(
      name: _nameController.text.trim(),
      speciesId: _selectedSpeciesId!,
      breedId: _selectedBreedId,
      sex: _emptyToNull(_selectedSex),
      color: _emptyToNull(_colorController.text),
      birthDate: _emptyToNull(_birthDateController.text),
      size: _emptyToNull(_sizeController.text),
      weight: weight,
      allergies: _emptyToNull(_allergiesController.text),
      notes: _emptyToNull(_notesController.text),
      photo: _emptyToNull(_photoController.text),
      estado: null,
    );

    try {
      String? photoUrl = _emptyToNull(_photoController.text);
      if (_selectedPhotoPath != null && _selectedPhotoPath!.isNotEmpty) {
        photoUrl = await widget.clientService.uploadPetPhoto(_selectedPhotoPath!);
        _photoController.text = photoUrl;
      }

      final requestWithPhoto = CreatePetRequest(
        name: request.name,
        speciesId: request.speciesId,
        breedId: request.breedId,
        sex: request.sex,
        color: request.color,
        birthDate: request.birthDate,
        size: request.size,
        weight: request.weight,
        allergies: request.allergies,
        notes: request.notes,
        photo: photoUrl,
        estado: request.estado,
      );

      final wasEditing = _isEditing;
      if (_isEditing) {
        await widget.clientService.updatePet(_editingPetId!, requestWithPhoto);
      } else {
        await widget.clientService.createPet(requestWithPhoto);
      }

      await _loadData();
      _clearForm();
      if (!mounted) return;
      setState(() {
        _showForm = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasEditing
                ? 'Mascota actualizada con exito'
                : 'Mascota registrada con exito',
          ),
        ),
      );
    } on ClientException catch (error) {
      final message = error.statusCode == 401
          ? 'Tu sesion expiro. Inicia sesion nuevamente.'
          : error.isForbidden
              ? 'No tienes permiso para registrar mascotas.'
              : error.toString();
      setState(() => _message = message);
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _startEdit(Pet pet) {
    setState(() {
      _editingPetId = pet.id;
      _showForm = true;
      _selectedSpeciesId = pet.speciesId == 0 ? null : pet.speciesId;
      _selectedBreedId = pet.breedId;
      _selectedSex = pet.sex;
      _nameController.text = pet.name;
      _colorController.text = pet.color ?? '';
      _birthDateController.text = pet.birthDate ?? '';
      _sizeController.text = pet.size ?? '';
      _weightController.text = pet.weight?.toString() ?? '';
      _allergiesController.text = pet.allergies ?? '';
      _notesController.text = pet.notes ?? '';
      _photoController.text = pet.photo ?? '';
      _selectedPhotoPath = null;
      _message = null;
    });

    if (_selectedSpeciesId != null) {
      _loadBreeds(_selectedSpeciesId!);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _colorController.clear();
    _birthDateController.clear();
    _sizeController.clear();
    _weightController.clear();
    _allergiesController.clear();
    _notesController.clear();
    _photoController.clear();
    _selectedPhotoPath = null;
    _selectedSpeciesId = null;
    _selectedBreedId = null;
    _selectedSex = null;
    _breeds = [];
    _editingPetId = null;
    _breedQueryDone = false;
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  num? _parseWeight(String value) {
    final trimmed = value.trim().replaceAll(',', '.');
    if (trimmed.isEmpty) return null;
    return num.tryParse(trimmed);
  }

  DateTime? _parseBirthDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _pickBirthDate() async {
    final initial = _parseBirthDate(_birthDateController.text) ?? DateTime.now();
    final firstDate = DateTime(1990, 1, 1);
    final lastDate = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(lastDate) ? lastDate : initial,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A11CB),
          primary: const Color(0xFF6A11CB),
        );
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: scheme,
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              headerBackgroundColor: Colors.white,
              headerForegroundColor: const Color(0xFF6A11CB),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                return const Color(0xFF5A5A5A);
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF6A11CB);
                }
                return null;
              }),
              dayShape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked == null || !mounted) return;
    setState(() {
      _birthDateController.text = _formatDate(picked);
    });
  }

  String _friendlyError(Object? error) {
    if (error is ClientException && error.isForbidden) {
      return 'No tienes permiso para consultar mascotas.';
    }
    return error.toString();
  }

  Future<void> _deletePet(Pet pet) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar mascota'),
          content: Text('¿Seguro que deseas eliminar a ${pet.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);
    try {
      await widget.clientService.deletePet(pet.id);
      await _loadData();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mascota eliminada con exito')),
      );
    } on ClientException catch (error) {
      final message = error.isForbidden
          ? 'No tienes permiso para eliminar mascotas.'
          : error.toString();
      setState(() => _message = message);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (file == null || !mounted) return;
      setState(() {
        _selectedPhotoPath = file.path;
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

  void _showPetDetail(Pet pet) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PetProfilePage(
          pet: pet,
          petsService: widget.clientService,
          onUseAddressInAppointment: (address) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CitasPage(
                  petsService: widget.clientService,
                  appointmentsService: widget.appointmentsService,
                  permissions: widget.permissions,
                ),
              ),
            );
            if (address.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Direccion lista para proxima cita: $address',
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _debugPermissions() {
    if (!kDebugMode) return;
    debugPrint(
      '[MascotasPage] perms '
      'CLI_MASCOTAS(create=${widget.permissions.canCreate('CLI_MASCOTAS')}, exec=${widget.permissions.canExecute('CLI_MASCOTAS')}), '
      'CLI_CATALOGOS(view=${widget.permissions.canView('CLI_CATALOGOS')}), '
      'MOVIL_MIS_MASCOTAS(view=${widget.permissions.canView('MOVIL_MIS_MASCOTAS')}), '
      'MOVIL_CREAR_MASCOTA(create=${widget.permissions.canCreate('MOVIL_CREAR_MASCOTA')}, exec=${widget.permissions.canExecute('MOVIL_CREAR_MASCOTA')})',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis mascotas'),
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: _friendlyError(snapshot.error),
              onRetry: () => setState(() => _loadFuture = _loadData()),
            );
          }

          final petsToRender = _filteredPets;

          return RefreshIndicator(
            onRefresh: () async {
              await _loadData();
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(),
                if (!_showForm) ...[
                  const SizedBox(height: 12),
                  _buildSearchAndFilter(),
                ],
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(_message!, style: const TextStyle(color: Colors.black54)),
                ],
                if (_catalogsForbidden) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: _retryCatalogs,
                      child: const Text('Reintentar catalogos'),
                    ),
                  ),
                ],
                if (_showForm) ...[
                  const SizedBox(height: 16),
                  if (_canCreatePet || (_isEditing && _hasEditPermission))
                    _buildForm()
                  else
                    const Text(
                      'No tienes permiso para crear/editar mascotas.',
                      style: TextStyle(color: Colors.black54),
                    ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Mis mascotas disponibles',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (_pets.isEmpty)
                  const _EmptyState(text: 'Aun no tienes mascotas registradas.')
                else if (petsToRender.isEmpty)
                  const _EmptyState(text: 'No se encontraron resultados.')
                else
                  ...petsToRender.map(
                    (pet) => _PetCard(
                      pet: pet,
                      onTap: () => _showPetDetail(pet),
                      onEdit: _hasEditPermission ? () => _startEdit(pet) : null,
                      onDelete:
                          _hasDeletePermission ? () => _deletePet(pet) : null,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mis mascotas',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_pets.length} disponibles',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: _canCreatePet
              ? () {
                  setState(() {
                    _message = null;
                    _editingPetId = null;
                    _showForm = !_showForm;
                    if (!_showForm) _clearForm();
                  });
                }
              : null,
          icon: Icon(_showForm ? Icons.close : Icons.add),
          label: Text(_showForm ? 'Cerrar' : 'Agregar'),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    final hasFilters = _searchController.text.trim().isNotEmpty || _filterSpeciesId != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _filterSpeciesId,
                  decoration: InputDecoration(
                    labelText: 'Filtrar especie',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Todas')),
                    ..._species.map(
                      (species) => DropdownMenuItem<int?>(
                        value: species.id,
                        child: Text(species.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _filterSpeciesId = value),
                ),
              ),
            ],
          ),
          if (hasFilters) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _filterSpeciesId = null);
                },
                icon: const Icon(Icons.filter_alt_off, size: 18),
                label: const Text('Limpiar filtros'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildForm() {
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
              Text(
                _isEditing ? 'Editar mascota' : 'Agregar mascota',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _selectedSpeciesId,
                decoration: const InputDecoration(labelText: 'Especie'),
                items: _species
                    .map(
                      (species) => DropdownMenuItem(
                        value: species.id,
                        child: Text(species.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  if (kDebugMode) debugPrint('selectedSpeciesId=$value');
                  setState(() {
                    _selectedSpeciesId = value;
                    _selectedBreedId = null;
                    _breeds = <PetBreed>[];
                  });
                  _loadBreeds(value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: (_selectedBreedId != null &&
                        _breeds.any((breed) => breed.id == _selectedBreedId))
                    ? _selectedBreedId
                    : null,
                decoration: const InputDecoration(labelText: 'Raza opcional'),
                items: _breeds
                    .map(
                      (breed) => DropdownMenuItem(
                        value: breed.id,
                        child: Text(breed.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedBreedId = value),
              ),
              if (_selectedSpeciesId != null && _breedQueryDone && _breeds.isEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'No hay razas para esta especie.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedSex,
                decoration: const InputDecoration(labelText: 'Sexo opcional'),
                items: const [
                  DropdownMenuItem(value: 'MACHO', child: Text('Macho')),
                  DropdownMenuItem(value: 'HEMBRA', child: Text('Hembra')),
                ],
                onChanged: (value) => setState(() => _selectedSex = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(labelText: 'Color'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _birthDateController,
                readOnly: true,
                onTap: _pickBirthDate,
                decoration: InputDecoration(
                  labelText: 'Fecha de nacimiento',
                  hintText: 'YYYY-MM-DD',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today_outlined, size: 20),
                    onPressed: _pickBirthDate,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sizeController,
                decoration: const InputDecoration(labelText: 'Tamano'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Peso'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _allergiesController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Alergias'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notas generales'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _photoController,
                decoration: const InputDecoration(
                  labelText: 'Foto (URL opcional)',
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : _showPhotoOptions,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Agregar foto'),
                ),
              ),
              if (_selectedPhotoPath != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(_selectedPhotoPath!),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Foto seleccionada: ${_selectedPhotoPath!.split(RegExp(r'[/\\\\]')).last}',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ] else if ((_photoController.text).trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    _photoController.text.trim(),
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSaving ||
                        (_isEditing ? !_hasEditPermission : !_canCreatePet)
                    ? null
                    : _savePet,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isEditing ? 'Guardar cambios' : 'Guardar mascota'),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _editingPetId = null;
                      _clearForm();
                    });
                  },
                  child: const Text('Cancelar edicion'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
}

class _PetCard extends StatelessWidget {
  const _PetCard({
    required this.pet,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final Pet pet;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.pets, color: Colors.white),
        ),
        title: Text(pet.name),
        subtitle: Text(
          '${pet.speciesName} - ${pet.breedName ?? 'No registrada'}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(pet.sex ?? ''),
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF6A11CB)),
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(child: Text(text)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
