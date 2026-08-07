import 'dart:async';
import 'package:flutter/material.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/core/services/api_service.dart';
import 'package:foundit/core/state/app_state.dart';
import 'package:foundit/features/auth/presentation/widgets/otp_input_field.dart';
import 'package:foundit/features/auth/presentation/widgets/primary_button.dart';
import 'package:foundit/features/home/presentation/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpVerifyOtpScreen extends StatefulWidget {
  final String name;
  final String email;
  final String password;
  final String phone;

  const SignUpVerifyOtpScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    this.phone = '',
  });

  @override
  State<SignUpVerifyOtpScreen> createState() => _SignUpVerifyOtpScreenState();
}

class _SignUpVerifyOtpScreenState extends State<SignUpVerifyOtpScreen> {
  String _enteredOtp = '';
  String? _otpError;
  bool _isLoading = false;
  bool _isResending = false;

  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendCountdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        if (mounted) setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleResendOtp() async {
    if (_resendCountdown > 0 || _isResending) return;

    setState(() => _isResending = true);
    final res = await ApiService.sendSignupOtp(email: widget.email);
    if (!mounted) return;
    setState(() => _isResending = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A new 6-digit OTP has been sent to ${widget.email}'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      _startResendTimer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to resend OTP code'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleVerifyAndRegister() async {
    if (_enteredOtp.length < 6) {
      setState(() => _otpError = 'Please enter all 6 digits of the OTP code');
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

    final res = await ApiService.register(
      name: widget.name,
      email: widget.email,
      password: widget.password,
      phone: widget.phone,
      otp: _enteredOtp,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      final userObj = res['user'] ?? {};
      final uid = (userObj['_id'] ?? userObj['id'] ?? '').toString();
      final userToken = res['token']?.toString();
      final phone = userObj['phone'] ?? widget.phone;

      AppState.instance.setCurrentUserProfile(
        id: uid,
        userToken: userToken,
        name: widget.name,
        email: widget.email,
        phone: phone,
        isNewLoginSession: true,
      );
      AppState.instance.registerNewUser(widget.name, widget.email);
      AppState.instance.addAdminNotification(
        'New Account Verified',
        '${widget.name} (${widget.email}) verified email & registered.',
        Icons.verified_user_rounded,
        const Color(0xFF10B981),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email verified! Welcome to Foundit, ${widget.name}! 🎉'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Verification failed'),
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenSize.height * 0.02),

              // Header Illustration Badge
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  color: AppColors.primaryBlue,
                  size: 40,
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'Verify Your Email',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'We sent a 6-digit verification code to\n'),
                      TextSpan(
                        text: widget.email,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const TextSpan(text: '. Enter code below to create your account.'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // 6-Digit OTP Field
              OtpInputField(
                length: 6,
                onCompleted: (otp) {
                  setState(() {
                    _enteredOtp = otp;
                    _otpError = null;
                  });
                },
                onChanged: (otp) {
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

              const SizedBox(height: 36),

              // Verify & Complete Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                  : PrimaryButton(
                      text: 'Verify & Create Account',
                      onPressed: _handleVerifyAndRegister,
                    ),

              const SizedBox(height: 28),

              // Resend OTP Countdown Timer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive code? ",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  _resendCountdown > 0
                      ? Text(
                          'Resend in ${_resendCountdown}s',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue.withValues(alpha: 0.6),
                          ),
                        )
                      : GestureDetector(
                          onTap: _isResending ? null : _handleResendOtp,
                          child: Text(
                            _isResending ? 'Sending...' : 'Resend Code',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
