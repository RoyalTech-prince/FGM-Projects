import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:full_gospel_hymnal/providers/settings_provider.dart';
import 'package:full_gospel_hymnal/screens/about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
    final Color sectionTextColor = isRedTheme ? const Color.fromARGB(255, 248, 247, 247) : (isDark ? Colors.white70 : Colors.black54);
    final Color dynamicIconColor = isBlackTheme ? Colors.white : (isRedTheme ? Colors.black: const Color(0xFFD32F2F));

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
                    // 1. LANGUAGE SELECTION ROW Drawer
                    SlidingOptionRow(
                      leadingIcon: Icons.language,
                      iconColor: dynamicIconColor,
                      title: isEng ? "App Language" : "Langue de l'application",
                      currentSubtitle: settings.defaultLanguage == AppLanguage.en ? "English" : "Français",
                      textColor: itemTextColor,
                      // UPDATED: Language menu uses solid white banner background if red theme is active
                      drawerBgColor: isRedTheme ? Colors.white : (isDark ? const Color(0xFF1E1E1E) : Colors.grey[100]!),
                      childBuilder: (collapse) => Row(
                        children: [
                          _buildLanguageButton(
                            label: "English (EN)",
                            isSelected: settings.defaultLanguage == AppLanguage.en,
                            isRedTheme: isRedTheme,
                            textColor: itemTextColor,
                            onTap: () {
                              settings.updateDefaultLanguage(AppLanguage.en);
                              collapse();
                            },
                          ),
                          _buildLanguageButton(
                            label: "Français (FR)",
                            isSelected: settings.defaultLanguage == AppLanguage.fr,
                            isRedTheme: isRedTheme,
                            textColor: itemTextColor,
                            onTap: () {
                              settings.updateDefaultLanguage(AppLanguage.fr);
                              collapse();
                            },
                          ),
                        ],
                      ),
                    ),
                    _buildDivider(isRedTheme, isDark),
                    
                    // 2. THEME SELECTION ROW Drawer
                    SlidingOptionRow(
                      leadingIcon: Icons.palette,
                      iconColor: dynamicIconColor,
                      title: isEng ? "Theme Mode" : "Mode Thème",
                      currentSubtitle: settings.selectedtheme == AppThemeType.red 
                          ? (isEng ? "Red" : "Rouge") 
                          : (settings.selectedtheme == AppThemeType.white ? (isEng ? "White(Default)" : "Blanc(Defaut)") : (isEng ? "Black" : "Noir")),
                      textColor: itemTextColor,
                      // UPDATED: Theme menu background layer is ALWAYS locked to clean white
                      drawerBgColor: Colors.white,
                      childBuilder: (collapse) => Row(
                        children: [
                          _buildColorSquare(
                            color: const Color(0xFFD32F2F), // Red Swatch
                            isSelected: settings.selectedtheme == AppThemeType.red,
                            onTap: () {
                              settings.updateTheme(AppThemeType.red);
                              collapse();
                            },
                          ),
                          _buildColorSquare(
                            color: Colors.grey[300]!, // White Swatch (using safe light grey border outline)
                            isSelected: settings.selectedtheme == AppThemeType.white,
                            onTap: () {
                              settings.updateTheme(AppThemeType.white);
                              collapse();
                            },
                          ),
                          _buildColorSquare(
                            color: Colors.black, // Black Swatch
                            isSelected: settings.selectedtheme == AppThemeType.black,
                            onTap: () {
                              settings.updateTheme(AppThemeType.black);
                              collapse();
                            },
                          ),
                        ],
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

              // SECTION 2: ABOUT
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

  // Builder for the Text Options (Language View layout)
  Widget _buildLanguageButton({
    required String label,
    required bool isSelected,
    required bool isRedTheme,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    // FIXED: Forced high-contrast red styling if the main app layout is set to Red Theme
    final Color optionColor = isRedTheme 
        ? const Color(0xFFD32F2F) 
        : (isSelected ? const Color(0xFFD32F2F) : textColor.withOpacity(0.6));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14, 
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, 
            color: optionColor,
          ),
        ),
      ),
    );
  }

  // FIXED: Builder for the color square design tokens (Theme View layout)
  Widget _buildColorSquare({
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8), // clean square shape with slight rounding
          border: Border.all(
            // Show a visual border ring if selected, otherwise give a subtle frame to the light swatches
            color: isSelected 
                ? const Color(0xFFD32F2F) 
                : (color == Colors.black ? Colors.transparent : Colors.grey[400]!),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFFD32F2F).withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
          ],
        ),
      ),
    );
  }
}

// Highly customized stateful layout drawer mechanics wrapper
class SlidingOptionRow extends StatefulWidget {
  final IconData leadingIcon;
  final Color iconColor;
  final String title;
  final String currentSubtitle;
  final Color textColor;
  final Color drawerBgColor;
  final Widget Function(VoidCallback collapse) childBuilder;

  const SlidingOptionRow({
    super.key,
    required this.leadingIcon,
    required this.iconColor,
    required this.title,
    required this.currentSubtitle,
    required this.textColor,
    required this.drawerBgColor,
    required this.childBuilder,
  });

  @override
  State<SlidingOptionRow> createState() => _SlidingOptionRowState();
}

class _SlidingOptionRowState extends State<SlidingOptionRow> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: Stack(
        children: [
          ListTile(
            leading: Icon(widget.leadingIcon, color: widget.iconColor),
            title: Text(widget.title, style: TextStyle(color: widget.textColor, fontWeight: FontWeight.w600)),
            subtitle: Text(widget.currentSubtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            trailing: AnimatedRotation(
              turns: _isOpen ? -0.25 : 0.25, // Turns left arrow direction upon toggle open action
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.arrow_forward_ios, size: 14, color: widget.textColor.withOpacity(0.6)),
            ),
            onTap: _toggleMenu,
          ),
          Positioned.fill(
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                color: widget.drawerBgColor, // Dynamically configured background colors
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_forward, color: Color(0xFFD32F2F)),
                      onPressed: _toggleMenu,
                    ),
                    const VerticalDivider(width: 1, thickness: 1, color: Colors.black12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        // Pass the internal close trigger out to the layout tree children options
                        child: widget.childBuilder(_toggleMenu),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}