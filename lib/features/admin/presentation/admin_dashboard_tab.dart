import 'package:flutter/material.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/core/services/api_service.dart';
import 'package:foundit/core/state/app_state.dart';
import 'package:foundit/features/home/domain/post_model.dart';
import 'package:foundit/features/profile/domain/user_profile_model.dart';
import 'package:foundit/features/admin/presentation/admin_user_profile_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardTab extends StatefulWidget {
  final VoidCallback onPostStatusChanged;
  final Function(int tabIndex, String filter)? onNavigateToTab;

  const AdminDashboardTab({
    super.key,
    required this.onPostStatusChanged,
    this.onNavigateToTab,
  });

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  int _selectedUserBox = 1;
  DateTimeRange? _selectedDateRange;
  int _currentPage = 0;
  final TextEditingController _userSearchCtrl = TextEditingController();
  List<UserProfileModel> _liveUsers = [];
  List<PostModel> _liveAdminPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLiveAdminUsers();
  }

  Future<void> _fetchLiveAdminUsers() async {
    final results = await Future.wait([
      ApiService.getAdminUsers(),
      ApiService.getAllAdminPosts(),
    ]);

    final usersRes = results[0];
    final postsRes = results[1];

    List<UserProfileModel> fetchedUsers = [];
    if (usersRes['success'] == true && usersRes['users'] != null) {
      final List raw = usersRes['users'];
      fetchedUsers = raw.where((u) {
        final String role = (u['role'] ?? 'user').toString().toLowerCase();
        final String email = (u['email'] ?? '').toString().toLowerCase();
        return role != 'admin' && email != 'admin@foundit.com' && email != 'support@foundit.com';
      }).map((u) {
        return UserProfileModel(
          name: u['name'] ?? 'User',
          email: u['email'] ?? '',
          phone: u['phone'] ?? '',
          photoPath: u['photoUrl'] ?? '',
          registrationDate: u['createdAt'] != null ? DateTime.tryParse(u['createdAt']) : DateTime.now(),
          isDeleted: u['isDeleted'] == true,
          registrationType: 'signup',
        );
      }).toList();
    }

    List<PostModel> fetchedPosts = [];
    if (postsRes['success'] == true && postsRes['posts'] != null) {
      final List raw = postsRes['posts'];
      fetchedPosts = raw.map((json) {
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
          if (name.isNotEmpty) {
            AppState.instance.setPosterDetails(
              postId: id,
              name: name,
              email: email,
              phone: phone,
            );
          }
        }

        final String stStr = json['status'] ?? 'pending';
        final PostStatus st = stStr == 'approved'
            ? PostStatus.approved
            : (stStr == 'rejected' ? PostStatus.rejected : PostStatus.pending);

        return PostModel(
          id: id,
          itemName: json['itemName'] ?? 'Item',
          isLost: json['isLost'] == true,
          date: json['date'] ?? '',
          location: json['locationName'] ?? json['city'] ?? '',
          imageUrl: imgUrl,
          status: st,
        );
      }).toList();
    }

    if (mounted) {
      setState(() {
        _liveUsers = fetchedUsers;
        _liveAdminPosts = fetchedPosts;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _userSearchCtrl.dispose();
    super.dispose();
  }

  List<PostModel> _allPosts() {
    final Map<String, PostModel> map = {};
    for (final p in _liveAdminPosts) {
      if (!AppState.instance.isDeleted(p.id)) {
        map[p.id] = p;
      }
    }
    for (final p in AppState.instance.myPosts) {
      if (!AppState.instance.isDeleted(p.id)) {
        map[p.id] = p;
      }
    }
    return map.values.toList();
  }

  bool _isWithinRange(DateTime date, DateTime start, DateTime end) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return (d.isAtSameMomentAs(s) || d.isAfter(s)) && (d.isAtSameMomentAs(e) || d.isBefore(e));
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  List<UserProfileModel> _getFilteredUsersForBox(int boxIndex) {
    final allUsers = _liveUsers;
    final simulatedToday = DateTime.now();
    List<UserProfileModel> list = [];

    switch (boxIndex) {
      case 1:
        if (_selectedDateRange != null) {
          list = allUsers
              .where((u) => u.registrationDate != null && _isWithinRange(u.registrationDate!, _selectedDateRange!.start, _selectedDateRange!.end))
              .toList();
        } else {
          list = allUsers;
        }
        break;
      case 2:
        if (_selectedDateRange != null) {
          list = allUsers
              .where((u) => u.isDeleted && u.deletionDate != null && _isWithinRange(u.deletionDate!, _selectedDateRange!.start, _selectedDateRange!.end))
              .toList();
        } else {
          list = allUsers.where((u) => u.isDeleted).toList();
        }
        break;
      case 3:
        if (_selectedDateRange != null) {
          list = allUsers
              .where((u) => u.registrationDate != null && _isWithinRange(u.registrationDate!, _selectedDateRange!.start, _selectedDateRange!.end))
              .toList();
        } else {
          list = allUsers
              .where((u) => u.registrationDate != null && _isSameDay(u.registrationDate!, simulatedToday))
              .toList();
          if (list.isEmpty) {
            list = allUsers
                .where((u) => u.registrationDate != null && simulatedToday.difference(u.registrationDate!).inDays <= 30)
                .toList();
          }
        }
        break;
      case 4:
        if (_selectedDateRange != null) {
          list = allUsers
              .where((u) => u.isDeleted && (u.deletionDate != null ? _isWithinRange(u.deletionDate!, _selectedDateRange!.start, _selectedDateRange!.end) : true))
              .toList();
        } else {
          list = allUsers
              .where((u) => u.isDeleted && (u.deletionDate == null || _isSameDay(u.deletionDate!, simulatedToday)))
              .toList();
        }
        break;
      default:
        list = [];
    }

    final query = _userSearchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((u) => u.name.toLowerCase().contains(query)).toList();
    }
    return list;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getBoxTitle(int index) {
    switch (index) {
      case 1:
        return 'All Registered Users';
      case 2:
        return 'Deleted Accounts';
      case 3:
        return 'New Signup Users';
      case 4:
        return 'Today\'s Deleted Accounts';
      default:
        return 'Users';
    }
  }

  Widget _buildUserAvatar(UserProfileModel user) {
    final hasPhoto = (user.photoPath ?? '').isNotEmpty;
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: hasPhoto
          ? ClipOval(
              child: Image.network(
                user.photoPath!,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Text(
                  user.initials,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          : Text(
              user.initials,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 14,
              ),
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

    final allPostsList = _allPosts();
    final pendingPostsCount = allPostsList.where((p) => AppState.instance.getPostStatusForUserPost(p.id, fallbackStatus: p.status) == PostStatus.pending).length;
    final approvedPostsCount = allPostsList.where((p) => AppState.instance.getPostStatusForUserPost(p.id, fallbackStatus: p.status) == PostStatus.approved).length;
    final rejectedPostsCount = allPostsList.where((p) => AppState.instance.getPostStatusForUserPost(p.id, fallbackStatus: p.status) == PostStatus.rejected).length;
    final totalPostsCount = allPostsList.length;

    // Filtered lists for boxes
    final allUsersCount = _getFilteredUsersForBox(1).length;
    final deletedCount = _getFilteredUsersForBox(2).length;

    // Current selected user list
    final filteredUsers = _getFilteredUsersForBox(_selectedUserBox);

    // Pagination calculations
    int totalPages = (filteredUsers.length / 5).ceil();
    if (totalPages == 0) totalPages = 1;
    if (_currentPage >= totalPages) {
      _currentPage = totalPages - 1;
    }
    if (_currentPage < 0) {
      _currentPage = 0;
    }

    final paginatedUsers = filteredUsers.skip(_currentPage * 5).take(5).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _fetchLiveAdminUsers,
      color: AppColors.primaryBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, Admin!',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Manage all posts and users from here.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Posts Record Section ──────────────────────────────────────────
          Text(
            'Posts Record',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          // Stats grid (Posts)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              GestureDetector(
                onTap: () {
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(2, 'All');
                  }
                },
                child: _StatCard(
                  label: 'Total Posts',
                  count: totalPostsCount,
                  icon: Icons.article_rounded,
                  color: AppColors.primaryBlue,
                  bgColor: const Color(0xFFE3F2FD),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(2, 'Pending');
                  }
                },
                child: _StatCard(
                  label: 'Pending',
                  count: pendingPostsCount,
                  icon: Icons.hourglass_top_rounded,
                  color: const Color(0xFFF59E0B),
                  bgColor: const Color(0xFFFFF8E1),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(2, 'Approved');
                  }
                },
                child: _StatCard(
                  label: 'Approved',
                  count: approvedPostsCount,
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF10B981),
                  bgColor: const Color(0xFFE8F8F0),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(2, 'Rejected');
                  }
                },
                child: _StatCard(
                  label: 'Rejected',
                  count: rejectedPostsCount,
                  icon: Icons.cancel_rounded,
                  color: const Color(0xFFEF4444),
                  bgColor: const Color(0xFFFFF0F0),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Users Record Section ──────────────────────────────────────────
          Text(
            'Users Record',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          // Stats grid (Users)
          // Stats grid (Users - 2 Boxes)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedUserBox = 1;
                      _currentPage = 0;
                    });
                  },
                  child: _UserStatCard(
                    label: 'All-time Registered',
                    count: allUsersCount,
                    icon: Icons.people_alt_rounded,
                    color: AppColors.primaryBlue,
                    bgColor: const Color(0xFFE3F2FD),
                    isSelected: _selectedUserBox == 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedUserBox = 2;
                      _currentPage = 0;
                    });
                  },
                  child: _UserStatCard(
                    label: 'All-time Deleted Accounts',
                    count: deletedCount,
                    icon: Icons.person_remove_rounded,
                    color: const Color(0xFFEF4444),
                    bgColor: const Color(0xFFFFF0F0),
                    isSelected: _selectedUserBox == 2,
                  ),
                ),
              ),
            ],
          ),

          // Date Filter Section (above lists)
          if (true) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).cardColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primaryBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedDateRange != null
                          ? '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}'
                          : 'Default: Oct 26, 2023 (Today)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        initialDateRange: _selectedDateRange ?? DateTimeRange(
                          start: DateTime(2023, 10, 20),
                          end: DateTime(2023, 10, 26),
                        ),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: AppColors.primaryBlue,
                                surface: isDark ? const Color(0xFF1E293B) : Colors.white,
                                onSurface: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (range != null) {
                        setState(() {
                          _selectedDateRange = range;
                          _currentPage = 0;
                        });
                      }
                    },
                    icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                    label: Text(
                      'Filter',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  if (_selectedDateRange != null)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFFEF4444)),
                      onPressed: () {
                        setState(() {
                          _selectedDateRange = null;
                          _currentPage = 0;
                        });
                      },
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          TextField(
            controller: _userSearchCtrl,
            style: GoogleFonts.inter(color: isDark ? Colors.white : AppColors.textPrimary),
            onChanged: (val) {
              setState(() {
                _currentPage = 0;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search user by name...',
              hintStyle: GoogleFonts.inter(color: (isDark ? Colors.white70 : AppColors.textSecondary).withValues(alpha: 0.5)),
              prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white30 : AppColors.inputIcon),
              filled: true,
              fillColor: isDark ? Theme.of(context).cardColor : const Color(0xFFF8FBFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primaryBlue),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getBoxTitle(_selectedUserBox),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                '${filteredUsers.length} Users',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (paginatedUsers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36),
              alignment: Alignment.center,
              child: Text(
                'No user records found under this selection.',
                style: GoogleFonts.inter(
                  color: (isDark ? Colors.white30 : AppColors.textSecondary).withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            )
          else
            ...paginatedUsers.map((user) {
              return Card(
                color: isDark ? Theme.of(context).cardColor : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.05)),
                ),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: _buildUserAvatar(user),
                  title: Text(
                    user.name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? Colors.white30 : AppColors.inputIcon,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminUserProfileDetailScreen(
                          user: user,
                          onUserUpdated: () {
                            setState(() {});
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            }),

          // Pagination controls (standard style from profile screen)
          if (totalPages > 1) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Previous Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _currentPage > 0
                        ? () {
                            setState(() {
                              _currentPage--;
                            });
                          }
                        : null,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _currentPage > 0
                            ? AppColors.primaryBlue.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _currentPage > 0
                              ? AppColors.primaryBlue.withValues(alpha: 0.15)
                              : AppColors.inputBorder.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: _currentPage > 0
                            ? AppColors.primaryBlue
                            : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary).withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Text(
                  'Page ${_currentPage + 1} of $totalPages',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 24),
                // Next Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _currentPage < totalPages - 1
                        ? () {
                            setState(() {
                              _currentPage++;
                            });
                          }
                        : null,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _currentPage < totalPages - 1
                            ? AppColors.primaryBlue.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _currentPage < totalPages - 1
                              ? AppColors.primaryBlue.withValues(alpha: 0.15)
                              : AppColors.inputBorder.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: _currentPage < totalPages - 1
                            ? AppColors.primaryBlue
                            : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary).withValues(alpha: 0.3),
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
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserStatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool isSelected;

  const _UserStatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isSelected ? 0.15 : 0.05),
            blurRadius: isSelected ? 20 : 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
