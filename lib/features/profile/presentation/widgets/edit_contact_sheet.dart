import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/core/services/api_service.dart';
import 'package:foundit/features/profile/presentation/widgets/contact_field_row.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom sheet where the user types a NEW email or phone number and saves directly.
class EditContactSheet extends StatefulWidget {
  /// Which field is being edited.
  final ContactFieldType type;

  /// The current (existing) value.
  final String currentValue;

  const EditContactSheet({
    super.key,
    required this.type,
    required this.currentValue,
  });

  /// Convenience launcher.
  static Future<String?> show(
    BuildContext context, {
    required ContactFieldType type,
    required String currentValue,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => EditContactSheet(
        type: type,
        currentValue: currentValue,
      ),
    );
  }

  @override
  State<EditContactSheet> createState() => _EditContactSheetState();
}

class _EditContactSheetState extends State<EditContactSheet> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _validate(String value) {
    final v = value.trim();
    if (v.isEmpty) {
      setState(() => _errorText = 'This field cannot be empty.');
      return false;
    }
    if (widget.type == ContactFieldType.email) {
      final emailOk = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(v);
      if (!emailOk) {
        setState(() => _errorText = 'Enter a valid email address.');
        return false;
      }
    } else {
      final digits = v.replaceAll(RegExp(r'[^\d]'), '');
      if (digits.length != 11) {
        setState(() => _errorText = 'Phone number must be exactly 11 digits.');
        return false;
      }
    }
    setState(() => _errorText = null);
    return true;
  }

  Future<void> _onSave() async {
    if (_isLoading) return;
    final value = _controller.text.trim();
    if (value == widget.currentValue.trim()) {
      setState(() => _errorText =
          'New value must be different from the current one.');
      return;
    }
    if (!_validate(value)) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    Map<String, dynamic> res;
    if (widget.type == ContactFieldType.email) {
      res = await ApiService.updateProfile(email: value);
    } else {
      res = await ApiService.updateProfile(phone: value);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      Navigator.of(context).pop(value);
    } else {
      setState(() {
        _errorText = res['message'] ?? 'Failed to update. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmail = widget.type == ContactFieldType.email;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inputBorder,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEmail ? 'Change Email' : 'Change Phone',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                    letterSpacing: -0.3,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded,
                      color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isEmail
                  ? 'Enter your new email address.'
                  : 'Enter your new 11-digit phone number.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // --- Input ---
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: isEmail
                    ? TextInputType.emailAddress
                    : TextInputType.number,
                maxLength: isEmail ? null : 11,
                inputFormatters: isEmail
                    ? null
                    : [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: isEmail ? 'new.email@example.com' : '03001234567',
                  hintStyle: GoogleFonts.inter(
                    color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary).withValues(alpha: 0.4),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    isEmail ? Icons.mail_rounded : Icons.call_rounded,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                        color: AppColors.primaryBlue, width: 1.5),
                  ),
                  errorText: _errorText,
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.redAccent),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                        color: Colors.redAccent, width: 1.5),
                  ),
                ),
                onChanged: (v) {
                  if (_errorText != null) setState(() => _errorText = null);
                },
              ),
            ),
            const SizedBox(height: 24),

            // --- Save Button ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryBlueMid, AppColors.primaryBlue],
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
                    onTap: _onSave,
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Save Changes',
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
          ],
        ),
      ),
    );
  }
}
