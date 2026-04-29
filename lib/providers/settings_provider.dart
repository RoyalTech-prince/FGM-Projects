import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

enum AppThemeType { white, red, black }

class SettingsProvider extends ChangeNotifier {
  // Use a single box reference for cleaner code
  final Box _box = Hive.box('settings');

  // --- STATE GETTERS ---

  // Fetches from Hive, defaults to red if null
  AppThemeType get selectedTheme {
    final themeIndex = _box.get('themeIndex', defaultValue: AppThemeType.red.index);
    return AppThemeType.values[themeIndex];
  }

  // Fetches from Hive, defaults to 18.0
  double get fontSize => _box.get('fontSize', defaultValue: 18.0);

  // Language preference: true = English, false = French
  bool get isEnglish => _box.get('isEnglish', defaultValue: true);

  // --- METHODS ---

  /// Persists the selected theme index to Hive
  void setTheme(AppThemeType theme) {
    _box.put('themeIndex', theme.index);
    notifyListeners();
  }

  /// Global language toggle for the LyricsScreen
  void toggleLanguage() {
    bool current = isEnglish;
    _box.put('isEnglish', !current);
    notifyListeners();
  }

  /// Updated to handle Delta (+1/-1) and persist to Hive
  void adjustFontSize(double delta) {
    double newSize = fontSize + delta;

    // Production-standard safety limits
    if (newSize >= 16.0 && newSize <= 40.0) {
      _box.put('fontSize', newSize);
      notifyListeners();
    }
  }

  /// Helper for your LyricsScreen buttons (+/-)
  void updateFontSize(bool increase) {
    adjustFontSize(increase ? 1.0 : -1.0);
  }
}