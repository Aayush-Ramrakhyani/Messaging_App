import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:my_project1/Custom_Widget/app_theme.dart';
import 'package:my_project1/firebase_options.dart';
import 'package:my_project1/splashscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global notifier — AccountScreen writes to this to toggle dark mode.
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    runApp(_FirebaseErrorApp(error: e.toString()));
    return;
  }

  // Restore saved theme preference
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('dark_mode') ?? false;
  themeModeNotifier.value =
      isDark ? ThemeMode.dark : ThemeMode.light;

  // Handle notification tap when app was terminated
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    // Deep-link handling can be added here once named routes are set up
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, mode, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Vibe',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: const SplashScreen(),
      ),
    );
  }
}

class _FirebaseErrorApp extends StatelessWidget {
  final String error;
  const _FirebaseErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Failed to initialize Firebase:\n$error',
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
