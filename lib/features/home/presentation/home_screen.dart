import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/core/services/api_service.dart';
import 'package:foundit/core/state/app_state.dart';
import 'package:foundit/features/home/domain/post_model.dart';
import 'package:foundit/features/home/presentation/widgets/post_card.dart';
import 'package:foundit/features/post/presentation/create_post_screen.dart';
import 'package:foundit/features/profile/presentation/profile_screen.dart';
import 'package:foundit/features/home/presentation/drawer_screens.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  late final ScrollController _scrollController;
  bool _isBottomNavVisible = true;

  // Filtering state
  List<PostModel> _displayedPosts = [];
  DateTime? _filterFromDate;
  DateTime? _filterToDate;
  String _filterCity = '';
  String _filterCategory = '';
  late final TextEditingController _searchController;
  String _searchText = '';

  bool _isGlobalRefreshing = false;

  Future<void> _refreshPosts() async {
    await _applyFilter(_filterFromDate, _filterToDate, city: _filterCity, category: _filterCategory);
  }

  Future<void> _triggerGlobalRefresh() async {
    if (_isGlobalRefreshing) return;
    setState(() => _isGlobalRefreshing = true);

    try {
      // 1. Fetch live user profile
      final userRes = await ApiService.getMe();
      if (userRes['success'] == true && userRes['user'] != null) {
        final u = userRes['user'];
        AppState.instance.setCurrentUserProfile(
          name: u['name'] ?? '',
          email: u['email'] ?? '',
          phone: u['phone'] ?? '',
          photoUrl: u['photoUrl'] ?? '',
        );
      }

      // 2. Refresh posts & user posts in parallel
      await Future.wait([
        _refreshPosts(),
        ApiService.getMyPosts(),
      ]);

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    AppState.instance.translate('App & Feeds Refreshed Successfully!'),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1B9B5A),
              duration: const Duration(seconds: 2),
            ),
          );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isGlobalRefreshing = false);
    }
  }

  Timer? _chatPollTimer;

  Future<void> _fetchUserChats({bool silent = false}) async {
    final res = await ApiService.getUserChats();
    if (res['success'] == true && res['chats'] != null) {
      final List rawChats = res['chats'];
      final List<ChatSession> syncedSessions = [];

      for (final chatObj in rawChats) {
        if (chatObj is! Map) continue;

        final postObj = chatObj['postId'];
        if (postObj == null) continue;

        String pid = '';
        String itemName = 'Item';
        bool isLost = true;
        String location = '';
        String? imageUrl;

        if (postObj is Map) {
          pid = postObj['_id']?.toString() ?? postObj['id']?.toString() ?? '';
          itemName = postObj['itemName'] ?? 'Item';
          isLost = postObj['isLost'] == true;
          location = postObj['locationName'] ?? '';
          if (postObj['images'] is List && (postObj['images'] as List).isNotEmpty) {
            imageUrl = ApiService.formatImageUrl((postObj['images'] as List).first.toString());
          }
        } else {
          pid = postObj.toString();
        }

        if (pid.isEmpty) continue;

        final post = PostModel(
          id: pid,
          itemName: itemName,
          isLost: isLost,
          date: '',
          location: location,
          imageUrl: imageUrl,
        );

        String otherName = '';
        final List userIds = [
          ...(chatObj['userIds'] is List ? chatObj['userIds'] : []),
          ...(chatObj['participants'] is List ? chatObj['participants'] : []),
        ];
        for (final u in userIds) {
          if (u is Map) {
            final email = (u['email'] ?? '').toString();
            final name = (u['name'] ?? '').toString();
            final phone = (u['phone'] ?? '').toString();

            final isMe = (name.isNotEmpty && name.toLowerCase() == AppState.instance.userName.toLowerCase()) ||
                         (email.isNotEmpty && email.toLowerCase() == AppState.instance.userEmail.toLowerCase());

            if (!isMe && name.isNotEmpty) {
              otherName = name;
              AppState.instance.setPosterDetails(
                postId: pid,
                name: name,
                email: email,
                phone: phone,
              );
              break;
            }
          }
        }

        final List msgs = chatObj['messages'] ?? [];
        final List<ChatMessage> parsedMsgs = msgs.map((m) {
          final String text = m['text'] ?? '';
          final String rawTime = (m['timestamp'] ?? m['createdAt'] ?? m['created_at'] ?? '').toString();

          String senderEmail = '';
          String senderId = '';
          String senderName = '';
          if (m['senderId'] is Map) {
            senderEmail = (m['senderId']['email'] ?? '').toString();
            senderId = (m['senderId']['_id'] ?? m['senderId']['id'] ?? '').toString();
            senderName = (m['senderId']['name'] ?? '').toString();
          } else {
            senderId = (m['senderId'] ?? '').toString();
          }

          DateTime? dt;
          if (rawTime.isNotEmpty) {
            dt = DateTime.tryParse(rawTime);
          }
          if (dt != null) {
            dt = dt.toLocal();
          } else {
            dt = DateTime.now();
          }

          final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
          final minuteStr = dt.minute.toString().padLeft(2, '0');
          final period = dt.hour >= 12 ? 'PM' : 'AM';
          final timeStr = "$hour12:$minuteStr $period";

          final isMe = (senderId == 'me' ||
              (senderEmail.isNotEmpty && senderEmail.toLowerCase() == AppState.instance.userEmail.toLowerCase()) ||
              (senderName.isNotEmpty && senderName.toLowerCase() == AppState.instance.userName.toLowerCase()) ||
              (senderId.isNotEmpty && AppState.instance.userId.isNotEmpty && senderId == AppState.instance.userId) ||
              (senderId.isNotEmpty && ApiService.userToken != null && senderId == ApiService.userToken));

          return ChatMessage(
            senderId: isMe ? 'me' : 'other',
            text: text,
            time: timeStr,
          );
        }).toList();

        syncedSessions.add(ChatSession(
          postId: pid,
          post: post,
          messages: parsedMsgs,
          otherPartyName: otherName.isNotEmpty ? otherName : null,
        ));
      }

      if (syncedSessions.isNotEmpty) {
        for (final session in syncedSessions) {
          final idx = AppState.instance.chats.indexWhere((c) => c.postId == session.postId);
          if (idx != -1) {
            final oldLen = AppState.instance.chats[idx].messages.length;
            AppState.instance.chats[idx] = session;
            if (session.messages.length > oldLen &&
                session.messages.isNotEmpty &&
                session.messages.last.senderId == 'other') {
              final senderName = AppState.instance.getPosterName(session.postId);
              AppState.instance.addNotification(
                'New Message',
                '$senderName: ${session.messages.last.text}',
                NotificationType.message,
              );
            }
          } else {
            AppState.instance.chats.add(session);
            if (session.messages.isNotEmpty && session.messages.last.senderId == 'other') {
              final senderName = AppState.instance.getPosterName(session.postId);
              AppState.instance.addNotification(
                'New Message',
                '$senderName: ${session.messages.last.text}',
                NotificationType.message,
              );
            }
          }
        }
      }

      if (mounted && !silent) {
        setState(() {});
      }
    }
  }

  Future<void> _fetchUserNotifications() async {
    try {
      final res = await ApiService.getNotifications();
      if (res['success'] == true && res['notifications'] != null) {
        AppState.instance.setNotificationsFromBackend(res['notifications']);
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _fetchLiveSavedPosts() async {
    try {
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
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController = TextEditingController();
    _refreshPosts();
    _fetchUserNotifications();
    _fetchLiveSavedPosts();
    _fetchUserChats(silent: true);

    // Poll live backend chats every 3 seconds
    _chatPollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchUserChats(silent: true);
    });
  }

  @override
  void dispose() {
    _chatPollTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Parses dummy data format e.g. "Oct 24, 2023"
  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.replaceAll(',', '').split(' ');
      final monthStr = parts[0];
      final day = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = months.indexOf(monthStr) + 1;
      return DateTime(year, month, day);
    } catch (e) {
      return DateTime.now();
    }
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

  String _getPostCategoryDefault(PostModel post) {
    final name = post.itemName.toLowerCase();
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

  Future<void> _applyFilter(DateTime? from, DateTime? to, {String city = '', String category = ''}) async {
    _filterFromDate = from;
    _filterToDate = to;
    _filterCity = city.trim();
    _filterCategory = category;

    // Fetch live posts from Node.js & MongoDB backend (both Lost and Found)
    final apiRes = await ApiService.searchPosts(
      query: _searchText,
      category: category,
      city: city,
    );

    List<PostModel> fetchedPosts = [];
    if (apiRes['success'] == true && apiRes['posts'] != null) {
      final List rawPosts = apiRes['posts'];
      fetchedPosts = rawPosts.map((json) {
        final String pid = json['_id'] ?? json['id'] ?? 'p_${DateTime.now().millisecondsSinceEpoch}';
        final List images = json['images'] ?? [];
        String? imgUrl;
        if (images.isNotEmpty) {
          final String firstImg = images.first.toString();
          imgUrl = ApiService.formatImageUrl(firstImg);
        }

        final userObj = json['userId'] ?? json['user'];
        String posterEmail = '';
        String posterPhone = '';
        if (userObj is Map) {
          final String name = userObj['name'] ?? '';
          posterEmail = userObj['email'] ?? '';
          posterPhone = userObj['phone'] ?? '';
          if (name.isNotEmpty) {
            AppState.instance.setPosterDetails(
              postId: pid,
              name: name,
              email: posterEmail,
              phone: posterPhone,
            );
          }
        }

        final String desc = json['description'] ?? '';
        final String cty = json['city'] ?? '';
        final String cat = json['category'] ?? '';
        AppState.instance.setPostMetadata(
          pid,
          description: desc,
          city: cty,
          category: cat,
          email: posterEmail,
          phone: posterPhone,
        );

        return PostModel(
          id: pid,
          itemName: json['itemName'] ?? 'Item',
          isLost: json['isLost'] == true,
          date: json['date'] ?? '',
          location: json['locationName'] ?? json['city'] ?? '',
          imageUrl: imgUrl,
          status: PostStatus.approved,
        );
      }).toList();
    }

    final Map<String, PostModel> uniquePostsMap = {};
    for (final post in [...fetchedPosts, ...AppState.instance.myPosts]) {
      final status = AppState.instance.getPostStatusForUserPost(post.id, fallbackStatus: post.status);
      if (!AppState.instance.isDeleted(post.id) && status == PostStatus.approved) {
        uniquePostsMap[post.id] = post;
      }
    }
    final activePosts = uniquePostsMap.values.toList();

    if (!mounted) return;

    if (from == null && to == null && city.trim().isEmpty && category.isEmpty && _searchText.trim().isEmpty) {
      setState(() {
        _displayedPosts = activePosts;
      });
      return;
    }

    final filtered = activePosts.where((post) {
      bool isValid = true;

      // --- Search Text filter (matches name, location, or description) ---
      if (_searchText.trim().isNotEmpty) {
        final query = _searchText.trim().toLowerCase();
        final metadata = AppState.instance.getPostMetadata(post.id);
        final desc = metadata != null ? metadata['description'] ?? '' : '';

        final matchesName = post.itemName.toLowerCase().contains(query);
        final matchesLocation = post.location.toLowerCase().contains(query);
        final matchesDesc = desc.toLowerCase().contains(query);

        if (!matchesName && !matchesLocation && !matchesDesc) {
          isValid = false;
        }
      }

      // --- Date filter ---
      if (isValid) {
        final postDate = _parseDate(post.date);
        final postDateOnly = DateTime(postDate.year, postDate.month, postDate.day);

        if (from != null) {
          final fromDateOnly = DateTime(from.year, from.month, from.day);
          if (postDateOnly.isBefore(fromDateOnly)) isValid = false;
        }
        if (to != null) {
          final toDateOnly = DateTime(to.year, to.month, to.day);
          if (postDateOnly.isAfter(toDateOnly)) isValid = false;
        }
      }

      // --- City filter ---
      if (isValid && city.trim().isNotEmpty) {
        final metadata = AppState.instance.getPostMetadata(post.id);
        final postCity = metadata != null && metadata['city'] != null && metadata['city']!.isNotEmpty
            ? metadata['city']!
            : _getPostCityDefault(post);

        isValid = postCity.toLowerCase().contains(city.trim().toLowerCase()) ||
            post.location.toLowerCase().contains(city.trim().toLowerCase());
      }

      // --- Category filter ---
      if (isValid && category.isNotEmpty) {
        final metadata = AppState.instance.getPostMetadata(post.id);
        final postCategory = metadata != null && metadata['category'] != null && metadata['category']!.isNotEmpty
            ? metadata['category']!
            : _getPostCategoryDefault(post);

        isValid = postCategory.toLowerCase() == category.toLowerCase();
      }

      return isValid;
    }).toList();

    setState(() {
      _displayedPosts = filtered;
    });
  }

  String _getPostCityDefault(PostModel post) {
    final loc = post.location.toLowerCase();
    if (loc.contains('ny') || loc.contains('york') || loc.contains('jfk') || loc.contains('brooklyn') || loc.contains('times square')) {
      return "New York";
    }
    return "Campus City";
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required VoidCallback onClear,
  }) {
    return GestureDetector(
      onTap: onClear,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.close_rounded, color: AppColors.primaryBlue, size: 14),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    DateTime? tempFromDate = _filterFromDate;
    DateTime? tempToDate = _filterToDate;
    final TextEditingController cityController =
        TextEditingController(text: _filterCity);
    String? tempCategory = _filterCategory.isEmpty ? null : _filterCategory;

    final List<String> categories = [
      'Mobiles',
      'Men wallets',
      'Women purse',
      'Suitcase or bag',
      'Electronics',
      'ID card',
      'Documents',
      'Cash',
      'Gold',
      'Gold and non-gold jewelry',
      'Others',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final String fromText = tempFromDate != null 
                ? "${tempFromDate!.day}/${tempFromDate!.month}/${tempFromDate!.year}" 
                : "Select Date";
            final String toText = tempToDate != null 
                ? "${tempToDate!.day}/${tempToDate!.month}/${tempToDate!.year}" 
                : "Select Date";

            final isDark = Theme.of(context).brightness == Brightness.dark;
            final primaryTextColor = isDark ? Colors.white : AppColors.textPrimary;
            final secondaryTextColor = isDark ? Colors.white70 : AppColors.textSecondary;
            final scafBg = Theme.of(context).scaffoldBackgroundColor;
            final cardBg = Theme.of(context).cardColor;
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Items',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close_rounded, color: secondaryTextColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // From Date Input
                    Text(
                      'From Date',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        // Open near Oct 2023 where our dummy data lives
                        final date = await showDatePicker(
                          context: context,
                          initialDate: tempFromDate ?? DateTime(2023, 10, 15),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.primaryBlue,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setModalState(() => tempFromDate = date);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: tempFromDate != null
                                ? AppColors.primaryBlue
                                : AppColors.primaryBlue.withValues(alpha: 0.1),
                            width: tempFromDate != null ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              fromText,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: tempFromDate != null ? FontWeight.w600 : FontWeight.w400,
                                color: tempFromDate != null ? AppColors.primaryBlue : secondaryTextColor.withValues(alpha: 0.5),
                              ),
                            ),
                            const Icon(Icons.calendar_month_rounded, color: AppColors.primaryBlue),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // To Date Input
                    Text(
                      'To Date',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        // Also default to Oct 2023 range so it's consistent with dummy data
                        final date = await showDatePicker(
                          context: context,
                          initialDate: tempToDate ?? DateTime(2023, 10, 25),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.primaryBlue,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setModalState(() => tempToDate = date);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: tempToDate != null
                                ? AppColors.primaryBlue
                                : AppColors.primaryBlue.withValues(alpha: 0.1),
                            width: tempToDate != null ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              toText,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: tempToDate != null ? FontWeight.w600 : FontWeight.w400,
                                color: tempToDate != null ? AppColors.primaryBlue : secondaryTextColor.withValues(alpha: 0.5),
                              ),
                            ),
                            const Icon(Icons.calendar_month_rounded, color: AppColors.primaryBlue),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // City Filter
                    Text(
                      'City',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: cityController,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: primaryTextColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. New York, Karachi...',
                        hintStyle: GoogleFonts.inter(
                          color: secondaryTextColor.withValues(alpha: 0.4),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: scafBg,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                              color: AppColors.primaryBlue
                                  .withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: AppColors.primaryBlue, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category Filter
                    Text(
                      'Category',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: tempCategory,
                      items: categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Row(
                            children: [
                              Icon(_getCategoryIconByName(cat), color: AppColors.primaryBlue, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                cat,
                                style: GoogleFonts.inter(fontSize: 15, color: primaryTextColor),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setModalState(() {
                          tempCategory = val;
                        });
                      },
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primaryBlue, size: 28),
                      decoration: InputDecoration(
                        hintText: 'Choose Category',
                        hintStyle: GoogleFonts.inter(color: secondaryTextColor.withValues(alpha: 0.5)),
                        filled: true,
                        fillColor: scafBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.primaryBlue,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempFromDate = null;
                                tempToDate = null;
                                cityController.clear();
                                tempCategory = null;
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              foregroundColor: secondaryTextColor,
                            ),
                            child: Text(
                              'Clear',
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              _applyFilter(
                                tempFromDate,
                                tempToDate,
                                city: cityController.text,
                                category: tempCategory ?? '',
                              );
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                              shadowColor: AppColors.primaryBlue.withValues(alpha: 0.3),
                            ),
                            child: Text(
                              'Apply Filter',
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showNotificationsBottomSheet() async {
    await _fetchUserNotifications();
    // Persist read status in MongoDB backend
    ApiService.markNotificationsAsRead();

    if (!mounted) return;

    bool isSelectionMode = false;
    final Set<int> selectedIndexes = {};

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final notifications = AppState.instance.notifications;

            final isDark = Theme.of(context).brightness == Brightness.dark;
            final primaryTextColor = isDark ? Colors.white : AppColors.textPrimary;
            final secondaryTextColor = isDark ? Colors.white70 : AppColors.textSecondary;
            final scafBg = Theme.of(context).scaffoldBackgroundColor;
            final cardBg = Theme.of(context).cardColor;
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sheet Header
                  isSelectionMode
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.close_rounded, color: primaryTextColor),
                                  onPressed: () {
                                    setSheetState(() {
                                      isSelectionMode = false;
                                      selectedIndexes.clear();
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${selectedIndexes.length} Selected',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: primaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setSheetState(() {
                                      if (selectedIndexes.length == notifications.length) {
                                        selectedIndexes.clear();
                                      } else {
                                        selectedIndexes.clear();
                                        selectedIndexes.addAll(Iterable<int>.generate(notifications.length));
                                      }
                                    });
                                  },
                                  child: Text(
                                    selectedIndexes.length == notifications.length ? 'Deselect All' : 'Select All',
                                    style: GoogleFonts.inter(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_rounded, color: Color(0xFFE54D2E)),
                                  onPressed: selectedIndexes.isEmpty
                                      ? null
                                      : () async {
                                          final messenger = ScaffoldMessenger.of(context);
                                          final bool? confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (BuildContext dialogContext) {
                                              final isDarkDialog = Theme.of(dialogContext).brightness == Brightness.dark;
                                              final primaryColor = isDarkDialog ? Colors.white : AppColors.textPrimary;
                                              return AlertDialog(
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                                title: Text(
                                                  'Delete Notifications?',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w700,
                                                    color: primaryColor,
                                                  ),
                                                ),
                                                content: Text(
                                                  'Are you sure you want to delete the ${selectedIndexes.length} selected notification(s)?',
                                                  style: GoogleFonts.inter(
                                                    color: isDarkDialog ? Colors.white70 : AppColors.textSecondary,
                                                    height: 1.5,
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.of(dialogContext).pop(false),
                                                    child: Text(
                                                      'Cancel',
                                                      style: GoogleFonts.inter(
                                                        fontWeight: FontWeight.w600,
                                                        color: isDarkDialog ? Colors.white70 : AppColors.textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.of(dialogContext).pop(true),
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

                                          if (confirm == true) {
                                            AppState.instance.deleteMultipleNotifications(selectedIndexes.toList());
                                            setSheetState(() {
                                              isSelectionMode = false;
                                              selectedIndexes.clear();
                                            });
                                            setState(() {});
                                            messenger.hideCurrentSnackBar();
                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text('Selected notifications deleted.'),
                                                behavior: SnackBarBehavior.floating,
                                                backgroundColor: Color(0xFFE54D2E),
                                              ),
                                            );
                                          }
                                        },
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Notifications',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: primaryTextColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.close_rounded, color: secondaryTextColor),
                            ),
                          ],
                        ),
                  const SizedBox(height: 20),
                  
                  // Notification List
                  Expanded(
                    child: notifications.isEmpty
                        ? Center(
                            child: Text(
                              'No notifications yet.',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: secondaryTextColor.withValues(alpha: 0.5),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              if (index >= notifications.length) return const SizedBox.shrink();
                              final item = notifications[index];
                              IconData icon;
                              Color iconColor;
                              Color bgColor;

                              switch (item.type) {
                                case NotificationType.message:
                                  icon = Icons.chat_bubble_rounded;
                                  iconColor = AppColors.primaryBlue;
                                  bgColor = AppColors.primaryBlue.withValues(alpha: 0.08);
                                  break;
                                case NotificationType.post:
                                  icon = Icons.post_add_rounded;
                                  iconColor = const Color(0xFF1B9B5A);
                                  bgColor = const Color(0xFF1B9B5A).withValues(alpha: 0.08);
                                  break;
                                case NotificationType.system:
                                  icon = Icons.info_rounded;
                                  iconColor = Colors.orangeAccent;
                                  bgColor = Colors.orangeAccent.withValues(alpha: 0.08);
                                  break;
                                case NotificationType.warning:
                                  icon = Icons.warning_rounded;
                                  iconColor = const Color(0xFFEF4444);
                                  bgColor = const Color(0xFFEF4444).withValues(alpha: 0.08);
                                  break;
                              }

                              return GestureDetector(
                                onTap: () {
                                  if (isSelectionMode) {
                                    setSheetState(() {
                                      if (selectedIndexes.contains(index)) {
                                        selectedIndexes.remove(index);
                                        if (selectedIndexes.isEmpty) {
                                          isSelectionMode = false;
                                        }
                                      } else {
                                        selectedIndexes.add(index);
                                      }
                                    });
                                  } else {
                                    if (item.isUnread) {
                                      setSheetState(() {
                                        AppState.instance.notifications[index] = item.copyWith(isUnread: false);
                                      });
                                      setState(() {});
                                    }
                                  }
                                },
                                onLongPress: () async {
                                  if (isSelectionMode) return;
                                  setSheetState(() {
                                    isSelectionMode = true;
                                    selectedIndexes.add(index);
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark ? scafBg : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: item.isUnread
                                          ? AppColors.primaryBlue.withValues(alpha: 0.3)
                                          : AppColors.primaryBlue.withValues(alpha: 0.05),
                                      width: item.isUnread ? 1.5 : 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (isSelectionMode) ...[
                                        Checkbox(
                                          value: selectedIndexes.contains(index),
                                          activeColor: AppColors.primaryBlue,
                                          shape: const CircleBorder(),
                                          onChanged: (bool? val) {
                                            setSheetState(() {
                                              if (selectedIndexes.contains(index)) {
                                                selectedIndexes.remove(index);
                                                if (selectedIndexes.isEmpty) {
                                                  isSelectionMode = false;
                                                }
                                              } else {
                                                selectedIndexes.add(index);
                                              }
                                            });
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: bgColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(icon, color: iconColor, size: 20),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      if (item.isUnread) ...[
                                                        Container(
                                                          width: 8,
                                                          height: 8,
                                                          margin: const EdgeInsets.only(right: 6),
                                                          decoration: const BoxDecoration(
                                                            color: Color(0xFFEF4444),
                                                            shape: BoxShape.circle,
                                                          ),
                                                        ),
                                                      ],
                                                      Expanded(
                                                        child: Text(
                                                          item.title,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: GoogleFonts.inter(
                                                            fontWeight: item.isUnread ? FontWeight.w800 : FontWeight.w700,
                                                            fontSize: 14,
                                                            color: primaryTextColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  item.formattedTime,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    color: secondaryTextColor.withValues(alpha: 0.6),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              item.body,
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                height: 1.4,
                                                color: secondaryTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          }
        );
      },
    ).then((_) {
      AppState.instance.markNotificationsAsRead();
      if (mounted) setState(() {});
    });
  }

  Widget _buildHomeHeader() {
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
        child: Column(
          children: [
            // App Bar Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (scaffoldContext) => _AnimatedMenuIcon(
                      hasUnread: AppState.instance.notifications.any((n) => n.isUnread),
                      onTap: () => Scaffold.of(scaffoldContext).openDrawer(),
                    ),
                  ),
                  Text(
                    'Foundit',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).cardColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _GlobalRefreshIcon(
                        isRefreshing: _isGlobalRefreshing,
                        onTap: _triggerGlobalRefresh,
                      ),
                      const SizedBox(width: 8),
                      _AnimatedFilterIcon(
                        isActive: _filterFromDate != null ||
                            _filterToDate != null ||
                            _filterCity.isNotEmpty ||
                            _filterCategory.isNotEmpty,
                        onTap: _showFilterBottomSheet,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchText = val;
                    });
                    _refreshPosts();
                  },
                  style: GoogleFonts.inter(fontSize: 15, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary))),
                  decoration: InputDecoration(
                    hintText: AppState.instance.translate('Search items by name, location...'),
                    hintStyle: GoogleFonts.inter(
                      color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary))).withValues(alpha: 0.4),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryBlue),
                    suffixIcon: _searchText.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary))),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchText = '';
                              });
                              _refreshPosts();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }



  Widget _buildTabBody() {
    switch (_currentTab) {
      case 0:
        return Column(
          children: [
            // --- Premium Header Area ---
            _buildHomeHeader(),

            // --- Main Content Area ---
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 28),
                  Text(
                    AppState.instance.translate('Latest Posts'),
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary)),
                      letterSpacing: -0.5,
                    ),
                  ),
                  // Active filter chips
                  if (_filterFromDate != null || _filterToDate != null || _filterCity.isNotEmpty || _filterCategory.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          if (_filterFromDate != null || _filterToDate != null)
                            _buildFilterChip(
                              icon: Icons.calendar_month_rounded,
                              label:
                                  '${_filterFromDate != null ? "${_filterFromDate!.day}/${_filterFromDate!.month}/${_filterFromDate!.year}" : "Any"}'
                                  '  →  '
                                  '${_filterToDate != null ? "${_filterToDate!.day}/${_filterToDate!.month}/${_filterToDate!.year}" : "Any"}',
                              onClear: () => _applyFilter(
                                null,
                                null,
                                city: _filterCity,
                                category: _filterCategory,
                              ),
                            ),
                          if (_filterCity.isNotEmpty)
                            _buildFilterChip(
                              icon: Icons.location_on_rounded,
                              label: _filterCity,
                              onClear: () => _applyFilter(
                                _filterFromDate,
                                _filterToDate,
                                city: '',
                                category: _filterCategory,
                              ),
                            ),
                          if (_filterCategory.isNotEmpty)
                            _buildFilterChip(
                              icon: _getCategoryIconByName(_filterCategory),
                              label: _filterCategory,
                              onClear: () => _applyFilter(
                                _filterFromDate,
                                _filterToDate,
                                city: _filterCity,
                                category: '',
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        _refreshPosts();
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      color: AppColors.primaryBlue,
                      child: _displayedPosts.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.4,
                                  child: Center(
                                    child: Text(
                                      AppState.instance.translate('No posts found in this date range.'),
                                      style: GoogleFonts.inter(
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : GridView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 100.0),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.72,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _displayedPosts.length,
                              itemBuilder: (context, index) {
                                return PostCard(
                                  post: _displayedPosts[index],
                                  onRefresh: _refreshPosts,
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        );
      case 1:
        return const ProfileScreen(showBottomNav: false);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required VoidCallback onTap,
    double iconSize = 26,
  }) {
    final isActive = _currentTab == index;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: iconSize,
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 4 : 0,
                height: isActive ? 4 : 0,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final name = AppState.instance.userName;
    final email = AppState.instance.userEmail;
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
    final cleanInitials = initials.isNotEmpty ? initials : 'U';

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Header Section with Gradient
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 28,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryBlueMid, AppColors.primaryBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: Container(
                      width: 66,
                      height: 66,
                      color: AppColors.primaryBluePale,
                      child: AppState.instance.currentUserProfile.photoPath != null && AppState.instance.currentUserProfile.photoPath!.isNotEmpty
                          ? ((AppState.instance.currentUserProfile.photoPath!.startsWith('http') || kIsWeb)
                              ? Image.network(
                                  AppState.instance.currentUserProfile.photoPath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Center(
                                    child: Text(
                                      cleanInitials,
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                  ),
                                )
                              : Image.file(
                                  io.File(AppState.instance.currentUserProfile.photoPath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Center(
                                    child: Text(
                                      cleanInitials,
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ))
                          : Center(
                              child: Text(
                                cleanInitials,
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).cardColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Drawer Menu List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              children: [
                _buildDrawerItem(
                  icon: Icons.notifications_rounded,
                  label: AppState.instance.translate('Notifications'),
                  onTap: () {
                    Navigator.pop(context); // Close Drawer
                    _showNotificationsBottomSheet();
                  },
                  showBadge: AppState.instance.notifications.any((n) => n.isUnread),
                ),
                _buildDrawerDivider(),
                _buildDrawerItem(
                  icon: Icons.description_rounded,
                  label: AppState.instance.translate('Terms & Conditions'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen()),
                    );
                  },
                ),
                _buildDrawerDivider(),
                _buildDrawerItem(
                  icon: Icons.privacy_tip_rounded,
                  label: AppState.instance.translate('Privacy Policy'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                    );
                  },
                ),
                _buildDrawerDivider(),
                _buildDrawerItem(
                  icon: Icons.feedback_rounded,
                  label: AppState.instance.translate('Feedback'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FeedbackScreen()),
                    );
                  },
                ),
                _buildDrawerDivider(),
                _buildDrawerItem(
                  icon: Icons.contact_support_rounded,
                  label: AppState.instance.translate('Contact Us'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ContactUsScreen()),
                    );
                  },
                ),
                _buildDrawerDivider(),
                _buildDrawerItem(
                  icon: Icons.settings_rounded,
                  label: AppState.instance.translate('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryBlue, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary)),
                    ),
                  ),
                ),
                if (showBadge)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(0xFFE54D2E),
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary),
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Divider(
        height: 8,
        thickness: 0.8,
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : AppColors.inputBorder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true, // Allow content to scroll behind floating nav bar
      drawer: Drawer(
        child: _buildDrawer(context),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification is ScrollUpdateNotification) {
            final scrollDelta = notification.scrollDelta ?? 0;
            if (scrollDelta > 2.0 && _isBottomNavVisible) {
              setState(() {
                _isBottomNavVisible = false;
              });
            } else if (scrollDelta < -2.0 && !_isBottomNavVisible) {
              setState(() {
                _isBottomNavVisible = true;
              });
            }
          }
          return false;
        },
        child: _buildTabBody(),
      ),
      
      // --- Floating Bottom Navigation Bar (Animated) ---
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        offset: _isBottomNavVisible ? Offset.zero : const Offset(0, 2),
        child: SafeArea(
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
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home_rounded,
                    onTap: () => setState(() => _currentTab = 0),
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.add_circle_rounded,
                    iconSize: 32,
                    onTap: () async {
                      final created = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreatePostScreen(),
                        ),
                      );
                      if (created == true && mounted) {
                        _refreshPosts();
                      }
                    },
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.person_rounded,
                    onTap: () => setState(() => _currentTab = 1),
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
// Dedicated widget so press state lives in its own lifecycle — no lint issues
// ---------------------------------------------------------------------------
class _AnimatedFilterIcon extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _AnimatedFilterIcon({required this.isActive, required this.onTap});

  @override
  State<_AnimatedFilterIcon> createState() => _AnimatedFilterIconState();
}

class _AnimatedFilterIconState extends State<_AnimatedFilterIcon> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),
      child: AnimatedScale(
        scale: isPressed ? 0.80 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: isPressed ? 0.55 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? Colors.white.withValues(alpha: 0.28)
                  : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.tune_rounded, color: Theme.of(context).cardColor, size: 24),
                if (widget.isActive)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE54D2E),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryBlue,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedNotificationIcon extends StatefulWidget {
  final bool hasUnread;
  final VoidCallback onTap;

  const _AnimatedNotificationIcon({required this.hasUnread, required this.onTap});

  @override
  State<_AnimatedNotificationIcon> createState() => _AnimatedNotificationIconState();
}

class _AnimatedNotificationIconState extends State<_AnimatedNotificationIcon> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),
      child: AnimatedScale(
        scale: isPressed ? 0.80 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: isPressed ? 0.55 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.hasUnread
                  ? Colors.white.withValues(alpha: 0.28)
                  : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                 Icon(Icons.notifications_rounded, color: Theme.of(context).cardColor, size: 24),
                if (widget.hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE54D2E),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryBlueMid,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedMenuIcon extends StatefulWidget {
  final bool hasUnread;
  final VoidCallback onTap;
  const _AnimatedMenuIcon({
    required this.hasUnread,
    required this.onTap,
  });

  @override
  State<_AnimatedMenuIcon> createState() => _AnimatedMenuIconState();
}

class _AnimatedMenuIconState extends State<_AnimatedMenuIcon> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),
      child: AnimatedScale(
        scale: isPressed ? 0.80 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: isPressed ? 0.55 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                if (widget.hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE54D2E),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryBlueMid,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated Global Refresh Button for Header
// ---------------------------------------------------------------------------
class _GlobalRefreshIcon extends StatefulWidget {
  final bool isRefreshing;
  final VoidCallback onTap;

  const _GlobalRefreshIcon({
    required this.isRefreshing,
    required this.onTap,
  });

  @override
  State<_GlobalRefreshIcon> createState() => _GlobalRefreshIconState();
}

class _GlobalRefreshIconState extends State<_GlobalRefreshIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isRefreshing) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _GlobalRefreshIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRefreshing && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isRefreshing && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isRefreshing ? null : widget.onTap,
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),
      child: AnimatedScale(
        scale: isPressed ? 0.80 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: isPressed ? 0.55 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: RotationTransition(
              turns: _controller,
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
