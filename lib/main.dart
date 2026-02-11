import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DistroHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme, // Optional: enable dark mode support
      themeMode: ThemeMode.light,    // Change to ThemeMode.system for auto
      home: const LoginScreen(),
    );
  }
}