import 'package:flutter/material.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/features/profile/domain/user_profile_model.dart';
import 'package:google_fonts/google_fonts.dart';

/// The blue gradient header of the Profile screen.
///
/// Shows an avatar (either the built-in static avatar, or a fully-editable
/// [ProfileImagePicker] passed via [avatar]), the user's name, and contact
/// chips. Visually consistent with the gradient headers used on the Home screen.
class ProfileHeader extends StatelessWidget {
  final UserProfileModel user;

  /// Optional small stat tiles shown at the bottom of the header.
  /// Pass `null` to omit them.
  final List<ProfileStatTile>? stats;

  /// Optional avatar widget. When provided it replaces the default static
  /// avatar (e.g. an editable [ProfileImagePicker]). Pass `null` to render
  /// the built-in non-editable avatar.
  final Widget? avatar;

  const ProfileHeader({
    super.key,
    required this.user,
    this.stats,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlueMid,
            AppColors.primaryBlue,
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            children: [
              // --- Avatar (editable picker or static fallback) ---
              avatar ?? _StaticAvatar(user: user),
              const SizedBox(height: 16),

              // --- Name ---
              Text(
                user.name,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // --- Contact chips ---
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ContactChip(
                    icon: Icons.mail_rounded,
                    text: user.email,
                  ),
                  _ContactChip(
                    icon: Icons.call_rounded,
                    text: user.phone,
                  ),
                ],
              ),

              // --- Optional stats ---
              if (stats != null && stats!.isNotEmpty) ...[
                const SizedBox(height: 22),
                Row(
                  children: [
                    for (int i = 0; i < stats!.length; i++) ...[
                      if (i > 0)
                        Container(
                          width: 1,
                          height: 36,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      Expanded(child: stats![i]),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Static (non-editable) avatar: photo + initials fallback
// ---------------------------------------------------------------------------
class _StaticAvatar extends StatelessWidget {
  final UserProfileModel user;

  const _StaticAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = (user.photoPath ?? '').isNotEmpty;
    return Container(
      width: 108,
      height: 108,
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
      child: CircleAvatar(
        backgroundColor: AppColors.primaryBluePale,
        backgroundImage:
            !hasPhoto ? null : (user.photoPath!.startsWith('http')
                ? NetworkImage(user.photoPath!)
                : null),
        child: hasPhoto && !user.photoPath!.startsWith('http')
            ? const SizedBox.shrink()
            : (hasPhoto
                ? null
                : Container(
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
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  )),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pill-shaped contact line
// ---------------------------------------------------------------------------
class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single stat tile shown at the bottom of [ProfileHeader] (e.g. "Posts: 4").
class ProfileStatTile extends StatelessWidget {
  final String value;
  final String label;

  const ProfileStatTile({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}
