import 'package:flutter/material.dart';
import 'core/theme/pro_theme.dart';
import 'core/storage/pro_session_storage.dart';
import 'features/auth/pro_auth_screen.dart';
import 'features/auth/pro_pending_screen.dart';
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
  bool? _isAuthenticated;
  bool _isOnboardingComplete = false;
  String _verificationStatus = 'PENDING';

  @override
  void initState() {
    super.initState();
    _refreshSessionState();
  }

  void _refreshSessionState() {
    setState(() {
      _isAuthenticated = ProSessionStorage.isAuthenticated;
      _isOnboardingComplete = ProSessionStorage.isOnboardingComplete;
      _verificationStatus = ProSessionStorage.verificationStatus;
    });
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
    if (_isAuthenticated == null) {
      return const Scaffold(
        backgroundColor: ProColors.background,
        body: Center(child: CircularProgressIndicator(color: ProColors.primary)),
      );
    }

    // Step 1: Not logged in -> Show Auth screen (Phone + OTP)
    if (!_isAuthenticated!) {
      return ProAuthScreen(onLoginSuccess: _onLoginSuccess);
    }

    // Step 2: Logged in but 4-step onboarding not completed -> Show Registration Basics
    if (!_isOnboardingComplete) {
      return ProRegistrationBasicsScreen(
        phoneNumber: ProSessionStorage.userPhone,
        onCompleted: _refreshSessionState,
      );
    }

    // Step 3: Onboarding complete, waiting for admin approval -> Show Pending Audit screen
    if (_verificationStatus != 'APPROVED') {
      return ProPendingScreen(
        onApproved: () => setState(() => _verificationStatus = 'APPROVED'),
        onLogout: _onLogout,
      );
    }

    // Step 4: Approved -> Show Main Navigation Dashboard
    return ProMainNavigationScreen(onLogout: _onLogout);
  }
}
