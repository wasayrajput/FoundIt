import 'package:flutter/material.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// The kind of contact field a [ContactFieldRow] represents.
enum ContactFieldType { email, phone, name }

/// A white rounded row showing a label, the current value, and a trailing
/// edit pencil. Tapping the card (or pencil) triggers [onEdit].
///
/// Used in the Profile screen body for the email and phone entries.
class ContactFieldRow extends StatelessWidget {
  final ContactFieldType type;
  final String value;
  final VoidCallback onEdit;

  const ContactFieldRow({
    super.key,
    required this.type,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final IconData iconData;
    final String labelText;

    switch (type) {
      case ContactFieldType.name:
        iconData = Icons.person_rounded;
        labelText = 'Full Name';
        break;
      case ContactFieldType.email:
        iconData = Icons.mail_rounded;
        labelText = 'Email Address';
        break;
      case ContactFieldType.phone:
        iconData = Icons.call_rounded;
        labelText = 'Phone Number';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    iconData,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        labelText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBluePale,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: AppColors.primaryBlue,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
