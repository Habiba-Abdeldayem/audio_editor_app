import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const seedColor = Color(0xFF6C5CE7);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        scaffoldBackgroundColor: const Color(0xFF121016),
      );
}
