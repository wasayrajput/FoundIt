import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/core/services/api_service.dart';
import 'package:foundit/core/state/app_state.dart';
import 'package:foundit/features/home/domain/post_model.dart';
import 'package:foundit/features/post/presentation/post_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onRefresh;

  const PostCard({
    super.key,
    required this.post,
    this.onRefresh,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late AnimationController _bookmarkController;
  late Animation<double> _bookmarkScale;

  @override
  void initState() {
    super.initState();
    _bookmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.7,
      upperBound: 1.0,
      value: 1.0,
    );
    _bookmarkScale = _bookmarkController;
  }

  @override
  void dispose() {
    _bookmarkController.dispose();
    super.dispose();
  }

  void _toggleSave() {
    AppState.instance.toggleSave(widget.post);
    // Bounce animation
    _bookmarkController.reverse().then((_) => _bookmarkController.forward());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final post = AppState.instance.getPost(widget.post);
    final isSaved = AppState.instance.isSaved(post.id);

    Uint8List? effectiveBytes = post.imageBytes;
    String? effectiveUrl = (post.imageUrl != null && post.imageUrl!.trim().isNotEmpty) ? post.imageUrl : null;

    if (effectiveBytes == null && effectiveUrl == null) {
      for (final p in AppState.instance.myPosts) {
        if (p.id == post.id || p.itemName.toLowerCase() == post.itemName.toLowerCase()) {
          effectiveBytes = p.imageBytes;
          if (p.imageUrl != null && p.imageUrl!.trim().isNotEmpty) {
            effectiveUrl = p.imageUrl;
          }
          break;
        }
      }
    }

    return RepaintBoundary(
      child: Container(
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
            onTap: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(post: post),
                ),
              );
              if (result == true && widget.onRefresh != null) {
                widget.onRefresh!();
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Area with bookmark button
                Expanded(
                  child: Stack(
                    children: [
                      // Image or placeholder
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          child: effectiveBytes != null
                              ? Image.memory(
                                  effectiveBytes,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.medium,
                                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                                )
                              : (effectiveUrl != null
                                  ? Image.network(
                                      ApiService.formatImageUrl(effectiveUrl),
                                      fit: BoxFit.cover,
                                      filterQuality: FilterQuality.medium,
                                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                                    )
                                  : _buildPlaceholder()),
                        ),
                      ),

                      // Bookmark button (top-right)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _toggleSave,
                          child: ScaleTransition(
                            scale: _bookmarkScale,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isSaved
                                    ? AppColors.primaryBlue
                                    : Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isSaved
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                color: isSaved
                                    ? Colors.white
                                    : AppColors.primaryBlue,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Text Area
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.itemName,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: post.isLost
                                  ? const Color(0xFFE54D2E)
                                  : const Color(0xFF1B9B5A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppState.instance.translate(post.isLost ? 'Lost' : 'Found'),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: post.isLost
                                  ? const Color(0xFFE54D2E)
                                  : const Color(0xFF1B9B5A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        post.date,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    final post = AppState.instance.getPost(widget.post);
    final isLost = post.isLost;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLost
              ? [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)]
              : [const Color(0xFF065F46), const Color(0xFF10B981)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              child: Icon(
                isLost ? Icons.search_rounded : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isLost ? 'LOST ITEM' : 'FOUND ITEM',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.95),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
