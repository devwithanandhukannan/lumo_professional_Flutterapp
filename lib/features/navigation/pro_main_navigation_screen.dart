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
    final isDark = ProColors.isDark(context);
    final List<Widget> pages = [
      ProDashboardScreen(onLogout: widget.onLogout),
      const ProInstantRequestsScreen(),
      const ProEarningsScreen(),
      ProSettingsScreen(onLogout: widget.onLogout),
    ];

    return Scaffold(
      backgroundColor: ProColors.bg(context),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        height: 68,
        decoration: BoxDecoration(
          color: ProColors.card(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? const Color(0xFF1A2A40) : ProColors.lightBorder,
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 110 : 28),
              blurRadius: 20,
              offset: const Offset(0, 6),
              spreadRadius: -4,
            ),
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
    );
  }
}

class _ProNavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? activeColor;

  const _ProNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = activeColor ??
        (isSelected ? ProColors.primaryAccent(context) : ProColors.primaryAccent(context));
    final Color effectiveColor = isSelected ? accent : ProColors.txtMuted(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? accent.withAlpha(20) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: effectiveColor,
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: effectiveColor,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 3,
                width: isSelected ? 18 : 0,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
