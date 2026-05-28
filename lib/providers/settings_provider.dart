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

  AppThemeType _selectedTheme = AppThemeType.white;

  // NEW: List to keep track of favorited hymn numbers dynamically
  List<String> _favoriteHymnNumbers = [];

  SettingsProvider(){
    _loadSettings();
  }

  void _loadSettings() {
    //Load language
    final langIndex = _settingsBox.get('languageIndex', defaultValue: 0);
    _defaultLanguage = AppLanguage.values[langIndex];
    _currentLanguage = _defaultLanguage; //Here the reading hymn language is reset to default on relaunch

    _fontSize = _settingsBox.get('fontSize', defaultValue: 18.0);
    
    //Load Theme
    final themeIndex = _settingsBox.get('themeIndex', defaultValue: AppThemeType.white.index);
    _selectedTheme = AppThemeType.values[themeIndex];

    // NEW: Load favorite hymns from disk (defaulting to an empty list if none exist)
    final savedFavorites = _settingsBox.get('favorites', defaultValue: <dynamic>[]);
    _favoriteHymnNumbers = List<String>.from(savedFavorites);

    notifyListeners();
  }

  //When the user changes their primary language in settings
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

  // ==========================================================================
  // NEW: FAVORITES METHODS
  // ==========================================================================

  /// Toggles the favorite status of a hymn.
  /// Adds it if it's missing, or removes it if it's already favorited.
  void toggleFavorite(String hymnNumber) {
    if (_favoriteHymnNumbers.contains(hymnNumber)) {
      _favoriteHymnNumbers.remove(hymnNumber);
    } else {
      _favoriteHymnNumbers.add(hymnNumber);
    }
    // Save the updated primitive string list back into our single settings box
    _settingsBox.put('favorites', _favoriteHymnNumbers);
    notifyListeners(); // Forces UI (like the heart icon or list view) to update instantly
  }

  /// Checks if a specific hymn number is favorited.
  /// Used to decide whether to render an outlined or filled heart icon.
  bool isFavorite(String hymnNumber) {
    return _favoriteHymnNumbers.contains(hymnNumber);
  }

  // ==========================================================================
  // GETTERS
  // ==========================================================================
  AppLanguage get defaultLanguage => _defaultLanguage;
  AppLanguage get currentLanguage => _currentLanguage;
  AppThemeType get selectedtheme => _selectedTheme;
  bool get isEnglish => _currentLanguage == AppLanguage.en;
  double get fontSize => _fontSize;
  
  // NEW: Exposed getter to display the custom collection in your Favorites Screen
  List<String> get favoriteHymnNumbers => _favoriteHymnNumbers;
}