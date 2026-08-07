import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/core/services/api_service.dart';
import 'package:foundit/core/state/app_state.dart';
import 'package:foundit/features/home/domain/post_model.dart';
import 'package:foundit/features/post/presentation/edit_post_screen.dart';
import 'package:foundit/features/profile/domain/user_profile_model.dart';
import 'package:foundit/features/profile/presentation/poster_profile_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _isModified = false;
  String _description = '';
  String _posterName = '';
  String _posterEmail = '';
  String _posterPhone = '';
  String? _posterPhoto;
  String? _posterId;
  String? _liveImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchLivePostDetails();
  }

  Future<void> _fetchLivePostDetails() async {
    final res = await ApiService.getPostById(widget.post.id);
    if (res['success'] == true && res['post'] != null) {
      final json = res['post'];
      final List images = json['images'] ?? [];
      String? img;
      if (images.isNotEmpty) {
        img = ApiService.formatImageUrl(images.first.toString());
      }

      final String postPhone = json['phone'] ?? '';
      final String postEmail = json['email'] ?? '';

      final userData = json['userId'] ?? json['user'];
      String name = '';
      String email = postEmail;
      String phone = postPhone;
      String? photo;
      String? uid;

      if (userData is Map) {
        if (name.isEmpty) name = userData['name'] ?? '';
        if (email.isEmpty) email = userData['email'] ?? '';
        if (phone.isEmpty) phone = userData['phone'] ?? '';
        photo = userData['photoUrl'];
        uid = userData['_id'] ?? userData['id'];

        if (name.isNotEmpty) {
          AppState.instance.setPosterDetails(
            postId: widget.post.id,
            name: name,
            email: email,
            phone: phone,
          );
        }
      }

      final String desc = json['description'] ?? '';
      final String cty = json['city'] ?? '';
      final String cat = json['category'] ?? '';
      AppState.instance.setPostMetadata(
        widget.post.id,
        description: desc,
        city: cty,
        category: cat,
        email: email,
        phone: phone,
      );

      if (mounted) {
        setState(() {
          _description = desc.isNotEmpty ? desc : 'No description provided.';
          if (name.isNotEmpty) _posterName = name;
          if (email.isNotEmpty) _posterEmail = email;
          if (phone.isNotEmpty) _posterPhone = phone;
          _posterPhoto = photo;
          _posterId = uid;
          _liveImageUrl = img;
        });
      }
    }
  }

  UserProfileModel _getPosterProfile() {
    if (_posterName.isNotEmpty && _posterName != 'User') {
      return UserProfileModel(
        id: _posterId ?? '',
        name: _posterName,
        email: _getEmail(),
        phone: _getPhone(),
        photoPath: _posterPhoto,
      );
    }
    final details = AppState.instance.getPosterDetails(widget.post.id);
    if (details != null && details['name'] != null && details['name']!.isNotEmpty) {
      return UserProfileModel(
        name: details['name']!,
        email: details['email'] ?? _getEmail(),
        phone: details['phone'] ?? _getPhone(),
        photoPath: _posterPhoto,
      );
    }
    if (AppState.instance.myPosts.any((p) => p.id == widget.post.id)) {
      return AppState.instance.currentUserProfile;
    }
    return UserProfileModel(
      name: _posterName.isNotEmpty ? _posterName : 'User',
      email: _getEmail(),
      phone: _getPhone(),
      photoPath: _posterPhoto,
    );
  }

  String _getDescription() {
    return _description.isNotEmpty ? _description : 'No description provided.';
  }

  String _getEmail() {
    if (_posterEmail.isNotEmpty) return _posterEmail;
    final details = AppState.instance.getPosterDetails(widget.post.id);
    if (details != null && details['email'] != null && details['email']!.isNotEmpty) {
      return details['email']!;
    }
    return 'No email provided';
  }

  String _getPhone() {
    if (_posterPhone.isNotEmpty) return _posterPhone;
    final details = AppState.instance.getPosterDetails(widget.post.id);
    if (details != null && details['phone'] != null && details['phone']!.isNotEmpty) {
      return details['phone']!;
    }
    return 'No phone provided';
  }

  // Get category icon
  IconData _getCategoryIcon() {
    return _getCategoryIconByName(_getCategoryName());
  }

  // Get category name
  String _getCategoryName() {
    final name = widget.post.itemName.toLowerCase();
    if (name.contains('iphone') || name.contains('phone')) {
      return "Mobiles";
    } else if (name.contains('macbook') || name.contains('headphones')) {
      return "Electronics";
    } else if (name.contains('wallet')) {
      return "Men wallets";
    } else if (name.contains('card')) {
      return "ID card";
    }
    return "Others";
  }

  IconData _getCategoryIconByName(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'mobiles':
        return Icons.phone_iphone_rounded;
      case 'men wallets':
        return Icons.account_balance_wallet_rounded;
      case 'women purse':
        return Icons.shopping_bag_rounded;
      case 'suitcase or bag':
      case 'suite case or bag':
        return Icons.business_center_rounded;
      case 'electronics':
        return Icons.devices_rounded;
      case 'id card':
        return Icons.badge_rounded;
      case 'documents':
        return Icons.description_rounded;
      case 'cash':
        return Icons.payments_rounded;
      case 'gold':
        return Icons.monetization_on_rounded;
      case 'gold and non-gold jewelry':
      case 'gold and non gold jewelry':
        return Icons.diamond_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  // Get city
  String _getCity() {
    final loc = widget.post.location.toLowerCase();
    if (loc.contains('ny') || loc.contains('york') || loc.contains('jfk') || loc.contains('brooklyn') || loc.contains('times square')) {
      return "New York";
    }
    return "Campus City";
  }

  void _copyToClipboard(String text, String fieldName) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$fieldName copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1B9B5A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmDelete(String postId) async {
    final bool? confirm1 = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Delete Post?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
            ),
          ),
          content: Text(
            'Are you sure you want to delete this post?',
            style: GoogleFonts.inter(
              color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE54D2E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                elevation: 0,
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm1 != true || !mounted) return;

    final bool? confirm2 = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Are you absolutely sure?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE54D2E),
            ),
          ),
          content: Text(
            'This action is irreversible. All details of this post will be removed permanently. Do you wish to proceed?',
            style: GoogleFonts.inter(
              color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE54D2E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                elevation: 0,
              ),
              child: Text(
                'Yes, Delete Permanently',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm2 == true && mounted) {
      AppState.instance.deletePost(postId);
      Navigator.of(context).pop(true); // Go back to profile screen returning true
      
      // Show snackbar on parent screen
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF1B9B5A),
          ),
        );
    }
  }

  Future<void> _navigateToEdit(PostModel post) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditPostScreen(post: post),
      ),
    );
    
    if (updated == true && mounted) {
      setState(() {
        _isModified = true;
      }); // Rebuild details page to show new details
    }
  }

  @override
  Widget build(BuildContext context) {
    // Resolve post to the edited one if it exists
    final post = AppState.instance.getPost(widget.post);
    final isSaved = AppState.instance.isSaved(post.id);
    
    // Resolve metadata
    final metadata = AppState.instance.getPostMetadata(post.id);
    final description = metadata != null && metadata['description']!.isNotEmpty ? metadata['description']! : _getDescription();
    final email = metadata != null && metadata['email']!.isNotEmpty ? metadata['email']! : _getEmail();
    final phone = metadata != null && metadata['phone']!.isNotEmpty ? metadata['phone']! : _getPhone();
    final city = metadata != null && metadata['city']!.isNotEmpty ? metadata['city']! : _getCity();

    final categoryName = metadata != null && metadata['category'] != null && metadata['category']!.isNotEmpty
        ? metadata['category']!
        : _getCategoryName();
    final categoryIcon = metadata != null && metadata['category'] != null && metadata['category']!.isNotEmpty
        ? _getCategoryIconByName(categoryName)
        : _getCategoryIcon();
    
    final isMyPost = post.id.startsWith('u') ||
        AppState.instance.myPosts.any((p) => p.id == post.id);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_isModified);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: RefreshIndicator(
          onRefresh: _fetchLivePostDetails,
          color: const Color(0xFF2563EB),
          child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Premium Cover Image / Header ---
            Stack(
              children: [
                // Cover Image or Placeholder
                Container(
                  height: 300,
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
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: post.imageBytes != null
                      ? Image.memory(
                          post.imageBytes!,
                          fit: BoxFit.cover,
                        )
                      : ((_liveImageUrl != null || post.imageUrl != null)
                          ? Image.network(
                              ApiService.formatImageUrl(_liveImageUrl ?? post.imageUrl!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildCategoryPlaceholder(categoryIcon),
                            )
                          : _buildCategoryPlaceholder(categoryIcon)),
                ),
                
                // Bottom curved border decoration
                Positioned(
                  bottom: -1,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                  ),
                ),

                // Back Button & Bookmark Button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Circular Back Button
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(_isModified),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                            size: 20,
                          ),
                        ),
                      ),
                      
                      // Circular Save/Unsave Button
                      GestureDetector(
                        onTap: () {
                          AppState.instance.toggleSave(post);
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Overlay Title on bottom of header
                Positioned(
                  bottom: 32,
                  left: 24,
                  right: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: post.isLost
                              ? const Color(0xFFE54D2E)
                              : const Color(0xFF1B9B5A),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: (post.isLost
                                      ? const Color(0xFFE54D2E)
                                      : const Color(0xFF1B9B5A))
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          post.isLost ? 'Lost Item' : 'Found Item',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).cardColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Item Name
                      Text(
                        post.itemName,
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).cardColor,
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- Body Details ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta Grid (2x2 premium layout)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.1,
                    children: [
                      _buildMetaCard(
                        icon: Icons.calendar_month_rounded,
                        title: 'Date Posted',
                        value: post.date,
                      ),
                      _buildMetaCard(
                        icon: categoryIcon,
                        title: 'Category',
                        value: categoryName,
                      ),
                      _buildMetaCard(
                        icon: Icons.location_on_rounded,
                        title: 'Location',
                        value: post.location,
                        onTap: () => _launchMaps(post),
                      ),
                      _buildMetaCard(
                        icon: Icons.location_city_rounded,
                        title: 'City where item lost/found',
                        value: city,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Reporter Section
                  Text(
                    'Posted By',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      final poster = _getPosterProfile();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PosterProfileScreen(
                            user: poster,
                            post: post,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryBlue.withValues(alpha: 0.05),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primaryBluePale,
                            child: Text(
                              _getPosterProfile().initials,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getPosterProfile().name,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isMyPost ? 'You (Owner)' : (post.date.isNotEmpty ? 'Posted on ${post.date}' : 'Original Poster'),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description Section
                  Text(
                    'Item Description',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.6,
                      color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (isMyPost) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // --- Delete Button ---
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmDelete(post.id),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE54D2E), width: 1.5),
                                foregroundColor: const Color(0xFFE54D2E),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.delete_outline_rounded, size: 20),
                              label: Text(
                                'Delete',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // --- Edit Button ---
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 56,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primaryBlueMid,
                                    AppColors.primaryBlue,
                                  ],
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
                                  onTap: () => _navigateToEdit(post),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Edit Post',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Contact Details Section
                    Text(
                      'Contact Details',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 14),
                    
                    // Contact Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.primaryBlue.withValues(alpha: 0.05),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Email Row
                          _buildContactRow(
                            icon: Icons.mail_rounded,
                            label: 'Email Address',
                            value: email,
                            onAction: () => _copyToClipboard(email, 'Email Address'),
                            actionLabel: 'Copy',
                          ),
                          const SizedBox(height: 16),
                          Container(height: 1, color: AppColors.inputBorder.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          // Phone Row
                          _buildContactRow(
                            icon: Icons.call_rounded,
                            label: 'Phone Number',
                            value: phone,
                            onAction: () => _copyToClipboard(phone, 'Phone Number'),
                            actionLabel: 'Copy',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Calling & WhatsApp Action Buttons Row
                    Row(
                      children: [
                        // --- Call Button ---
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final Uri telUri = Uri.parse('tel:$phone');
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
                                elevation: 4,
                                shadowColor: AppColors.primaryBlue.withValues(alpha: 0.3),
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
                              onPressed: () => _launchWhatsApp(phone, post),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                                shadowColor: const Color(0xFF25D366).withValues(alpha: 0.35),
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

                  ],
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

  Future<void> _launchMaps(PostModel post) async {
    final double? lat = post.latitude;
    final double? lon = post.longitude;
    Uri url;
    if (lat != null && lon != null) {
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    } else {
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(post.location)}');
    }

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      try {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open map: $err'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  String _formatPhoneForWhatsApp(String rawPhone) {
    String digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('03') && digits.length == 11) {
      digits = '92${digits.substring(1)}';
    } else if (digits.length == 10 && !digits.startsWith('92')) {
      digits = '92$digits';
    }
    return digits;
  }

  Future<void> _launchWhatsApp(String phone, PostModel post) async {
    final formattedNumber = _formatPhoneForWhatsApp(phone);
    if (formattedNumber.isEmpty) {
      _showWhatsAppNotAvailableDialog('Phone number is missing or invalid for this post.');
      return;
    }

    final message = Uri.encodeComponent(
      'Hi, I saw your ${post.isLost ? "lost" : "found"} post for "${post.itemName}" on Foundit. Is this item still available?',
    );

    final Uri appSchemeUri = Uri.parse('whatsapp://send?phone=$formattedNumber&text=$message');
    final Uri whatsappWebUri = Uri.parse('https://wa.me/$formattedNumber?text=$message');

    try {
      final appLaunched = await launchUrl(appSchemeUri, mode: LaunchMode.externalApplication);
      if (!appLaunched) {
        final launched = await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
        if (!launched) {
          _showWhatsAppNotAvailableDialog('This user is not available on WhatsApp or WhatsApp is not installed on your device.');
        }
      }
    } catch (_) {
      try {
        final launched = await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
        if (!launched) {
          _showWhatsAppNotAvailableDialog('This user is not available on WhatsApp or WhatsApp is not installed on your device.');
        }
      } catch (err) {
        _showWhatsAppNotAvailableDialog('This user is not available on WhatsApp or WhatsApp is not installed on your device.');
      }
    }
  }

  void _showWhatsAppNotAvailableDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
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

  // Helper to build Metadata Cards
  Widget _buildMetaCard({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    final cardContent = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryBlue,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary),
                      ),
                    ),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 11,
                      color: AppColors.primaryBlue,
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    if (onTap != null) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: AppColors.primaryBlue.withValues(alpha: 0.08),
            highlightColor: AppColors.primaryBlue.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: cardContent,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: cardContent,
    );
  }

  // Helper to build Contact details rows
  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onAction,
    required String actionLabel,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
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
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: onAction,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            side: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
            foregroundColor: AppColors.primaryBlue,
          ),
          child: Text(
            actionLabel,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPlaceholder(IconData icon) {
    return Center(
      child: Opacity(
        opacity: 0.15,
        child: Icon(
          icon,
          size: 140,
          color: Theme.of(context).cardColor,
        ),
      ),
    );
  }
}
