import 'package:flutter/material.dart';
import '../storage/pro_session_storage.dart';

class ProThemeController extends ChangeNotifier {
  static final ProThemeController instance = ProThemeController._internal();

  ProThemeController._internal() {
    _loadThemeMode();
  }

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void _loadThemeMode() {
    _themeMode = ProSessionStorage.themeModePreference;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await ProSessionStorage.setThemeModePreference(mode);
  }

  String get themeModeLabel {
    switch (_themeMode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.dark:
        return 'Dark Mode';
      case ThemeMode.light:
        return 'Light Mode';
    }
  }
}
