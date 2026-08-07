import 'package:flutter/material.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/core/services/api_service.dart';
import 'package:foundit/core/state/app_state.dart';
import 'package:foundit/features/home/domain/post_model.dart';
import 'package:foundit/features/admin/presentation/widgets/admin_post_card.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminPendingTab extends StatefulWidget {
  final VoidCallback onPostStatusChanged;
  const AdminPendingTab({super.key, required this.onPostStatusChanged});

  @override
  State<AdminPendingTab> createState() => _AdminPendingTabState();
}

class _AdminPendingTabState extends State<AdminPendingTab> {
  List<PostModel> _pendingPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingPosts();
  }

  Future<void> _fetchPendingPosts() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getPendingPosts();
    List<PostModel> fetched = [];

    if (res['success'] == true && res['posts'] != null) {
      final List raw = res['posts'];
      fetched = raw.map((json) {
        final List images = json['images'] ?? [];
        String? imgUrl;
        if (images.isNotEmpty) {
          final String firstImg = images.first.toString();
          imgUrl = ApiService.formatImageUrl(firstImg);
        }

        final id = json['_id'] ?? json['id'] ?? '';
        final userObj = json['userId'] ?? json['user'];
        if (userObj is Map) {
          final String name = userObj['name'] ?? '';
          final String email = userObj['email'] ?? '';
          final String phone = userObj['phone'] ?? '';
          AppState.instance.setPosterDetails(
            postId: id,
            name: name,
            email: email,
            phone: phone,
          );
        }

        return PostModel(
          id: id,
          itemName: json['itemName'] ?? 'Pending Item',
          isLost: json['isLost'] == true,
          date: json['date'] ?? '',
          location: json['locationName'] ?? json['city'] ?? '',
          imageUrl: imgUrl,
          status: PostStatus.pending,
        );
      }).toList();
    }

    if (mounted) {
      setState(() {
        _pendingPosts = fetched;
        _isLoading = false;
      });
    }
  }

  Future<void> _approve(PostModel post) async {
    final res = await ApiService.updatePostStatus(postId: post.id, status: 'approved');
    if (res['success'] == true) {
      AppState.instance.approvePost(post.id);
      _fetchPendingPosts();
      widget.onPostStatusChanged();
      _showSnack('✅ "${post.itemName}" approved & live on Feed!', Colors.green);
    } else {
      _showSnack('Failed to approve post: ${res['message']}', Colors.red.shade700);
    }
  }

  Future<void> _reject(PostModel post) async {
    final res = await ApiService.updatePostStatus(postId: post.id, status: 'rejected');
    if (res['success'] == true) {
      AppState.instance.rejectPost(post.id);
      _fetchPendingPosts();
      widget.onPostStatusChanged();
      _showSnack('❌ "${post.itemName}" rejected.', Colors.red.shade700);
    } else {
      _showSnack('Failed to reject post: ${res['message']}', Colors.red.shade700);
    }
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (_pendingPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    const Color(0xFFF59E0B).withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: const Icon(Icons.check_circle_outline_rounded, size: 44, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(height: 20),
            Text(
              'No Pending Approvals',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All lost & found item reports have been reviewed.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPendingPosts,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _pendingPosts.length,
        itemBuilder: (context, index) {
          final post = _pendingPosts[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: AdminPostCard(
              post: post,
              status: PostStatus.pending,
              onApprove: () => _approve(post),
              onReject: () => _reject(post),
            ),
          );
        },
      ),
    );
  }
}
