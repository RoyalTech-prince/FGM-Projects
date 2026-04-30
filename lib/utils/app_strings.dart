import 'package:full_gospel_hymnal/providers/settings_provider.dart';

class AppStrings {
  // ---Home Screen---
  static String searchHint(AppLanguage lang) =>
      lang == AppLanguage.en ? "Search by title or number.." : "Rechercher par titre ou numero..";

  static String homeTitle(AppLanguage lang) =>
      lang == AppLanguage.en ? "Full Gospel Hymnal" : "Cantiques du Plein Évangile";

  // ---Settings Screen ---
  static String settings(AppLanguage lang) =>
      lang == AppLanguage.en ? "Settings" : "Paramètres";

  static String appearance(AppLanguage lang) =>
      lang == AppLanguage.en ? "Appearance" : "Apparence";

static String language(AppLanguage lang) =>
      lang == AppLanguage.en ? "Language" : "Langue";

static String theme(AppLanguage lang) =>
      lang == AppLanguage.en ? "Theme" : "Thème";

static String themeRed(AppLanguage lang) =>
      lang == AppLanguage.en ? "Red (Default)" : "Rouge (Défaut)";

static String themeWhite(AppLanguage lang) =>
      lang == AppLanguage.en ? "White" : "Blanc";

static String themeBlack(AppLanguage lang) =>
      lang == AppLanguage.en ? "Black" : "Noir";

static String welcome(AppLanguage lang) =>
      lang == AppLanguage.en ? "Welcome !" : "Bienvenue !";

static String selectLang(AppLanguage lang) =>
      lang == AppLanguage.en ? "Choose your preferred language" : "Choisissez votre langue préférée";

}