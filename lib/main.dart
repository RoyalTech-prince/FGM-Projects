import 'dart:io'; // Crucial for checking platform types (Linux vs Android)
import 'package:flutter/foundation.dart'; // Crucial for kIsWeb check
import 'package:flutter/material.dart';
import 'package:full_gospel_hymnal/providers/hymn_provider.dart';
import 'package:full_gospel_hymnal/screens/splash_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:full_gospel_hymnal/providers/settings_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:full_gospel_hymnal/models/hymn.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _buildThemeData(settings.selectedtheme),
      // NEW FLOW: 
      // 1. Always show SplashScreen first for branding/animation.
      // 2. The SplashScreen will then decide to go to LanguageSelection or Home.
      home: const SplashScreen(), 
    );
  }

  ThemeData _buildThemeData(AppThemeType type) {
    if (type == AppThemeType.red) {
      return ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFFD32F2F),
        primaryColor: Colors.white,
        cardColor: Colors.white,
        dividerColor: Colors.grey[300],
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
          bodyLarge: TextStyle(color: Colors.black87),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFD32F2F)),
      );
    } else if (type == AppThemeType.black) {
      return ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        cardColor: const Color(0xFF1E1E1E),
        dividerColor: Colors.white10,
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      );
    } else {
      // PROFESSIONAL WHITE THEME
      return ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF1F3F5), // Soft Gray Background
        cardColor: Colors.white,
        primaryColor: const Color(0xFF2D3436),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF2D3436)), // Charcoal Text
        ),
      );
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Make status bar transparent on mobile devices
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Initialize Local Databases (Hive)
  await Hive.initFlutter();
  Hive.registerAdapter(HymnAdapter());
  await Hive.openBox('settings');
  //await Hive.box('settings').clear();
  await Hive.deleteBoxFromDisk('hymnsBox');
  
  // WakelockPlus keeps the screen on while the app is open
  WakelockPlus.enable();

  // Create the core App runner widget structure
  final appRoot = MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ChangeNotifierProvider(create: (_) => HymnProvider()..initHymns()),
    ],
    child: const MyApp(),
  );

  // PLATFORM CHECK FOR DESKTOP WINDOW INITIALIZATION
  if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
    await windowManager.ensureInitialized();
    
    WindowOptions windowOptions = const WindowOptions(
      size: Size(400, 700),
      center: true,
      title: "Full Gospel Hymnal",
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Fallback / Main runner: Runs globally regardless of execution environment
  runApp(appRoot);
}