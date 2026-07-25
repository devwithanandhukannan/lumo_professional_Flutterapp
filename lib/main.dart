import 'package:flutter/material.dart';
import 'core/theme/pro_theme.dart';
import 'core/storage/pro_session_storage.dart';
import 'core/network/pro_api_client.dart';
import 'features/auth/pro_auth_screen.dart';
import 'features/onboarding/pro_registration_basics_screen.dart';
import 'features/navigation/pro_main_navigation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProSessionStorage.init();
  runApp(const LumoProApp());
}

class LumoProApp extends StatelessWidget {
  const LumoProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LUMO Partner — Verified Professionals',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ProTheme.darkTheme,
      home: const _ProAuthGate(),
    );
  }
}

class _ProAuthGate extends StatefulWidget {
  const _ProAuthGate();

  @override
  State<_ProAuthGate> createState() => _ProAuthGateState();
}

class _ProAuthGateState extends State<_ProAuthGate> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _isOnboardingComplete = false;

  @override
  void initState() {
    super.initState();
    _refreshSessionState();
  }

  Future<void> _refreshSessionState() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    if (!ProSessionStorage.isAuthenticated) {
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isOnboardingComplete = false;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final profileRes = await ProApiClient.getProfile();
      final user = profileRes['user'] ?? profileRes['data']?['user'] ?? {};
      final pro = profileRes['profile'] ?? profileRes['data']?['profile'] ?? {};

      final bool hasName = user['full_name'] != null &&
          user['full_name'].toString().trim().isNotEmpty &&
          user['full_name'] != 'New User' &&
          user['full_name'] != 'Professional';

      final bool hasLocation = (user['service_area'] != null && user['service_area'].toString().trim().isNotEmpty) ||
          (pro['service_area'] != null && pro['service_area'].toString().trim().isNotEmpty);

      final bool hasSelfie = pro['face_verification_url'] != null && pro['face_verification_url'].toString().trim().isNotEmpty;

      final bool isFullyRegistered = hasName && hasLocation && (hasSelfie || ProSessionStorage.isOnboardingComplete);

      await ProSessionStorage.setSession(
        token: ProSessionStorage.authToken ?? '',
        phone: user['phone_number']?.toString() ?? ProSessionStorage.userPhone,
        email: user['email']?.toString(),
        name: user['full_name']?.toString() ?? ProSessionStorage.userName,
        gender: user['gender']?.toString() ?? ProSessionStorage.gender,
        userId: user['id']?.toString() ?? ProSessionStorage.userId,
        verificationStatus: pro['verification_status']?.toString() ?? 'PENDING',
        isOnboardingComplete: isFullyRegistered,
      );

      if (mounted) {
        setState(() {
          _isAuthenticated = true;
          _isOnboardingComplete = isFullyRegistered;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isAuthenticated = ProSessionStorage.isAuthenticated;
          _isOnboardingComplete = ProSessionStorage.isOnboardingComplete;
          _isLoading = false;
        });
      }
    }
  }

  void _onLoginSuccess() {
    _refreshSessionState();
  }

  void _onLogout() async {
    await ProSessionStorage.clearSession();
    _refreshSessionState();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: ProColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: ProColors.primary),
              SizedBox(height: 16),
              Text(
                'Syncing profile with LUMO server...',
                style: TextStyle(color: ProColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // Step 1: Not logged in -> Show Auth screen (Phone + OTP)
    if (!_isAuthenticated) {
      return ProAuthScreen(onLoginSuccess: _onLoginSuccess);
    }

    // Step 2: Logged in but 4-step onboarding not completed -> Show Registration Basics
    if (!_isOnboardingComplete) {
      return ProRegistrationBasicsScreen(
        phoneNumber: ProSessionStorage.userPhone,
        onCompleted: _refreshSessionState,
      );
    }

    // Step 3: Onboarding complete -> Go directly to dashboard
    return ProMainNavigationScreen(onLogout: _onLogout);
  }
}
