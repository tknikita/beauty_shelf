import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_io.dart' if (dart.library.html) 'theme/app_theme_web.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  loadThemeFromStorage();
  runApp(const BeautyShelfApp());
}

class BeautyShelfApp extends StatefulWidget {
  const BeautyShelfApp({super.key});

  @override
  State<BeautyShelfApp> createState() => _BeautyShelfAppState();
}

class _BeautyShelfAppState extends State<BeautyShelfApp> {
  @override
  void initState() {
    super.initState();
    AppTheme.instance.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    AppTheme.instance.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;
    
    return MaterialApp(
      title: 'Beauty Shelf',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: theme.primaryColor,
          surface: theme.backgroundColor,
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
        primaryColor: theme.primaryColor,
        scaffoldBackgroundColor: theme.backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: theme.textColor,
          elevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.textColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
