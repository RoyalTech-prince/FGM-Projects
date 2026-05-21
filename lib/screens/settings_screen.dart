import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:full_gospel_hymnal/providers/settings_provider.dart';
import 'package:full_gospel_hymnal/screens/about_screen.dart'; // Make sure to import the new screen file

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Helper calculation to spawn the dropdown popup precisely aligned to the right-hand margin of the screen
  void _showRightAlignedMenu<T>({
    required BuildContext context,
    required List<PopupMenuEntry<T>> items,
    required ValueChanged<T> onSelected,
  }) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    
    // Setting up position vectors forcing alignment constraints to the far right edge
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(button.size.topRight(Offset.zero), ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<T>(
      context: context,
      position: position,
      items: items,
      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
    ).then((value) {
      if (value != null) onSelected(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    
    final isDark = theme.brightness == Brightness.dark;
    final isBlackTheme = settings.selectedtheme == AppThemeType.black;
    final isRedTheme = settings.selectedtheme == AppThemeType.red;
    final isEng = settings.defaultLanguage == AppLanguage.en;

    final Color cardBg = isRedTheme ? Colors.white : theme.cardColor;
    final Color itemTextColor = isRedTheme ? Colors.black : (isDark ? Colors.white : Colors.black87);
    final Color sectionTextColor = isRedTheme ? const Color(0xFFD32F2F) : (isDark ? Colors.white70 : Colors.black54);
    final Color dynamicIconColor = isBlackTheme ? Colors.white : const Color(0xFFD32F2F);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Header Label
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
                child: Text(
                  isEng ? "Settings" : "Paramètres",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isRedTheme ? Colors.white : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ),

              // SECTION 1: PREFERENCES
              _buildSectionHeader(isEng ? "PREFERENCES" : "PRÉFÉRENCES", sectionTextColor),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // 1. Language Row - Entire surface triggers right-aligned menu
                    Builder(
                      builder: (context) => ListTile(
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        leading: Icon(Icons.language, color: dynamicIconColor),
                        title: Text(isEng ? "App Language" : "Langue de l'application", style: TextStyle(color: itemTextColor, fontWeight: FontWeight.w600)),
                        subtitle: Text(settings.defaultLanguage == AppLanguage.en ? "English" : "Français", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        trailing: Icon(Icons.arrow_drop_down, color: itemTextColor.withOpacity(0.6)),
                        onTap: () => _showRightAlignedMenu<AppLanguage>(
                          context: context,
                          onSelected: (newLang) => settings.updateDefaultLanguage(newLang),
                          items: const [
                            PopupMenuItem(value: AppLanguage.en, child: Text("English (EN)")),
                            PopupMenuItem(value: AppLanguage.fr, child: Text("Français (FR)")),
                          ],
                        ),
                      ),
                    ),
                    _buildDivider(isRedTheme, isDark),
                    
                    // 2. Theme Row - Entire surface triggers right-aligned menu
                    Builder(
                      builder: (context) => ListTile(
                        leading: Icon(Icons.palette, color: dynamicIconColor),
                        title: Text(isEng ? "Theme Mode" : "Mode Thème", style: TextStyle(color: itemTextColor, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          settings.selectedtheme == AppThemeType.red 
                              ? (isEng ? "Red(default)" : "Rouge(defaut)") 
                              : (settings.selectedtheme == AppThemeType.white ? (isEng ? "White" : "Blanc") : (isEng ? "Black" : "Noir")),
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        trailing: Icon(Icons.arrow_drop_down, color: itemTextColor.withOpacity(0.6)),
                        onTap: () => _showRightAlignedMenu<AppThemeType>(
                          context: context,
                          onSelected: (newTheme) => settings.updateTheme(newTheme),
                          items: [
                            PopupMenuItem(value: AppThemeType.red, child: Text(isEng ? "Red" : "Rouge")),
                            PopupMenuItem(value: AppThemeType.white, child: Text(isEng ? "White" : "Blanc")),
                            PopupMenuItem(value: AppThemeType.black, child: Text(isEng ? "Black" : "Noir")),
                          ],
                        ),
                      ),
                    ),
                    _buildDivider(isRedTheme, isDark),

                    // 3. Typography Size Selection Item Row
                    ListTile(
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
                      leading: Icon(Icons.text_fields, color: dynamicIconColor),
                      title: Text(isEng ? "Lyrics Font Size" : "Taille de la police", style: TextStyle(color: itemTextColor, fontWeight: FontWeight.w600)),
                      subtitle: Text("${settings.fontSize.toInt()} pt", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, color: dynamicIconColor),
                            onPressed: () => settings.updateFontSize(false),
                          ),
                          IconButton(
                            icon: Icon(Icons.add_circle_outline, color: dynamicIconColor),
                            onPressed: () => settings.updateFontSize(true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20), 

              // SECTION 2: ABOUT (Standalone Isolated Box Layout Screen Router)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  leading: Icon(Icons.info_outline, color: dynamicIconColor),
                  title: Text(
                    isEng ? "About" : "À propos", 
                    style: TextStyle(color: itemTextColor, fontWeight: FontWeight.w600)
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: itemTextColor.withOpacity(0.5)),
                  // UPDATED: Navigates completely to an entirely standalone separate view layout screen
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildDivider(bool isRedTheme, bool isDark) {
    return Divider(
      indent: 55,
      endIndent: 15,
      height: 1,
      color: isRedTheme ? const Color(0xFFD32F2F).withOpacity(0.1) : (isDark ? Colors.white10 : Colors.black12),
    );
  }
}