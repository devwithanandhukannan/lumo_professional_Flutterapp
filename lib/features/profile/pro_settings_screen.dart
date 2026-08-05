import 'package:flutter/material.dart';
import '../../core/storage/pro_session_storage.dart';
import '../../core/theme/pro_theme.dart';
import '../health/pro_account_health_screen.dart';
import 'pro_profile_screen.dart';

class ProSettingsScreen extends StatelessWidget {
  final VoidCallback onLogout;
  const ProSettingsScreen({super.key, required this.onLogout});

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
            // Account Profile Header Card
            GlassCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProProfileScreen(onLogout: onLogout)),
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
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
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
                        Text(phone, style: const TextStyle(fontSize: 12, color: ProColors.textMuted)),
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
            _SettingTile(
              icon: Icons.badge_outlined,
              title: 'View & Edit Partner Profile',
              subtitle: 'Manage offered services, documents & credentials',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProProfileScreen(onLogout: onLogout)),
                );
              },
            ),

            const SizedBox(height: 16),
            const Text('DISPATCH & SAFETY', style: ProText.label),
            const SizedBox(height: 10),
            _SettingTile(
              icon: Icons.my_location_rounded,
              title: 'Dispatch Coverage & GPS Range',
              subtitle: '50.00 km radius · Live GPS Auto-Tracking Active',
              onTap: () {},
            ),
            _SettingTile(
              icon: Icons.shield_outlined,
              title: 'Account Health & Compliance',
              subtitle: 'Police clearance verified · Safety score 100%',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProAccountHealthScreen()));
              },
            ),
            _SettingTile(
              icon: Icons.notifications_outlined,
              title: 'Instant Job Dispatch Alerts',
              subtitle: 'Sound & vibration alert preferences',
              onTap: () {},
            ),

            const SizedBox(height: 32),
            GlassCard(
              onTap: onLogout,
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
