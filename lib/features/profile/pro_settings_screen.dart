import 'package:flutter/material.dart';
import '../../core/theme/pro_theme.dart';
import '../health/pro_account_health_screen.dart';

class ProSettingsScreen extends StatelessWidget {
  final VoidCallback onLogout;
  const ProSettingsScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProColors.background,
      appBar: AppBar(
        backgroundColor: ProColors.surface,
        title: const Text('App Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('APP PREFERENCES', style: ProText.label),
            const SizedBox(height: 10),
            _SettingTile(
              icon: Icons.shield_outlined,
              title: 'About & Account Health',
              subtitle: 'View safety score, compliance & account health status',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProAccountHealthScreen()));
              },
            ),
            _SettingTile(
              icon: Icons.notifications_outlined,
              title: 'Push Notifications',
              subtitle: 'Sound, vibration & job alert preferences',
              onTap: () {},
            ),
            _SettingTile(
              icon: Icons.language,
              title: 'App Language',
              subtitle: 'English (US)',
              onTap: () {},
            ),

            const SizedBox(height: 24),
            const Text('SUPPORT & LEGAL', style: ProText.label),
            const SizedBox(height: 10),
            _SettingTile(
              icon: Icons.help_outline,
              title: 'Partner Support & Hotline',
              subtitle: '24/7 Priority escalation center',
              onTap: () {},
            ),
            _SettingTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy & Terms',
              subtitle: 'Legal information and user data policies',
              onTap: () {},
            ),

            const SizedBox(height: 30),
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
