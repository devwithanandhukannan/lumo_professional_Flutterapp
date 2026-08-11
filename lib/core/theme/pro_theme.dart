import 'package:flutter/material.dart';
import 'pro_smooth_animations.dart';
import 'pro_theme_controller.dart';

// ─── Professional Pro Color Palette ──────────────────────────────────────────
class ProColors {
  // ── Dark Mode Base ─────────────────────────────────────────────────────────
  static const Color background   = Color(0xFF090E1A); // deepest midnight
  static const Color surface      = Color(0xFF101826); // card level
  static const Color surfaceHigh  = Color(0xFF182030); // elevated
  static const Color cardBg       = Color(0xFF101826); // alias

  // ── Light Mode Base ────────────────────────────────────────────────────────
  static const Color lightBackground   = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface      = Color(0xFFFFFFFF);
  static const Color lightSurfaceHigh  = Color(0xFFF1F5F9); // Slate 100
  static const Color lightCardBg       = Color(0xFFFFFFFF);
  static const Color lightBorder       = Color(0xFFE2E8F0); // Slate 200
  static const Color lightBorderSoft   = Color(0xFFEDF2F7);
  static const Color lightTextPrimary  = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF475569); // Slate 600
  static const Color lightTextMuted    = Color(0xFF64748B); // Slate 500

  // ── Legacy compat ──────────────────────────────────────────────────────────
  static const Color border            = Color(0xFF1A2A40);
  static const Color glassBg           = Color(0x00000000);
  static const Color glassBorder       = Color(0x00000000);
  static const Color glassBorderBright = Color(0x00000000);

  // ── Accent ─────────────────────────────────────────────────────────────────
  static const Color primary          = Color(0xFF059669); // Emerald 600
  static const Color primaryDark      = Color(0xFF047857);
  static const Color primaryLight     = Color(0xFF10B981); // Emerald 500
  static const Color primarySoft      = Color(0x140EA572);
  static const Color primaryGlow      = Color(0x280EA572);
  static const Color accent           = Color(0xFF2563EB);
  static const Color accentSoft       = Color(0x143B7FF5);
  static const Color emergencyRed     = Color(0xFFEF4444);
  static const Color emergencyRedSoft = Color(0x14EF4444);
  static const Color emergencyRedBorder = Color(0x33EF4444);
  static const Color warningAmber     = Color(0xFFF59E0B);
  static const Color warningAmberSoft = Color(0x14F59E0B);
  static const Color warningAmberBorder = Color(0x33F59E0B);
  static const Color purple           = Color(0xFF8B5CF6);
  static const Color purpleSoft       = Color(0x148B5CF6);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFEEF3FF);
  static const Color textSecondary = Color(0xFF94ABD0);
  static const Color textMuted     = Color(0xFF4A6080);
  static const Color textDisabled  = Color(0xFF253348);

  // ── Dynamic Helpers ────────────────────────────────────────────────────────
  static bool isDark([BuildContext? context]) {
    if (context != null) {
      return Theme.of(context).brightness == Brightness.dark;
    }
    return ProThemeController.instance.isDark;
  }

  static Color bg([BuildContext? context]) =>
      isDark(context) ? background : lightBackground;

  static Color surf([BuildContext? context]) =>
      isDark(context) ? surface : lightSurface;

  static Color surfHigh([BuildContext? context]) =>
      isDark(context) ? surfaceHigh : lightSurfaceHigh;

  static Color card([BuildContext? context]) =>
      isDark(context) ? surface : lightSurface;

  static Color txt([BuildContext? context]) =>
      isDark(context) ? textPrimary : lightTextPrimary;

  static Color txtSec([BuildContext? context]) =>
      isDark(context) ? textSecondary : lightTextSecondary;

  static Color txtMuted([BuildContext? context]) =>
      isDark(context) ? textMuted : lightTextMuted;

  static Color brd([BuildContext? context]) =>
      isDark(context) ? const Color(0xFF1A2A40) : lightBorder;

  static Color primaryAccent([BuildContext? context]) =>
      isDark(context) ? primaryLight : primary;

  static Color labelColor([BuildContext? context]) =>
      isDark(context) ? const Color(0xFF34D399) : primaryDark;

  // ── Shadow System ──────────────────────────────────────────────────────────

  /// Clean elevation shadow — single direction, professional
  static List<BoxShadow> cardShadow(BuildContext context, {double elevation = 1.0}) {
    if (isDark(context)) {
      return [
        BoxShadow(
          color: Colors.black.withAlpha((110 * elevation).round()),
          offset: Offset(0, 4 * elevation),
          blurRadius: 16 * elevation,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: Colors.black.withAlpha((45 * elevation).round()),
          offset: Offset(0, 1 * elevation),
          blurRadius: 4 * elevation,
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: const Color(0xFF7A93B8).withAlpha((38 * elevation).round()),
          offset: Offset(0, 4 * elevation),
          blurRadius: 16 * elevation,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: const Color(0xFF7A93B8).withAlpha((18 * elevation).round()),
          offset: Offset(0, 1 * elevation),
          blurRadius: 4 * elevation,
        ),
      ];
    }
  }

  /// Neumorphic pair — only meaningful in light mode
  static List<BoxShadow> neuRaised(BuildContext context, {double intensity = 1.0}) {
    if (isDark(context)) {
      return cardShadow(context, elevation: intensity);
    } else {
      return [
        BoxShadow(
          color: Colors.white.withAlpha(255),
          offset: Offset(-5 * intensity, -5 * intensity),
          blurRadius: 12 * intensity,
        ),
        BoxShadow(
          color: const Color(0xFFADC0D8).withAlpha((200 * intensity).round()),
          offset: Offset(5 * intensity, 5 * intensity),
          blurRadius: 12 * intensity,
        ),
      ];
    }
  }

  static List<BoxShadow> neuPressed(BuildContext context) {
    if (isDark(context)) {
      return [
        BoxShadow(
          color: Colors.black.withAlpha(120),
          offset: const Offset(0, 2),
          blurRadius: 6,
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: const Color(0xFFADC0D8).withAlpha(180),
          offset: const Offset(2, 2),
          blurRadius: 5,
        ),
        BoxShadow(
          color: Colors.white.withAlpha(255),
          offset: const Offset(-2, -2),
          blurRadius: 5,
        ),
      ];
    }
  }

  static List<BoxShadow> neuSmall(BuildContext context) =>
      neuRaised(context, intensity: 0.6);

  static List<BoxShadow> neuAccentGlow(Color accentColor) => [
        BoxShadow(
          color: accentColor.withAlpha(70),
          offset: const Offset(0, 8),
          blurRadius: 20,
          spreadRadius: -4,
        ),
      ];

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0EA572), Color(0xFF0A7D57)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF090E1A), Color(0xFF101826), Color(0xFF090E1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x00000000), Color(0x00000000)],
  );
}

// ─── Text Styles ──────────────────────────────────────────────────────────────
class ProText {
  static const TextStyle heading1 = TextStyle(
      fontSize: 26, fontWeight: FontWeight.w800, color: ProColors.textPrimary,
      letterSpacing: -0.5, fontFamily: 'Inter');
  static const TextStyle heading2 = TextStyle(
      fontSize: 20, fontWeight: FontWeight.w700, color: ProColors.textPrimary,
      letterSpacing: -0.3, fontFamily: 'Inter');
  static const TextStyle heading3 = TextStyle(
      fontSize: 16, fontWeight: FontWeight.w600, color: ProColors.textPrimary,
      fontFamily: 'Inter');
  static const TextStyle body = TextStyle(
      fontSize: 14, color: ProColors.textSecondary, height: 1.5, fontFamily: 'Inter');
  static const TextStyle caption = TextStyle(
      fontSize: 12, color: ProColors.textMuted, height: 1.4, fontFamily: 'Inter');
  static const TextStyle label = TextStyle(
      fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF34D399),
      letterSpacing: 1.0, fontFamily: 'Inter');
  static const TextStyle mono = TextStyle(
      fontSize: 13, fontFamily: 'monospace', color: ProColors.textPrimary);
  static const TextStyle buttonText = TextStyle(
      fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white,
      letterSpacing: 0.4, fontFamily: 'Inter');

  static TextStyle heading1Style(BuildContext context) => TextStyle(
      fontSize: 26, fontWeight: FontWeight.w800, color: ProColors.txt(context),
      letterSpacing: -0.5);
  static TextStyle heading2Style(BuildContext context) => TextStyle(
      fontSize: 20, fontWeight: FontWeight.w700, color: ProColors.txt(context),
      letterSpacing: -0.3);
  static TextStyle heading3Style(BuildContext context) => TextStyle(
      fontSize: 16, fontWeight: FontWeight.w600, color: ProColors.txt(context));
  static TextStyle bodyStyle(BuildContext context) => TextStyle(
      fontSize: 14, color: ProColors.txtSec(context), height: 1.5);
  static TextStyle captionStyle(BuildContext context) => TextStyle(
      fontSize: 12, color: ProColors.txtMuted(context), height: 1.4);
  static TextStyle labelStyle(BuildContext context) => TextStyle(
      fontSize: 11, fontWeight: FontWeight.w700,
      color: ProColors.labelColor(context), letterSpacing: 1.0);
}

// ─── Input Decoration ─────────────────────────────────────────────────────────
InputDecoration proInputDecoration({
  String? hint,
  Widget? prefix,
  String? label,
  Widget? suffix,
  BuildContext? context,
}) {
  final isDark = context == null || ProColors.isDark(context);
  final fillColor = isDark ? ProColors.surfaceHigh : const Color(0xFFF4F8FD);

  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
        color: isDark ? ProColors.textDisabled : ProColors.lightTextMuted,
        fontSize: 14),
    labelText: label,
    labelStyle: TextStyle(
        color: isDark ? ProColors.textMuted : ProColors.lightTextMuted,
        fontSize: 12),
    prefixIcon: prefix,
    suffixIcon: suffix,
    filled: true,
    fillColor: fillColor,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
          color: isDark ? ProColors.border : ProColors.lightBorder, width: 0.8),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: ProColors.primaryLight, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: ProColors.emergencyRed),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: ProColors.emergencyRed, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
  );
}

// ─── GlassCard — Professional elevated card ───────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double blurRadius;
  final Color borderColor;
  final double borderRadius;
  final double borderWidth;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;
  final bool isPressed;
  final Color? backgroundColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.blurRadius = 0,
    this.borderColor = Colors.transparent,
    this.borderRadius = 20,
    this.borderWidth = 0,
    this.gradientColors,
    this.onTap,
    this.isPressed = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ProColors.isDark(context);
    final bg = backgroundColor ?? ProColors.card(context);
    final effectiveShadows = isPressed
        ? ProColors.neuPressed(context)
        : ProColors.cardShadow(context);

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: effectiveShadows,
        border: isDark
            ? Border.all(color: const Color(0xFF1A2A40), width: 0.5)
            : Border.all(color: ProColors.lightBorderSoft, width: 0.8),
      ),
      child: child,
    );

    if (onTap != null) {
      return ProBounceTap(onTap: onTap, child: content);
    }
    return content;
  }
}

// ─── GradientButton ───────────────────────────────────────────────────────────
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
    this.colors = const [Color(0xFF0EA572), Color(0xFF0A7D57)],
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final List<Color> effectiveColors =
        isLoading ? [ProColors.surfaceHigh, ProColors.surface] : colors;

    return ProBounceTap(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: effectiveColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isLoading
              ? null
              : ProColors.neuAccentGlow(effectiveColors.first),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: ProColors.textMuted, strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 17),
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
      fontFamily: 'Inter',
      scaffoldBackgroundColor: ProColors.background,
      colorScheme: const ColorScheme.dark(
        primary: ProColors.primaryLight,
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
        titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: ProColors.textPrimary,
            fontFamily: 'Inter'),
        iconTheme: IconThemeData(color: ProColors.textMuted),
      ),
      cardTheme: CardThemeData(
        color: ProColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: ProColors.primaryLight,
        unselectedItemColor: ProColors.textMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: const Color(0xFF1A2A40),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: ProColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: ProColors.primary,
        secondary: ProColors.accent,
        surface: ProColors.lightSurface,
        error: ProColors.emergencyRed,
        onPrimary: Colors.white,
        onSurface: ProColors.lightTextPrimary,
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
        titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: ProColors.lightTextPrimary,
            fontFamily: 'Inter'),
        iconTheme: IconThemeData(color: ProColors.lightTextMuted),
      ),
      cardTheme: CardThemeData(
        color: ProColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ProColors.lightSurface,
        selectedItemColor: ProColors.primary,
        unselectedItemColor: ProColors.lightTextMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: ProColors.lightBorder,
    );
  }
}
