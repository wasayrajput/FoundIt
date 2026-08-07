import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foundit/core/theme/app_theme.dart';
import 'package:foundit/features/splash/presentation/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for a controlled splash experience
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Make the status bar transparent to blend with the splash background
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const FounditApp());
}

class FounditApp extends StatelessWidget {
  const FounditApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foundit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      builder: (context, child) {
        // If running on web or desktop, constrain the app to a mobile phone width
        // so it looks like an app instead of stretching across the browser.
        if (kIsWeb || (!kIsWeb && (Theme.of(context).platform == TargetPlatform.windows || 
                                   Theme.of(context).platform == TargetPlatform.macOS || 
                                   Theme.of(context).platform == TargetPlatform.linux))) {
          return Center(
            child: Container(
              width: 420, // Typical max mobile width
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRect(child: child),
            ),
          );
        }
        return child!;
      },
    );
  }
}
