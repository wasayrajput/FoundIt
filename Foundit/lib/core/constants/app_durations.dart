/// Animation duration constants used across the app.
class AppDurations {
  AppDurations._();

  /// Total duration of the splash screen before navigation.
  static const Duration splashTotal = Duration(milliseconds: 4000);

  /// Fade-in animation for the logo.
  static const Duration logoFadeIn = Duration(milliseconds: 1200);

  /// Fade-in animation for the app name text.
  static const Duration nameFadeIn = Duration(milliseconds: 1000);

  /// Fade-in animation for the tagline text.
  static const Duration taglineFadeIn = Duration(milliseconds: 1000);

  /// Fade-in animation for the loading indicator.
  static const Duration loaderFadeIn = Duration(milliseconds: 800);

  /// Delay before starting logo animation.
  static const Duration logoDelay = Duration(milliseconds: 300);

  /// Delay before starting name animation (after logo starts).
  static const Duration nameDelay = Duration(milliseconds: 800);

  /// Delay before starting tagline animation (after name starts).
  static const Duration taglineDelay = Duration(milliseconds: 1400);

  /// Delay before starting loader animation (after tagline starts).
  static const Duration loaderDelay = Duration(milliseconds: 2000);
}
