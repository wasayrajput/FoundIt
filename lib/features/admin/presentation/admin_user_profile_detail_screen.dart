import 'package:flutter/material.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/core/services/api_service.dart';
import 'package:foundit/core/state/app_state.dart';
import 'package:foundit/features/profile/domain/user_profile_model.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUserProfileDetailScreen extends StatefulWidget {
  final UserProfileModel user;
  final VoidCallback onUserUpdated;

  const AdminUserProfileDetailScreen({
    super.key,
    required this.user,
    required this.onUserUpdated,
  });

  @override
  State<AdminUserProfileDetailScreen> createState() => _AdminUserProfileDetailScreenState();
}

class _AdminUserProfileDetailScreenState extends State<AdminUserProfileDetailScreen> {
  late UserProfileModel _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildAvatar() {
    final hasPhoto = (_currentUser.photoPath ?? '').isNotEmpty;
    return Container(
      width: 90,
      height: 90,
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
                _currentUser.photoPath!,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Text(
                  _currentUser.initials,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 28,
                  ),
                ),
              ),
            )
          : Text(
              _currentUser.initials,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 28,
              ),
            ),
    );
  }

  Future<void> _deleteAccount() async {
    final messenger = ScaffoldMessenger.of(context);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final isDarkDialog = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Delete User Account?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: isDarkDialog ? Colors.white : AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to delete ${_currentUser.name}\'s account? This action will set their status as deleted/left.',
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
                'Delete Account',
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
      final userParam = _currentUser.email.isNotEmpty ? _currentUser.email : _currentUser.name;
      final res = await ApiService.deleteAdminUser(userParam);

      AppState.instance.deleteUserAccount(_currentUser.email);
      widget.onUserUpdated();

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(res['success'] == true
              ? '${_currentUser.name}\'s account and all associated data have been permanently deleted.'
              : res['message'] ?? 'Failed to delete user account'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: res['success'] == true ? const Color(0xFFEF4444) : Colors.redAccent,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color textCol, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryBlue),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textCol,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningHistoryCard(String email, bool isDark) {
    final warnings = AppState.instance.getWarningsForUser(email);
    final hasWarnings = warnings.isNotEmpty;
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryTextColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final cardBg = isDark ? Theme.of(context).cardColor : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasWarnings ? const Color(0xFFF59E0B).withValues(alpha: 0.2) : AppColors.primaryBlue.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: (hasWarnings ? const Color(0xFFF59E0B) : AppColors.primaryBlue).withValues(alpha: 0.04),
            blurRadius: 16,
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
                style: GoogleFonts.poppins(
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
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Subject: ${w.subject}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: primaryTextColor,
                              ),
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
                      const SizedBox(height: 4),
                      Text(
                        'Post: "${w.postName}"',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: secondaryTextColor,
                          fontWeight: FontWeight.w500,
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
                      const Divider(),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimary;
    final cardBg = isDark ? Theme.of(context).cardColor : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FBFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'User Profile Detail',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: primaryTextColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  _buildAvatar(),
                  const SizedBox(height: 16),
                  Text(
                    _currentUser.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _currentUser.isDeleted
                          ? const Color(0xFFFFF0F0)
                          : const Color(0xFFE8F8F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _currentUser.isDeleted ? 'Account Deleted / Left' : 'Active Account',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _currentUser.isDeleted
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Profile info screen card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Information',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  _buildInfoRow(Icons.email_rounded, 'Email Address', _currentUser.email, primaryTextColor, isDark),
                  const Divider(),
                  _buildInfoRow(Icons.phone_rounded, 'Mobile Phone', _currentUser.phone, primaryTextColor, isDark),
                  const Divider(),
                  _buildInfoRow(
                    Icons.app_registration_rounded,
                    'Registration Method',
                    _currentUser.registrationType == 'signup' ? 'Self Signed Up' : 'Admin Registered',
                    primaryTextColor,
                    isDark,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    Icons.calendar_month_rounded,
                    'Date Registered',
                    _formatDate(_currentUser.registrationDate),
                    primaryTextColor,
                    isDark,
                  ),
                  if (_currentUser.isDeleted && _currentUser.deletionDate != null) ...[
                    const Divider(),
                    _buildInfoRow(
                      Icons.cancel_rounded,
                      'Date Account Left / Deleted',
                      _formatDate(_currentUser.deletionDate),
                      const Color(0xFFEF4444),
                      isDark,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildWarningHistoryCard(_currentUser.email, isDark),

            const SizedBox(height: 40),

            // Delete Button if Active
            if (!_currentUser.isDeleted)
              ElevatedButton.icon(
                onPressed: _deleteAccount,
                icon: const Icon(Icons.delete_forever_rounded),
                label: Text(
                  'Delete User Account',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
