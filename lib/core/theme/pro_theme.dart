import 'package:flutter/material.dart';
import 'dart:ui';
import 'pro_smooth_animations.dart';

// ─── Color Palette ────────────────────────────────────────────────────────────
class ProColors {
  static const Color background = Color(0xFF060A14);
  static const Color surface = Color(0xFF0C1222);
  static const Color cardBg = Color(0xFF111827);

  static const Color glassBg = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x26FFFFFF);
  static const Color glassBorderBright = Color(0x40FFFFFF);

  static const Color border = Color(0x1AFFFFFF);

  static const Color primary = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF059669);
  static const Color primarySoft = Color(0x1F10B981);
  static const Color primaryGlow = Color(0x4010B981);
  static const Color accent = Color(0xFF3B82F6);
  static const Color accentSoft = Color(0x1A3B82F6);
  static const Color emergencyRed = Color(0xFFEF4444);
  static const Color emergencyRedSoft = Color(0x1AEF4444);
  static const Color emergencyRedBorder = Color(0x40EF4444);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color warningAmberSoft = Color(0x1FF59E0B);
  static const Color warningAmberBorder = Color(0x40F59E0B);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleSoft = Color(0x1A8B5CF6);

  static const Color textPrimary = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF7C8DB0);
  static const Color textDisabled = Color(0xFF3D4A63);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF060A14), Color(0xFF0C1222), Color(0xFF060A14)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x22FFFFFF), Color(0x0AFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─── Text Styles ──────────────────────────────────────────────────────────────
class ProText {
  static const TextStyle heading1 = TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: ProColors.textPrimary, letterSpacing: -0.5);
  static const TextStyle heading2 = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ProColors.textPrimary, letterSpacing: -0.3);
  static const TextStyle heading3 = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ProColors.textPrimary);
  static const TextStyle body = TextStyle(fontSize: 14, color: ProColors.textSecondary, height: 1.5);
  static const TextStyle caption = TextStyle(fontSize: 12, color: ProColors.textMuted, height: 1.4);
  static const TextStyle label = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ProColors.textMuted, letterSpacing: 1.0);
  static const TextStyle mono = TextStyle(fontSize: 13, fontFamily: 'monospace', color: ProColors.textPrimary);
  static const TextStyle buttonText = TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.8);
}

// ─── Glassmorphism Helpers ────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double blurRadius;
  final Color borderColor;
  final double borderRadius;
  final double borderWidth;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.blurRadius = 20,
    this.borderColor = ProColors.glassBorder,
    this.borderRadius = 20,
    this.borderWidth = 1,
    this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors ?? [const Color(0x1AFFFFFF), const Color(0x0AFFFFFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return ProBounceTap(onTap: onTap, child: content);
    }
    return content;
  }
}

// Input Decoration
InputDecoration proInputDecoration({String? hint, Widget? prefix, String? label, Widget? suffix}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: ProColors.textDisabled, fontSize: 14),
    labelText: label,
    labelStyle: ProText.caption,
    prefixIcon: prefix,
    suffixIcon: suffix,
    filled: true,
    fillColor: const Color(0x14FFFFFF),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: ProColors.glassBorder, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: ProColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: ProColors.emergencyRed),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: ProColors.emergencyRed, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  );
}

// Gradient Button
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final double height;
  final List<Color> colors;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.height = 54,
    this.colors = const [Color(0xFF10B981), Color(0xFF059669)],
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ProBounceTap(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLoading ? [ProColors.surface, ProColors.surface] : colors,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
              ? []
              : [BoxShadow(color: colors.first.withAlpha(80), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(label, style: ProText.buttonText),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Theme ────────────────────────────────────────────────────────────────────
class ProTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ProColors.background,
      colorScheme: const ColorScheme.dark(
        primary: ProColors.primary,
        secondary: ProColors.accent,
        surface: ProColors.surface,
        error: ProColors.emergencyRed,
        onPrimary: Colors.white,
        onSurface: ProColors.textPrimary,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ProPageTransitionsBuilder(),
          TargetPlatform.iOS: ProPageTransitionsBuilder(),
          TargetPlatform.macOS: ProPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: ProColors.textPrimary),
        iconTheme: IconThemeData(color: ProColors.textMuted),
      ),
      cardTheme: CardThemeData(
        color: ProColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: ProColors.glassBorder),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ProColors.surface,
        selectedItemColor: ProColors.primary,
        unselectedItemColor: ProColors.textMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: ProColors.border,
    );
  }
}
