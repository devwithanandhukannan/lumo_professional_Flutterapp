import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/pro_theme.dart';
import '../dashboard/pro_dashboard_screen.dart';
import '../financials/pro_earnings_screen.dart';
import '../jobs/pro_instant_requests_screen.dart';
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
      const ProInstantRequestsScreen(),
      const ProEarningsScreen(),
      ProSettingsScreen(onLogout: widget.onLogout),
    ];

    return Scaffold(
      backgroundColor: ProColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        height: 72,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0x2EFFFFFF), Color(0x12FFFFFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: ProColors.glassBorderBright, width: 1.2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(90), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                children: [
                  _ProNavItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isSelected: _currentIndex == 0,
                    onTap: () => setState(() => _currentIndex = 0),
                  ),
                  _ProNavItem(
                    icon: Icons.bolt_outlined,
                    activeIcon: Icons.bolt_rounded,
                    label: 'Requests',
                    isSelected: _currentIndex == 1,
                    onTap: () => setState(() => _currentIndex = 1),
                    activeColor: ProColors.warningAmber,
                  ),
                  _ProNavItem(
                    icon: Icons.account_balance_wallet_outlined,
                    activeIcon: Icons.account_balance_wallet_rounded,
                    label: 'Earnings',
                    isSelected: _currentIndex == 2,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                  _ProNavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                    isSelected: _currentIndex == 3,
                    onTap: () => setState(() => _currentIndex = 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProNavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;

  const _ProNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor = ProColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withAlpha(35) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? activeColor.withAlpha(140) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? activeColor : ProColors.textMuted,
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? activeColor : ProColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
