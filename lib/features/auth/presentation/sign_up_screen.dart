import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/core/constants/app_strings.dart';
import 'package:foundit/features/auth/presentation/sign_in_screen.dart';
import 'package:foundit/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:foundit/features/auth/presentation/widgets/primary_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:foundit/core/services/api_service.dart';
import 'package:foundit/features/auth/presentation/sign_up_verify_otp_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _agreedToTerms = false;
  bool _isLoading = false;
  String _fullName = '';
  String _email = '';
  String _phone = '';
  String _password = '';
  String _confirmPassword = '';

  bool _isEmailValid(String email) {
    if (email.isEmpty) return true;
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool get _isFormValid =>
      _fullName.trim().isNotEmpty &&
      _email.trim().isNotEmpty &&
      _isEmailValid(_email) &&
      _phone.trim().length == 11 &&
      _password.trim().length >= 6 &&
      _confirmPassword.trim() == _password.trim() &&
      _agreedToTerms;

  Future<void> _handleSignUp() async {
    if (!_isFormValid) return;

    if (_password != _confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Call Backend REST API to send 6-digit OTP email
    final result = await ApiService.sendSignupOtp(email: _email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('6-Digit OTP code sent to $_email'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      // Proceed to Email OTP Verification Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignUpVerifyOtpScreen(
            name: _fullName,
            email: _email,
            password: _password,
            phone: _phone,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to send OTP code'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenSize.height * 0.05),

                // --- Logo ---
                Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.glowBlue,
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/foundit_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: screenSize.height * 0.04),

                // --- Headings ---
                Text(
                  AppStrings.createAccount,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.signUpSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),

                SizedBox(height: screenSize.height * 0.04),

                // --- Input Fields ---
                AuthTextField(
                  labelText: AppStrings.fullNameLabel,
                  prefixIcon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                  onChanged: (val) => setState(() => _fullName = val),
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  labelText: AppStrings.emailLabel,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  errorText: (_email.isNotEmpty && !_isEmailValid(_email))
                      ? 'Invalid email format'
                      : null,
                  onChanged: (val) => setState(() => _email = val),
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  labelText: AppStrings.phoneNumberLabel,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.number,
                  maxLength: 11,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  errorText: (_phone.isNotEmpty && _phone.length < 11)
                      ? 'Phone number must be exactly 11 digits'
                      : null,
                  onChanged: (val) => setState(() => _phone = val),
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  labelText: AppStrings.passwordLabel,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  onChanged: (val) => setState(() => _password = val),
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  labelText: AppStrings.confirmPasswordLabel,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  onChanged: (val) => setState(() => _confirmPassword = val),
                ),

                const SizedBox(height: 20),

                // --- Terms and Conditions Checkbox ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreedToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreedToTerms = value ?? false;
                          });
                        },
                        activeColor: AppColors.primaryBlueMid,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: const BorderSide(
                          color: AppColors.inputBorder,
                          width: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.agreeToTerms,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: screenSize.height * 0.04),

                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                        ),
                      )
                    : PrimaryButton(
                        text: AppStrings.createAccount,
                        onPressed: _isFormValid ? _handleSignUp : null,
                      ),

                SizedBox(height: screenSize.height * 0.03),

                // --- Sign In Prompt ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.alreadyHaveAccount,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: () {
                        // Navigate back to Sign In
                        Navigator.of(context).pushReplacement(
                          PageRouteBuilder(
                            transitionDuration: const Duration(milliseconds: 300),
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
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        AppStrings.signIn,
                        style: GoogleFonts.inter(
                          color: AppColors.primaryBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: screenSize.height * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
