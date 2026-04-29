import 'package:flutter/material.dart';
import 'package:full_gospel_hymnal/providers/hymn_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:full_gospel_hymnal/providers/settings_provider.dart';
import 'package:full_gospel_hymnal/screens/home_screen.dart';
import 'package:window_manager/window_manager.dart';
import 'package:full_gospel_hymnal/models/hymn.dart';
import 'package:flutter/services.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // We listen to the theme choice here
    final selectedTheme = context.watch<SettingsProvider>().selectedTheme;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _buildThemeData(selectedTheme),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildThemeData(AppThemeType type) {
    if (type == AppThemeType.red) {
      return ThemeData(scaffoldBackgroundColor: const Color(0xFFD32F2F));
    } else if (type == AppThemeType.black) {
      return ThemeData(scaffoldBackgroundColor: Colors.black);
    } else {
      return ThemeData(scaffoldBackgroundColor: Colors.white);
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await Hive.initFlutter();

  //Make status bar transparent
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  Hive.registerAdapter(HymnAdapter());
  await Hive.openBox('settings');
  //await Hive.deleteBoxFromDisk('hymnsBox');

  WindowOptions windowOptions = const WindowOptions(
    size: Size(400, 700),
    center: true,
    title: "Full Gospel Hymnal",
  );
  await windowManager.waitUntilReadyToShow(windowOptions,() async {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => HymnProvider()..initHymns()),
        ],
        child: const MyApp(),
      ),
      
    );
  });
}

