import 'package:flutter/material.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/features/auth/presentation/widgets/otp_input_field.dart';
import 'package:foundit/features/profile/presentation/widgets/contact_field_row.dart';
import 'package:google_fonts/google_fonts.dart';

/// 6-digit OTP verification screen for confirming a new email or phone.
///
/// FRONTEND ONLY: the 6-digit code is generated locally by [EditContactSheet]
/// and passed in as [generatedOtp]. There is no real SMS/email delivery â€” to
/// make the flow demoable, the code is shown in a hint banner. On a correct
/// match the new value is returned to the caller via [Navigator.pop].
class VerifyContactOtpScreen extends StatefulWidget {
/// Which contact field is being verified.
final ContactFieldType fieldType;

/// The new value the user wants to switch to.
final String newValue;

/// Locally-generated 6-digit demo code (no backend involved).
final String generatedOtp;

const VerifyContactOtpScreen({
super.key,
required this.fieldType,
required this.newValue,
required this.generatedOtp,
});

@override
State<VerifyContactOtpScreen> createState() => _VerifyContactOtpScreenState();
}

class _VerifyContactOtpScreenState extends State<VerifyContactOtpScreen> {
String _enteredOtp = '';
String? _errorText;
bool _verifying = false;

bool get _isEmail => widget.fieldType == ContactFieldType.email;

void _onVerify() {
setState(() => _verifying = true);

// Simulate a brief verification delay for realism (no network call).
Future.delayed(const Duration(milliseconds: 600), () {
if (!mounted) return;
setState(() => _verifying = false);

if (_enteredOtp == widget.generatedOtp) {
// Success â€” return the verified new value. The EditContactSheet that
// pushed this screen awaits the result and forwards it to Profile.
Navigator.of(context).pop(widget.newValue);
} else {
setState(() => _errorText = 'Incorrect code. Please try again.');
}
});
}

void _onResend() {
// FRONTEND-ONLY: in a real app an OTP would be re-sent via email/SMS.
ScaffoldMessenger.of(context).hideCurrentSnackBar();
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('A new code has been sent.'),
behavior: SnackBarBehavior.floating,
backgroundColor: AppColors.primaryBlue,
),
);
setState(() => _errorText = null);
}

@override
Widget build(BuildContext context) {
final Size screenSize = MediaQuery.of(context).size;

return Scaffold(
backgroundColor: Theme.of(context).scaffoldBackgroundColor,
appBar: AppBar(
backgroundColor: Colors.transparent,
elevation: 0,
leading: IconButton(
icon: Icon(Icons.arrow_back_ios_new,
color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary), size: 20),
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
_isEmail ? 'Verify New Email' : 'Verify New Phone',
style: GoogleFonts.poppins(
fontSize: 28,
fontWeight: FontWeight.w700,
color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
letterSpacing: 0.5,
),
),
const SizedBox(height: 8),
Text(
_isEmail
? 'Enter the 6-digit code sent to your current email to confirm the change to ${widget.newValue}.'
: 'Enter the 6-digit code sent to your current phone to confirm the change to ${widget.newValue}.',
style: GoogleFonts.inter(
fontSize: 15,
fontWeight: FontWeight.w400,
color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary),
height: 1.4,
),
),

SizedBox(height: screenSize.height * 0.05),

// --- OTP fields ---
OtpInputField(
onCompleted: (otp) {
setState(() {
_enteredOtp = otp;
_errorText = null;
});
},
),

if (_errorText != null) ...[
const SizedBox(height: 12),
Text(
_errorText!,
style: GoogleFonts.inter(
fontSize: 13,
fontWeight: FontWeight.w500,
),
),
],

SizedBox(height: screenSize.height * 0.06),

// --- Verify button ---
SizedBox(
width: double.infinity,
height: 56,
child: DecoratedBox(
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(16),
gradient: const LinearGradient(
colors: [
AppColors.primaryBlueMid,
AppColors.primaryBlue
],
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
),
boxShadow: [
BoxShadow(
color: AppColors.primaryBlue.withValues(alpha: 0.3),
blurRadius: 16,
offset: const Offset(0, 8),
),
],
),
child: Material(
color: Colors.transparent,
child: InkWell(
borderRadius: BorderRadius.circular(16),
onTap: _verifying ? null : _onVerify,
child: Center(
child: _verifying
? const SizedBox(
width: 22,
height: 22,
child: CircularProgressIndicator(
strokeWidth: 2.5,
valueColor: AlwaysStoppedAnimation<Color>(
Colors.white),
),
)
: Text(
'Verify & Update',
style: GoogleFonts.inter(
color: Colors.white,
fontSize: 16,
fontWeight: FontWeight.w600,
letterSpacing: 0.5,
),
),
),
),
),
),
),

const SizedBox(height: 16),

// --- Resend ---
Center(
child: TextButton(
onPressed: _onResend,
style: TextButton.styleFrom(
padding: const EdgeInsets.symmetric(
horizontal: 16, vertical: 8),
),
child: Text(
'Resend Code',
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

