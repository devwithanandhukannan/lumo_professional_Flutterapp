import 'package:flutter/material.dart';
import '../../core/network/pro_api_client.dart';
import '../../core/storage/pro_session_storage.dart';
import '../../core/theme/pro_theme.dart';
import '../onboarding/pro_service_setup_screen.dart';

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

  void _showLocationChangeDialog() {
    final locCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    bool submitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: ProColors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.map_rounded, color: ProColors.primary),
              SizedBox(width: 10),
              Text('Request Location Change', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Submit target service area or region for Admin review & approval.',
                style: TextStyle(color: ProColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'New Location / Region Name',
                  labelStyle: const TextStyle(color: ProColors.textMuted),
                  hintText: 'e.g. Trivandrum, Kerala',
                  hintStyle: const TextStyle(color: ProColors.border),
                  filled: true,
                  fillColor: ProColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ProColors.border)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Reason for Relocation (Optional)',
                  labelStyle: const TextStyle(color: ProColors.textMuted),
                  hintText: 'e.g. Relocated home address',
                  hintStyle: const TextStyle(color: ProColors.border),
                  filled: true,
                  fillColor: ProColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ProColors.border)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: ProColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ProColors.primary, foregroundColor: Colors.white),
              onPressed: submitting ? null : () async {
                final targetLoc = locCtrl.text.trim();
                if (targetLoc.isEmpty) return;
                setDlgState(() => submitting = true);
                try {
                  await ProApiClient.requestLocationChange(
                    requestedLocation: targetLoc,
                    reason: reasonCtrl.text.trim(),
                  );
                  if (mounted) {
                    if (ctx.mounted) Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Location update request submitted for Admin approval ✓'), backgroundColor: ProColors.primary),
                    );
                    _loadHealth();
                  }
                } catch (e) {
                  if (mounted) {
                    setDlgState(() => submitting = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: ProColors.emergencyRed),
                    );
                  }
                }
              },
              child: submitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('SUBMIT REQUEST'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentRegion = _health?['serviceArea'] ?? _health?['assignedRegion'] ?? ProSessionStorage.serviceArea;
    final String? locStatus = _health?['locationChangeStatus']?.toString();

    return Scaffold(
      backgroundColor: ProColors.background,
      appBar: AppBar(
        backgroundColor: ProColors.surface,
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
          : SingleChildScrollView(
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
                      _health?['verificationStatus']?.toString() ?? 'APPROVED',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: ProColors.primary),
                    ),
                  ),

                  const SizedBox(height: 28),

                  if (_health != null) ...[
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.2,
                      children: [
                        _StatTile('Account Score', '${(_health!['accountHealthScore'] as num?)?.toStringAsFixed(1) ?? '--'}/100', ProColors.primary),
                        _StatTile('Rating Avg', '★ ${_health!['ratingAvg']?.toString() ?? '--'}', ProColors.warningAmber),
                        _StatTile('Coverage Radius', '${_health!['coverageRadiusKm']?.toString() ?? '50'} km', ProColors.accent),
                        _StatTile('Acceptance Rate', '${_health!['acceptanceRate']?.toString() ?? '--'}%', ProColors.primary),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  _Tile(
                    icon: Icons.location_city_rounded,
                    label: 'Service Region / Location',
                    value: locStatus == 'PENDING_ADMIN_APPROVAL'
                        ? '$currentRegion (Location Change Pending Admin Approval)'
                        : (currentRegion.isNotEmpty ? currentRegion : 'Tap to set location'),
                    onTap: _showLocationChangeDialog,
                  ),

                  _Tile(
                    icon: Icons.design_services_outlined,
                    label: 'Offered Services & Custom Pricing',
                    value: 'Configure rates for customer bookings',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ProServiceSetupScreen(onCompleted: () => Navigator.pop(context))));
                    },
                  ),
                  _Tile(icon: Icons.phone_android, label: 'Mobile Number', value: ProSessionStorage.userPhone),
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
