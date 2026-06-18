import 'package:flutter/material.dart';
import 'package:pethome_app/src/core/features/compras/providers/carrito_provider.dart';
import 'package:pethome_app/src/features/appointments/data/appointments_service.dart';
import 'package:pethome_app/src/features/pets/data/pets_service.dart';

class AgregarServicioSheet extends StatefulWidget {
  const AgregarServicioSheet({
    super.key,
    required this.provider,
  });

  final CarritoProvider provider;

  @override
  State<AgregarServicioSheet> createState() => _AgregarServicioSheetState();
}

class _AgregarServicioSheetState extends State<AgregarServicioSheet> {
  late final Future<_SheetData> _initialFuture = _loadInitial();

  int? _servicioId;
  int? _precioServicioId;
  int? _mascotaId;
  final TextEditingController _cantidadController = TextEditingController(text: '1');
  String? _error;
  bool _saving = false;

  List<ServicePrice> _availablePrices = <ServicePrice>[];

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  Future<_SheetData> _loadInitial() async {
    final results = await Future.wait<dynamic>([
      widget.provider.getMascotas(),
      widget.provider.getServiciosActivos(),
    ]);
    final pets = (results[0] as List<Pet>);
    final services = (results[1] as List<ServiceItem>);
    return _SheetData(mascotas: pets, servicios: services);
  }

  Future<void> _onServiceChange(int? serviceId) async {
    setState(() {
      _servicioId = serviceId;
      _precioServicioId = null;
      _availablePrices = <ServicePrice>[];
      _error = null;
    });
    if (serviceId == null) return;
    final prices = await widget.provider.getPreciosActivos(servicioId: serviceId);
    if (!mounted) return;
    setState(() => _availablePrices = prices);
  }

  Future<void> _submit() async {
    final qty = double.tryParse(_cantidadController.text.replaceAll(',', '.').trim()) ?? 0;
    if (_servicioId == null || _precioServicioId == null || _mascotaId == null || qty <= 0) {
      setState(() {
        _error = _mascotaId == null
            ? 'Debe seleccionar una mascota para agregar este servicio al carrito.'
            : 'Completa servicio, precio y cantidad valida.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final ok = await widget.provider.addServicio(
      servicioId: _servicioId!,
      precioServicioId: _precioServicioId!,
      mascotaId: _mascotaId!,
      cantidad: qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(2),
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.of(context).pop('Servicio agregado al carrito.');
      return;
    }

    setState(() {
      _error = widget.provider.errorMessage ?? 'No se pudo agregar el servicio.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 18,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: FutureBuilder<_SheetData>(
        future: _initialFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return const SizedBox(
              height: 220,
              child: Center(child: Text('No se pudieron cargar servicios o mascotas.')),
            );
          }

          final data = snapshot.data!;
          if (data.mascotas.isEmpty) {
            return const SizedBox(
              height: 220,
              child: Center(
                child: Text(
                  'Debe registrar una mascota antes de agregar este servicio al carrito.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Agregar servicio al carrito',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _servicioId,
                  decoration: const InputDecoration(labelText: 'Servicio'),
                  items: data.servicios
                      .map(
                        (service) => DropdownMenuItem<int>(
                          value: service.id,
                          child: Text(service.name),
                        ),
                      )
                      .toList(),
                  onChanged: _onServiceChange,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: _precioServicioId,
                  decoration: const InputDecoration(labelText: 'Precio/variacion'),
                  items: _availablePrices
                      .map(
                        (price) => DropdownMenuItem<int>(
                          value: price.id,
                          child: Text('${price.variation} - Bs ${price.price}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _precioServicioId = value),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: _mascotaId,
                  decoration: const InputDecoration(labelText: 'Mascota'),
                  items: data.mascotas
                      .map(
                        (pet) => DropdownMenuItem<int>(
                          value: pet.id,
                          child: Text(pet.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _mascotaId = value),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _cantidadController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Agregar servicio'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SheetData {
  const _SheetData({
    required this.mascotas,
    required this.servicios,
  });

  final List<Pet> mascotas;
  final List<ServiceItem> servicios;
}
