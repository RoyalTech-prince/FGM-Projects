import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

enum AppThemeType { white, red, black }
enum AppLanguage { en, fr }

class SettingsProvider extends ChangeNotifier {
  // Use a single box reference for cleaner code
  final Box _settingsBox = Hive.box('settings');

  double _fontSize = 18.0;

  //Global app language
  AppLanguage _defaultLanguage = AppLanguage.en;
  //Reading hymn language
  AppLanguage _currentLanguage = AppLanguage.en;

  AppThemeType _selectedTheme = AppThemeType.red;

  SettingsProvider(){
    _loadSettings();
  }

  void _loadSettings() {
    //Load language
    final langIndex = _settingsBox.get('languageIndex', defaultValue: 0);
    _defaultLanguage = AppLanguage.values[langIndex];
    _currentLanguage = _defaultLanguage; //Here the reding hymn language is reset to default on relaunch

    _fontSize = _settingsBox.get('fontSize', defaultValue: 18.0);
    //Load Theme
    final themeIndex = _settingsBox.get('themeIndex', defaultValue: AppThemeType.red.index);
    _selectedTheme = AppThemeType.values[themeIndex];
    notifyListeners();
  }

  //When the user chages their primary language in settings
  void updateDefaultLanguage(AppLanguage lang) {
    _defaultLanguage = lang;
    _currentLanguage = lang;
    _settingsBox.put('languageIndex', lang.index);
    notifyListeners();
  }

  //Toggle language management
  void toggleCurrentLanguage(){
    _currentLanguage = (_currentLanguage == AppLanguage.en)
        ? AppLanguage.fr : AppLanguage.en;
    notifyListeners();
  }

  //The app theme
  void updateTheme(AppThemeType theme){
    _selectedTheme = theme;
    _settingsBox.put('themeIndex', theme.index);
    notifyListeners();
  }

  void updateFontSize(bool increase){
    if (increase){
      if (_fontSize < 40) _fontSize +=1;
    }else {
      if (_fontSize > 12) _fontSize -=1;
    }
    _settingsBox.put('fontSize', _fontSize);
    notifyListeners();
  }

  AppLanguage get defaultLanguage => _defaultLanguage;
  AppLanguage get currentLanguage => _currentLanguage;
  AppThemeType get selectedtheme => _selectedTheme;
  bool get isEnglish => _currentLanguage == AppLanguage.en;
  double get fontSize => _fontSize;
}