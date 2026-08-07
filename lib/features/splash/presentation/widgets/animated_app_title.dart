import 'package:flutter/material.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/core/constants/app_durations.dart';
import 'package:foundit/core/constants/app_strings.dart';
import 'package:google_fonts/google_fonts.dart';

/// Animated app name and tagline that fade in sequentially with
/// a subtle upward slide for depth.
class AnimatedAppTitle extends StatefulWidget {
  const AnimatedAppTitle({super.key});

  @override
  State<AnimatedAppTitle> createState() => _AnimatedAppTitleState();
}

class _AnimatedAppTitleState extends State<AnimatedAppTitle>
    with TickerProviderStateMixin {
  late final AnimationController _nameController;
  late final AnimationController _taglineController;

  late final Animation<double> _nameFade;
  late final Animation<Offset> _nameSlide;

  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;

  @override
  void initState() {
    super.initState();

    // --- App name animations ---
    _nameController = AnimationController(
      vsync: this,
      duration: AppDurations.nameFadeIn,
    );
    _nameFade = CurvedAnimation(
      parent: _nameController,
      curve: Curves.easeOut,
    );
    _nameSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _nameController,
      curve: Curves.easeOutCubic,
    ));

    // --- Tagline animations ---
    _taglineController = AnimationController(
      vsync: this,
      duration: AppDurations.taglineFadeIn,
    );
    _taglineFade = CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeOut,
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeOutCubic,
    ));

    // Stagger the entrances
    Future.delayed(AppDurations.nameDelay, () {
      if (mounted) _nameController.forward();
    });

    Future.delayed(AppDurations.taglineDelay, () {
      if (mounted) _taglineController.forward();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive font sizing
    final double screenWidth = MediaQuery.of(context).size.width;
    final double nameFontSize = screenWidth * 0.09;
    final double taglineFontSize = screenWidth * 0.038;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // App name
        SlideTransition(
          position: _nameSlide,
          child: FadeTransition(
            opacity: _nameFade,
            child: Text(
              AppStrings.appName,
              style: GoogleFonts.poppins(
                fontSize: nameFontSize.clamp(28, 42),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),

        SizedBox(height: screenWidth * 0.025),

        // Tagline
        SlideTransition(
          position: _taglineSlide,
          child: FadeTransition(
            opacity: _taglineFade,
            child: Text(
              AppStrings.tagline,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: taglineFontSize.clamp(13, 17),
                fontWeight: FontWeight.w400,
                color: AppColors.textTagline,
                letterSpacing: 0.3,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
