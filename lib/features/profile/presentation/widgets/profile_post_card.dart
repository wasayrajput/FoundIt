import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/core/state/app_state.dart';
import 'package:foundit/features/home/domain/post_model.dart';
import 'package:foundit/features/home/presentation/widgets/status_badge.dart';
import 'package:google_fonts/google_fonts.dart';

/// Horizontal card used in the Profile screen's "My Posts" list.
///
/// Renders: item thumbnail · name · Lost/Found badge · date · location ·
/// a trailing chevron. Tapping calls [onTap]. Visually consistent with the
/// rounded white cards used elsewhere in the app.
class ProfilePostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;
  final VoidCallback? onBookmarkToggle;
  final bool showStatus;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;

  const ProfilePostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.onBookmarkToggle,
    this.showStatus = true,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedPost = AppState.instance.getPost(post);
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // --- Item thumbnail (placeholder; falls back to icon) ---
                  _ItemThumbnail(imageUrl: resolvedPost.imageUrl, imageBytes: resolvedPost.imageBytes),
                  const SizedBox(width: 14),

                  // --- Text details ---
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.itemName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            StatusBadge(isLost: post.isLost),
                            if (showStatus) ...[
                              const SizedBox(width: 8),
                              PostStatusChip(postId: post.id),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _MetaLine(
                              icon: Icons.calendar_today_rounded,
                              text: post.date,
                            ),
                            const SizedBox(width: 14),
                            Flexible(
                              child: _MetaLine(
                                icon: Icons.location_on_rounded,
                                text: post.location,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // --- Trailing save/unsave button ---
                  if (onBookmarkToggle != null && !isSelectionMode) ...[
                    GestureDetector(
                      onTap: onBookmarkToggle,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: AppState.instance.isSaved(post.id) ? 0.08 : 0.04),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          AppState.instance.isSaved(resolvedPost.id)
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // --- Trailing chevron or selection indicator ---
                  if (isSelectionMode)
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? AppColors.primaryBlue : AppColors.inputIcon,
                      size: 24,
                    )
                  else
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.inputIcon,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Square thumbnail: shows the image, or a soft gradient placeholder with an
// image icon when no imageUrl is available (matches the Home PostCard style).
// ---------------------------------------------------------------------------
class _ItemThumbnail extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;

  const _ItemThumbnail({this.imageUrl, this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.05),
            AppColors.primaryBlue.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: imageBytes != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.memory(
                imageBytes!,
                fit: BoxFit.cover,
              ),
            )
          : (imageUrl == null
              ? Icon(
                  Icons.image_rounded,
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  size: 28,
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.image_rounded,
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                      size: 28,
                    ),
                  ),
                )),
    );
  }
}

// ---------------------------------------------------------------------------
// Small icon + text line used for date/location metadata.
// ---------------------------------------------------------------------------
class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Chip that shows the admin approval status of a post (Pending / Approved /
// Rejected). Reads from AppState so it stays in sync after admin actions.
// ---------------------------------------------------------------------------
class PostStatusChip extends StatelessWidget {
  final String postId;
  const PostStatusChip({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    final status = AppState.instance.getPostStatusForUserPost(postId);

    Color bg, fg;
    String label;
    IconData icon;

    switch (status) {
      case PostStatus.pending:
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFF59E0B);
        label = 'Pending';
        icon = Icons.hourglass_top_rounded;
        break;
      case PostStatus.approved:
        bg = const Color(0xFFE8F8F0);
        fg = const Color(0xFF1B9B5A);
        label = 'Approved';
        icon = Icons.check_circle_rounded;
        break;
      case PostStatus.rejected:
        bg = const Color(0xFFFFF0F0);
        fg = const Color(0xFFE54D2E);
        label = 'Rejected';
        icon = Icons.cancel_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
