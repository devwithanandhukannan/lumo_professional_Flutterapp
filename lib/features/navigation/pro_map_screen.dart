import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/pro_theme.dart';

class ProMapScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const ProMapScreen({super.key, required this.job});

  @override
  State<ProMapScreen> createState() => _ProMapScreenState();
}

class _ProMapScreenState extends State<ProMapScreen> {

  static const LatLng _proLocation = LatLng(12.9716, 77.5946);
  static const LatLng _customerLocation = LatLng(12.9783, 77.6408);

  final Set<Marker> _markers = {
    Marker(
      markerId: const MarkerId('pro_marker'),
      position: _proLocation,
      infoWindow: const InfoWindow(title: 'You (Professional)', snippet: 'On-Duty Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ),
    Marker(
      markerId: const MarkerId('customer_marker'),
      position: _customerLocation,
      infoWindow: const InfoWindow(title: 'Customer Address', snippet: 'Indiranagar, Bangalore'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ),
  };

  final Set<Polyline> _polylines = {
    const Polyline(
      polylineId: PolylineId('route'),
      points: [_proLocation, LatLng(12.9750, 77.6100), LatLng(12.9770, 77.6250), _customerLocation],
      color: ProColors.primary,
      width: 5,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final serviceName = widget.job['service_name']?.toString() ?? 'Service';
    final address = widget.job['customer_address']?.toString() ?? 'Address';

    return Scaffold(
      backgroundColor: ProColors.background,
      appBar: AppBar(
        backgroundColor: ProColors.surface,
        title: Text('Navigation: $serviceName'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(12.9750, 77.6177),
              zoom: 13.5,
            ),
            onMapCreated: (_) {},
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ProColors.cardBg.withAlpha(240),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ProColors.primary.withAlpha(80)),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: ProColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.navigation_rounded, color: ProColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('LIVE GOOGLE MAPS NAVIGATION', style: ProText.label),
                        const SizedBox(height: 2),
                        Text(address, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: ProColors.accentSoft, borderRadius: BorderRadius.circular(20)),
                    child: const Text('4.8 km · 12 min', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ProColors.accent)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
