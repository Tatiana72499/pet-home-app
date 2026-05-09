import 'package:flutter/material.dart';

import '../services/client_service.dart';
import 'historial_clinico_page.dart';

class MascotasPage extends StatefulWidget {
  const MascotasPage({super.key, required this.clientService});

  final ClientService clientService;

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

  late Future<void> _loadFuture = _loadData();
  List<Pet> _pets = [];
  List<PetSpecies> _species = [];
  List<PetBreed> _breeds = [];
  int? _selectedSpeciesId;
  int? _selectedBreedId;
  String? _selectedSex;
  bool _showForm = false;
  bool _isSaving = false;
  String? _message;

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    _birthDateController.dispose();
    _sizeController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      widget.clientService.getPets(),
      widget.clientService.getSpecies(),
    ]);

    _pets = results[0] as List<Pet>;
    _species = results[1] as List<PetSpecies>;
  }

  Future<void> _loadBreeds(int speciesId) async {
    final breeds = await widget.clientService.getBreeds(speciesId: speciesId);
    if (!mounted) return;
    setState(() {
      _breeds = breeds;
      _selectedBreedId = null;
    });
  }

  Future<void> _savePet() async {
    if (!(_formKey.currentState?.validate() ?? false) ||
        _selectedSpeciesId == null) {
      setState(() => _message = 'Completa nombre y especie.');
      return;
    }

    setState(() {
      _isSaving = true;
      _message = null;
    });

    try {
      await widget.clientService.createPet(
        CreatePetRequest(
          name: _nameController.text.trim(),
          speciesId: _selectedSpeciesId!,
          breedId: _selectedBreedId,
          sex: _selectedSex,
          color: _emptyToNull(_colorController.text),
          birthDate: _emptyToNull(_birthDateController.text),
          size: _emptyToNull(_sizeController.text),
          weight: _emptyToNull(_weightController.text),
          allergies: _emptyToNull(_allergiesController.text),
          notes: _emptyToNull(_notesController.text),
        ),
      );

      _clearForm();
      await _loadData();
      if (!mounted) return;
      setState(() {
        _message = 'Mascota registrada correctamente.';
        _showForm = false;
      });
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
    _selectedSpeciesId = null;
    _selectedBreedId = null;
    _selectedSex = null;
    _breeds = [];
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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
              message: snapshot.error.toString(),
              onRetry: () => setState(() => _loadFuture = _loadData()),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _loadData();
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(_message!, style: const TextStyle(color: Colors.black54)),
                ],
                if (_showForm) ...[
                  const SizedBox(height: 16),
                  _buildForm(),
                ],
                const SizedBox(height: 16),
                Text(
                  'Mis mascotas disponibles',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (_pets.isEmpty)
                  const _EmptyState(text: 'Aun no tienes mascotas registradas.')
                else
                  ..._pets.map((pet) => _PetCard(
                        pet: pet,
                        clientService: widget.clientService,
                      )),
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
          onPressed: () {
            setState(() {
              _message = null;
              _showForm = !_showForm;
            });
          },
          icon: Icon(_showForm ? Icons.close : Icons.add),
          label: Text(_showForm ? 'Cerrar' : 'Agregar'),
        ),
      ],
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
              const Text(
                'Agregar mascota',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                value: _selectedSpeciesId,
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
                  setState(() => _selectedSpeciesId = value);
                  _loadBreeds(value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedBreedId,
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedSex,
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
                decoration: const InputDecoration(
                  labelText: 'Fecha de nacimiento',
                  hintText: 'YYYY-MM-DD',
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
                keyboardType: TextInputType.number,
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSaving ? null : _savePet,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar mascota'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({
    required this.pet,
    required this.clientService,
  });

  final Pet pet;
  final ClientService clientService;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.orange,
            child: Icon(Icons.pets, color: Colors.white),
          ),
          title: Text(pet.name),
          subtitle: Text(
            '${pet.speciesName}${pet.breedName == null ? '' : ' - ${pet.breedName}'}',
          ),
          trailing: SizedBox(
            width: 120,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(pet.sex ?? '', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Ver historial clínico',
                  child: IconButton(
                    icon: const Icon(
                      Icons.history,
                      color: Color(0xFF6A11CB),
                      size: 20,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HistorialClinicoPage(
                            petId: pet.id,
                            petName: pet.name,
                            clientService: clientService,
                          ),
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
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
