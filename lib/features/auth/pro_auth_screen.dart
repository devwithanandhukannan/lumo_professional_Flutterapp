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
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
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
    if (digits.startsWith('91') &&
        digits.length > 10 &&
        _selectedRegion.dialCode == '+91') {
      digits = digits.substring(2);
    }
    return '${_selectedRegion.dialCode}$digits';
  }

  Future<void> _sendOtp() async {
    final digits =
        _phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty ||
        (digits.length < 7 && _selectedRegion.code != 'IN') ||
        (digits.length < 10 && _selectedRegion.code == 'IN')) {
      setState(() => _error = 'Enter a valid mobile phone number');
      return;
    }
    setState(() {
      _isSendingOtp = true;
      _error = null;
    });
    try {
      final phone = _normalizedPhone;

      if (_isRegisterMode) {
        try {
          final checkRes = await ProApiClient.checkPhoneExists(phone);
          final checkData =
              (checkRes['data'] ?? checkRes) as Map<String, dynamic>;
          if (checkData['exists'] == true) {
            if (mounted) {
              setState(() {
                _isRegisterMode = false;
                _infoMessage =
                    'Phone already registered — switched to Sign In.';
              });
            }
          }
        } catch (_) {}
      }

      final res =
          await ProApiClient.sendOtp(phone, isSignInMode: !_isRegisterMode);
      setState(() {
        _otpSent = true;
        final debugOtp = res['debugOtp']?.toString();
        _infoMessage =
            debugOtp != null ? 'Dev OTP: $debugOtp' : 'OTP sent to $phone';
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
    setState(() {
      _isVerifyingOtp = true;
      _error = null;
    });
    try {
      final phone = _normalizedPhone;
      final res = await ProApiClient.verifyOtp(
        phoneNumber: phone,
        otp: code,
        isSignInMode: !_isRegisterMode,
      );
      final data = res['data'] ?? res;
      final token =
          data['tokens']?['accessToken'] ?? data['accessToken'] ?? '';
      final user = data['user'] ?? {};
      final pro = data['profile'] ?? {};
      final isRegistered = data['isRegistered'] == true;

      final bool hasFullName = user['fullName'] != null &&
          user['fullName'].toString().trim().isNotEmpty &&
          user['fullName'] != 'New User' &&
          user['fullName'] != 'Professional';
      final bool hasLocation =
          (user['serviceArea'] != null &&
              user['serviceArea'].toString().trim().isNotEmpty) ||
          (pro['service_area'] != null &&
              pro['service_area'].toString().trim().isNotEmpty);
      final bool hasSelfie = pro['face_verification_url'] != null &&
          pro['face_verification_url'].toString().trim().isNotEmpty;
      final bool isFullyRegistered =
          isRegistered && hasFullName && hasLocation && hasSelfie;

      await ProSessionStorage.setSession(
        token: token,
        phone: user['phoneNumber']?.toString() ?? phone,
        email: user['email']?.toString(),
        name: user['fullName']?.toString() ?? 'Professional',
        gender: user['gender']?.toString() ?? 'OTHER',
        userId: user['id']?.toString(),
        verificationStatus:
            data['verificationStatus']?.toString() ?? 'PENDING',
        isOnboardingComplete: isFullyRegistered,
      );

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
      backgroundColor: ProColors.card(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Select Country / Region Code',
                style: TextStyle(
                    color: ProColors.txt(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
          Divider(color: ProColors.brd(context), height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: defaultCountryRegions.length,
              itemBuilder: (ctx, i) {
                final region = defaultCountryRegions[i];
                final isSelected = region.code == _selectedRegion.code;
                return ListTile(
                  leading: Text(region.flag,
                      style: const TextStyle(fontSize: 24)),
                  title: Text(region.name,
                      style: TextStyle(
                          color: isSelected
                              ? ProColors.primaryAccent(context)
                              : ProColors.txt(context),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal)),
                  trailing: Text(region.dialCode,
                      style: TextStyle(
                          color: isSelected
                              ? ProColors.primaryAccent(context)
                              : ProColors.txtMuted(context),
                          fontWeight: FontWeight.bold)),
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
      backgroundColor: ProColors.bg(context),
      body: Stack(
        children: [
          _buildBackgroundBlobs(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildTabSwitcher(),
                    const SizedBox(height: 20),
                    _isRegisterMode
                        ? _buildRegisterCard()
                        : _buildSignInCard(),
                    const SizedBox(height: 28),
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
    final isDark = ProColors.isDark(context);
    return Stack(
      children: [
        Positioned(
          top: -80, right: -60,
          child: Container(
            width: 260, height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                ProColors.primary.withAlpha(isDark ? 35 : 18),
                Colors.transparent
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: 80, left: -80,
          child: Container(
            width: 220, height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                ProColors.accent.withAlpha(isDark ? 25 : 12),
                Colors.transparent
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [ProColors.primaryLight, ProColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                  color: ProColors.primary.withAlpha(90),
                  blurRadius: 28,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: const Icon(Icons.shield_rounded, size: 36, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          'LUMO Partner',
          style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: ProColors.txt(context),
              letterSpacing: 0.3),
        ),
        const SizedBox(height: 4),
        Text('Verified Professional Portal',
            style: ProText.captionStyle(context)),
      ],
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ProColors.surf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProColors.brd(context), width: 0.8),
        boxShadow: ProColors.cardShadow(context),
      ),
      child: Row(
        children: [
          _tab(
            'Create Account',
            _isRegisterMode,
            () => setState(() {
              _isRegisterMode = true;
              _otpSent = false;
              _error = null;
            }),
          ),
          _tab(
            'Sign In',
            !_isRegisterMode,
            () => setState(() {
              _isRegisterMode = false;
              _otpSent = false;
              _error = null;
            }),
          ),
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
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: ProColors.primary.withAlpha(70),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color:
                  selected ? Colors.white : ProColors.txtMuted(context),
            ),
          ),
        ),
      ),
    );
  }

  // ── Phone + Region Input ────────────────────────────────────────────────────
  Widget _buildPhoneAndRegionInput() {
    final isDark = ProColors.isDark(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MOBILE PHONE & REGION', style: ProText.labelStyle(context)),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: _showRegionPicker,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? ProColors.surfaceHigh : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: ProColors.brd(context), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_selectedRegion.flag,
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text(
                      _selectedRegion.dialCode,
                      style: TextStyle(
                          color: ProColors.txt(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down,
                        color: ProColors.txtMuted(context), size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                    color: ProColors.txt(context),
                    fontSize: 16,
                    letterSpacing: 1),
                decoration: proInputDecoration(
                  hint: '98765 43210',
                  prefix: Icon(Icons.phone_android,
                      color: ProColors.primaryAccent(context), size: 20),
                  context: context,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Form Cards ──────────────────────────────────────────────────────────────
  Widget _buildRegisterCard() {
    return _authCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('NEW PROFESSIONAL ACCOUNT', style: ProText.labelStyle(context)),
          const SizedBox(height: 4),
          Text('4-Step Onboarding Pipeline',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ProColors.txt(context))),
          const SizedBox(height: 6),
          Text(
              'Select your country region and enter your mobile number to start.',
              style: ProText.captionStyle(context)),
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
            Divider(color: ProColors.brd(context)),
            const SizedBox(height: 16),
            Text('VERIFICATION CODE', style: ProText.labelStyle(context)),
            const SizedBox(height: 8),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: ProColors.txt(context),
                  fontSize: 28,
                  letterSpacing: 12,
                  fontWeight: FontWeight.w800),
              decoration: proInputDecoration(hint: '· · · · · ·', context: context)
                  .copyWith(counterText: ''),
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: 'VERIFY & PROCEED',
              onTap: _verifyOtpAndSignIn,
              isLoading: _isVerifyingOtp,
              icon: Icons.arrow_forward_rounded,
              colors: const [ProColors.accent, Color(0xFF1D4ED8)],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSignInCard() {
    return _authCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('EXISTING PARTNER', style: ProText.labelStyle(context)),
          const SizedBox(height: 4),
          Text('Welcome Back',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ProColors.txt(context))),
          const SizedBox(height: 6),
          Text(
              'Select your region and enter your registered mobile number.',
              style: ProText.captionStyle(context)),
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
            Divider(color: ProColors.brd(context)),
            const SizedBox(height: 16),
            Text('VERIFICATION CODE', style: ProText.labelStyle(context)),
            const SizedBox(height: 8),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: ProColors.txt(context),
                  fontSize: 28,
                  letterSpacing: 12,
                  fontWeight: FontWeight.w800),
              decoration: proInputDecoration(hint: '· · · · · ·', context: context)
                  .copyWith(counterText: ''),
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: 'VERIFY & SIGN IN',
              onTap: _verifyOtpAndSignIn,
              isLoading: _isVerifyingOtp,
              icon: Icons.login_rounded,
              colors: const [ProColors.primaryLight, ProColors.primary],
            ),
          ],
        ],
      ),
    );
  }

  /// Theme-adaptive auth card
  Widget _authCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: ProColors.card(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ProColors.brd(context), width: 0.8),
        boxShadow: ProColors.cardShadow(context),
      ),
      child: child,
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
          const Icon(Icons.error_outline,
              color: ProColors.emergencyRed, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg,
                  style: const TextStyle(
                      color: ProColors.emergencyRed, fontSize: 13))),
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
          Icon(Icons.info_outline,
              color: ProColors.primaryAccent(context), size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg,
                  style: TextStyle(
                      color: ProColors.primaryAccent(context),
                      fontSize: 12,
                      height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined,
                color: ProColors.primaryAccent(context), size: 15),
            const SizedBox(width: 6),
            Text('Bank-Grade Security & Verification Audit',
                style: TextStyle(
                    fontSize: 11, color: ProColors.txtMuted(context))),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'By proceeding, you agree to LUMO Partner Terms & Security Guidelines.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: ProColors.txtMuted(context)),
        ),
      ],
    );
  }
}
