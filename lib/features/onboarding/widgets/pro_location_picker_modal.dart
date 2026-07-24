import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/pro_theme.dart';

class ProLocationPickerModal extends StatefulWidget {
  final String apiKey;
  final String initialAddress;

  const ProLocationPickerModal({
    super.key,
    this.apiKey = 'AIzaSyD9r59vIxUjLj3hiICvy9CYbXYbmil0Xb4',
    this.initialAddress = 'Kochi, Kerala',
  });

  @override
  State<ProLocationPickerModal> createState() => _ProLocationPickerModalState();
}

class _ProLocationPickerModalState extends State<ProLocationPickerModal> {
  GoogleMapController? _mapController;
  LatLng _currentCameraPos = const LatLng(9.9312, 76.2673); // Default Kochi
  String _selectedAddress = 'Fetching location...';
  String _cityName = 'Kochi';
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    _cityName = widget.initialAddress;
    _selectedAddress = widget.initialAddress;
    _locateCurrentPos();
  }

  Future<void> _locateCurrentPos() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        final latLng = LatLng(pos.latitude, pos.longitude);
        setState(() { _currentCameraPos = latLng; });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15.0));
        _reverseGeocode(latLng);
      }
    } catch (_) {
      _reverseGeocode(_currentCameraPos);
    }
  }

  Future<void> _reverseGeocode(LatLng target) async {
    setState(() => _isGeocoding = true);
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${target.latitude},${target.longitude}&key=${widget.apiKey}',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
        final first = data['results'][0];
        final formatted = first['formatted_address']?.toString() ?? '';

        String city = '';
        for (var comp in first['address_components'] as List) {
          final types = (comp['types'] as List).cast<String>();
          if (types.contains('locality') || types.contains('administrative_area_level_2')) {
            city = comp['long_name']?.toString() ?? '';
            break;
          }
        }

        if (mounted) {
          setState(() {
            _selectedAddress = formatted;
            _cityName = city.isNotEmpty ? city : formatted.split(',').first;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _selectedAddress = 'Location (${target.latitude.toStringAsFixed(4)}, ${target.longitude.toStringAsFixed(4)})';
            _cityName = 'Kochi';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _selectedAddress = 'Selected location (${target.latitude.toStringAsFixed(3)}, ${target.longitude.toStringAsFixed(3)})';
        });
      }
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: ProColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: ProColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.map_rounded, color: ProColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Select Service Area on Google Map', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Drag pin to your operational service region', style: TextStyle(color: ProColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: ProColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Google Map view container
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: _currentCameraPos, zoom: 14.0),
                  onMapCreated: (ctrl) {
                    _mapController = ctrl;
                  },
                  onCameraMove: (pos) {
                    _currentCameraPos = pos.target;
                  },
                  onCameraIdle: () {
                    _reverseGeocode(_currentCameraPos);
                  },
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),

                // Center Pin Icon
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: ProColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ProColors.primary),
                          ),
                          child: const Text('SERVICE PIN', style: TextStyle(color: ProColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 4),
                        const Icon(Icons.location_pin, color: ProColors.emergencyRed, size: 48),
                      ],
                    ),
                  ),
                ),

                // GPS My Location Floating Action
                Positioned(
                  right: 16, top: 16,
                  child: FloatingActionButton.small(
                    onPressed: _locateCurrentPos,
                    backgroundColor: ProColors.surface,
                    child: const Icon(Icons.my_location_rounded, color: ProColors.primary),
                  ),
                ),
              ],
            ),
          ),

          // Selected Address Detail Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: ProColors.cardBg,
              border: Border(top: BorderSide(color: ProColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: ProColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _cityName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    if (_isGeocoding) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: ProColors.primary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedAddress,
                  style: const TextStyle(color: ProColors.textMuted, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                GradientButton(
                  label: 'CONFIRM SERVICE LOCATION',
                  icon: Icons.check_circle_rounded,
                  onTap: () {
                    Navigator.pop(context, _cityName);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
