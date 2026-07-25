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
  bool _isSearching = false;
  MapType _currentMapType = MapType.normal;

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _cityName = widget.initialAddress;
    _selectedAddress = widget.initialAddress;
    _locateCurrentPos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        if (mounted) {
          setState(() { _currentCameraPos = latLng; });
        }
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16.0));
        _reverseGeocode(latLng);
        _showSnack('Updated to your current GPS location ✓');
      } else {
        _reverseGeocode(_currentCameraPos);
      }
    } catch (_) {
      _reverseGeocode(_currentCameraPos);
    }
  }

  Future<void> _searchPlace(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(query.trim())}&key=${widget.apiKey}',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
        final results = (data['results'] as List).take(5).map((item) {
          final loc = item['geometry']['location'];
          return {
            'formatted': item['formatted_address']?.toString() ?? '',
            'lat': (loc['lat'] as num).toDouble(),
            'lng': (loc['lng'] as num).toDouble(),
          };
        }).toList();

        if (mounted) {
          setState(() {
            _searchResults = results;
          });
        }
      } else {
        if (mounted) {
          setState(() => _searchResults = []);
          _showSnack('No locations found for "$query"');
        }
      }
    } catch (e) {
      if (mounted) _showSnack('Search error: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final latLng = LatLng(result['lat'], result['lng']);
    setState(() {
      _currentCameraPos = latLng;
      _searchResults = [];
      _searchController.text = result['formatted'];
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16.0));
    _reverseGeocode(latLng);
    FocusScope.of(context).unfocus();
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
        String state = '';
        for (var comp in first['address_components'] as List) {
          final types = (comp['types'] as List).cast<String>();
          if (types.contains('locality') || types.contains('sublocality_level_1') || types.contains('administrative_area_level_2')) {
            if (city.isEmpty) city = comp['long_name']?.toString() ?? '';
          }
          if (types.contains('administrative_area_level_1')) {
            state = comp['long_name']?.toString() ?? '';
          }
        }

        String displayLocation = '';
        if (city.isNotEmpty && state.isNotEmpty) {
          displayLocation = '$city, $state';
        } else if (city.isNotEmpty) {
          displayLocation = city;
        } else {
          final nonPlusParts = formatted.split(',').map((s) => s.trim()).where((s) => !s.contains('+')).toList();
          displayLocation = nonPlusParts.isNotEmpty ? nonPlusParts.take(2).join(', ') : formatted;
        }

        if (mounted) {
          setState(() {
            _selectedAddress = formatted;
            _cityName = displayLocation;
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

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  void _toggleMapType() {
    setState(() {
      if (_currentMapType == MapType.normal) {
        _currentMapType = MapType.satellite;
      } else if (_currentMapType == MapType.satellite) {
        _currentMapType = MapType.hybrid;
      } else {
        _currentMapType = MapType.normal;
      }
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ProColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
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
                      Text('Search or drag pin to operational region', style: TextStyle(color: ProColors.textMuted, fontSize: 11)),
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
                  mapType: _currentMapType,
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
                  zoomGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  scrollGesturesEnabled: true,
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

                // Search Bar Overlay
                Positioned(
                  left: 16, right: 16, top: 16,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: ProColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: ProColors.glassBorder),
                          boxShadow: const [
                            BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          onSubmitted: _searchPlace,
                          decoration: InputDecoration(
                            hintText: 'Search city, landmark, or address...',
                            hintStyle: const TextStyle(color: ProColors.textMuted, fontSize: 13),
                            prefixIcon: const Icon(Icons.search_rounded, color: ProColors.primary, size: 20),
                            suffixIcon: _isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: ProColors.primary)),
                                  )
                                : _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, color: ProColors.textMuted, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchResults = []);
                                        },
                                      )
                                    : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),

                      // Search Suggestions Dropdown
                      if (_searchResults.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: ProColors.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: ProColors.glassBorder),
                          ),
                          child: Column(
                            children: _searchResults.map((res) {
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.place_rounded, color: ProColors.accent, size: 18),
                                title: Text(res['formatted'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                                onTap: () => _selectSearchResult(res),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),

                // Floating Action Controls: Map Type, GPS, Zoom In, Zoom Out
                Positioned(
                  right: 16, bottom: 20,
                  child: Column(
                    children: [
                      // Toggle Map Type Button (Satellite / Normal)
                      FloatingActionButton.small(
                        heroTag: 'mapTypeBtn',
                        onPressed: _toggleMapType,
                        backgroundColor: ProColors.surface,
                        child: Icon(
                          _currentMapType == MapType.normal ? Icons.satellite_alt_rounded : Icons.map_rounded,
                          color: ProColors.accent, size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Current Location GPS Button
                      FloatingActionButton.small(
                        heroTag: 'myLocBtn',
                        onPressed: _locateCurrentPos,
                        backgroundColor: ProColors.surface,
                        child: const Icon(Icons.my_location_rounded, color: ProColors.primary, size: 20),
                      ),
                      const SizedBox(height: 8),

                      // Zoom In Button
                      FloatingActionButton.small(
                        heroTag: 'zoomInBtn',
                        onPressed: _zoomIn,
                        backgroundColor: ProColors.surface,
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(height: 8),

                      // Zoom Out Button
                      FloatingActionButton.small(
                        heroTag: 'zoomOutBtn',
                        onPressed: _zoomOut,
                        backgroundColor: ProColors.surface,
                        child: const Icon(Icons.remove_rounded, color: Colors.white, size: 22),
                      ),
                    ],
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
                    Navigator.pop(context, {
                      'cityName': _cityName,
                      'address': _selectedAddress,
                      'latitude': _currentCameraPos.latitude,
                      'longitude': _currentCameraPos.longitude,
                    });
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
