import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';

import 'splash_screen.dart' as splash;
import 'auth_wrapper.dart';
import 'app_localization.dart';
import 'firebase_options.dart';

enum NotificationType { success, error, warning, info }

void showAppNotification({
  required String title,
  required String message,
  NotificationType type = NotificationType.info,
}) {
  Color background;
  IconData icon;

  switch (type) {
    case NotificationType.success:
      background = Color(0xFF4A22A8);
      icon = Icons.check_circle;
      break;
    case NotificationType.error:
      background = Colors.red;
      icon = Icons.error;
      break;
    case NotificationType.warning:
      background = Color(0xFF4A22A8);
      icon = Icons.warning;
      break;
    case NotificationType.info:
    default:
      background = Color(0xFF4A22A8);
      icon = Icons.info;
      break;
  }

  showSimpleNotification(
    Row(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    background: background,
    autoDismiss: true,
    duration: const Duration(seconds: 4),
    slideDismiss: true,
    position: NotificationPosition.top,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI style (light status bar for white theme)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Initialize localization first
  await AppLocalization.initialize();
  await _initializeApp();

  runApp(
    OverlaySupport.global(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: const MyAppWrapper(),
      ),
    ),
  );
}

Future<void> _initializeApp() async {
  try {
    // Initialize Firebase with the correct options for the running platform
    // (iOS vs Android). Hardcoding one platform crashes the app on the other.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print("✅ Firebase initialized successfully");
  } catch (e) {
    print("❌ Initialization failed: $e");
    // App continues without services if failed
  }
}

class MyAppWrapper extends StatelessWidget {
  const MyAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return MyApp(languageProvider: languageProvider);
      },
    );
  }
}

class MyApp extends StatelessWidget {
  final LanguageProvider languageProvider;

  const MyApp({
    super.key,
    required this.languageProvider,
  });

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      primarySwatch: Colors.deepPurple,
      primaryColor: const Color(0xFF4A22A8),
    );

    return ValueListenableBuilder<String>(
      valueListenable: AppLocalization.currentLanguage,
      builder: (context, currentLang, child) {
        return MaterialApp(
          title: 'Nico Mart LK',
          debugShowCheckedModeBanner: false,
          theme: baseTheme.copyWith(
            textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme),
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
              titleTextStyle: GoogleFonts.poppins(
                color: const Color(0xFF1A1A1A),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            textTheme: GoogleFonts.poppinsTextTheme(
              ThemeData.dark().textTheme,
            ),
          ),
          // Locale and localization setup
          locale: Locale(currentLang),
          supportedLocales: const [
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Start with smooth splash screen transitioning to auth wrapper
          home: splash.SplashScreen(
            nextScreen: const AuthWrapper(),
          ),
        );
      },
    );
  }
}

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'en';

  String get currentLanguage => 'en';

  LanguageProvider() {
    _currentLanguage = 'en';
  }

  void _onLanguageChanged() {
    _currentLanguage = 'en';
    notifyListeners();
  }

  Future<void> changeLanguage(String lang) async {
    // English only
    _currentLanguage = 'en';
    notifyListeners();
  }

  @override
  void dispose() {
    AppLocalization.currentLanguage.removeListener(_onLanguageChanged);
    super.dispose();
  }
}
