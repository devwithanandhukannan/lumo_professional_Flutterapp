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
        backgroundColor: ProColors.surface,
        title: const Text('Partner Account Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Account Profile Header Card
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProProfileScreen(onLogout: onLogout)),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ProColors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ProColors.primary.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 26,
                      backgroundColor: ProColors.primarySoft,
                      child: Icon(Icons.person, color: ProColors.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
            ElevatedButton.icon(
              onPressed: onLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0x22EF4444),
                foregroundColor: ProColors.emergencyRed,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: ProColors.emergencyRed),
                ),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('LOG OUT OF ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
      decoration: BoxDecoration(
        color: ProColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: ProColors.primarySoft, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: ProColors.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: ProColors.textMuted, fontSize: 11)),
        trailing: const Icon(Icons.chevron_right, color: ProColors.textMuted, size: 18),
      ),
    );
  }
}
