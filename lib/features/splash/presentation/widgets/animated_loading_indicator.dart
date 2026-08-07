import 'package:flutter/material.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/core/constants/app_durations.dart';

/// A custom animated loading indicator that fades in with a smooth
/// pulsing dot animation — more elegant than a standard spinner.
class AnimatedLoadingIndicator extends StatefulWidget {
  const AnimatedLoadingIndicator({super.key});

  @override
  State<AnimatedLoadingIndicator> createState() =>
      _AnimatedLoadingIndicatorState();
}

class _AnimatedLoadingIndicatorState extends State<AnimatedLoadingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Fade-in controller
    _fadeController = AnimationController(
      vsync: this,
      duration: AppDurations.loaderFadeIn,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Continuous pulse controller for the dots
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Delayed entrance
    Future.delayed(AppDurations.loaderDelay, () {
      if (mounted) {
        _fadeController.forward();
        _pulseController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizedBox(
        height: 24,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                // Stagger each dot by a phase offset
                final double phase = (index * 0.33);
                final double value =
                    ((_pulseController.value + phase) % 1.0);
                // Smooth sine-based bounce
                final double scale =
                    0.5 + 0.5 * _sineEase(value);
                final double opacity =
                    0.3 + 0.7 * _sineEase(value);

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryBlue,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue
                                  .withValues(alpha: 0.3 * opacity),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  /// Sine-based easing for smooth, organic motion
  double _sineEase(double t) {
    return (1.0 - (2.0 * t - 1.0).abs()).clamp(0.0, 1.0);
  }
}
