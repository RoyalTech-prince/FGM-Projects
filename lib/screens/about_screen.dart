import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:full_gospel_hymnal/providers/settings_provider.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
    final Color dynamicIconColor = isBlackTheme ? Colors.white : const Color(0xFFD32F2F);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardBg,
        centerTitle: true, 
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: dynamicIconColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEng ? "About" : "À propos",
          style: TextStyle(color: itemTextColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      // UPDATED: Changed from Center() to Align() to pull content slightly upward
      body: Align(
        alignment: const Alignment(0.0, -0.5), // X: 0.0 (centered horizontally), Y: -0.3 (shifted up slightly)
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Shrinks column to fit contents only
            crossAxisAlignment: CrossAxisAlignment.center, // Keeps all elements centered horizontally
            children: [
              const SizedBox(height: 10),
              // App Branding Graphic Context
              CircleAvatar(
                radius: 45,
                backgroundColor: const Color(0xFFD32F2F),
                child: const Icon(Icons.auto_stories, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 25),
              Text(
                isEng ? "Full Gospel Mission Hymnal" : "Cantiques de la Mission du Plein Évangile",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.w700, 
                  color: itemTextColor, 
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Version 1.0.0",
                style: TextStyle(fontSize: 13, color: Colors.grey.withOpacity(0.8), letterSpacing: 0.5),
              ),
              const SizedBox(height: 30),
              Text(
                isEng
                    ? "PRAISE BE TO THE LORD OF HOST"
                    : "Louange à l'Éternel des armées",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.6, color: itemTextColor.withOpacity(0.8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}