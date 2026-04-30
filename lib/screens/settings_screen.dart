import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:full_gospel_hymnal/providers/settings_provider.dart';
import 'package:full_gospel_hymnal/utils/app_strings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to the SettingsProvider for any changes
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final lang = settings.defaultLanguage;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.settings(lang)),
        // AppBar color adapts to the theme
        backgroundColor: theme.brightness == Brightness.dark 
            ? Colors.black 
            : const Color(0xFFD32F2F),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSectionHeader(AppStrings.appearance(lang), theme),
          
          // --- THEME SELECTION ---
          ListTile(
            leading: const Icon(Icons.palette),
            title: Text(AppStrings.theme(lang)),
            subtitle: Text(_getThemeName(settings.selectedtheme, lang)),
            onTap: () => _showThemeDialog(context, settings),
          ),

          // --- FONT SIZE ADJUSTMENT ---
          ListTile(
            leading: const Icon(Icons.format_size),
            title: Text(lang == AppLanguage.en ? "Lyrics Font Size" : "Taille de la police"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => settings.updateFontSize(false),
                ),
                Text(
                  settings.fontSize.toInt().toString(), 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => settings.updateFontSize(true),
                ),
              ],
            ),
          ),

          const Divider(),
          _buildSectionHeader(AppStrings.language(lang), theme),

          // --- DEFAULT LANGUAGE SELECTION ---
          RadioListTile<AppLanguage>(
            title: const Text("English"),
            subtitle: const Text("Set as default language"),
            value: AppLanguage.en,
            groupValue: settings.defaultLanguage,
            activeColor: const Color(0xFFD32F2F),
            onChanged: (val) {
              if (val != null) settings.updateDefaultLanguage(val);
            },
          ),
          RadioListTile<AppLanguage>(
            title: const Text("Français"),
            subtitle: const Text("Définir comme langue par défaut"),
            value: AppLanguage.fr,
            groupValue: settings.defaultLanguage,
            activeColor: const Color(0xFFD32F2F),
            onChanged: (val) {
              if (val != null) settings.updateDefaultLanguage(val);
            },
          ),
        ],
      ),
    );
  }

  // Helper for Section Titles (APPEARANCE, LANGUAGE, etc.)
  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: theme.brightness == Brightness.dark 
              ? Colors.redAccent 
              : const Color(0xFFD32F2F),
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Maps the Enum to the String in AppStrings
  String _getThemeName(AppThemeType type, AppLanguage lang) {
    switch (type) {
      case AppThemeType.red:
        return AppStrings.themeRed(lang);
      case AppThemeType.white:
        return AppStrings.themeWhite(lang);
      case AppThemeType.black:
        return AppStrings.themeBlack(lang);
    }
  }

  // Displays the Theme selection popup
  void _showThemeDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.theme(settings.defaultLanguage)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeType.values.map((type) {
            return RadioListTile<AppThemeType>(
              title: Text(_getThemeName(type, settings.defaultLanguage)),
              value: type,
              groupValue: settings.selectedtheme, // Matches your getter
              onChanged: (val) {
                if (val != null) {
                  settings.updateTheme(val);
                  Navigator.pop(context); // Close dialog after selection
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}