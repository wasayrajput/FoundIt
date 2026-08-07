import 'package:flutter/material.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/core/services/api_service.dart';
import 'package:foundit/core/state/app_state.dart';
import 'package:foundit/features/home/domain/post_model.dart';
import 'package:foundit/features/admin/presentation/widgets/admin_post_card.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminAllPostsTab extends StatefulWidget {
  final VoidCallback onPostStatusChanged;
  final String initialFilter;

  const AdminAllPostsTab({
    super.key,
    required this.onPostStatusChanged,
    this.initialFilter = 'All',
  });

  @override
  State<AdminAllPostsTab> createState() => _AdminAllPostsTabState();
}

class _AdminAllPostsTabState extends State<AdminAllPostsTab> {
  late String _filter;
  DateTimeRange? _selectedDateRange;
  bool _isSelectionMode = false;
  final Set<String> _selectedPostIds = {};
  List<PostModel> _allAdminPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _fetchLiveAdminPosts();
  }

  Future<void> _fetchLiveAdminPosts() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getAllAdminPosts();
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
        _allAdminPosts = fetched;
        _isLoading = false;
      });
    }
  }

  @override
  void didUpdateWidget(AdminAllPostsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      _filter = widget.initialFilter;
      _isSelectionMode = false;
      _selectedPostIds.clear();
    }
  }

  DateTime? _parsePostDate(String dateStr) {
    try {
      final clean = dateStr.trim();
      if (clean == 'Just now') return DateTime(2023, 10, 26); // simulated today
      final parts = clean.split(RegExp(r'[\s,]+'));
      if (parts.length >= 3) {
        final monthStr = parts[0];
        final dayStr = parts[1];
        final yearStr = parts[2];
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final month = months.indexOf(monthStr) + 1;
        final day = int.parse(dayStr);
        final year = int.parse(yearStr);
        if (month > 0) {
          return DateTime(year, month, day);
        }
      }
    } catch (_) {}
    return null;
  }

  bool _isWithinRange(DateTime date, DateTime start, DateTime end) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return (d.isAtSameMomentAs(s) || d.isAfter(s)) && (d.isAtSameMomentAs(e) || d.isBefore(e));
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  List<PostModel> _filteredPosts() {
    final all = _allAdminPosts;

    return all.where((p) {
      final status = AppState.instance.getPostStatusForUserPost(p.id, fallbackStatus: p.status);
      bool matchesFilter = false;
      if (_filter == 'All') {
        matchesFilter = true;
      } else if (_filter == 'Pending') {
        matchesFilter = (status == PostStatus.pending);
      } else if (_filter == 'Approved') {
        matchesFilter = (status == PostStatus.approved);
      } else if (_filter == 'Rejected') {
        matchesFilter = (status == PostStatus.rejected);
      }

      if (!matchesFilter) return false;

      if (_selectedDateRange != null) {
        final postDate = _parsePostDate(p.date);
        if (postDate == null) return false;
        return _isWithinRange(postDate, _selectedDateRange!.start, _selectedDateRange!.end);
      }
      return true;
    }).toList();
  }

  Future<void> _approve(PostModel post) async {
    await ApiService.updatePostStatus(postId: post.id, status: 'approved');
    AppState.instance.approvePost(post.id);
    _fetchLiveAdminPosts();
    widget.onPostStatusChanged();
  }

  Future<void> _reject(PostModel post) async {
    await ApiService.updatePostStatus(postId: post.id, status: 'rejected');
    AppState.instance.rejectPost(post.id);
    _fetchLiveAdminPosts();
    widget.onPostStatusChanged();
  }

  Future<void> _deleteSelectedPosts(List<PostModel> activeList) async {
    final messenger = ScaffoldMessenger.of(context);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final isDarkDialog = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Delete Selected Posts?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: isDarkDialog ? Colors.white : AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to permanently delete the ${_selectedPostIds.length} selected post(s)?',
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
                backgroundColor: const Color(0xFFEF4444),
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
      for (final id in _selectedPostIds) {
        AppState.instance.deletePost(id);
      }
      setState(() {
        _selectedPostIds.clear();
        _isSelectionMode = false;
      });
      widget.onPostStatusChanged();
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Selected posts deleted successfully.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  Widget _buildFilterChip(String label, Color activeColor) {
    final isActive = _filter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filter = label;
          _isSelectionMode = false;
          _selectedPostIds.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor : activeColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : activeColor.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : activeColor,
          ),
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

    final posts = _filteredPosts();
    final nonPendingPosts = posts.where((p) => AppState.instance.getPostStatusForUserPost(p.id) != PostStatus.pending).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Filter Header or Selection Header
        _isSelectionMode
            ? Container(
                color: isDark ? Theme.of(context).cardColor : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : AppColors.textPrimary),
                          onPressed: () {
                            setState(() {
                              _isSelectionMode = false;
                              _selectedPostIds.clear();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedPostIds.length} Selected',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (_selectedPostIds.length == nonPendingPosts.length) {
                                _selectedPostIds.clear();
                              } else {
                                _selectedPostIds.clear();
                                _selectedPostIds.addAll(nonPendingPosts.map((p) => p.id));
                              }
                            });
                          },
                          child: Text(
                            _selectedPostIds.length == nonPendingPosts.length ? 'Deselect All' : 'Select All',
                            style: GoogleFonts.inter(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444)),
                          onPressed: _selectedPostIds.isEmpty
                              ? null
                              : () => _deleteSelectedPosts(posts),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : Container(
                color: isDark ? Theme.of(context).cardColor : Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', AppColors.primaryBlue),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending', const Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      _buildFilterChip('Approved', const Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      _buildFilterChip('Rejected', const Color(0xFFEF4444)),
                    ],
                  ),
                ),
              ),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),

        // Date Filter Section (visible when not in selection mode)
        if (!_isSelectionMode)
          Container(
            color: isDark ? Theme.of(context).cardColor : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FBFF),
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
                          : 'Filter by Date (All Dates)',
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
                        });
                      },
                    ),
                ],
              ),
            ),
          ),

        if (!_isSelectionMode)
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

        // Posts list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchLiveAdminPosts,
            color: const Color(0xFF2563EB),
            child: posts.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_rounded, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text(
                              'No posts found',
                              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final status = AppState.instance.getPostStatusForUserPost(post.id, fallbackStatus: post.status);
                    return AdminPostCard(
                      post: post,
                      status: status,
                      onApprove: (status == PostStatus.pending || status == PostStatus.rejected) ? () => _approve(post) : null,
                      onReject: (status == PostStatus.pending || status == PostStatus.approved) ? () => _reject(post) : null,
                      isSelectionMode: _isSelectionMode,
                      isSelected: _selectedPostIds.contains(post.id),
                      onLongPress: (status != PostStatus.pending && (_filter == 'All' || _filter == 'Approved'))
                          ? () {
                              setState(() {
                                _isSelectionMode = true;
                                _selectedPostIds.add(post.id);
                              });
                            }
                          : null,
                      onTap: status == PostStatus.pending
                          ? null
                          : () {
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
                            },
                    );
                  },
                ),
          ),
        ),
      ],
    );
  }
}
