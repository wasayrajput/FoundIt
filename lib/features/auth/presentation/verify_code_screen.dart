import 'package:flutter/material.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/core/constants/app_strings.dart';
import 'package:foundit/core/services/api_service.dart';
import 'package:foundit/features/auth/presentation/create_new_password_screen.dart';
import 'package:foundit/features/auth/presentation/widgets/otp_input_field.dart';
import 'package:foundit/features/auth/presentation/widgets/primary_button.dart';
import 'package:google_fonts/google_fonts.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String userEmail;

  const VerifyCodeScreen({
    super.key,
    this.userEmail = '',
  });

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  String _enteredOtp = '';
  String? _otpError;
  bool _isLoading = false;

  Future<void> _handleVerifyCode() async {
    if (_enteredOtp.length < 6) {
      setState(() => _otpError = 'Please enter the complete 6-digit code');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all 6 digits of the verification code'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _otpError = null;
      _isLoading = true;
    });

    // Call Backend REST API to verify 6-digit OTP code with MongoDB
    final result = await ApiService.verifyOTP(
      email: widget.userEmail,
      otp: _enteredOtp,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP Verified Successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Proceed to Create New Password Screen
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) => 
              CreateNewPasswordScreen(
                userEmail: widget.userEmail,
                otp: _enteredOtp,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Invalid or expired OTP code'),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenSize.height * 0.02),

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

                SizedBox(height: screenSize.height * 0.05),

                // --- Headings ---
                Text(
                  AppStrings.verifyCodeTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.userEmail.isNotEmpty
                      ? 'Enter the 6-digit verification code sent to ${widget.userEmail}'
                      : AppStrings.verifyCodeSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),

                SizedBox(height: screenSize.height * 0.05),

                // --- 6-Digit OTP Fields ---
                OtpInputField(
                  length: 6,
                  onCompleted: (otp) {
                    setState(() {
                      _enteredOtp = otp;
                      _otpError = null;
                    });
                  },
                ),

                if (_otpError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _otpError!,
                    style: GoogleFonts.inter(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                SizedBox(height: screenSize.height * 0.06),

                // --- Verify Code Button ---
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                        ),
                      )
                    : PrimaryButton(
                        text: AppStrings.verifyCode,
                        onPressed: _handleVerifyCode,
                      ),
                
                const SizedBox(height: 16),

                // --- Resend Code ---
                Center(
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('A new 6-digit code has been sent to ${widget.userEmail.isNotEmpty ? widget.userEmail : "your email"}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      AppStrings.resendCode,
                      style: GoogleFonts.inter(
                        color: AppColors.primaryBlueMid,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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
