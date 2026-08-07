import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/core/services/api_service.dart';
import 'package:foundit/core/state/app_state.dart';
import 'package:foundit/features/home/domain/post_model.dart';
import 'package:foundit/features/home/presentation/home_screen.dart';
import 'package:foundit/features/post/presentation/create_post_screen.dart';
import 'package:foundit/features/post/presentation/post_detail_screen.dart';
import 'package:foundit/features/profile/data/profile_dummy_data.dart';
import 'package:foundit/features/profile/domain/user_profile_model.dart';
import 'package:foundit/features/profile/presentation/widgets/contact_field_row.dart';
import 'package:foundit/features/profile/presentation/widgets/edit_contact_sheet.dart';
import 'package:foundit/features/profile/presentation/widgets/profile_header.dart';
import 'package:foundit/features/profile/presentation/widgets/profile_image_picker.dart';
import 'package:foundit/features/profile/presentation/widgets/profile_post_card.dart';
import 'package:google_fonts/google_fonts.dart';

/// Profile screen â€” reached from the Home bottom-nav Profile icon.
///
/// FRONTEND ONLY: user data and the "My Posts" list come from
/// [ProfileDummyData]. Edits (photo, email, phone) are held in local
/// [State] only â€” no backend, no persistence. The email/phone change flow
/// simulates OTP verification locally via [EditContactSheet] +
/// [VerifyContactOtpScreen].
class ProfileScreen extends StatefulWidget {
  final UserProfileModel? user;
  final List<PostModel> myPosts;
  final bool showBottomNav;

  const ProfileScreen({
    super.key,
    this.user,
    this.myPosts = const [],
    this.showBottomNav = true,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfileModel _user;
  int _selectedTabIndex = 0;
  late final TextEditingController _searchController;
  String _searchText = '';

  // Pagination states
  int _myPostsPage = 0;
  int _savedPostsPage = 0;

  // Selection states
  bool _isSelectionMode = false;
  final Set<String> _selectedPostIds = {};

  @override
  void initState() {
    super.initState();
    _user = widget.user ?? AppState.instance.currentUserProfile;
    _searchController = TextEditingController();
    _fetchLiveProfile();
    _fetchLiveMyPosts();
    _fetchLiveSavedPosts();
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _fetchLiveProfile(),
      _fetchLiveMyPosts(),
      _fetchLiveSavedPosts(),
    ]);
  }

  Future<void> _fetchLiveSavedPosts() async {
    final res = await ApiService.getSavedPosts();
    if (res['success'] == true && res['savedPosts'] != null) {
      final List raw = res['savedPosts'];
      final List<PostModel> liveSaved = [];
      for (final json in raw) {
        if (json is! Map) continue;
        final List images = json['images'] ?? [];
        String? imgUrl;
        if (images.isNotEmpty) {
          final String firstImg = images.first.toString();
          imgUrl = ApiService.formatImageUrl(firstImg);
        }
        final String rawStatus = (json['status'] ?? '').toString().toLowerCase().trim();
        final PostStatus parsedStatus = rawStatus == 'approved'
            ? PostStatus.approved
            : (rawStatus == 'rejected' ? PostStatus.rejected : PostStatus.pending);

        final String pid = json['_id'] ?? json['id'] ?? '';
        final String desc = json['description'] ?? '';
        final String city = json['city'] ?? '';
        final String category = json['category'] ?? '';

        final userObj = json['userId'] ?? json['user'];
        String posterEmail = '';
        String posterPhone = '';
        String posterName = '';
        if (userObj is Map) {
          posterName = userObj['name'] ?? '';
          posterEmail = userObj['email'] ?? '';
          posterPhone = userObj['phone'] ?? '';
          if (posterName.isNotEmpty) {
            AppState.instance.setPosterDetails(
              postId: pid,
              name: posterName,
              email: posterEmail,
              phone: posterPhone,
            );
          }
        }

        AppState.instance.setPostMetadata(
          pid,
          description: desc,
          city: city,
          category: category,
          email: posterEmail,
          phone: posterPhone,
        );

        liveSaved.add(PostModel(
          id: pid,
          itemName: json['itemName'] ?? 'Item',
          isLost: json['isLost'] == true,
          date: json['date'] ?? '',
          location: json['locationName'] ?? json['city'] ?? '',
          imageUrl: imgUrl,
          status: parsedStatus,
        ));
      }

      AppState.instance.setSavedPosts(liveSaved);
      if (mounted) setState(() {});
    }
  }

  Future<void> _fetchLiveProfile() async {
    final res = await ApiService.getMe();
    if (res['success'] == true && res['user'] != null) {
      final u = res['user'];
      final String name = u['name'] ?? _user.name;
      final String email = u['email'] ?? _user.email;
      final String phone = u['phone'] ?? _user.phone;
      final String? photo = u['photoUrl'];

      AppState.instance.updateCurrentUserProfile(
        name: name,
        email: email,
        phone: phone,
        photoUrl: photo,
      );

      if (mounted) {
        setState(() {
          _user = AppState.instance.currentUserProfile;
        });
      }
    }
  }

  Future<void> _fetchLiveMyPosts() async {
    final res = await ApiService.getMyPosts();
    if (res['success'] == true && res['posts'] != null) {
      final List raw = res['posts'];
      final liveMyPosts = raw.map((json) {
        final List images = json['images'] ?? [];
        String? imgUrl;
        if (images.isNotEmpty) {
          final String firstImg = images.first.toString();
          imgUrl = firstImg.startsWith('http')
              ? firstImg
              : '${ApiService.baseUrl.replaceAll('/api', '')}$firstImg';
        }
        final String rawStatus = (json['status'] ?? '').toString().toLowerCase().trim();
        final PostStatus parsedStatus = rawStatus == 'approved'
            ? PostStatus.approved
            : (rawStatus == 'rejected' ? PostStatus.rejected : PostStatus.pending);

        final String pid = json['_id'] ?? json['id'] ?? '';
        if (parsedStatus == PostStatus.approved) {
          AppState.instance.approvePost(pid);
        } else if (parsedStatus == PostStatus.rejected) {
          AppState.instance.rejectPost(pid);
        }

        final String desc = json['description'] ?? '';
        final String city = json['city'] ?? '';
        final String category = json['category'] ?? '';
        final userObj = json['userId'] ?? json['user'];
        String userEmail = AppState.instance.userEmail;
        String userPhone = AppState.instance.userPhone;
        String userName = AppState.instance.userName;
        if (userObj is Map) {
          if ((userObj['email'] ?? '').toString().isNotEmpty) userEmail = userObj['email'];
          if ((userObj['phone'] ?? '').toString().isNotEmpty) userPhone = userObj['phone'];
          if ((userObj['name'] ?? '').toString().isNotEmpty) userName = userObj['name'];
        }

        AppState.instance.setPostMetadata(
          pid,
          description: desc,
          city: city,
          category: category,
          email: userEmail,
          phone: userPhone,
        );

        AppState.instance.setPosterDetails(
          postId: pid,
          name: userName,
          email: userEmail,
          phone: userPhone,
        );

        return PostModel(
          id: pid,
          itemName: json['itemName'] ?? 'Item',
          isLost: json['isLost'] == true,
          date: json['date'] ?? '',
          location: json['locationName'] ?? json['city'] ?? '',
          imageUrl: imgUrl,
          status: parsedStatus,
        );
      }).toList();

      if (mounted) {
        setState(() {
          // Replace myPosts with live MongoDB user posts
          AppState.instance.myPosts.clear();
          AppState.instance.myPosts.addAll(liveMyPosts);
        });
      }
    }
  }

void _exitSelectionMode() {
setState(() {
_isSelectionMode = false;
_selectedPostIds.clear();
});
}

void _selectAllPosts(List<PostModel> activeList) {
setState(() {
if (_selectedPostIds.length == activeList.length) {
_selectedPostIds.clear();
} else {
_selectedPostIds.clear();
_selectedPostIds.addAll(activeList.map((p) => p.id));
}
});
}

Future<void> _deleteSelectedPosts(List<PostModel> activeList) async {
if (_selectedPostIds.isEmpty) return;

final isMyPosts = _selectedTabIndex == 0;
final titleText = isMyPosts ? 'Delete Posts?' : 'Unsave Posts?';
final contentText = isMyPosts
? 'Are you sure you want to permanently delete the ${_selectedPostIds.length} selected post(s)?'
: 'Are you sure you want to remove the ${_selectedPostIds.length} selected post(s) from your saved posts?';
final actionText = isMyPosts ? 'Delete' : 'Remove';
final actionColor = isMyPosts ? const Color(0xFFE54D2E) : AppColors.primaryBlue;

final bool? confirm = await showDialog<bool>(
context: context,
barrierDismissible: false,
builder: (BuildContext context) {
return AlertDialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
title: Text(
titleText,
style: GoogleFonts.poppins(
fontWeight: FontWeight.w700,
color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
),
),
content: Text(
contentText,
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
backgroundColor: actionColor,
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
elevation: 0,
),
child: Text(
actionText,
style: GoogleFonts.inter(
fontWeight: FontWeight.w700,
),
),
),
],
);
},
);

if (confirm != true || !mounted) return;

    if (isMyPosts) {
      for (final id in _selectedPostIds) {
        AppState.instance.deletePost(id);
        ApiService.deletePost(id);
      }
      _showToast('${_selectedPostIds.length} post(s) deleted successfully');
      _fetchLiveMyPosts();
    } else {
final postsToUnsave = activeList.where((p) => _selectedPostIds.contains(p.id)).toList();
for (final post in postsToUnsave) {
AppState.instance.toggleSave(post);
}
_showToast('${_selectedPostIds.length} post(s) removed from saved');
}

_exitSelectionMode();
}

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

  // --- Photo upload ---------------------------
  // NOTE: Image bytes are uploaded to the server inside ProfileImagePicker._pick().
  // This callback receives the server path (e.g. /uploads/profile_xxx.jpg) directly.
  void _onImagePicked(String serverPath) async {
    if (serverPath.isEmpty) {
      // Remove photo
      setState(() {
        _user = _user.copyWith(clearPhoto: true);
      });
      await ApiService.updateProfile(photoUrl: '');
      AppState.instance.setCurrentUserProfile(
        name: _user.name,
        email: _user.email,
        phone: _user.phone,
        photoUrl: '',
      );
      _showToast('Profile photo removed');
      return;
    }

    // serverPath is already a backend path like /uploads/profile_xxx.jpg
    // If it's a webcam data URI, upload it now
    if (serverPath.startsWith('data:image')) {
      try {
        final base64Str = serverPath.split(',').last;
        final bytes = base64Decode(base64Str);
        final uploadRes = await ApiService.uploadImageBytes(
          bytes: bytes,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        if (uploadRes['success'] == true && uploadRes['filePath'] != null) {
          serverPath = uploadRes['filePath'];
        }
      } catch (_) {}
    }

    // Update UI immediately
    if (mounted) {
      setState(() {
        _user = _user.copyWith(photoPath: serverPath);
      });
    }

    // Save to MongoDB
    await ApiService.updateProfile(photoUrl: serverPath);
    AppState.instance.setCurrentUserProfile(
      name: _user.name,
      email: _user.email,
      phone: _user.phone,
      photoUrl: serverPath,
    );
    _showToast('Profile photo updated successfully!');
  }

// --- Name edit (direct popup dialog) -------------------------------------
Future<void> _editName() async {
final TextEditingController nameController =
TextEditingController(text: _user.name);
final formKey = GlobalKey<FormState>();

final newName = await showModalBottomSheet<String>(
context: context,
backgroundColor: Colors.transparent,
isScrollControlled: true,
builder: (context) => Padding(
padding: EdgeInsets.only(
bottom: MediaQuery.of(context).viewInsets.bottom,
),
child: Container(
decoration: BoxDecoration(
color: Theme.of(context).cardColor,
borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
),
padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
child: SafeArea(
top: false,
child: Form(
key: formKey,
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Center(
child: Container(
width: 40,
height: 4,
decoration: BoxDecoration(
color: (Theme.of(context).brightness == Brightness.dark ? Colors.white10 : AppColors.inputBorder),
borderRadius: BorderRadius.circular(100),
),
),
),
const SizedBox(height: 20),
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(
'Change Name',
style: GoogleFonts.poppins(
fontSize: 20,
fontWeight: FontWeight.w700,
color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
letterSpacing: -0.3,
),
),
IconButton(
onPressed: () => Navigator.of(context).pop(),
icon: const Icon(Icons.close_rounded,
color: AppColors.textSecondary),
),
],
),
const SizedBox(height: 4),
Text(
'Enter your full name to display on your profile and posts.',
style: GoogleFonts.inter(
fontSize: 13,
color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary),
height: 1.5,
),
),
const SizedBox(height: 20),
TextFormField(
controller: nameController,
autofocus: true,
style: GoogleFonts.inter(
fontSize: 15,
fontWeight: FontWeight.w600,
color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
),
decoration: InputDecoration(
hintText: 'John Doe',
hintStyle: GoogleFonts.inter(
color: AppColors.textSecondary.withValues(alpha: 0.4),
fontSize: 14,
),
prefixIcon: const Icon(
Icons.person_rounded,
color: AppColors.primaryBlue,
size: 20,
),
filled: true,
fillColor: Theme.of(context).scaffoldBackgroundColor,
contentPadding: const EdgeInsets.symmetric(
horizontal: 16, vertical: 16),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: BorderSide(
color: AppColors.primaryBlue.withValues(alpha: 0.1),
),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: const BorderSide(
color: AppColors.primaryBlue, width: 1.5),
),
),
validator: (v) {
if (v == null || v.trim().isEmpty) {
return 'Name cannot be empty.';
}
if (v.trim().length < 2) {
return 'Name must be at least 2 characters.';
}
return null;
},
),
const SizedBox(height: 24),
SizedBox(
width: double.infinity,
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
onTap: () {
if (formKey.currentState!.validate()) {
Navigator.of(context).pop(nameController.text.trim());
}
},
child: Center(
child: Text(
'Save Changes',
style: GoogleFonts.inter(
color: Colors.white,
fontSize: 16,
fontWeight: FontWeight.w600,
letterSpacing: 0.5,
),
),
),
),
),
),
),
],
),
),
),
),
),
);

if (newName != null && mounted && newName != _user.name) {
  // Sync live update with MongoDB Database
  ApiService.updateProfile(name: newName);
  AppState.instance.updateCurrentUserProfile(name: newName);

  setState(() {
    _user = _user.copyWith(name: newName);
  });
  _showToast('Name updated successfully in Database');
}
}

// --- Email / phone edit flow -------------------------
Future<void> _editField(ContactFieldType type) async {
  final currentValue =
      type == ContactFieldType.email ? _user.email : _user.phone;

  final result = await EditContactSheet.show(
    context,
    type: type,
    currentValue: currentValue,
  );

  if (result != null && mounted) {
    setState(() {
      _user = type == ContactFieldType.email
          ? _user.copyWith(email: result)
          : _user.copyWith(phone: result);
    });

    AppState.instance.updateCurrentUserProfile(
      email: type == ContactFieldType.email ? result : null,
      phone: type == ContactFieldType.phone ? result : null,
    );

    _showToast(
      type == ContactFieldType.email
          ? 'Email updated successfully'
          : 'Phone number updated successfully',
    );
  }
}

void _showToast(String message, {bool isError = false}) {
final messenger = ScaffoldMessenger.of(context);
messenger
..hideCurrentSnackBar()
..showSnackBar(
SnackBar(
content: Text(message),
behavior: SnackBarBehavior.floating,
backgroundColor: isError ? Colors.redAccent : const Color(0xFF1B9B5A),
duration: const Duration(seconds: 2),
),
);
}

Widget _buildTabOption({
required int index,
required String label,
required int count,
}) {
final isSelected = _selectedTabIndex == index;
return Expanded(
child: GestureDetector(
onTap: () {
setState(() {
_selectedTabIndex = index;
_myPostsPage = 0;
_savedPostsPage = 0;
_isSelectionMode = false;
_selectedPostIds.clear();
});
},
child: AnimatedContainer(
duration: const Duration(milliseconds: 250),
curve: Curves.easeInOut,
padding: const EdgeInsets.symmetric(vertical: 10),
decoration: BoxDecoration(
color: isSelected ? Theme.of(context).cardColor : Colors.transparent,
borderRadius: BorderRadius.circular(100),
boxShadow: isSelected
? [
BoxShadow(
color: AppColors.primaryBlue.withValues(alpha: 0.08),
blurRadius: 10,
offset: const Offset(0, 4),
),
]
: [],
),
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Text(
label,
style: GoogleFonts.inter(
fontSize: 14,
fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
color: isSelected ? AppColors.primaryBlue : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary),
),
),
const SizedBox(width: 6),
AnimatedContainer(
duration: const Duration(milliseconds: 250),
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
decoration: BoxDecoration(
color: isSelected
? AppColors.primaryBlue
: AppColors.primaryBlue.withValues(alpha: 0.08),
borderRadius: BorderRadius.circular(100),
),
child: Text(
'$count',
style: GoogleFonts.inter(
fontSize: 11,
fontWeight: FontWeight.w700,
color: isSelected ? Colors.white : AppColors.primaryBlue,
),
),
),
],
),
),
),
);
}

@override
Widget build(BuildContext context) {
final List<PostModel> allMyPosts = [...widget.myPosts, ...AppState.instance.myPosts]
.where((post) => !AppState.instance.isDeleted(post.id))
.toList();
final List<PostModel> savedPosts = AppState.instance.savedPosts
.where((post) => !AppState.instance.isDeleted(post.id))
.toList();

final int lostCount = allMyPosts.where((p) => p.isLost).toList().length;
final int foundCount = allMyPosts.length - lostCount;

final List<PostModel> activeList = (_selectedTabIndex == 0 ? allMyPosts : savedPosts)
.where((post) {
if (_searchText.trim().isEmpty) return true;
final query = _searchText.trim().toLowerCase();
final metadata = AppState.instance.getPostMetadata(post.id);
final desc = metadata != null ? metadata['description'] ?? '' : '';

return post.itemName.toLowerCase().contains(query) ||
post.location.toLowerCase().contains(query) ||
desc.toLowerCase().contains(query);
})
.toList();

// Slicing logic for pagination
final int currentPage = _selectedTabIndex == 0 ? _myPostsPage : _savedPostsPage;
const int pageSize = 5;
final int totalItems = activeList.length;
final int totalPages = (totalItems / pageSize).ceil();

int safePage = currentPage;
if (safePage >= totalPages && totalPages > 0) {
safePage = totalPages - 1;
if (_selectedTabIndex == 0) {
_myPostsPage = safePage;
} else {
_savedPostsPage = safePage;
}
}
if (safePage < 0) {
safePage = 0;
if (_selectedTabIndex == 0) {
_myPostsPage = 0;
} else {
_savedPostsPage = 0;
}
}

final List<PostModel> activeListPaged = activeList.skip(safePage * pageSize).take(pageSize).toList();

    final liveUser = AppState.instance.currentUserProfile;
    final effectiveUser = UserProfileModel(
      name: _user.name.isNotEmpty ? _user.name : liveUser.name,
      email: _user.email.isNotEmpty ? _user.email : liveUser.email,
      phone: _user.phone.isNotEmpty ? _user.phone : liveUser.phone,
      photoPath: (_user.photoPath != null && _user.photoPath!.isNotEmpty)
          ? _user.photoPath
          : liveUser.photoPath,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: AppColors.primaryBlue,
              elevation: 4,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: _exitSelectionMode,
              ),
              title: Text(
                '${_selectedPostIds.length} Selected',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => _selectAllPosts(activeList),
                  child: Text(
                    _selectedPostIds.length == activeList.length ? 'Deselect All' : 'Select All',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.white),
                  onPressed: () => _deleteSelectedPosts(activeList),
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primaryBlue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // --- Header (gradient, editable avatar, name, contact chips, stats) ---
          SliverToBoxAdapter(
            child: ProfileHeader(
              user: effectiveUser,
              avatar: ProfileImagePicker(
                user: effectiveUser,
                onImagePicked: _onImagePicked,
              ),
              stats: [
                ProfileStatTile(
                    value: '${allMyPosts.length}', label: 'Total Posts'),
                ProfileStatTile(value: '$lostCount', label: 'Lost'),
                ProfileStatTile(value: '$foundCount', label: 'Found'),
              ],
            ),
          ),

          // --- "Profile Info" editable section ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
              child: Text(
                'Profile Info',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Column(
                children: [
                  ContactFieldRow(
                    type: ContactFieldType.name,
                    value: effectiveUser.name,
                    onEdit: _editName,
                  ),
                  ContactFieldRow(
                    type: ContactFieldType.email,
                    value: effectiveUser.email,
                    onEdit: () => _editField(ContactFieldType.email),
                  ),
                  ContactFieldRow(
                    type: ContactFieldType.phone,
                    value: effectiveUser.phone,
                    onEdit: () => _editField(ContactFieldType.phone),
                  ),
],
),
),
),

// --- Tab selector ("My Posts" vs "Saved Posts") ---
SliverToBoxAdapter(
child: Padding(
padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
child: Container(
padding: const EdgeInsets.all(4),
decoration: BoxDecoration(
color: AppColors.primaryBlue.withValues(alpha: 0.05),
borderRadius: BorderRadius.circular(100),
border: Border.all(
color: AppColors.primaryBlue.withValues(alpha: 0.08),
),
),
child: Row(
children: [
_buildTabOption(
index: 0,
label: AppState.instance.translate('My Posts'),
count: allMyPosts.length,
),
_buildTabOption(
index: 1,
label: AppState.instance.translate('Saved Posts'),
count: savedPosts.length,
),
],
),
),
),
),

// --- Search Bar ---
SliverToBoxAdapter(
child: Padding(
padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
child: Container(
decoration: BoxDecoration(
color: Theme.of(context).cardColor,
borderRadius: BorderRadius.circular(16),
border: Border.all(
color: AppColors.primaryBlue.withValues(alpha: 0.1),
width: 1,
),
boxShadow: [
BoxShadow(
color: Colors.black.withValues(alpha: 0.02),
blurRadius: 10,
offset: const Offset(0, 4),
),
],
),
child: TextField(
controller: _searchController,
onChanged: (val) {
setState(() {
_searchText = val;
_myPostsPage = 0;
_savedPostsPage = 0;
});
},
style: GoogleFonts.inter(fontSize: 14, color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary)),
decoration: InputDecoration(
hintText: AppState.instance.translate(_selectedTabIndex == 0 ? 'Search my posts...' : 'Search saved posts...'),
hintStyle: GoogleFonts.inter(
color: AppColors.textSecondary.withValues(alpha: 0.4),
fontSize: 13,
),
prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryBlue, size: 20),
suffixIcon: _searchText.isNotEmpty
? IconButton(
icon: Icon(Icons.clear_rounded, color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary), size: 18),
onPressed: () {
_searchController.clear();
setState(() {
_searchText = '';
_myPostsPage = 0;
_savedPostsPage = 0;
});
},
)
: null,
border: InputBorder.none,
contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
),
),
),
),
),

// --- Posts list (or empty state) ---
activeList.isEmpty
? SliverFillRemaining(
hasScrollBody: false,
child: _searchText.isNotEmpty
? _EmptyPostsState(
title: 'No results found',
subtitle: 'No posts matched "$_searchText".',
icon: Icons.search_off_rounded,
)
: _selectedTabIndex == 0
? const _EmptyPostsState(
title: 'No posts yet',
subtitle: 'Posts you create will appear here.',
icon: Icons.inbox_rounded,
)
: const _EmptyPostsState(
title: 'No saved posts',
subtitle: 'Posts you bookmark will appear here.',
icon: Icons.bookmark_border_rounded,
),
)
: SliverPadding(
padding: EdgeInsets.fromLTRB(24, 16, 24, totalPages > 1 ? 0 : 120),
sliver: SliverList(
delegate: SliverChildBuilderDelegate(
(context, index) {
final post = activeListPaged[index];
return ProfilePostCard(
post: post,
showStatus: _selectedTabIndex == 0,
isSelectionMode: _isSelectionMode,
isSelected: _selectedPostIds.contains(post.id),
onLongPress: () {
setState(() {
_isSelectionMode = true;
_selectedPostIds.add(post.id);
});
},
onBookmarkToggle: () {
AppState.instance.toggleSave(post);
setState(() {});
},
onTap: () async {
if (_isSelectionMode) {
setState(() {
if (_selectedPostIds.contains(post.id)) {
_selectedPostIds.remove(post.id);
if (_selectedPostIds.isEmpty) {
_isSelectionMode = false;
}
} else {
_selectedPostIds.add(post.id);
}
});
} else {
await Navigator.push(
context,
MaterialPageRoute(
builder: (context) =>
PostDetailScreen(post: post),
),
);
setState(() {});
}
},
);
},
childCount: activeListPaged.length,
),
),
),

// --- Pagination Row ---
if (activeList.isNotEmpty && totalPages > 1)
SliverToBoxAdapter(
child: Padding(
padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
// Previous Button
Material(
color: Colors.transparent,
child: InkWell(
onTap: safePage > 0
? () {
setState(() {
if (_selectedTabIndex == 0) {
_myPostsPage--;
} else {
_savedPostsPage--;
}
});
}
: null,
borderRadius: BorderRadius.circular(14),
child: Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: safePage > 0
                                ? AppColors.primaryBlue.withValues(alpha: 0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: safePage > 0
                                  ? AppColors.primaryBlue.withValues(alpha: 0.15)
                                  : AppColors.inputBorder.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: safePage > 0
                                ? AppColors.primaryBlue
                                : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary).withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Text(
                      'Page ${safePage + 1} of $totalPages',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Next Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: safePage < totalPages - 1
                            ? () {
                                setState(() {
                                  if (_selectedTabIndex == 0) {
                                    _myPostsPage++;
                                  } else {
                                    _savedPostsPage++;
                                  }
                                });
                              }
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: safePage < totalPages - 1
                                ? AppColors.primaryBlue.withValues(alpha: 0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: safePage < totalPages - 1
                                  ? AppColors.primaryBlue.withValues(alpha: 0.15)
                                  : AppColors.inputBorder.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: safePage < totalPages - 1
                                ? AppColors.primaryBlue
                                : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary).withValues(alpha: 0.3),
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
      ),

      // --- Floating bottom navigation bar (mirrors Home) ---
      bottomNavigationBar: widget.showBottomNav && !_isSelectionMode
          ? SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.primaryBlueMid,
                      AppColors.primaryBlue,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 64,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.home_rounded,
                            color: Colors.white60, size: 26),
                        onPressed: () {
                          // Frontend-only: pop back to the Home screen
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(),
                            ),
                            (route) => false,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_rounded,
                            color: Colors.white, size: 32),
                        onPressed: () async {
                          final created = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreatePostScreen(),
                            ),
                          );
                          if (created == true && mounted) {
                            _fetchLiveMyPosts();
                          }
                        },
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_rounded,
                              color: Theme.of(context).cardColor, size: 26),
                          const SizedBox(height: 4),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Empty-state shown when a list is empty.
// ---------------------------------------------------------------------------
class _EmptyPostsState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _EmptyPostsState({
    this.title = 'No posts yet',
    this.subtitle = 'Posts you oreate will appear here.',
    this.icon = Icons.inbox_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.primaryBlue.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
