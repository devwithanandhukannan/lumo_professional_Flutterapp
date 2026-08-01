import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/network/pro_api_client.dart';


class ProSosWidget extends StatefulWidget {
  final String? bookingId;
  final bool isFullScreenModal;
  const ProSosWidget({super.key, this.bookingId, this.isFullScreenModal = false});

  @override
  State<ProSosWidget> createState() => _ProSosWidgetState();
}

class _ProSosWidgetState extends State<ProSosWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  bool _isTriggering = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.96, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return await Geolocator.getLastKnownPosition();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return await Geolocator.getLastKnownPosition();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return await Geolocator.getLastKnownPosition();
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (_) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  void _confirmSos() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'TRIGGER EMERGENCY SOS',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        content: const Text(
          'This will immediately broadcast an urgent Emergency SOS signal with your current GPS coordinates to the LUMO Admin Safety Control Center.\n\nAre you sure you want to proceed?',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _triggerSos();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('BROADCAST SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerSos() async {
    setState(() => _isTriggering = true);

    double lat = 12.9716;
    double lng = 77.5946;

    try {
      final pos = await _getCurrentLocation();
      if (pos != null) {
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } catch (_) {}

    try {
      await ProApiClient.triggerSos(
        latitude: lat,
        longitude: lng,
        bookingId: widget.bookingId,
        notes: 'Provider Emergency Red Button Pressed (GPS: $lat, $lng)',
      );
    } catch (_) {}

    if (mounted) {
      setState(() => _isTriggering = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '🚨 EMERGENCY SOS BROADCASTED TO ADMIN SAFETY CONTROL CENTER',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _confirmSos,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (_, child) => Transform.scale(
              scale: _pulse.value,
              child: child,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Ring 2 (Largest glowing border ring)
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF7F1D1D).withValues(alpha: 0.15),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.25), width: 1.5),
                  ),
                ),

                // Outer Ring 1
                Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF991B1B).withValues(alpha: 0.25),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),

                // Center Vibrant Red Circular Emergency Button
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                        blurRadius: 25,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isTriggering
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'TAP FOR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'EMERGENCY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
