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
    
    // Gets the height of the status bar (time/battery area)
    final double topPadding = MediaQuery.of(context).padding.top;

    // Define the status bar icon color based on the theme brightness
    final statusBarTheme = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      // If the top bar is white (light), icons must be dark. If dark, icons must be light.
      statusBarIconBrightness: theme.brightness == Brightness.dark 
          ? Brightness.light 
          : Brightness.dark,
      statusBarBrightness: theme.brightness, // For iOS
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusBarTheme,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            // TOP BAR: Extended to the very top of the device
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
    // Determine icon color based on cardColor (White in Red theme, Dark in Black theme)
    final Color iconColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: iconColor),
            onPressed: () => Navigator.pop(context),
          ),
          _languageDropdown(settings),
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

  Widget _languageDropdown(SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF007A92),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: () => settings.toggleLanguage(),
        child: Row(
          children: [
            Text(
              settings.isEnglish ? "EN" : "FR",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildHymnHeader(ThemeData theme, SettingsProvider settings) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 0), // Touches the top bar
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: theme.brightness == Brightness.light ? const Color.fromARGB(230, 240, 239, 239) : Colors.grey[800],
      child: Text(
        "${hymn.number.toString().padLeft(2, '0')}. ${settings.isEnglish ? hymn.titleEn : hymn.titleFr}",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w900, 
          fontSize: 18,
          color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildLyricsCard(BuildContext context, ThemeData theme, SettingsProvider settings) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.fromLTRB(25, 20, 25, 20),
        padding: const EdgeInsets.symmetric(horizontal:10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(15), // Professional high-radius "Cut"
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Text(
              settings.isEnglish ? hymn.lyricsEn : hymn.lyricsFr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: settings.fontSize,
              height: 1.5,
              color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}