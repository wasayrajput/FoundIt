import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/core/services/api_service.dart';
import 'package:foundit/features/auth/presentation/sign_in_screen.dart';
import 'package:foundit/features/admin/presentation/admin_dashboard_tab.dart';
import 'package:foundit/features/admin/presentation/admin_pending_tab.dart';
import 'package:foundit/features/admin/presentation/admin_all_posts_tab.dart';
import 'package:foundit/features/admin/presentation/admin_notifications_tab.dart';
import 'package:foundit/features/admin/presentation/admin_warnings_tab.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  int _currentTab = 0;
  String _selectedAllPostsFilter = 'All';
  late AnimationController _navAnimCtrl;
  bool _isNavVisible = true;
  int _livePendingCount = 0;

  @override
  void initState() {
    super.initState();
    _navAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _fetchLivePendingCount();
  }

  Future<void> _fetchLivePendingCount() async {
    final res = await ApiService.getPendingPosts();
    if (res['success'] == true && res['count'] != null) {
      if (mounted) {
        setState(() {
          _livePendingCount = res['count'];
        });
      }
    }
  }

  @override
  void dispose() {
    _navAnimCtrl.dispose();
    super.dispose();
  }

  void _onPostStatusChanged() {
    _fetchLivePendingCount();
    setState(() {});
  }

  int _pendingCount() {
    return _livePendingCount;
  }

  Widget _buildBody() {
    switch (_currentTab) {
      case 0:
        return AdminDashboardTab(
          onPostStatusChanged: _onPostStatusChanged,
          onNavigateToTab: (tabIndex, filter) {
            setState(() {
              _currentTab = tabIndex;
              _selectedAllPostsFilter = filter;
            });
          },
        );
      case 1:
        return AdminPendingTab(onPostStatusChanged: _onPostStatusChanged);
      case 2:
        return AdminAllPostsTab(
          onPostStatusChanged: _onPostStatusChanged,
          initialFilter: _selectedAllPostsFilter,
        );
      case 3:
        return const AdminNotificationsTab();
      case 4:
        return const AdminWarningsTab();
      default:
        return const SizedBox();
    }
  }

  void _handleBack() {
    if (_currentTab != 0) {
      setState(() {
        _currentTab = 0;
        _isNavVisible = true;
        _navAnimCtrl.forward();
      });
    } else {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignInScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pendingCount();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FBFF),
          body: Column(
            children: [
              // ── Admin Header ──────────────────────────────────────────────
              _AdminHeader(
                currentTab: _currentTab,
                onBackPressed: _handleBack,
              ),

              // ── Body ──────────────────────────────────────────────────────
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification) {
                      final delta = notification.scrollDelta ?? 0;
                      if (delta > 6 && _isNavVisible) {
                        setState(() => _isNavVisible = false);
                        _navAnimCtrl.reverse();
                      } else if (delta < -6 && !_isNavVisible) {
                        setState(() => _isNavVisible = true);
                        _navAnimCtrl.forward();
                      }
                    }
                    return false;
                  },
                  child: _buildBody(),
                ),
              ),
            ],
          ),

          // ── Admin Bottom Nav ──────────────────────────────────────────────
          bottomNavigationBar: AnimatedBuilder(
            animation: _navAnimCtrl,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, (1 - _navAnimCtrl.value) * 80),
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _NavItem(
                          icon: Icons.dashboard_rounded,
                          label: 'Dashboard',
                          isActive: _currentTab == 0,
                          onTap: () => setState(() {
                            _currentTab = 0;
                            _isNavVisible = true;
                            _navAnimCtrl.forward();
                          }),
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          icon: Icons.pending_actions_rounded,
                          label: 'Pending',
                          isActive: _currentTab == 1,
                          badge: pending > 0 ? pending : null,
                          onTap: () => setState(() {
                            _currentTab = 1;
                            _isNavVisible = true;
                            _navAnimCtrl.forward();
                          }),
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          icon: Icons.list_alt_rounded,
                          label: 'All Posts',
                          isActive: _currentTab == 2,
                          onTap: () => setState(() {
                            _currentTab = 2;
                            _isNavVisible = true;
                            _navAnimCtrl.forward();
                          }),
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          icon: Icons.notifications_active_rounded,
                          label: 'Notifications',
                          isActive: _currentTab == 3,
                          onTap: () => setState(() {
                            _currentTab = 3;
                            _isNavVisible = true;
                            _navAnimCtrl.forward();
                          }),
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          icon: Icons.warning_amber_rounded,
                          label: 'Warnings',
                          isActive: _currentTab == 4,
                          onTap: () => setState(() {
                            _currentTab = 4;
                            _isNavVisible = true;
                            _navAnimCtrl.forward();
                          }),
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
    );
  }
}

// ── Admin Header ─────────────────────────────────────────────────────────────
class _AdminHeader extends StatelessWidget {
  final int currentTab;
  final VoidCallback onBackPressed;

  const _AdminHeader({
    required this.currentTab,
    required this.onBackPressed,
  });

  String get _title {
    switch (currentTab) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Pending Posts';
      case 2:
        return 'All Posts';
      case 3:
        return 'Audit Logs';
      case 4:
        return 'User Warnings';
      default:
        return 'Admin Panel';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              // Back button
              InkWell(
                onTap: onBackPressed,
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              // Icon + title
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Panel',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      _title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              // Admin badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Admin',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Nav Item ─────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final int? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryBlue.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isActive ? AppColors.primaryBlue : AppColors.textSecondary,
                  size: 24,
                ),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$badge',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primaryBlue : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
