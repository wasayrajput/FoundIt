import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String labelText;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const AuthTextField({
    super.key,
    this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.errorText,
    this.validator,
    this.maxLength,
    this.inputFormatters,
  });

@override
State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
bool _obscureText = true;

@override
void initState() {
super.initState();
_obscureText = widget.isPassword;
}

@override
Widget build(BuildContext context) {
return Container(
decoration: BoxDecoration(
color: AppColors.inputFill,
borderRadius: BorderRadius.circular(16),
boxShadow: [
BoxShadow(
color: Colors.black.withValues(alpha: 0.03),
blurRadius: 10,
offset: const Offset(0, 4),
),
],
),
child: TextFormField(
controller: widget.controller,
validator: widget.validator,
onChanged: widget.onChanged,
obscureText: _obscureText,
keyboardType: widget.keyboardType,
maxLength: widget.maxLength,
inputFormatters: widget.inputFormatters,
style: GoogleFonts.inter(
color: AppColors.textPrimary,
fontSize: 15,
fontWeight: FontWeight.w500,
),
decoration: InputDecoration(
counterText: '',
labelText: widget.labelText,
labelStyle: GoogleFonts.inter(
color: AppColors.textSecondary,
fontSize: 14,
),
prefixIcon: Icon(
widget.prefixIcon,
color: AppColors.inputIcon,
size: 22,
),
suffixIcon: widget.isPassword
? IconButton(
icon: Icon(
_obscureText
? Icons.visibility_off_outlined
: Icons.visibility_outlined,
color: AppColors.inputIcon,
size: 22,
),
onPressed: () {
setState(() {
_obscureText = !_obscureText;
});
},
)
: null,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: const BorderSide(
color: AppColors.inputBorder,
width: 1,
),
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: const BorderSide(
color: AppColors.inputBorder,
width: 1,
),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: const BorderSide(
color: AppColors.inputFocusBorder,
width: 1.5,
),
),
errorText: widget.errorText,
errorBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: const BorderSide(
color: Colors.redAccent,
width: 1,
),
),
focusedErrorBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: const BorderSide(
color: Colors.redAccent,
width: 1.5,
),
),
contentPadding: const EdgeInsets.symmetric(
vertical: 18,
horizontal: 20,
),
),
),
);
}
}

