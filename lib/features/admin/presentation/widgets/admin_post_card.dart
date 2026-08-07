import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/core/services/api_service.dart';
import 'package:foundit/core/state/app_state.dart';
import 'package:foundit/features/home/domain/post_model.dart';
import 'package:foundit/features/admin/presentation/admin_post_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';

/// Card used inside the Admin Panel to display a post with its current status
/// and optional approve/reject action buttons.
class AdminPostCard extends StatelessWidget {
  final PostModel post;
  final PostStatus status;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  const AdminPostCard({
    super.key,
    required this.post,
    required this.status,
    this.onApprove,
    this.onReject,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedPost = AppState.instance.getPost(post);

    return GestureDetector(
      onTap: () {
        if (isSelectionMode) {
          if (onTap != null) onTap!();
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminPostDetailScreen(post: post),
            ),
          );
        }
      },
      onLongPress: onLongPress,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusBorderColor().withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isSelectionMode) ...[
                  Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: isSelected ? AppColors.primaryBlue : AppColors.inputIcon,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                ],
                // Thumbnail
                _Thumbnail(post: resolvedPost),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              post.itemName,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _AdminStatusChip(status: status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _MetaRow(
                        icon: post.isLost ? Icons.search_rounded : Icons.handshake_rounded,
                        text: post.isLost ? 'Lost' : 'Found',
                        color: post.isLost ? const Color(0xFFE54D2E) : const Color(0xFF1B9B5A),
                      ),
                      const SizedBox(height: 3),
                      _MetaRow(icon: Icons.calendar_today_rounded, text: post.date),
                      const SizedBox(height: 3),
                      _MetaRow(icon: Icons.location_on_rounded, text: post.location),
                      const SizedBox(height: 3),
                      _MetaRow(
                        icon: Icons.person_rounded,
                        text: 'By: ${AppState.instance.getPosterName(post.id)}${(AppState.instance.getPosterEmail(post.id).isNotEmpty && AppState.instance.getPosterEmail(post.id) != "poster@foundit.com") ? " (${AppState.instance.getPosterEmail(post.id)})" : ""}',
                        color: AppColors.primaryBlue,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Action buttons
            if (onApprove != null || onReject != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onReject != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: Text('Reject', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  if (onApprove != null && onReject != null)
                    const SizedBox(width: 10),
                  if (onApprove != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: Text('Approve', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),   // closes Container
    );   // closes GestureDetector / return
  }

  Color _statusBorderColor() {
    switch (status) {
      case PostStatus.pending:
        return const Color(0xFFF59E0B);
      case PostStatus.approved:
        return const Color(0xFF10B981);
      case PostStatus.rejected:
        return const Color(0xFFEF4444);
    }
  }
}

class _AdminStatusChip extends StatelessWidget {
  final PostStatus status;
  const _AdminStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, text;
    String label;
    IconData icon;

    switch (status) {
      case PostStatus.pending:
        bg = const Color(0xFFFFF8E1);
        text = const Color(0xFFF59E0B);
        label = 'Pending';
        icon = Icons.hourglass_top_rounded;
        break;
      case PostStatus.approved:
        bg = const Color(0xFFE8F8F0);
        text = const Color(0xFF10B981);
        label = 'Approved';
        icon = Icons.check_circle_rounded;
        break;
      case PostStatus.rejected:
        bg = const Color(0xFFFFF0F0);
        text = const Color(0xFFEF4444);
        label = 'Rejected';
        icon = Icons.cancel_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: text),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final PostModel post;
  const _Thumbnail({required this.post});

  @override
  Widget build(BuildContext context) {
    Uint8List? bytes = post.imageBytes;
    String? url = (post.imageUrl != null && post.imageUrl!.trim().isNotEmpty) ? post.imageUrl : null;

    if (bytes == null && url == null) {
      for (final p in AppState.instance.myPosts) {
        if (p.id == post.id || p.itemName.toLowerCase() == post.itemName.toLowerCase()) {
          bytes = p.imageBytes;
          if (p.imageUrl != null && p.imageUrl!.trim().isNotEmpty) {
            url = p.imageUrl;
          }
          break;
        }
      }
    }

    Widget content;
    if (bytes != null) {
      content = Image.memory(bytes, fit: BoxFit.cover);
    } else if (url != null) {
      content = Image.network(
        ApiService.formatImageUrl(url),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.image_rounded,
          color: AppColors.primaryBlue.withValues(alpha: 0.3),
          size: 26,
        ),
      );
    } else {
      content = Icon(
        Icons.image_rounded,
        color: AppColors.primaryBlue.withValues(alpha: 0.3),
        size: 26,
      );
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.06),
            AppColors.primaryBlue.withValues(alpha: 0.12),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: content,
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _MetaRow({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color ?? AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color ?? AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
