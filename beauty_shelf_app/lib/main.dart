import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'screens/home_screen.dart';
import 'services/image_recovery.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On Android, default gallery picking fires an implicit ACTION_GET_CONTENT
  // intent with no chooser, so the OS hands it to whatever app owns the
  // default handler (usually Google Photos). Opt into the system Photo Picker
  // so selection happens in an OS-owned UI instead.
  final pickerImpl = ImagePickerPlatform.instance;
  if (pickerImpl is ImagePickerAndroid) {
    pickerImpl.useAndroidPhotoPicker = true;
  }

  // Recover a photo the OS swallowed while the picker was foregrounded.
  await ImageRecovery.instance.check();

  // Initialize notification service. Never let a plugin failure (e.g. on
  // platforms without support) prevent the app from starting.
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }

  await Future.wait([
    loadThemeFromStorage(),
    loadDarkMode(),
    loadCategories(),
  ]);
  runApp(const BeautyShelfApp());
}

class BeautyShelfApp extends StatefulWidget {
  const BeautyShelfApp({super.key});

  @override
  State<BeautyShelfApp> createState() => _BeautyShelfAppState();
}

class _BeautyShelfAppState extends State<BeautyShelfApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppTheme.instance.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppTheme.instance.removeListener(_onThemeChange);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Activity re-creation after process death can deliver a parked picker
    // result on resume rather than at startup.
    if (state == AppLifecycleState.resumed) {
      ImageRecovery.instance.check();
    }
  }

  void _onThemeChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;
    
    return MaterialApp(
      title: 'Полочка',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: theme.primaryColor,
          surface: theme.backgroundColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
        primaryColor: theme.primaryColor,
        scaffoldBackgroundColor: theme.backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: theme.surfaceColor,
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
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.primaryColor, width: 2),
          ),
          fillColor: theme.backgroundColor,
          filled: true,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: theme.primaryColor,
          selectionColor: theme.primaryColor.withAlpha(77),
          selectionHandleColor: theme.primaryColor,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: theme.primaryColor,
          surface: theme.backgroundColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
        primaryColor: theme.primaryColor,
        scaffoldBackgroundColor: theme.backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: theme.surfaceColor,
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
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.primaryColor, width: 2),
          ),
          fillColor: theme.backgroundColor,
          filled: true,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: theme.primaryColor,
          selectionColor: theme.primaryColor.withAlpha(77),
          selectionHandleColor: theme.primaryColor,
        ),
      ),
      themeMode: theme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}
