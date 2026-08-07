import 'package:flutter/material.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/core/services/api_service.dart';
import 'package:foundit/core/state/app_state.dart';
import 'package:foundit/features/home/domain/post_model.dart';
import 'package:foundit/features/profile/domain/user_profile_model.dart';
import 'package:foundit/features/post/presentation/post_detail_screen.dart';
import 'package:foundit/features/profile/presentation/widgets/profile_post_card.dart';
import 'package:foundit/features/home/data/dummy_data.dart';
import 'package:foundit/features/profile/data/profile_dummy_data.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class PosterProfileScreen extends StatefulWidget {
  final UserProfileModel user;
  final PostModel post;

  const PosterProfileScreen({
    super.key,
    required this.user,
    required this.post,
  });

  @override
  State<PosterProfileScreen> createState() => _PosterProfileScreenState();
}

class _PosterProfileScreenState extends State<PosterProfileScreen> {
  List<PostModel> _posterPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosterPosts();
  }

  Future<void> _loadPosterPosts() async {
    final isMyProfile = widget.user.name == AppState.instance.userName ||
        widget.user.name == 'John Doe' ||
        widget.user.name == 'John Doe (You)';

    if (isMyProfile) {
      final myPosts = [...ProfileDummyData.myPosts, ...AppState.instance.myPosts]
          .where((post) => !AppState.instance.isDeleted(post.id))
          .toList();
      if (mounted) {
        setState(() {
          _posterPosts = myPosts;
          _isLoading = false;
        });
      }
      return;
    }

    List<PostModel> fetchedFromApi = [];
    final apiRes = await ApiService.searchPosts(query: '');
    if (apiRes['success'] == true && apiRes['posts'] != null) {
      final List rawPosts = apiRes['posts'];
      for (final json in rawPosts) {
        final String pid = json['_id'] ?? json['id'] ?? '';
        if (pid.isEmpty) continue;

        final List images = json['images'] ?? [];
        String? imgUrl;
        if (images.isNotEmpty) {
          imgUrl = ApiService.formatImageUrl(images.first.toString());
        }

        final userObj = json['userId'] ?? json['user'];
        String pName = '';
        String pEmail = '';
        String pPhone = '';
        if (userObj is Map) {
          pName = userObj['name'] ?? '';
          pEmail = userObj['email'] ?? '';
          pPhone = userObj['phone'] ?? '';
          if (pName.isNotEmpty) {
            AppState.instance.setPosterDetails(
              postId: pid,
              name: pName,
              email: pEmail,
              phone: pPhone,
            );
          }
        }

        final String desc = json['description'] ?? '';
        final String cty = json['city'] ?? '';
        final String cat = json['category'] ?? '';
        if (desc.isNotEmpty || cty.isNotEmpty || cat.isNotEmpty) {
          AppState.instance.setPostMetadata(
            pid,
            description: desc,
            city: cty,
            category: cat,
          );
        }

        final postModel = PostModel(
          id: pid,
          itemName: json['itemName'] ?? 'Item',
          isLost: json['isLost'] == true,
          date: json['date'] ?? '',
          location: json['locationName'] ?? json['city'] ?? '',
          imageUrl: imgUrl,
          status: PostStatus.approved,
        );

        final targetName = widget.user.name.toLowerCase().trim();
        final targetEmail = widget.user.email.toLowerCase().trim();
        final matchedName = pName.toLowerCase().trim();
        final matchedEmail = pEmail.toLowerCase().trim();

        bool isMatch = false;
        if (pid == widget.post.id) {
          isMatch = true;
        } else if (targetName.isNotEmpty && matchedName == targetName) {
          isMatch = true;
        } else if (targetEmail.isNotEmpty && matchedEmail == targetEmail) {
          isMatch = true;
        } else if (AppState.instance.getPosterName(pid).toLowerCase().trim() == targetName) {
          isMatch = true;
        }

        if (isMatch && !AppState.instance.isDeleted(pid)) {
          fetchedFromApi.add(postModel);
        }
      }
    }

    // Always include widget.post if it's approved and not deleted
    final Map<String, PostModel> uniqueMap = {};
    if (!AppState.instance.isDeleted(widget.post.id)) {
      uniqueMap[widget.post.id] = widget.post;
    }

    for (final p in fetchedFromApi) {
      uniqueMap[p.id] = p;
    }

    // Also check dummy posts for match
    for (final p in DummyData.posts) {
      if (AppState.instance.isDeleted(p.id)) continue;
      final name = AppState.instance.getPosterName(p.id).toLowerCase().trim();
      if (name.isNotEmpty && name == widget.user.name.toLowerCase().trim()) {
        final status = AppState.instance.getPostStatusForUserPost(p.id);
        if (status == PostStatus.approved) {
          uniqueMap[p.id] = p;
        }
      }
    }

    if (mounted) {
      setState(() {
        _posterPosts = uniqueMap.values.toList();
        _isLoading = false;
      });
    }
  }

  Widget _buildHeaderContactChip(IconData icon, String text) {
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
          Icon(icon, color: Colors.white, size: 14),
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

  @override
  Widget build(BuildContext context) {
    final isMyProfile = widget.user.name == AppState.instance.userName ||
        widget.user.name == 'John Doe' ||
        widget.user.name == 'John Doe (You)';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadPosterPosts,
              color: AppColors.primaryBlue,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Top Custom Collapsing App Bar
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 260.0,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: Text(
                      'Profile Info',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    centerTitle: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryBlueMid, AppColors.primaryBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 48),
                              // Avatar
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  backgroundColor: AppColors.primaryBluePale,
                                  child: Text(
                                    widget.user.initials,
                                    style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Name
                              Text(
                                widget.user.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Contact info chips
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildHeaderContactChip(Icons.mail_rounded, widget.user.email),
                                  _buildHeaderContactChip(
                                    Icons.call_rounded,
                                    widget.user.phone.trim().isNotEmpty
                                        ? widget.user.phone
                                        : 'No phone provided',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Posts Section Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                      child: Text(
                        'Posts by ${widget.user.name}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ),

                  // Posts List
                  if (_isLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primaryBlue),
                      ),
                    )
                  else if (_posterPosts.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('No active posts from this user.'),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = _posterPosts[index];
                            return ProfilePostCard(
                              post: item,
                              showStatus: isMyProfile,
                              onBookmarkToggle: () {
                                AppState.instance.toggleSave(item);
                              },
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PostDetailScreen(post: item),
                                  ),
                                );
                              },
                            );
                          },
                          childCount: _posterPosts.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom buttons bar (only show if not my own profile)
          if (!isMyProfile)
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // --- Call Button ---
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final Uri telUri = Uri.parse('tel:${widget.user.phone}');
                            try {
                              await launchUrl(telUri);
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Could not open phone dialer: $e'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.call_rounded, size: 20),
                          label: Text(
                            'Call',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // --- WhatsApp Button ---
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            String digits = widget.user.phone.replaceAll(RegExp(r'\D'), '');
                            if (digits.startsWith('03') && digits.length == 11) {
                              digits = '92${digits.substring(1)}';
                            } else if (digits.length == 10 && !digits.startsWith('92')) {
                              digits = '92$digits';
                            }

                            if (digits.isEmpty) {
                              _showWhatsAppNotAvailableDialog(context, 'Phone number is missing or invalid for this user.');
                              return;
                            }

                            final message = Uri.encodeComponent(
                              'Hi ${widget.user.name}, I saw your post on Foundit app. Is it still available?',
                            );

                            final Uri appSchemeUri = Uri.parse('whatsapp://send?phone=$digits&text=$message');
                            final Uri whatsappWebUri = Uri.parse('https://wa.me/$digits?text=$message');

                            try {
                              final appLaunched = await launchUrl(appSchemeUri, mode: LaunchMode.externalApplication);
                              if (!appLaunched) {
                                final launched = await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
                                if (!launched && context.mounted) {
                                  _showWhatsAppNotAvailableDialog(context, 'This user is not available on WhatsApp or WhatsApp is not installed on your device.');
                                }
                              }
                            } catch (_) {
                              try {
                                final launched = await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
                                if (!launched && context.mounted) {
                                  _showWhatsAppNotAvailableDialog(context, 'This user is not available on WhatsApp or WhatsApp is not installed on your device.');
                                }
                              } catch (err) {
                                if (context.mounted) {
                                  _showWhatsAppNotAvailableDialog(context, 'This user is not available on WhatsApp or WhatsApp is not installed on your device.');
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.chat_rounded, size: 20),
                          label: Text(
                            'WhatsApp',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showWhatsAppNotAvailableDialog(BuildContext ctx, String message) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: Theme.of(dialogCtx).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFE54D2E), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'WhatsApp Not Available',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('OK', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
