import 'package:flutter/material.dart';
import '../../core/theme/pro_theme.dart';
import '../dashboard/pro_dashboard_screen.dart';
import '../financials/pro_earnings_screen.dart';
import '../health/pro_account_health_screen.dart';
import '../profile/pro_profile_screen.dart';
import '../profile/pro_settings_screen.dart';

class ProMainNavigationScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const ProMainNavigationScreen({super.key, required this.onLogout});

  @override
  State<ProMainNavigationScreen> createState() => _ProMainNavigationScreenState();
}

class _ProMainNavigationScreenState extends State<ProMainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      ProDashboardScreen(onLogout: widget.onLogout),
      const ProEarningsScreen(),
      const ProAccountHealthScreen(),
      ProProfileScreen(onLogout: widget.onLogout),
      ProSettingsScreen(onLogout: widget.onLogout),
    ];

    return Scaffold(
      backgroundColor: ProColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: ProColors.surface,
          border: Border(top: BorderSide(color: ProColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: ProColors.surface,
          selectedItemColor: ProColors.primary,
          unselectedItemColor: ProColors.textMuted,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              activeIcon: Icon(Icons.dashboard_rounded, color: ProColors.primary),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet, color: ProColors.primary),
              label: 'Earnings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shield_outlined),
              activeIcon: Icon(Icons.shield_rounded, color: ProColors.primary),
              label: 'Health',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded, color: ProColors.primary),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded, color: ProColors.primary),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
