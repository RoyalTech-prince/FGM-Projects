import 'package:flutter/material.dart';
class AppThemes {
  static const Color fgmRed = Color(0xFFD32F2F);

  //1. White theme
  static final whiteTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: fgmRed,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(backgroundColor: fgmRed, foregroundColor: Colors.white),
    textTheme: const TextTheme(bodyLarge: TextStyle(color: Colors.black)),
  );

  //2. Red theme
  static final redTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.black,
    scaffoldBackgroundColor: fgmRed,
    appBarTheme: const AppBarTheme(backgroundColor: Colors.black, foregroundColor: Colors.white),
    textTheme: const TextTheme(bodyLarge: TextStyle(color: Colors.white)),
  );

  //3. Dark theme
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: fgmRed,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(backgroundColor: fgmRed, foregroundColor: Colors.white),
    textTheme: const TextTheme(bodyLarge: TextStyle(color: Colors.white)),
  );
}