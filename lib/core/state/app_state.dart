import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foundit/core/services/api_service.dart';
import 'package:foundit/features/home/domain/post_model.dart';
import 'package:foundit/features/profile/domain/user_profile_model.dart';

/// Simple in-memory store for saved posts and user profile data.
/// In a real app this would be backed by SharedPreferences / a database.
class AppState {
  AppState._() {
    _initializeRegisteredUsers();
    _initializeAdminNotifications();
    _initializeUserWarnings();
  }
  static final AppState instance = AppState._();

  // ── Currently Logged-In User Profile ─────────────────────────────────────
  UserProfileModel? _currentUserProfile;
  UserProfileModel get currentUserProfile =>
      _currentUserProfile ??
      const UserProfileModel(
        name: 'User',
        email: 'user@example.com',
        phone: '',
      );

  String _userId = '';
  String? token;
  String get userId => _userId;
  String get userName => currentUserProfile.name;
  String get userEmail => currentUserProfile.email;
  String get userPhone => currentUserProfile.phone;

  void setCurrentUserProfile({
    String id = '',
    String? userToken,
    required String name,
    required String email,
    String phone = '',
    String photoUrl = '',
    bool isNewLoginSession = false,
  }) {
    if (id.isNotEmpty) _userId = id;
    if (userToken != null && userToken.isNotEmpty) token = userToken;
    final existingPhoto = _currentUserProfile?.photoPath;
    _currentUserProfile = UserProfileModel(
      name: name,
      email: email,
      phone: phone,
      photoPath: photoUrl.isNotEmpty ? photoUrl : existingPhoto,
    );
    if (isNewLoginSession) {
      _myPosts.clear();
    }
  }

  void updateCurrentUserProfile({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
  }) {
    final current = currentUserProfile;
    final updatedName = name ?? current.name;
    final updatedEmail = email ?? current.email;
    final updatedPhone = phone ?? current.phone;
    final updatedPhoto = photoUrl ?? current.photoPath;

    _currentUserProfile = UserProfileModel(
      name: updatedName,
      email: updatedEmail,
      phone: updatedPhone,
      photoPath: updatedPhoto,
    );

    // Update in registeredUsers list if present
    final idx = _registeredUsers.indexWhere((u) =>
        u.email.toLowerCase() == current.email.toLowerCase() ||
        u.email.toLowerCase() == updatedEmail.toLowerCase());
    if (idx != -1) {
      _registeredUsers[idx] = _registeredUsers[idx].copyWith(
        name: updatedName,
        email: updatedEmail,
        phone: updatedPhone,
      );
    }
  }

  // ── Registered Users (for Admin Panel) ──────────────────────────────────
  final List<UserProfileModel> _registeredUsers = [];
  List<UserProfileModel> get registeredUsers => _registeredUsers;

  void _initializeRegisteredUsers() {
    _registeredUsers.addAll([
      UserProfileModel(
        name: 'John Doe',
        email: 'john.doe@example.com',
        phone: '+1 (123) 456-7890',
        registrationDate: DateTime(2023, 10, 22),
        isDeleted: false,
        registrationType: 'signup',
      ),
      UserProfileModel(
        name: 'Alex Morgan',
        email: 'alex.m@example.com',
        phone: '+1 (555) 019-2834',
        registrationDate: DateTime(2023, 10, 23),
        isDeleted: false,
        registrationType: 'signup',
      ),
      UserProfileModel(
        name: 'Jessica Brown',
        email: 'jessica.b@example.com',
        phone: '+1 (555) 024-9988',
        registrationDate: DateTime(2023, 10, 24),
        isDeleted: false,
        registrationType: 'registered',
      ),
      UserProfileModel(
        name: 'Michael Smith',
        email: 'michael.s@example.com',
        phone: '+1 (555) 038-1245',
        registrationDate: DateTime(2023, 10, 25),
        isDeleted: true,
        deletionDate: DateTime(2023, 10, 26),
        registrationType: 'signup',
      ),
      UserProfileModel(
        name: 'Emily Davis',
        email: 'emily.d@example.com',
        phone: '+1 (555) 042-3377',
        registrationDate: DateTime(2023, 10, 26),
        isDeleted: false,
        registrationType: 'signup',
      ),
      UserProfileModel(
        name: 'David Jones',
        email: 'david.j@example.com',
        phone: '+1 (555) 088-7711',
        registrationDate: DateTime(2023, 10, 26),
        isDeleted: false,
        registrationType: 'registered',
      ),
      UserProfileModel(
        name: 'Sarah Wilson',
        email: 'sarah.w@example.com',
        phone: '+1 (555) 099-2244',
        registrationDate: DateTime(2023, 10, 26),
        isDeleted: false,
        registrationType: 'signup',
      ),
      UserProfileModel(
        name: 'James Taylor',
        email: 'james.t@example.com',
        phone: '+1 (555) 077-8899',
        registrationDate: DateTime(2023, 10, 25),
        isDeleted: false,
        registrationType: 'signup',
      ),
      UserProfileModel(
        name: 'Linda Thomas',
        email: 'linda.t@example.com',
        phone: '+1 (555) 066-5544',
        registrationDate: DateTime(2023, 10, 24),
        isDeleted: true,
        deletionDate: DateTime(2023, 10, 25),
        registrationType: 'registered',
      ),
      UserProfileModel(
        name: 'Robert Jackson',
        email: 'robert.j@example.com',
        phone: '+1 (555) 011-2233',
        registrationDate: DateTime(2023, 10, 23),
        isDeleted: false,
        registrationType: 'signup',
      ),
      UserProfileModel(
        name: 'Patricia White',
        email: 'patricia.w@example.com',
        phone: '+1 (555) 044-5566',
        registrationDate: DateTime(2023, 10, 22),
        isDeleted: false,
        registrationType: 'registered',
      ),
      UserProfileModel(
        name: 'Charles Harris',
        email: 'charles.h@example.com',
        phone: '+1 (555) 077-8822',
        registrationDate: DateTime(2023, 10, 21),
        isDeleted: true,
        deletionDate: DateTime(2023, 10, 23),
        registrationType: 'signup',
      ),
      UserProfileModel(
        name: 'Barbara Martin',
        email: 'barbara.m@example.com',
        phone: '+1 (555) 099-0011',
        registrationDate: DateTime(2023, 10, 20),
        isDeleted: false,
        registrationType: 'signup',
      ),
      UserProfileModel(
        name: 'William Thompson',
        email: 'william.t@example.com',
        phone: '+1 (555) 088-9900',
        registrationDate: DateTime(2023, 10, 26),
        isDeleted: false,
        registrationType: 'registered',
      ),
      UserProfileModel(
        name: 'Elizabeth Garcia',
        email: 'elizabeth.g@example.com',
        phone: '+1 (555) 077-6655',
        registrationDate: DateTime(2023, 10, 26),
        isDeleted: true,
        deletionDate: DateTime(2023, 10, 26),
        registrationType: 'signup',
      ),
    ]);
  }

  // ── Admin Notifications ─────────────────────────────────────────────────
  final List<AdminNotification> _adminNotifications = [];
  List<AdminNotification> get adminNotifications => _adminNotifications;

  void addAdminNotification(String title, String body, IconData icon, Color color) {
    _adminNotifications.insert(
      0,
      AdminNotification(
        title: title,
        body: body,
        time: 'Just now',
        icon: icon,
        color: color,
      ),
    );
  }

  void _initializeAdminNotifications() {
    _adminNotifications.addAll([
      AdminNotification(
        title: 'New Account Created',
        body: 'Emily Davis (emily.d@example.com) signed up as a new user.',
        time: '1h ago',
        icon: Icons.person_add_alt_1_rounded,
        color: const Color(0xFF10B981),
      ),
      AdminNotification(
        title: 'Account Deleted',
        body: 'Michael Smith (michael.s@example.com) has deleted their account.',
        time: '2h ago',
        icon: Icons.person_remove_rounded,
        color: const Color(0xFFEF4444),
      ),
      AdminNotification(
        title: 'New Account Created',
        body: 'William Thompson (william.t@example.com) registered an account.',
        time: '3h ago',
        icon: Icons.person_add_alt_1_rounded,
        color: const Color(0xFF10B981),
      ),
      AdminNotification(
        title: 'Account Deleted',
        body: 'Linda Thomas (linda.t@example.com) has deleted their account.',
        time: 'Yesterday',
        icon: Icons.person_remove_rounded,
        color: const Color(0xFFEF4444),
      ),
    ]);
  }

  void registerNewUser(String name, String email) {
    _registeredUsers.add(UserProfileModel(
      name: name,
      email: email,
      phone: '+1 (555) 019-0000',
      registrationDate: DateTime(2023, 10, 26), // simulated today
      isDeleted: false,
      registrationType: 'signup',
    ));
  }

  void deleteUserAccount(String email) {
    final idx = _registeredUsers.indexWhere((u) => u.email == email);
    if (idx != -1) {
      final user = _registeredUsers[idx];
      _registeredUsers[idx] = user.copyWith(
        isDeleted: true,
        deletionDate: DateTime(2023, 10, 26), // simulated today
      );
      addAdminNotification(
        'Account Deleted',
        '${user.name} (${user.email}) has deleted their account.',
        Icons.person_remove_rounded,
        const Color(0xFFEF4444),
      );
    }
  }

  // ── User Warnings (Admin Issued) ─────────────────────────────────────────
  final List<UserWarning> _issuedWarnings = [];
  List<UserWarning> get issuedWarnings => _issuedWarnings;

  void issueWarningToUser({
    required String userEmail,
    required String postId,
    required String postName,
    required String subject,
    required String explanation,
  }) {
    _issuedWarnings.add(UserWarning(
      userEmail: userEmail,
      postId: postId,
      postName: postName,
      subject: subject,
      explanation: explanation,
      date: DateTime.now(),
    ));

    // Send warning notification to user
    addNotification(
      'foundit has issued a warning on this post',
      'Post: "$postName"\nSubject: $subject\nReason: $explanation',
      NotificationType.warning,
    );

    // Add activity log to admin panel Audit Logs tab
    addAdminNotification(
      'Warning Issued',
      'Warning sent to $userEmail on post "$postName". Subject: $subject',
      Icons.warning_amber_rounded,
      const Color(0xFFF59E0B),
    );
  }

  List<UserWarning> getWarningsForUser(String email) {
    return _issuedWarnings.where((w) => w.userEmail.toLowerCase() == email.toLowerCase()).toList();
  }

  void _initializeUserWarnings() {
    _issuedWarnings.add(UserWarning(
      userEmail: 'james.ob@email.com',
      postId: 'p4',
      postName: 'Black Leather Gloves',
      subject: 'Incomplete Description',
      explanation: 'Please add details about the brand and size of the gloves.',
      date: DateTime(2023, 10, 24),
    ));
  }

  // ── Saved Posts ──────────────────────────────────────────────────────────
  final Set<String> _savedPostIds = {};

  bool isSaved(String postId) => _savedPostIds.contains(postId);

  void toggleSave(PostModel post) {
    if (_savedPostIds.contains(post.id)) {
      _savedPostIds.remove(post.id);
      _savedPosts.removeWhere((p) => p.id == post.id);
    } else {
      _savedPostIds.add(post.id);
      _savedPosts.add(post);
    }
    // Sync live bookmark update with MongoDB database
    ApiService.toggleSavePost(post.id);
  }

  final List<PostModel> _savedPosts = [];
  List<PostModel> get savedPosts => List.unmodifiable(_savedPosts);

  void setSavedPosts(List<PostModel> posts) {
    _savedPosts.clear();
    _savedPostIds.clear();
    for (final p in posts) {
      _savedPosts.add(p);
      _savedPostIds.add(p.id);
    }
  }

  // ── My Posts (frontend-only — posts the user "published") ────────────────
  final List<PostModel> _myPosts = [];
  List<PostModel> get myPosts => _myPosts;
  List<PostModel> get allPosts => List.unmodifiable([..._myPosts, ..._savedPosts]);

  void addMyPost(PostModel post) {
    // New user posts start as pending
    _myPosts.add(post.copyWith(status: PostStatus.pending));
    _postStatuses[post.id] = PostStatus.pending;
  }

  // ── Theme State ──────────────────────────────────────────────────────────
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);
  bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;
  void toggleTheme(bool isDark) {
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  // ── Language State (Removed) ────────────────────────────────────────────
  String translate(String key) => key;

  // ── Notifications State ──────────────────────────────────────────────────
  bool notificationsEnabled = true;

  // ── User Profile ─────────────────────────────────────────────────────────
  // (Managed via currentUserProfile getters)

  // ── Deleted and Edited Posts ──────────────────────────────────────────────
  final Set<String> _deletedPostIds = {};
  final Map<String, PostModel> _editedPosts = {};
  final Map<String, Map<String, String>> _editedPostMetadata = {};

  bool isDeleted(String postId) => _deletedPostIds.contains(postId);

  void deletePost(String postId) {
    _deletedPostIds.add(postId);
    _myPosts.removeWhere((p) => p.id == postId);
    _savedPostIds.remove(postId);
    _savedPosts.removeWhere((p) => p.id == postId);
    ApiService.deletePost(postId);
  }

  void updatePost(PostModel updatedPost, {
    String? description,
    String? phone,
    String? email,
    String? city,
    String? category,
  }) {
    _editedPosts[updatedPost.id] = updatedPost;
    
    _editedPostMetadata[updatedPost.id] = {
      'description': description ?? '',
      'phone': phone ?? '',
      'email': email ?? '',
      'city': city ?? '',
      'category': category ?? '',
    };

    // Update in savedPosts list if it exists
    final savedIdx = _savedPosts.indexWhere((p) => p.id == updatedPost.id);
    if (savedIdx != -1) {
      _savedPosts[savedIdx] = updatedPost;
    }
  }

  PostModel getPost(PostModel originalPost) {
    return _editedPosts[originalPost.id] ?? originalPost;
  }

  void setPostMetadata(String postId, {
    String? description,
    String? phone,
    String? email,
    String? city,
    String? category,
  }) {
    final existing = _editedPostMetadata[postId] ?? {};
    _editedPostMetadata[postId] = {
      'description': (description != null && description.isNotEmpty) ? description : (existing['description'] ?? ''),
      'phone': (phone != null && phone.isNotEmpty) ? phone : (existing['phone'] ?? ''),
      'email': (email != null && email.isNotEmpty) ? email : (existing['email'] ?? ''),
      'city': (city != null && city.isNotEmpty) ? city : (existing['city'] ?? ''),
      'category': (category != null && category.isNotEmpty) ? category : (existing['category'] ?? ''),
    };
  }

  Map<String, String>? getPostMetadata(String postId) {
    return _editedPostMetadata[postId];
  }

  Map<String, String>? getPosterDetails(String postId) {
    if (_demoPosterNames.containsKey(postId) || _demoPosterEmails.containsKey(postId) || _demoPosterPhones.containsKey(postId)) {
      return {
        'name': _demoPosterNames[postId] ?? '',
        'email': _demoPosterEmails[postId] ?? '',
        'phone': _demoPosterPhones[postId] ?? '',
      };
    }
    return null;
  }

  // ── Admin: Post Status Management ─────────────────────────────────────────
  final Map<String, PostStatus> _postStatuses = {};

  // ── Demo poster profiles (name / email / phone keyed by post id) ──────────
  final Map<String, String> _demoPosterNames  = {};
  final Map<String, String> _demoPosterEmails = {};
  final Map<String, String> _demoPosterPhones = {};

  void setPosterDetails({
    required String postId,
    required String name,
    required String email,
    required String phone,
  }) {
    if (name.trim().isNotEmpty) _demoPosterNames[postId] = name.trim();
    if (email.trim().isNotEmpty) _demoPosterEmails[postId] = email.trim();
    if (phone.trim().isNotEmpty) _demoPosterPhones[postId] = phone.trim();
  }

  /// Returns the display name for the poster of [postId].
  String getPosterName(String postId) {
    if (_demoPosterNames.containsKey(postId)) return _demoPosterNames[postId]!;
    // Dummy posts
    switch (postId) {
      case '1': return 'Alex Morgan';
      case '2': return 'Starbucks Staff';
      case '3': return "Max's Family";
      case '4': return 'JFK Security Office';
      case '5': return 'Student Center Desk';
      case '6': return 'Jessica Brown';
      default:  return getUserNameByEmail(currentUserProfile.email);
    }
  }

  String getUserNameByEmail(String email) {
    if (email.trim().isEmpty) return 'User';
    final targetEmail = email.trim().toLowerCase();

    if (currentUserProfile.email.trim().toLowerCase() == targetEmail && currentUserProfile.name.trim().isNotEmpty) {
      return currentUserProfile.name;
    }
    for (final u in _registeredUsers) {
      if (u.email.trim().toLowerCase() == targetEmail && u.name.trim().isNotEmpty && u.name != 'User') {
        return u.name;
      }
    }
    for (final entry in _demoPosterEmails.entries) {
      if (entry.value.trim().toLowerCase() == targetEmail) {
        final name = _demoPosterNames[entry.key];
        if (name != null && name.trim().isNotEmpty && name != 'User') {
          return name;
        }
      }
    }
    final uname = targetEmail.split('@').first;
    if (uname.isNotEmpty) {
      return uname[0].toUpperCase() + uname.substring(1);
    }
    return 'User';
  }

  /// Returns the poster email for [postId].
  String getPosterEmail(String postId) {
    if (_demoPosterEmails.containsKey(postId)) return _demoPosterEmails[postId]!;
    return 'poster@foundit.com';
  }

  /// Returns the poster phone for [postId].
  String getPosterPhone(String postId) {
    if (_demoPosterPhones.containsKey(postId)) return _demoPosterPhones[postId]!;
    return '+1 (555) 019-2834';
  }

  PostStatus getPostStatus(String postId) {
    return getPostStatusForUserPost(postId);
  }

  PostStatus getPostStatusForUserPost(String postId, {PostStatus? fallbackStatus}) {
    if (_postStatuses.containsKey(postId)) {
      return _postStatuses[postId]!;
    }
    for (final p in _myPosts) {
      if (p.id == postId) {
        return p.status;
      }
    }
    return fallbackStatus ?? PostStatus.pending;
  }

  void approvePost(String postId) {
    _postStatuses[postId] = PostStatus.approved;

    // Update in _myPosts if present
    final idx = _myPosts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      _myPosts[idx] = _myPosts[idx].copyWith(status: PostStatus.approved);
    }
    // Update in _editedPosts if present
    if (_editedPosts.containsKey(postId)) {
      _editedPosts[postId] = _editedPosts[postId]!.copyWith(status: PostStatus.approved);
    }

    // Fire a user notification
    final post = _allPosts().firstWhere(
      (p) => p.id == postId,
      orElse: () => PostModel(id: postId, itemName: 'Post', isLost: true, date: '', location: ''),
    );
    addNotification(
      '✅ Post Approved',
      'Your post "${post.itemName}" has been approved and is now visible to everyone.',
      NotificationType.system,
    );
  }

  void rejectPost(String postId) {
    _postStatuses[postId] = PostStatus.rejected;

    // Update in _myPosts if present
    final idx = _myPosts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      _myPosts[idx] = _myPosts[idx].copyWith(status: PostStatus.rejected);
    }
    // Update in _editedPosts if present
    if (_editedPosts.containsKey(postId)) {
      _editedPosts[postId] = _editedPosts[postId]!.copyWith(status: PostStatus.rejected);
    }

    // Fire a user notification
    final post = _allPosts().firstWhere(
      (p) => p.id == postId,
      orElse: () => PostModel(id: postId, itemName: 'Post', isLost: true, date: '', location: ''),
    );
    addNotification(
      '❌ Post Rejected',
      'Your post "${post.itemName}" was not approved. Please review our community guidelines.',
      NotificationType.system,
    );
  }

  /// Combined list of all dummy + user posts (not deleted).
  List<PostModel> _allPosts() {
    // Import-free: we just look at _myPosts here; caller injects dummy data
    return [..._myPosts];
  }

  // ── In-App Chats ──────────────────────────────────────────────────────────
  final List<ChatSession> _chats = [];
  List<ChatSession> get chats => _chats;

  void addMessageToChat(PostModel post, String text, {String senderId = 'me', Uint8List? imageBytes}) {
    final idx = _chats.indexWhere((c) => c.postId == post.id);
    final now = DateTime.now();
    final hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minuteStr = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    final timeStr = "$hour12:$minuteStr $period";
    final newMessage = ChatMessage(
      senderId: senderId,
      senderEmail: senderId == 'me' ? userEmail : null,
      senderName: senderId == 'me' ? userName : getPosterName(post.id),
      text: text,
      time: timeStr,
      imageBytes: imageBytes,
    );
    
    if (idx != -1) {
      _chats[idx].messages.add(newMessage);
      // Move this chat session to the top of the list (most recent first)
      final session = _chats.removeAt(idx);
      _chats.insert(0, session);
    } else {
      _chats.insert(0, ChatSession(
        postId: post.id,
        post: post,
        messages: [newMessage],
      ));
    }
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  void setNotificationsFromBackend(List<dynamic> backendList) {
    _notifications.clear();
    for (final item in backendList) {
      if (item is Map) {
        final String notifId = (item['_id'] ?? item['id'] ?? '').toString();
        final String title = (item['title'] ?? '').toString();
        final String body = (item['body'] ?? '').toString();
        final String rawType = (item['type'] ?? 'system').toString();
        final bool isUnread = item['isUnread'] ?? true;
        final String createdAtStr = (item['createdAt'] ?? item['created_at'] ?? '').toString();

        DateTime? dt;
        if (createdAtStr.isNotEmpty) {
          dt = DateTime.tryParse(createdAtStr);
        }

        NotificationType type = NotificationType.system;
        if (rawType == 'message') type = NotificationType.message;
        if (rawType == 'post') type = NotificationType.post;
        if (rawType == 'warning') type = NotificationType.warning;

        _notifications.add(AppNotification(
          id: notifId,
          title: title,
          body: body,
          time: 'Just now',
          createdAt: dt,
          isUnread: isUnread,
          type: type,
        ));
      }
    }
  }

  void markNotificationsAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].isUnread) {
        _notifications[i] = _notifications[i].copyWith(isUnread: false);
      }
    }
    // Async call to backend so read status is persisted in MongoDB
    ApiService.markNotificationsAsRead();
  }

  void deleteNotification(int index) {
    if (index >= 0 && index < _notifications.length) {
      final item = _notifications.removeAt(index);
      if (item.id != null && item.id!.isNotEmpty) {
        ApiService.deleteNotifications([item.id!]);
      }
    }
  }

  void deleteMultipleNotifications(List<int> indexes) {
    final idsToDelete = <String>[];
    // Sort descending so removal doesn't shift remaining indexes
    indexes.sort((a, b) => b.compareTo(a));
    for (final idx in indexes) {
      if (idx >= 0 && idx < _notifications.length) {
        final item = _notifications.removeAt(idx);
        if (item.id != null && item.id!.isNotEmpty) {
          idsToDelete.add(item.id!);
        }
      }
    }
    if (idsToDelete.isNotEmpty) {
      ApiService.deleteNotifications(idsToDelete);
    }
  }

  void addNotification(String title, String body, NotificationType type) {
    if (!notificationsEnabled) return;
    _notifications.insert(0, AppNotification(
      title: title,
      body: body,
      time: 'Just now',
      createdAt: DateTime.now(),
      isUnread: true,
      type: type,
    ));
    SystemSound.play(SystemSoundType.alert);
  }

  // Pre-populate demo chats and notifications
  void initializeDemoChats() {
    if (_chats.isNotEmpty) return;

    // ── Seed demo PENDING posts ──────────────────────────────────────────────
    // These simulate posts submitted by users that are awaiting admin review.
    const pendingPosts = [
      PostModel(
        id: 'p1',
        itemName: 'Blue Nike Backpack',
        isLost: true,
        date: 'Jun 24, 2026',
        location: 'Times Square Station',
        status: PostStatus.pending,
      ),
      PostModel(
        id: 'p2',
        itemName: 'Silver Apple Watch',
        isLost: false,
        date: 'Jun 23, 2026',
        location: 'Grand Central Terminal',
        status: PostStatus.pending,
      ),
      PostModel(
        id: 'p3',
        itemName: 'University ID Card',
        isLost: true,
        date: 'Jun 22, 2026',
        location: 'Columbia University Library',
        status: PostStatus.pending,
      ),
      PostModel(
        id: 'p4',
        itemName: 'Black Leather Gloves',
        isLost: false,
        date: 'Jun 21, 2026',
        location: 'Madison Square Garden',
        status: PostStatus.pending,
      ),
    ];

    for (final post in pendingPosts) {
      _myPosts.add(post);
      _postStatuses[post.id] = PostStatus.pending;
    }

    // ── Demo poster profiles for pending posts ───────────────────────────────
    _demoPosterNames['p1'] = 'Sarah Mitchell';
    _demoPosterNames['p2'] = 'Carlos Rivera';
    _demoPosterNames['p3'] = 'Priya Sharma';
    _demoPosterNames['p4'] = 'James O\'Brien';
    _demoPosterEmails['p1'] = 'sarah.m@university.edu';
    _demoPosterEmails['p2'] = 'carlos.r@email.com';
    _demoPosterEmails['p3'] = 'priya.sharma@university.edu';
    _demoPosterEmails['p4'] = 'james.ob@email.com';
    _demoPosterPhones['p1'] = '+1 (917) 555-0182';
    _demoPosterPhones['p2'] = '+1 (646) 555-0341';
    _demoPosterPhones['p3'] = '+1 (212) 555-0789';
    _demoPosterPhones['p4'] = '+1 (718) 555-0456';
    


    // Demo notifications
    _notifications.addAll([
      const AppNotification(
        title: 'New Message',
        body: 'Syed Z sent a message about Brown Leather Wallet: "That matches! I left..."',
        time: '5m ago',
        isUnread: true,
        type: NotificationType.message,
      ),
      const AppNotification(
        title: 'New Lost Post near you',
        body: 'A new post "MacBook Pro 16"" was created in NYU Library.',
        time: '2h ago',
        isUnread: true,
        type: NotificationType.post,
      ),
      const AppNotification(
        title: 'Welcome to Foundit!',
        body: 'Start tracking or reporting lost and found items. Set up your profile to make contact easy.',
        time: '1d ago',
        isUnread: false,
        type: NotificationType.system,
      ),
    ]);
  }
}

// ── Supporting Data Models for Messaging & Notifications ───────────────────

class ChatMessage {
  final String senderId; // 'me' or 'other'
  final String? senderEmail;
  final String? senderName;
  final String text;
  final String time;
  final Uint8List? imageBytes;

  const ChatMessage({
    required this.senderId,
    this.senderEmail,
    this.senderName,
    required this.text,
    required this.time,
    this.imageBytes,
  });
}

class ChatSession {
  final String postId;
  final PostModel post;
  final List<ChatMessage> messages;
  final String? otherPartyName;

  ChatSession({
    required this.postId,
    required this.post,
    required this.messages,
    this.otherPartyName,
  });
}

enum NotificationType { message, post, system, warning }

class AppNotification {
  final String? id;
  final String title;
  final String body;
  final String time;
  final DateTime? createdAt;
  final bool isUnread;
  final NotificationType type;

  const AppNotification({
    this.id,
    required this.title,
    required this.body,
    required this.time,
    this.createdAt,
    required this.isUnread,
    required this.type,
  });

  String get formattedTime {
    if (createdAt == null) return time;
    final now = DateTime.now();
    final diff = now.difference(createdAt!);

    if (diff.inSeconds < 45) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }

    final local = createdAt!.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minuteStr = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';

    if (diff.inHours < 24 && local.day == now.day) {
      return "$hour12:$minuteStr $period";
    }

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthName = months[local.month - 1];
    return "$monthName ${local.day}, $hour12:$minuteStr $period";
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? time,
    DateTime? createdAt,
    bool? isUnread,
    NotificationType? type,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      time: time ?? this.time,
      createdAt: createdAt ?? this.createdAt,
      isUnread: isUnread ?? this.isUnread,
      type: type ?? this.type,
    );
  }
}

class AdminNotification {
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color color;

  AdminNotification({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.color,
  });
}

class UserWarning {
  final String userEmail;
  final String postId;
  final String postName;
  final String subject;
  final String explanation;
  final DateTime date;

  UserWarning({
    required this.userEmail,
    required this.postId,
    required this.postName,
    required this.subject,
    required this.explanation,
    required this.date,
  });
}
