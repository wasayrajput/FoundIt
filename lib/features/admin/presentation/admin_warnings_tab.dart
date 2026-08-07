import 'package:flutter/material.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/core/state/app_state.dart';
import 'package:foundit/features/home/domain/post_model.dart';
import 'package:foundit/features/profile/domain/user_profile_model.dart';
import 'package:foundit/features/admin/presentation/admin_user_profile_detail_screen.dart';
import 'package:foundit/features/admin/presentation/admin_post_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminWarningsTab extends StatefulWidget {
  const AdminWarningsTab({super.key});

  @override
  State<AdminWarningsTab> createState() => _AdminWarningsTabState();
}

class _AdminWarningsTabState extends State<AdminWarningsTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  DateTimeRange? _selectedDateRange;

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  bool _isWithinRange(DateTime date, DateTime start, DateTime end) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return (d.isAtSameMomentAs(s) || d.isAfter(s)) && (d.isAtSameMomentAs(e) || d.isBefore(e));
  }

  List<UserWarning> _getFilteredWarnings() {
    final warnings = AppState.instance.issuedWarnings;
    final query = _searchCtrl.text.trim().toLowerCase();

    return warnings.where((w) {
      final name = AppState.instance.getUserNameByEmail(w.userEmail);
      final matchesName = name.toLowerCase().contains(query) ||
                          w.userEmail.toLowerCase().contains(query) ||
                          w.postName.toLowerCase().contains(query) ||
                          w.subject.toLowerCase().contains(query);
      if (!matchesName) return false;

      if (_selectedDateRange != null) {
        return _isWithinRange(w.date, _selectedDateRange!.start, _selectedDateRange!.end);
      }
      return true;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryTextColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final filtered = _getFilteredWarnings();

    return Column(
      children: [
        // Name Search & Date Filter Bar
        Container(
          color: isDark ? Theme.of(context).cardColor : Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                style: GoogleFonts.inter(color: primaryTextColor),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search warned user by name...',
                  hintStyle: GoogleFonts.inter(color: secondaryTextColor.withValues(alpha: 0.5)),
                  prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white30 : AppColors.inputIcon),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FBFF),
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
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
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
                          color: secondaryTextColor,
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
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),

        // Warnings list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 48, color: secondaryTextColor.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text(
                        'No warning records found',
                        style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 15),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final w = filtered[index];
                    final resolvedName = AppState.instance.getUserNameByEmail(w.userEmail);
                    final userProfile = AppState.instance.registeredUsers.firstWhere(
                      (u) => u.email.toLowerCase() == w.userEmail.toLowerCase(),
                      orElse: () => UserProfileModel(name: resolvedName, email: w.userEmail, phone: ''),
                    );
                    final displayName = (userProfile.name.isNotEmpty && userProfile.name != 'User')
                        ? userProfile.name
                        : resolvedName;
                    final effectiveProfile = userProfile.copyWith(name: displayName);

                    return Card(
                      color: isDark ? Theme.of(context).cardColor : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: const Color(0xFFF59E0B).withValues(alpha: 0.15)),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            effectiveProfile.initials,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              effectiveProfile.name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: primaryTextColor,
                              ),
                            ),
                            Text(
                              _formatDate(w.date),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Subject: ${w.subject}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Post: "${w.postName}"',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              w.explanation,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? Colors.white30 : AppColors.inputIcon,
                        ),
                        onTap: () {
                          if (w.postId.isNotEmpty) {
                            final targetPost = AppState.instance.allPosts.firstWhere(
                              (p) => p.id == w.postId,
                              orElse: () => PostModel(
                                id: w.postId,
                                itemName: w.postName,
                                isLost: true,
                                date: _formatDate(w.date),
                                location: '',
                              ),
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminPostDetailScreen(post: targetPost),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminUserProfileDetailScreen(
                                  user: effectiveProfile,
                                  onUserUpdated: () => setState(() {}),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
