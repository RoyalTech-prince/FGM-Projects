import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:full_gospel_hymnal/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:full_gospel_hymnal/models/hymn.dart';

class LyricsScreen extends StatelessWidget {
  final Hymn hymn;
  const LyricsScreen({super.key, required this.hymn});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    final isWhiteTheme = settings.selectedtheme == AppThemeType.white;
    final isRedTheme = settings.selectedtheme == AppThemeType.red;
    
    final double topPadding = MediaQuery.of(context).padding.top;

    final statusBarTheme = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: theme.brightness == Brightness.dark 
          ? Brightness.light 
          : Brightness.dark,
      statusBarBrightness: theme.brightness,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusBarTheme,
      child: Scaffold(
        backgroundColor: isWhiteTheme ? const Color(0xFFF1F3F5) : (isRedTheme ? const Color(0xFFD32F2F) : Colors.black),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: topPadding, bottom: 5),
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildTopBarContent(context, theme, settings),
            ),
            
            _buildHymnHeader(theme, settings),
            
            _buildLyricsCard(context, theme, settings),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBarContent(BuildContext context, ThemeData theme, SettingsProvider settings) {
    final isRedTheme = settings.selectedtheme == AppThemeType.red;
    final isDark = theme.brightness == Brightness.dark;
    final Color iconColor = isRedTheme ? const Color(0xFFD32F2F) : (theme.brightness == Brightness.dark ? Colors.white : Colors.black);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: iconColor),
            onPressed: () => Navigator.pop(context),
          ),
          _languageToggle(settings, isRedTheme, isDark),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove, color: iconColor),
                onPressed: () => settings.updateFontSize(false),
              ),
              IconButton(
                icon: Icon(Icons.add, color: iconColor),
                onPressed: () => settings.updateFontSize(true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _languageToggle(SettingsProvider settings, bool isRedTheme, bool isDark){
    return InkWell(
      onTap: () => settings.toggleCurrentLanguage(),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          //Giving a transparent background
          border: Border.all(
            color: isRedTheme ? const Color(0xFFD32F2F) : (isDark ? Colors.white54 : Colors.black26),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            settings.isEnglish ? "EN" : "FR",
            key: ValueKey(settings.isEnglish),
            style: TextStyle(
              fontSize: 14,
              color: isRedTheme ? const Color(0xFFD32F2F) : (isDark ? Colors.white : Colors.black),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHymnHeader(ThemeData theme, SettingsProvider settings) {
    final isThemeRed = settings.selectedtheme == AppThemeType.red;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: isThemeRed ? Colors.white : (theme.brightness == Brightness.dark ? Colors.black : const Color.fromARGB(255, 218, 216, 216)),
      child: Text(
        "${hymn.number.toString().padLeft(2, '0')}. ${settings.isEnglish ? hymn.titleEn : hymn.titleFr}",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w900, 
          fontSize: 18,
          color: isThemeRed ? Colors.black : (theme.brightness == Brightness.dark ? Colors.white : const Color(0xFF2D3436)),
        ),
      ),
    );
  }

 Widget _buildLyricsCard(BuildContext context, ThemeData theme, SettingsProvider settings) {
  final isBlackTheme = settings.selectedtheme == AppThemeType.black;
  final isRedTheme = settings.selectedtheme == AppThemeType.red;

  return Expanded(
    child: Container(
      // 1. Forced width ensures the card doesn't change size with text
      width: double.infinity, 
      margin: const EdgeInsets.fromLTRB(15, 10, 15, 20),
      decoration: BoxDecoration(
        color: isRedTheme ? Colors.white : (isBlackTheme ? const Color(0xFF121212) : Colors.white),
        borderRadius: BorderRadius.circular(15),
        // Adding a subtle shadow makes the "fixed" area feel more grounded
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            // 2. Padding stays constant, font size only affects internal scrolling
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Text(
              settings.isEnglish ? hymn.lyricsEn : hymn.lyricsFr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: settings.fontSize,
                height: 1.6, // Increased line height for better readability
                color: isBlackTheme ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}