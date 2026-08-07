import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/pro_api_client.dart';
import '../../core/storage/pro_session_storage.dart';
import '../../core/theme/pro_theme.dart';
import '../../core/services/notification_service.dart';

class CountryRegion {
  final String code;
  final String name;
  final String flag;
  final String dialCode;

  const CountryRegion({
    required this.code,
    required this.name,
    required this.flag,
    required this.dialCode,
  });
}

const List<CountryRegion> defaultCountryRegions = [
  CountryRegion(code: 'IN', name: 'India', flag: '🇮🇳', dialCode: '+91'),
  CountryRegion(code: 'US', name: 'United States', flag: '🇺🇸', dialCode: '+1'),
  CountryRegion(code: 'GB', name: 'United Kingdom', flag: '🇬🇧', dialCode: '+44'),
  CountryRegion(code: 'AE', name: 'UAE', flag: '🇦🇪', dialCode: '+971'),
  CountryRegion(code: 'SG', name: 'Singapore', flag: '🇸🇬', dialCode: '+65'),
  CountryRegion(code: 'SA', name: 'Saudi Arabia', flag: '🇸🇦', dialCode: '+966'),
  CountryRegion(code: 'QA', name: 'Qatar', flag: '🇶🇦', dialCode: '+974'),
  CountryRegion(code: 'KW', name: 'Kuwait', flag: '🇰🇼', dialCode: '+965'),
  CountryRegion(code: 'OM', name: 'Oman', flag: '🇴🇲', dialCode: '+968'),
  CountryRegion(code: 'BH', name: 'Bahrain', flag: '🇧🇭', dialCode: '+973'),
  CountryRegion(code: 'MY', name: 'Malaysia', flag: '🇲🇾', dialCode: '+60'),
  CountryRegion(code: 'AU', name: 'Australia', flag: '🇦🇺', dialCode: '+61'),
  CountryRegion(code: 'DE', name: 'Germany', flag: '🇩🇪', dialCode: '+49'),
];

class ProAuthScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const ProAuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<ProAuthScreen> createState() => _ProAuthScreenState();
}

class _ProAuthScreenState extends State<ProAuthScreen>
    with TickerProviderStateMixin {
  bool _isRegisterMode = true;

  // Region & phone selection
  CountryRegion _selectedRegion = defaultCountryRegions.first;
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _otpSent = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  String? _error;
  String? _infoMessage;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  String get _normalizedPhone {
    String digits = _phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('91') && digits.length > 10 && _selectedRegion.dialCode == '+91') {
      digits = digits.substring(2);
    }
    return '${_selectedRegion.dialCode}$digits';
  }

  Future<void> _sendOtp() async {
    final digits = _phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty || (digits.length < 7 && _selectedRegion.code != 'IN') || (digits.length < 10 && _selectedRegion.code == 'IN')) {
      setState(() => _error = 'Enter a valid mobile phone number');
      return;
    }
    setState(() { _isSendingOtp = true; _error = null; });
    try {
      final phone = _normalizedPhone;

      // Update 2: Pre-flight phone check — block re-registration of existing pros
      if (_isRegisterMode) {
        try {
          final checkRes = await ProApiClient.checkPhoneExists(phone);
          final checkData = (checkRes['data'] ?? checkRes) as Map<String, dynamic>;
          if (checkData['exists'] == true) {
            if (mounted) {
              setState(() {
                _isRegisterMode = false;
                _infoMessage = 'Phone already registered — switched to Sign In.';
              });
            }
          }
        } catch (_) {
          // Non-blocking: if pre-check fails, proceed normally
        }
      }

      final res = await ProApiClient.sendOtp(phone, isSignInMode: !_isRegisterMode);
      setState(() {
        _otpSent = true;
        final debugOtp = res['debugOtp']?.toString();
        _infoMessage = debugOtp != null
            ? 'Dev OTP: $debugOtp'
            : 'OTP sent to $phone';
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _verifyOtpAndSignIn() async {
    final code = _otpCtrl.text.trim();
    if (code.length < 6) {
      setState(() => _error = 'Enter the 6-digit OTP');
      return;
    }
    setState(() { _isVerifyingOtp = true; _error = null; });
    try {
      final phone = _normalizedPhone;
      final res = await ProApiClient.verifyOtp(
        phoneNumber: phone,
        otp: code,
        isSignInMode: !_isRegisterMode,
      );
      final data = res['data'] ?? res;
      final token = data['tokens']?['accessToken'] ?? data['accessToken'] ?? '';
      final user = data['user'] ?? {};
      final pro = data['profile'] ?? {};
      final isRegistered = data['isRegistered'] == true;

      final bool hasFullName = user['fullName'] != null &&
          user['fullName'].toString().trim().isNotEmpty &&
          user['fullName'] != 'New User' &&
          user['fullName'] != 'Professional';

      final bool hasLocation = (user['serviceArea'] != null && user['serviceArea'].toString().trim().isNotEmpty) ||
          (pro['service_area'] != null && pro['service_area'].toString().trim().isNotEmpty);

      final bool hasSelfie = pro['face_verification_url'] != null && pro['face_verification_url'].toString().trim().isNotEmpty;

      final bool isFullyRegistered = isRegistered && hasFullName && hasLocation && hasSelfie;

      await ProSessionStorage.setSession(
        token: token,
        phone: user['phoneNumber']?.toString() ?? phone,
        email: user['email']?.toString(),
        name: user['fullName']?.toString() ?? 'Professional',
        gender: user['gender']?.toString() ?? 'OTHER',
        userId: user['id']?.toString(),
        verificationStatus: data['verificationStatus']?.toString() ?? 'PENDING',
        isOnboardingComplete: isFullyRegistered,
      );

      // Sync FCM token now that auth token is saved — enables push notifications
      await NotificationService.syncFcmTokenAfterLogin();

      if (mounted) widget.onLoginSuccess();
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
  }

  void _showRegionPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ProColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Select Country / Region Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const Divider(color: ProColors.border, height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: defaultCountryRegions.length,
              itemBuilder: (ctx, i) {
                final region = defaultCountryRegions[i];
                final isSelected = region.code == _selectedRegion.code;
                return ListTile(
                  leading: Text(region.flag, style: const TextStyle(fontSize: 24)),
                  title: Text(region.name, style: TextStyle(color: isSelected ? ProColors.primary : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  trailing: Text(region.dialCode, style: TextStyle(color: isSelected ? ProColors.primary : ProColors.textMuted, fontWeight: FontWeight.bold)),
                  onTap: () {
                    setState(() => _selectedRegion = region);
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProColors.background,
      body: Stack(
        children: [
          _buildBackgroundBlobs(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildTabSwitcher(),
                    const SizedBox(height: 28),
                    _isRegisterMode ? _buildRegisterCard() : _buildSignInCard(),
                    const SizedBox(height: 24),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundBlobs() {
    return Stack(
      children: [
        Positioned(
          top: -100, right: -80,
          child: Container(
            width: 300, height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [ProColors.primary.withAlpha(40), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 50, left: -100,
          child: Container(
            width: 250, height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [ProColors.accent.withAlpha(30), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [ProColors.primary, ProColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: ProColors.primary.withAlpha(80), blurRadius: 30, offset: const Offset(0, 12)),
            ],
          ),
          child: const Icon(Icons.shield_rounded, size: 36, color: Colors.white),
        ),
        const SizedBox(height: 16),
        const Text('LUMO Partner', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        const Text('Verified Professional Portal', style: ProText.caption),
      ],
    );
  }

  Widget _buildTabSwitcher() {
    return GlassCard(
      padding: const EdgeInsets.all(4),
      borderRadius: 16,
      child: Row(
        children: [
          _tab('Create Account', _isRegisterMode, () => setState(() { _isRegisterMode = true; _otpSent = false; _error = null; })),
          _tab('Sign In', !_isRegisterMode, () => setState(() { _isRegisterMode = false; _otpSent = false; _error = null; })),
        ],
      ),
    );
  }

  Widget _tab(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? ProColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: selected ? Colors.white : ProColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneAndRegionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MOBILE PHONE & REGION', style: ProText.label),
        const SizedBox(height: 8),
        Row(
          children: [
            // Region Selector Dropdown Button
            GestureDetector(
              onTap: _showRegionPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                decoration: BoxDecoration(
                  color: ProColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ProColors.glassBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_selectedRegion.flag, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text(_selectedRegion.dialCode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, color: ProColors.textMuted, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Phone number textfield
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: ProColors.textPrimary, fontSize: 16, letterSpacing: 1),
                decoration: proInputDecoration(
                  hint: '98765 43210',
                  prefix: const Icon(Icons.phone_android, color: ProColors.primary, size: 20),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterCard() {
    return GlassCard(
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('NEW PROFESSIONAL ACCOUNT', style: ProText.label),
          const SizedBox(height: 4),
          const Text('4-Step Onboarding Pipeline', style: ProText.heading3),
          const SizedBox(height: 6),
          const Text('Select your country region and enter your mobile number to start.', style: ProText.caption),
          const SizedBox(height: 20),

          if (_error != null) _errorBanner(_error!),

          if (_infoMessage != null) _infoBanner(_infoMessage!),

          _buildPhoneAndRegionInput(),
          const SizedBox(height: 20),

          GradientButton(
            label: 'SEND OTP TO REGISTER',
            onTap: _sendOtp,
            isLoading: _isSendingOtp,
            icon: Icons.send_rounded,
          ),

          if (_otpSent) ...[
            const SizedBox(height: 20),
            const Divider(color: ProColors.glassBorder),
            const SizedBox(height: 16),
            const Text('VERIFICATION CODE', style: ProText.label),
            const SizedBox(height: 8),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.w800),
              decoration: proInputDecoration(hint: '· · · · · ·').copyWith(counterText: ''),
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: 'VERIFY & PROCEED TO STEP 2',
              onTap: _verifyOtpAndSignIn,
              isLoading: _isVerifyingOtp,
              icon: Icons.arrow_forward_rounded,
              colors: const [ProColors.accent, Color(0xFF059669)],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSignInCard() {
    return GlassCard(
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('EXISTING PARTNER', style: ProText.label),
          const SizedBox(height: 4),
          const Text('Welcome Back', style: ProText.heading3),
          const SizedBox(height: 6),
          const Text('Select your region and enter your registered mobile number.', style: ProText.caption),
          const SizedBox(height: 20),

          if (_error != null) _errorBanner(_error!),

          if (_infoMessage != null) _infoBanner(_infoMessage!),

          _buildPhoneAndRegionInput(),
          const SizedBox(height: 20),

          GradientButton(
            label: 'SEND OTP CODE',
            onTap: _sendOtp,
            isLoading: _isSendingOtp,
            icon: Icons.sms_rounded,
          ),

          if (_otpSent) ...[
            const SizedBox(height: 20),
            const Divider(color: ProColors.glassBorder),
            const SizedBox(height: 16),
            const Text('VERIFICATION CODE', style: ProText.label),
            const SizedBox(height: 8),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.w800),
              decoration: proInputDecoration(hint: '· · · · · ·').copyWith(counterText: ''),
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: 'VERIFY & SIGN IN',
              onTap: _verifyOtpAndSignIn,
              isLoading: _isVerifyingOtp,
              icon: Icons.login_rounded,
              colors: const [ProColors.primary, ProColors.primaryDark],
            ),
          ],
        ],
      ),
    );
  }

  Widget _errorBanner(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ProColors.emergencyRedSoft,
        border: Border.all(color: ProColors.emergencyRedBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: ProColors.emergencyRed, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: const TextStyle(color: ProColors.emergencyRed, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _infoBanner(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ProColors.primarySoft,
        border: Border.all(color: ProColors.primary.withAlpha(60)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: ProColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: const TextStyle(color: ProColors.primary, fontSize: 12, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return const Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, color: ProColors.accent, size: 16),
            SizedBox(width: 6),
            Text('Bank-Grade Security & Verification Audit', style: TextStyle(fontSize: 11, color: ProColors.textMuted)),
          ],
        ),
        SizedBox(height: 12),
        Text('By proceeding, you agree to LUMO Partner Terms & Security Guidelines.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: ProColors.textMuted)),
      ],
    );
  }
}
