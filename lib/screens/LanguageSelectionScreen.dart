import 'package:flutter/material.dart';
import 'package:full_gospel_hymnal/providers/settings_provider.dart';
import 'package:full_gospel_hymnal/screens/home_screen.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  void _finishFirstLaunch(BuildContext context, AppLanguage lang) {
    final settings = context.read<SettingsProvider>();
    
    // 1. Set the persistent language
    settings.updateDefaultLanguage(lang);
    
    // 2. Mark first launch as complete in Hive
    Hive.box('settings').put('isFirstRun', false);
    
    // 3. Navigate to Home and "kill" this screen so they can't go back to it
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD32F2F), Color(0xFF8B0000)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_books, size: 100, color: Colors.white),
            const SizedBox(height: 30),
            const Text(
              "Full Gospel Hymnal\nCantiques Plein Évangile",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 50),
            const Text(
              "Choose your preferred language\nChoisissez votre langue préférée",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 40),
            
            // ENGLISH BUTTON
            _langButton(
              context, 
              "English", 
              AppLanguage.en, 
              Icons.language_rounded
            ),
            
            const SizedBox(height: 20),
            
            // FRENCH BUTTON
            _langButton(
              context, 
              "Français", 
              AppLanguage.fr, 
              Icons.translate_rounded
            ),
          ],
        ),
      ),
    );
  }

  Widget _langButton(BuildContext context, String label, AppLanguage lang, IconData icon) {
    return SizedBox(
      width: 250,
      height: 60,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color.fromARGB(255, 12, 8, 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onPressed: () => _finishFirstLaunch(context, lang),
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}