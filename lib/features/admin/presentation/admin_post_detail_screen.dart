import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/core/services/api_service.dart';
import 'package:foundit/core/state/app_state.dart';
import 'package:foundit/features/home/domain/post_model.dart';
import 'package:foundit/features/profile/domain/user_profile_model.dart';
import 'package:foundit/features/admin/presentation/admin_poster_profile_screen.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full post detail view shown when an admin taps any post in the Admin Panel.
/// Mirrors the look-and-feel of the user-facing PostDetailScreen but adds:
///  • Poster profile card (tappable → AdminPosterProfileScreen)
///  • Admin status badge
///  • Approve / Reject bottom bar (only for pending posts)
class AdminPostDetailScreen extends StatefulWidget {
  final PostModel post;

  const AdminPostDetailScreen({super.key, required this.post});

  @override
  State<AdminPostDetailScreen> createState() => _AdminPostDetailScreenState();
}

class _AdminPostDetailScreenState extends State<AdminPostDetailScreen> {
  String _liveDescription = '';

  @override
  void initState() {
    super.initState();
    _fetchLivePostDetails();
  }

  Future<void> _fetchLivePostDetails() async {
    final res = await ApiService.getPostById(widget.post.id);
    if (res['success'] == true && res['post'] != null) {
      final json = res['post'];
      final userObj = json['user'];
      if (userObj is Map) {
        final String name = userObj['name'] ?? '';
        final String email = userObj['email'] ?? '';
        final String phone = userObj['phone'] ?? '';
        AppState.instance.setPosterDetails(
          postId: widget.post.id,
          name: name,
          email: email,
          phone: phone,
        );
      }
      if (mounted) {
        setState(() {
          _liveDescription = json['description'] ?? '';
        });
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _getDescription() {
    if (_liveDescription.isNotEmpty) return _liveDescription;
    switch (widget.post.id) {
      case '1':
        return 'Found a black iPhone 14 Pro Max near the Central Park zoo. The phone has a transparent silicon case and is locked. Please contact with proof of ownership.';
      case '2':
        return 'Lost a brown leather bi-fold wallet (Fossil brand) near Starbucks on 5th Ave. It contains a student ID, transit pass, and some cash. Reward offered.';
      case '3':
        return 'Our beloved Golden Retriever named Max went missing near Brooklyn Bridge. He is wearing a red collar with a tag. He is friendly but might be scared.';
      case '4':
        return 'Found a set of Toyota car keys with a black fob and a small red keychain on the floor of Terminal 4 at JFK. Turned them in to security.';
      case '5':
        return 'Lost my space gray MacBook Pro 16-inch at the NYU Library 3rd floor. It was in a black sleeve with a rocket-ship sticker. Extremely important for finals.';
      case '6':
        return 'Found a pair of classic black Ray-Ban Wayfarer sunglasses left on a bench near Times Square. They are in a brown leather case. Contact me to claim.';
      case 'p1':
        return 'Lost a blue Nike backpack at Times Square Station during morning rush hour. Contains laptop, charger, and university notes. Very important. Please contact if found.';
      case 'p2':
        return 'Found a silver Apple Watch Series 8 near Gate 42 at Grand Central Terminal. Watch is locked and has a white sport band. Turned in to lost and found desk.';
      case 'p3':
        return 'Lost university ID card (Columbia University, Student Services). Card was lost near the main library entrance. Needed urgently for campus access. Please return.';
      case 'p4':
        return 'Found a pair of black leather gloves near the entrance of Madison Square Garden after the evening event. Appears to be high quality. Happy to return to owner.';
      default:
        return 'No description provided. Please contact the poster for more details about this item.';
    }
  }

  String _getCategoryName() {
    final name = widget.post.itemName.toLowerCase();
    if (name.contains('iphone') || name.contains('phone')) return 'Mobiles';
    if (name.contains('macbook') || name.contains('laptop')) return 'Electronics';
    if (name.contains('wallet')) return 'Men Wallets';
    if (name.contains('card') || name.contains('id')) return 'ID Card';
    if (name.contains('watch')) return 'Electronics';
    if (name.contains('backpack') || name.contains('bag')) return 'Suitcase or Bag';
    if (name.contains('gloves')) return 'Clothing';
    if (name.contains('sunglasses')) return 'Others';
    return 'Others';
  }

  IconData _getCategoryIcon() {
    final cat = _getCategoryName().toLowerCase();
    if (cat.contains('mobile')) return Icons.phone_iphone_rounded;
    if (cat.contains('electronic') || cat.contains('watch')) return Icons.devices_rounded;
    if (cat.contains('wallet')) return Icons.account_balance_wallet_rounded;
    if (cat.contains('id card')) return Icons.badge_rounded;
    if (cat.contains('suitcase') || cat.contains('bag')) return Icons.business_center_rounded;
    return Icons.category_rounded;
  }

  UserProfileModel _getPoster() {
    return UserProfileModel(
      name: AppState.instance.getPosterName(widget.post.id),
      email: AppState.instance.getPosterEmail(widget.post.id),
      phone: AppState.instance.getPosterPhone(widget.post.id),
    );
  }

  void _sendWarning(String subject, String explanation) {
    final poster = _getPoster();
    AppState.instance.issueWarningToUser(
      userEmail: poster.email,
      postId: widget.post.id,
      postName: widget.post.itemName,
      subject: subject,
      explanation: explanation,
    );
    setState(() {}); // Refresh warnings section inline
    _showSnack('⚠️ Warning issued to user successfully.', const Color(0xFFF59E0B));
  }

  void _showIssueWarningDialog() {
    final subjectCtrl = TextEditingController();
    final explainCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        final primaryTextColor = isDark ? Colors.white : AppColors.textPrimary;
        final secondaryTextColor = isDark ? Colors.white70 : AppColors.textSecondary;
        final dialogBg = Theme.of(dialogCtx).cardColor;

        return AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 24),
              const SizedBox(width: 10),
              Text(
                'Issue Warning',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: primaryTextColor,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: subjectCtrl,
                    style: GoogleFonts.inter(color: primaryTextColor),
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      labelStyle: GoogleFonts.inter(color: secondaryTextColor),
                      hintText: 'e.g. Inappropriate Content',
                      hintStyle: GoogleFonts.inter(color: secondaryTextColor.withValues(alpha: 0.5)),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primaryBlue),
                      ),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a subject' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: explainCtrl,
                    maxLines: 4,
                    style: GoogleFonts.inter(color: primaryTextColor),
                    decoration: InputDecoration(
                      labelText: 'Explaining Reason',
                      labelStyle: GoogleFonts.inter(color: secondaryTextColor),
                      hintText: 'Describe why this post is inappropriate...',
                      hintStyle: GoogleFonts.inter(color: secondaryTextColor.withValues(alpha: 0.5)),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primaryBlue),
                      ),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter the explanation' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  _sendWarning(subjectCtrl.text.trim(), explainCtrl.text.trim());
                  Navigator.pop(dialogCtx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                'Send Warning',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWarningHistoryCard(String email) {
    final warnings = AppState.instance.getWarningsForUser(email);
    final hasWarnings = warnings.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasWarnings ? const Color(0xFFF59E0B).withValues(alpha: 0.2) : AppColors.primaryBlue.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: (hasWarnings ? const Color(0xFFF59E0B) : AppColors.primaryBlue).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasWarnings ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                color: hasWarnings ? const Color(0xFFF59E0B) : const Color(0xFF1B9B5A),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                hasWarnings
                    ? '${warnings.length} Warning(s) Issued Previously'
                    : 'No warnings issued to this user before',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: hasWarnings ? const Color(0xFFD97706) : const Color(0xFF1B9B5A),
                ),
              ),
            ],
          ),
          if (hasWarnings) ...[
            const SizedBox(height: 12),
            const Divider(),
            ...warnings.map((w) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subject: ${w.subject}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _formatWarningDate(w.date),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? Colors.white30 : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Post: "${w.postName}"',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        w.explanation,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  String _formatWarningDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _approve() async {
    final res = await ApiService.updatePostStatus(postId: widget.post.id, status: 'approved');
    if (res['success'] == true) {
      AppState.instance.approvePost(widget.post.id);
      if (mounted) setState(() {});
      _showSnack('✅ Post approved successfully!', const Color(0xFF10B981));
    }
  }

  void _reject() async {
    final res = await ApiService.updatePostStatus(postId: widget.post.id, status: 'rejected');
    if (res['success'] == true) {
      AppState.instance.rejectPost(widget.post.id);
      if (mounted) setState(() {});
      _showSnack('❌ Post rejected.', const Color(0xFFEF4444));
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── UI Builders ────────────────────────────────────────────────────────────

  Widget _buildCategoryPlaceholder(IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 64),
          const SizedBox(height: 12),
          Text(
            _getCategoryName(),
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    )),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStatusBanner(PostStatus status) {
    Color bg, fg;
    String label;
    IconData icon;

    switch (status) {
      case PostStatus.pending:
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFF59E0B);
        label = 'Pending Admin Review';
        icon = Icons.hourglass_top_rounded;
        break;
      case PostStatus.approved:
        bg = const Color(0xFFE8F8F0);
        fg = const Color(0xFF10B981);
        label = 'Approved by Admin';
        icon = Icons.check_circle_rounded;
        break;
      case PostStatus.rejected:
        bg = const Color(0xFFFFF0F0);
        fg = const Color(0xFFEF4444);
        label = 'Rejected by Admin';
        icon = Icons.cancel_rounded;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final post = AppState.instance.getPost(widget.post);
    final status = AppState.instance.getPostStatusForUserPost(post.id, fallbackStatus: widget.post.status);
    final poster = _getPoster();
    final description = _getDescription();
    final catIcon = _getCategoryIcon();
    final catName = _getCategoryName();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // ── Scrollable body ────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Hero image / header ────────────────────────────────
                    Stack(
                      children: [
                        // Cover
                        Container(
                          height: 280,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                            ),
                          ),
                          child: post.imageBytes != null
                              ? Image.memory(post.imageBytes!, fit: BoxFit.cover)
                              : post.imageUrl != null
                                  ? Image.network(post.imageUrl!, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _buildCategoryPlaceholder(catIcon))
                                  : _buildCategoryPlaceholder(catIcon),
                        ),

                        // Bottom curve
                        Positioned(
                          bottom: -1, left: 0, right: 0,
                          child: Container(
                            height: 24,
                            decoration: const BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                          ),
                        ),

                        // Top bar
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 12,
                          left: 16, right: 16,
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10)],
                                  ),
                                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Admin Review',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18, fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    shadows: [Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8)],
                                  ),
                                ),
                              ),
                              // Admin badge pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.admin_panel_settings_rounded, size: 13, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text('Admin', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Title overlay at bottom of cover
                        Positioned(
                          bottom: 32, left: 20, right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: post.isLost ? const Color(0xFFE54D2E) : const Color(0xFF1B9B5A),
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: [BoxShadow(
                                    color: (post.isLost ? const Color(0xFFE54D2E) : const Color(0xFF1B9B5A)).withValues(alpha: 0.35),
                                    blurRadius: 8, offset: const Offset(0, 4),
                                  )],
                                ),
                                child: Text(
                                  post.isLost ? 'Lost Item' : 'Found Item',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                post.itemName,
                                style: GoogleFonts.poppins(
                                  fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white,
                                  letterSpacing: -0.5,
                                  shadows: [Shadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ── Body ──────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Admin Status Banner
                          _buildAdminStatusBanner(status),
                          const SizedBox(height: 20),

                          // ── Poster Profile Card ────────────────────────
                          Text('Posted by',
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const SizedBox(height: 10),

                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminPosterProfileScreen(
                                  postId: post.id,
                                  poster: poster,
                                ),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.08)),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withValues(alpha: 0.07),
                                    blurRadius: 16, offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 52, height: 52,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.25), blurRadius: 10),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        poster.initials,
                                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Name + email
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          poster.name,
                                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.mail_rounded, size: 13, color: AppColors.textSecondary),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(poster.email,
                                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                                maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone_rounded, size: 13, color: AppColors.textSecondary),
                                            const SizedBox(width: 4),
                                            Text(poster.phone,
                                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Tap hint
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue.withValues(alpha: 0.06),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primaryBlue),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                          Text('User Warning History',
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary)),
                          const SizedBox(height: 10),
                          _buildWarningHistoryCard(poster.email),

                          const SizedBox(height: 24),

                          // ── Post Details ───────────────────────────────
                          Text('Post Details',
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const SizedBox(height: 14),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.06)),
                              boxShadow: [
                                BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _infoRow(Icons.calendar_today_rounded, 'DATE REPORTED', post.date),
                                _infoRow(Icons.location_on_rounded, 'LOCATION', post.location),
                                _infoRow(Icons.category_rounded, 'CATEGORY', catName),
                                _infoRow(
                                  post.isLost ? Icons.search_rounded : Icons.handshake_rounded,
                                  'TYPE',
                                  post.isLost ? 'Lost — owner is looking for this item' : 'Found — person has this item',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Description ───────────────────────────────
                          Text('Description',
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.06)),
                              boxShadow: [
                                BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Text(
                              description,
                              style: GoogleFonts.inter(
                                fontSize: 14, fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary, height: 1.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom bar: Approve / Reject (only for pending) ────────────
            if (status == PostStatus.pending)
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.02 : 0.08),
                        blurRadius: 20, offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showIssueWarningDialog,
                        icon: const Icon(Icons.warning_amber_rounded, size: 18),
                        label: Text('Issue Warning', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Reject
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: _reject,
                                icon: const Icon(Icons.close_rounded, size: 18),
                                label: Text('Reject',
                                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFEF4444),
                                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Approve
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: _approve,
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: Text('Approve',
                                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              // Show status info bar for already-decided posts
              SafeArea(
                top: false,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.02 : 0.06), blurRadius: 16, offset: const Offset(0, -4)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAdminStatusBanner(status),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (status == PostStatus.approved)
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed: _reject,
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  label: Text('Reject',
                                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFEF4444),
                                    side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ),
                            ),
                          if (status == PostStatus.rejected)
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _approve,
                                  icon: const Icon(Icons.check_rounded, size: 18),
                                  label: Text('Approve',
                                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _showIssueWarningDialog,
                                icon: const Icon(Icons.warning_amber_rounded, size: 18),
                                label: Text('Warning', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF59E0B),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
