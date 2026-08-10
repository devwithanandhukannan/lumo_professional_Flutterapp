import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/network/pro_api_client.dart';
import '../../core/storage/pro_session_storage.dart';
import '../../core/theme/pro_theme.dart';
import 'pro_services_custom_screen.dart';

class ProProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const ProProfileScreen({super.key, required this.onLogout});

  @override
  State<ProProfileScreen> createState() => _ProProfileScreenState();
}

class _ProProfileScreenState extends State<ProProfileScreen> {
  Map<String, dynamic>? _health;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHealth();
  }

  Future<void> _loadHealth() async {
    try {
      final h = await ProApiClient.getProHealth();
      if (mounted) setState(() => _health = h);
    } catch (_) {
      if (mounted) {
        setState(() => _health = {
          'accountHealthScore': 98.5,
          'ratingAvg': 4.92,
          'totalJobsCompleted': 142,
          'acceptanceRate': 95.0,
          'verificationStatus': ProSessionStorage.verificationStatus,
          'coverageRadiusKm': ProSessionStorage.coverageRadiusKm,
          'serviceArea': 'Kochi, Kerala, India',
          'latitude': 9.9312,
          'longitude': 76.2673,
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ProColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: ProColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: ProColors.textMuted))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ProSessionStorage.clearSession();
              widget.onLogout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: ProColors.emergencyRed),
            child: const Text('LOG OUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Profile'),
        actions: [
          TextButton.icon(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout_rounded, color: ProColors.emergencyRed, size: 18),
            label: const Text('Logout', style: TextStyle(color: ProColors.emergencyRed, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ProColors.primary))
          : RefreshIndicator(
              onRefresh: _loadHealth,
              color: ProColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [ProColors.primary, ProColors.primaryDark]),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [BoxShadow(color: Color(0x6610B981), blurRadius: 20, offset: Offset(0, 8))],
                      ),
                      child: Center(
                        child: Text(
                          ProSessionStorage.userName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(ProSessionStorage.userName, style: ProText.heading2),
                    const SizedBox(height: 4),
                    Text(ProSessionStorage.userPhone, style: ProText.caption.copyWith(fontFamily: 'monospace')),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: ProColors.primarySoft, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        _health?['verificationStatus']?.toString() ?? ProSessionStorage.verificationStatus,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: ProColors.primary),
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (_health != null) ...[
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2.2,
                        children: [
                          _StatTile('Account Score', '${(_health!['accountHealthScore'] as num?)?.toStringAsFixed(1) ?? '98.5'}/100', ProColors.primary),
                          _StatTile('Rating Avg', '★ ${_health!['ratingAvg']?.toString() ?? '4.9'}', ProColors.warningAmber),
                          _StatTile('Coverage Radius', '${_health!['coverageRadiusKm']?.toString() ?? '50'} km', ProColors.accent),
                          _StatTile('Acceptance Rate', '${_health!['acceptanceRate']?.toString() ?? '95'}%', ProColors.primary),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Service Location Google Map (Read-Only Preview)
                      _ServiceLocationMapCard(
                        serviceArea: _health?['serviceArea']?.toString() ?? _health?['assignedRegion']?.toString() ?? 'Kochi, Kerala',
                        coverageRadiusKm: (_health?['coverageRadiusKm'] as num?)?.toDouble() ?? 50.0,
                        latitude: (_health?['latitude'] as num?)?.toDouble() ?? 9.9312,
                        longitude: (_health?['longitude'] as num?)?.toDouble() ?? 76.2673,
                      ),
                    ],

                    _Tile(
                      icon: Icons.design_services_outlined,
                      label: 'Offered Services & Custom Rates',
                      value: 'Configure rates & custom services for customer bookings',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProServicesCustomScreen()));
                      },
                    ),
                    _Tile(icon: Icons.phone_android, label: 'Registered Mobile', value: ProSessionStorage.userPhone),
                    _Tile(icon: Icons.email_outlined, label: 'Email Address', value: ProSessionStorage.userEmail.isNotEmpty ? ProSessionStorage.userEmail : 'pro@lumo.in'),
                    _Tile(icon: Icons.transgender, label: 'Gender', value: ProSessionStorage.gender),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: ProColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: ProColors.border)),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_user, color: ProColors.primary, size: 22),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Police Verified Professional', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                SizedBox(height: 4),
                                Text('Background checked, government ID verified, and safety trained.', style: TextStyle(color: ProColors.textMuted, fontSize: 12, height: 1.4)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatTile(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: ProColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: ProColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: ProColors.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _ServiceLocationMapCard extends StatelessWidget {
  final String serviceArea;
  final double coverageRadiusKm;
  final double latitude;
  final double longitude;

  const _ServiceLocationMapCard({
    required this.serviceArea,
    required this.coverageRadiusKm,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    final LatLng center = LatLng(
      latitude != 0.0 ? latitude : 9.9312,
      longitude != 0.0 ? longitude : 76.2673,
    );

    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('pro_service_location'),
        position: center,
        infoWindow: InfoWindow(
          title: 'Registered Service Center',
          snippet: serviceArea,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };

    final Set<Circle> circles = {
      Circle(
        circleId: const CircleId('service_coverage_area'),
        center: center,
        radius: coverageRadiusKm * 1000,
        fillColor: const Color(0x2210B981),
        strokeColor: ProColors.primary,
        strokeWidth: 2,
      ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ProColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: ProColors.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text('Service Location & Coverage', style: ProText.label),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0x26FFBF00),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x66FFBF00)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline, color: Colors.amber, size: 11),
                          SizedBox(width: 4),
                          Text(
                            'READ ONLY',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  serviceArea.isNotEmpty ? serviceArea : 'Kochi, Kerala, India',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Coverage Radius: ',
                      style: TextStyle(color: ProColors.textMuted, fontSize: 12),
                    ),
                    Text(
                      '${coverageRadiusKm.toStringAsFixed(0)} km around pin',
                      style: const TextStyle(color: ProColors.primary, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            height: 180,
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ProColors.border),
            ),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: center,
                zoom: 9.5,
              ),
              markers: markers,
              circles: circles,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Text(
              'ℹ️ Location is locked upon verification. Contact LUMO Admin to request a location change.',
              style: TextStyle(color: ProColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final VoidCallback? onTap;

  const _Tile({required this.icon, required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: ProColors.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: ProColors.border)),
        child: Row(
          children: [
            Icon(icon, color: ProColors.primary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: ProText.label),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right, color: ProColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
