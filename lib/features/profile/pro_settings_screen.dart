import 'package:flutter/material.dart';
import '../../core/storage/pro_session_storage.dart';
import '../../core/theme/pro_theme.dart';
import '../health/pro_account_health_screen.dart';
import 'pro_profile_screen.dart';
import 'pro_services_custom_screen.dart';

class ProSettingsScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const ProSettingsScreen({super.key, required this.onLogout});

  @override
  State<ProSettingsScreen> createState() => _ProSettingsScreenState();
}

class _ProSettingsScreenState extends State<ProSettingsScreen> {
  late double _coverageRadius;

  @override
  void initState() {
    super.initState();
    _coverageRadius = ProSessionStorage.coverageRadiusKm;
  }

  void _openCoverageRangeModal() {
    double tempRadius = _coverageRadius;
    showModalBottomSheet(
      context: context,
      backgroundColor: ProColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: ProColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.my_location_rounded, color: ProColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dispatch Coverage & Radius', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Set maximum distance for receiving job dispatches', style: TextStyle(color: ProColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: ProColors.textMuted), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: ProColors.border, height: 1),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('COVERAGE RADIUS', style: ProText.label),
                  Text('${tempRadius.toStringAsFixed(0)} KM RADIUS', style: const TextStyle(color: ProColors.primary, fontWeight: FontWeight.w800, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 10),

              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: ProColors.primary,
                  inactiveTrackColor: ProColors.surface,
                  thumbColor: ProColors.accent,
                  overlayColor: const Color(0x3310B981),
                  valueIndicatorTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
                child: Slider(
                  value: tempRadius,
                  min: 5.0,
                  max: 100.0,
                  divisions: 19,
                  label: '${tempRadius.toStringAsFixed(0)} km',
                  onChanged: (val) {
                    setModalState(() => tempRadius = val);
                  },
                ),
              ),

              const SizedBox(height: 20),

              GradientButton(
                label: 'SAVE COVERAGE RADIUS',
                icon: Icons.check_circle_rounded,
                onTap: () async {
                  await ProSessionStorage.setCoverageRadiusKm(tempRadius);
                  setState(() => _coverageRadius = tempRadius);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Coverage radius updated to ${tempRadius.toStringAsFixed(0)} km! ✓'),
                        backgroundColor: ProColors.primary,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ProColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of your partner account?', style: TextStyle(color: ProColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: ProColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ProSessionStorage.clearSession();
              widget.onLogout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: ProColors.emergencyRed),
            child: const Text('LOG OUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = ProSessionStorage.userName;
    final phone = ProSessionStorage.userPhone;
    final email = ProSessionStorage.userEmail;
    final status = ProSessionStorage.verificationStatus;

    return Scaffold(
      backgroundColor: ProColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Partner Account Settings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Account Profile Header Hero Card
            GlassCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProProfileScreen(onLogout: widget.onLogout)),
                );
              },
              padding: const EdgeInsets.all(18),
              borderRadius: 22,
              borderColor: ProColors.primary.withAlpha(100),
              gradientColors: const [Color(0x2810B981), Color(0x0C10B981)],
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: ProColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: ProColors.primary.withAlpha(80), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(name.isNotEmpty ? name : 'Partner Pro', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: ProColors.primary, size: 16),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(phone, style: const TextStyle(fontSize: 12, color: ProColors.textMuted, fontFamily: 'monospace')),
                        if (email.isNotEmpty) Text(email, style: const TextStyle(fontSize: 11, color: ProColors.textMuted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: ProColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                    child: Text(status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: ProColors.primary)),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, color: ProColors.textMuted, size: 20),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text('ACCOUNT & SERVICES', style: ProText.label),
            const SizedBox(height: 10),

            // 1. Direct Page: Configure Services & Custom Rates
            _SettingTile(
              icon: Icons.design_services_rounded,
              title: 'Configure Services & Custom Rates',
              subtitle: 'Enable offerings, custom pricing & manage catalog',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProServicesCustomScreen()),
                );
              },
            ),

            // 2. Direct Action: Request Custom Service
            _SettingTile(
              icon: Icons.add_circle_outline_rounded,
              title: 'Request New Custom Service',
              subtitle: 'Submit an unlisted specialized service for Admin review',
              onTap: () {
                ProServicesCustomScreen.showCustomServiceModal(context);
              },
            ),

            const SizedBox(height: 20),
            const Text('DISPATCH & SAFETY', style: ProText.label),
            const SizedBox(height: 10),

            // 3. Interactive Dispatch Coverage
            _SettingTile(
              icon: Icons.my_location_rounded,
              title: 'Dispatch Coverage & GPS Range',
              subtitle: '${_coverageRadius.toStringAsFixed(0)} km radius · Live GPS Auto-Tracking Active',
              onTap: _openCoverageRangeModal,
            ),

            // 4. Account Health & Compliance
            _SettingTile(
              icon: Icons.shield_outlined,
              title: 'Account Health & Compliance',
              subtitle: 'Police clearance verified · Safety score 100%',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProAccountHealthScreen()));
              },
            ),

            const SizedBox(height: 32),

            // Logout Action Card
            GlassCard(
              onTap: _confirmLogout,
              gradientColors: const [Color(0x26EF4444), Color(0x0AEF4444)],
              borderColor: ProColors.emergencyRedBorder,
              borderRadius: 16,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: ProColors.emergencyRed, size: 20),
                  SizedBox(width: 10),
                  Text('LOG OUT OF ACCOUNT', style: TextStyle(color: ProColors.emergencyRed, fontWeight: FontWeight.w900, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: ProColors.primarySoft, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: ProColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: ProText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: ProColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
