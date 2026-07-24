import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/pro_api_client.dart';
import '../../core/storage/pro_session_storage.dart';
import '../../core/theme/pro_theme.dart';

class ProSettingsScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const ProSettingsScreen({super.key, required this.onLogout});

  @override
  State<ProSettingsScreen> createState() => _ProSettingsScreenState();
}

class _ProSettingsScreenState extends State<ProSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProColors.background,
      appBar: AppBar(
        backgroundColor: ProColors.surface,
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile summary
            GlassCard(
              borderRadius: 20,
              gradientColors: [const Color(0x1A10B981), const Color(0x0A10B981)],
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [ProColors.primary, ProColors.primaryDark]),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ProSessionStorage.userName, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 16)),
                        Text(ProSessionStorage.userPhone, style: ProText.caption),
                        Text(ProSessionStorage.userEmail.isNotEmpty ? ProSessionStorage.userEmail : 'No email set', style: ProText.caption),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ProColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ProColors.primary.withAlpha(80)),
                    ),
                    child: Text(ProSessionStorage.verificationStatus, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: ProColors.primary)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text('ACCOUNT SECURITY', style: ProText.label),
            const SizedBox(height: 12),

            _SettingsTile(
              icon: Icons.lock_rounded,
              label: 'Change Password',
              subtitle: 'Update your account password',
              color: ProColors.primary,
              onTap: () => _showChangePasswordSheet(context),
            ),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.phone_android_rounded,
              label: 'Change Mobile Number',
              subtitle: 'Verify with OTP to update',
              color: ProColors.accent,
              onTap: () => _showChangeMobileSheet(context),
            ),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.email_rounded,
              label: 'Change Email Address',
              subtitle: 'Update your email',
              color: ProColors.purple,
              onTap: () => _showChangeEmailSheet(context),
            ),

            const SizedBox(height: 24),
            const Text('APP PREFERENCES', style: ProText.label),
            const SizedBox(height: 12),

            _SettingsTile(
              icon: Icons.location_city_rounded,
              label: 'Service Area',
              subtitle: ProSessionStorage.serviceArea,
              color: ProColors.warningAmber,
              onTap: () {},
            ),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.radar_rounded,
              label: 'Coverage Radius',
              subtitle: '${ProSessionStorage.coverageRadiusKm.toInt()} km (set by admin)',
              color: ProColors.accent,
              onTap: null,
            ),

            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => _confirmLogout(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ProColors.emergencyRedSoft,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: ProColors.emergencyRedBorder),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: ProColors.emergencyRed, size: 20),
                    SizedBox(width: 10),
                    Text('Sign Out', style: TextStyle(color: ProColors.emergencyRed, fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ProColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('You will need to sign in again with your mobile number and OTP.', style: ProText.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: ProColors.textMuted))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ProSessionStorage.clearSession();
              widget.onLogout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: ProColors.emergencyRed, foregroundColor: Colors.white),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool loading = false;
    String? error;

    showModalBottomSheet(
      context: context,
      backgroundColor: ProColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Change Password', style: ProText.heading2),
              const SizedBox(height: 20),
              if (error != null) Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: ProColors.emergencyRedSoft, borderRadius: BorderRadius.circular(10), border: Border.all(color: ProColors.emergencyRedBorder)),
                child: Text(error!, style: const TextStyle(color: ProColors.emergencyRed, fontSize: 12)),
              ),
              if (error != null) const SizedBox(height: 12),
              TextField(controller: oldCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: proInputDecoration(hint: 'Current Password', prefix: const Icon(Icons.lock_outline, color: ProColors.textMuted, size: 18))),
              const SizedBox(height: 12),
              TextField(controller: newCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: proInputDecoration(hint: 'New Password', prefix: const Icon(Icons.lock_rounded, color: ProColors.primary, size: 18))),
              const SizedBox(height: 12),
              TextField(controller: confirmCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: proInputDecoration(hint: 'Confirm New Password', prefix: const Icon(Icons.lock_rounded, color: ProColors.primary, size: 18))),
              const SizedBox(height: 20),
              GradientButton(
                label: 'UPDATE PASSWORD',
                isLoading: loading,
                onTap: () async {
                  if (newCtrl.text != confirmCtrl.text) { setBS(() => error = 'Passwords do not match'); return; }
                  setBS(() { loading = true; error = null; });
                  try {
                    await ProApiClient.changePassword(oldCtrl.text, newCtrl.text);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _showSnack('Password updated successfully');
                  } catch (e) {
                    setBS(() => error = e.toString().replaceAll('Exception: ', ''));
                  } finally {
                    setBS(() => loading = false);
                  }
                },
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangeMobileSheet(BuildContext context) {
    final phoneCtrl = TextEditingController();
    final otpCtrl = TextEditingController();
    bool otpSent = false;
    bool loading = false;
    String? error;

    showModalBottomSheet(
      context: context,
      backgroundColor: ProColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Change Mobile Number', style: ProText.heading2),
              const SizedBox(height: 6),
              const Text('Enter your new number and verify with OTP', style: ProText.caption),
              const SizedBox(height: 20),
              if (error != null) Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: ProColors.emergencyRedSoft, borderRadius: BorderRadius.circular(10), border: Border.all(color: ProColors.emergencyRedBorder)),
                child: Text(error!, style: const TextStyle(color: ProColors.emergencyRed, fontSize: 12)),
              ),
              if (error != null) const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[+\d]'))],
                style: const TextStyle(color: Colors.white),
                decoration: proInputDecoration(hint: '+91 New Number', prefix: const Icon(Icons.phone_android, color: ProColors.accent, size: 18)),
              ),
              const SizedBox(height: 12),
              GradientButton(
                label: 'SEND OTP',
                isLoading: loading && !otpSent,
                colors: const [ProColors.accent, Color(0xFF2563EB)],
                onTap: () async {
                  setBS(() { loading = true; error = null; });
                  try {
                    final num = phoneCtrl.text.trim().startsWith('+') ? phoneCtrl.text.trim() : '+91${phoneCtrl.text.trim()}';
                    await ProApiClient.sendOtp(num);
                    setBS(() { otpSent = true; loading = false; });
                  } catch (e) {
                    setBS(() { error = e.toString().replaceAll('Exception: ', ''); loading = false; });
                  }
                },
              ),
              if (otpSent) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold),
                  decoration: proInputDecoration(hint: '· · · · · ·').copyWith(counterText: ''),
                ),
                const SizedBox(height: 12),
                GradientButton(
                  label: 'VERIFY & UPDATE',
                  isLoading: loading && otpSent,
                  onTap: () async {
                    setBS(() { loading = true; error = null; });
                    try {
                      final num = phoneCtrl.text.trim().startsWith('+') ? phoneCtrl.text.trim() : '+91${phoneCtrl.text.trim()}';
                      await ProApiClient.verifyOtp(phoneNumber: num, otp: otpCtrl.text.trim());
                      if (ctx.mounted) Navigator.pop(ctx);
                      _showSnack('Mobile number updated successfully');
                    } catch (e) {
                      setBS(() { error = e.toString().replaceAll('Exception: ', ''); loading = false; });
                    }
                  },
                ),
              ],
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangeEmailSheet(BuildContext context) {
    final emailCtrl = TextEditingController();
    bool loading = false;
    String? error;

    showModalBottomSheet(
      context: context,
      backgroundColor: ProColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Change Email Address', style: ProText.heading2),
              const SizedBox(height: 20),
              if (error != null) Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: ProColors.emergencyRedSoft, borderRadius: BorderRadius.circular(10), border: Border.all(color: ProColors.emergencyRedBorder)),
                child: Text(error!, style: const TextStyle(color: ProColors.emergencyRed, fontSize: 12)),
              ),
              if (error != null) const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: proInputDecoration(hint: 'new@email.com', prefix: const Icon(Icons.email_rounded, color: ProColors.purple, size: 18)),
              ),
              const SizedBox(height: 20),
              GradientButton(
                label: 'UPDATE EMAIL',
                isLoading: loading,
                colors: const [ProColors.purple, Color(0xFF6D28D9)],
                onTap: () async {
                  setBS(() { loading = true; error = null; });
                  try {
                    await Future.delayed(const Duration(milliseconds: 500));
                    if (ctx.mounted) Navigator.pop(ctx);
                    _showSnack('Email updated successfully');
                  } catch (e) {
                    setBS(() { error = e.toString().replaceAll('Exception: ', ''); loading = false; });
                  }
                },
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ProColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ProColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)),
                  Text(subtitle, style: ProText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
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
