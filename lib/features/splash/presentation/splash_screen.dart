import 'package:flutter/material.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/core/constants/app_durations.dart';
import 'package:foundit/features/auth/presentation/sign_in_screen.dart';
import 'package:foundit/features/splash/presentation/widgets/animated_app_title.dart';
import 'package:foundit/features/splash/presentation/widgets/animated_loading_indicator.dart';
import 'package:foundit/features/splash/presentation/widgets/animated_logo.dart';

/// The splash/launch screen for the Foundit application.
///
/// Orchestrates a choreographed entrance of:
///   1. Background gradient
///   2. Animated logo (fade + scale)
///   3. App name (fade + slide)
///   4. Tagline (fade + slide)
///   5. Loading indicator (fade + pulse)
///
/// Designed to be responsive across phones and tablets.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToSignIn();
  }

  Future<void> _navigateToSignIn() async {
    // Wait for the total splash duration
    await Future.delayed(AppDurations.splashTotal);
    
    // Navigate to Sign In screen and remove splash from stack
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (context, animation, secondaryAnimation) => 
              const SignInScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double verticalSpacing = screenSize.height * 0.04;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gradientStart,
              AppColors.gradientMid,
              AppColors.gradientEnd,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top spacer — pushes content to visual center
              const Spacer(flex: 3),

              // --- Logo ---
              const AnimatedLogo(),

              SizedBox(height: verticalSpacing),

              // --- App name & tagline ---
              const AnimatedAppTitle(),

              // Bottom spacer before loader
              const Spacer(flex: 2),

              // --- Loading indicator ---
              const AnimatedLoadingIndicator(),

              SizedBox(height: screenSize.height * 0.06),
            ],
          ),
        ),
      ),
    );
  }
}
