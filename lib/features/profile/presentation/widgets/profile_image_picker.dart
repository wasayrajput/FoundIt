import 'package:flutter/material.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/features/profile/domain/user_profile_model.dart';
import 'package:google_fonts/google_fonts.dart';

/// Clean Avatar widget used in the Profile header.
/// Displays a gradient circle with the user's initials.
class ProfileImagePicker extends StatelessWidget {
  final UserProfileModel user;
  final ValueChanged<String> onImagePicked;

  /// Avatar diameter in logical pixels.
  final double size;

  const ProfileImagePicker({
    super.key,
    required this.user,
    required this.onImagePicked,
    this.size = 108,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, AppColors.primaryBluePale],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              user.initials,
              style: GoogleFonts.poppins(
                fontSize: size * 0.35,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
