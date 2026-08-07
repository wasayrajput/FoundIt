import 'package:foundit/core/state/app_state.dart';

/// Centralised string constants for the Foundit application.
class AppStrings {
  AppStrings._();

  static String get appName => AppState.instance.translate('Foundit');
  static String get tagline => AppState.instance.translate('Reconnecting People with What Matters.');
  
  // --- Auth Strings ---
  static String get welcomeBack => AppState.instance.translate('Welcome Back');
  static String get signInSubtitle => AppState.instance.translate('Sign in to continue using Foundit.');
  static String get emailLabel => AppState.instance.translate('Email');
  static String get passwordLabel => AppState.instance.translate('Password');
  static String get forgotPassword => AppState.instance.translate('Forgot Password?');
  static String get signIn => AppState.instance.translate('Sign In');
  static String get noAccount => AppState.instance.translate("Don't have an account?");
  static String get signUp => AppState.instance.translate('Sign Up');

  // --- Sign Up Strings ---
  static String get createAccount => AppState.instance.translate('Create Account');
  static String get signUpSubtitle => AppState.instance.translate('Join Foundit and help reconnect people with what matters.');
  static String get fullNameLabel => AppState.instance.translate('Full Name');
  static String get phoneNumberLabel => AppState.instance.translate('Phone Number');
  static String get confirmPasswordLabel => AppState.instance.translate('Confirm Password');
  static String get agreeToTerms => AppState.instance.translate('I agree to the Terms and Conditions and Privacy Policy.');
  static String get alreadyHaveAccount => AppState.instance.translate('Already have an account?');

  // --- Forgot Password Strings ---
  static String get forgotPasswordTitle => AppState.instance.translate('Forgot Password?');
  static String get forgotPasswordSubtitle => AppState.instance.translate('Enter your email address to receive a verification code.');
  static String get sendCode => AppState.instance.translate('Send Code');
  
  static String get verifyCodeTitle => AppState.instance.translate('Verify Code');
  static String get verifyCodeSubtitle => AppState.instance.translate('Enter the verification code sent to your email address.');
  static String get verifyCode => AppState.instance.translate('Verify Code');
  static String get resendCode => AppState.instance.translate('Resend Code');

  static String get createNewPasswordTitle => AppState.instance.translate('Create New Password');
  static String get createNewPasswordSubtitle => AppState.instance.translate('Your new password must be different from your previous password.');
  static String get resetPassword => AppState.instance.translate('Reset Password');
  static String get newPasswordLabel => AppState.instance.translate('New Password');

  static String get passwordChangedTitle => AppState.instance.translate('Password Changed Successfully');
  static String get passwordChangedSubtitle => AppState.instance.translate('Your password has been updated successfully. You can now sign in using your new password.');
  static String get backToSignIn => AppState.instance.translate('Back to Sign In');
}
