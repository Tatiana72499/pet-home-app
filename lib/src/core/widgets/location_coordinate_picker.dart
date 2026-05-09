import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationCoordinatePicker extends StatefulWidget {
  const LocationCoordinatePicker({
    super.key,
    required this.onChanged,
    this.initialCoordinates,
    this.buttonLabel = 'Usar mi ubicacion',
  });

  final String? initialCoordinates;
  final ValueChanged<String> onChanged;
  final String buttonLabel;

  static String formatCoordinates(LatLng point) {
    return '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
  }

  static LatLng? tryParseCoordinates(String? rawValue) {
    final raw = rawValue?.trim() ?? '';
    if (raw.isEmpty) return null;

    final parts = raw.split(',');
    if (parts.length != 2) return null;

    final latitude = double.tryParse(parts[0].trim());
    final longitude = double.tryParse(parts[1].trim());
    if (latitude == null || longitude == null) return null;

    return LatLng(latitude, longitude);
  }

  @override
  State<LocationCoordinatePicker> createState() =>
      _LocationCoordinatePickerState();
}

class _LocationCoordinatePickerState extends State<LocationCoordinatePicker> {
  static const LatLng _defaultCenter = LatLng(-17.7833, -63.1821);

  final MapController _mapController = MapController();

  LatLng? _selectedPoint;
  bool _isLocating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedPoint =
        LocationCoordinatePicker.tryParseCoordinates(widget.initialCoordinates);
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _errorMessage = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Activa la ubicacion del dispositivo para continuar.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('No se concedio permiso para acceder a tu ubicacion.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final point = LatLng(position.latitude, position.longitude);
      _setSelectedPoint(point, moveMap: true);
    } catch (error) {
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  void _setSelectedPoint(LatLng point, {bool moveMap = false}) {
    final formatted = LocationCoordinatePicker.formatCoordinates(point);
    setState(() {
      _selectedPoint = point;
      _errorMessage = null;
    });
    widget.onChanged(formatted);

    if (moveMap) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(point, 16);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPoint = _selectedPoint;
    final coordinatesText = selectedPoint == null
        ? ''
        : LocationCoordinatePicker.formatCoordinates(selectedPoint);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _isLocating ? null : _useCurrentLocation,
          icon: _isLocating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
          label: Text(widget.buttonLabel),
        ),
        const SizedBox(height: 10),
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Direccion de atencion',
            border: OutlineInputBorder(),
          ),
          child: Text(
            coordinatesText.isEmpty ? 'Toca el mapa para elegir la ubicacion.' : coordinatesText,
            style: TextStyle(
              color: coordinatesText.isEmpty ? Colors.black54 : Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Se guardara en formato latitud, longitud.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 6),
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 12, color: Colors.redAccent),
          ),
        ],
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 240,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: selectedPoint ?? _defaultCenter,
                initialZoom: selectedPoint == null ? 13 : 16,
                onTap: (_, point) => _setSelectedPoint(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.pethome_app',
                ),
                if (selectedPoint != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: selectedPoint,
                        width: 42,
                        height: 42,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.redAccent,
                          size: 42,
                        ),
                      ),
                    ],
                  ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          selectedPoint == null
              ? 'Selecciona un punto en el mapa.'
              : 'Coordenadas: $coordinatesText',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
