import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/core/state/app_state.dart';
import 'package:foundit/core/services/api_service.dart';
import 'package:foundit/features/auth/presentation/sign_in_screen.dart';

// ---------------------------------------------------------------------------
// 1. TERMS AND CONDITIONS SCREEN
// ---------------------------------------------------------------------------
class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryTextColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final scafBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scafBg,
      appBar: AppBar(
        backgroundColor: scafBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Terms & Conditions',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: primaryTextColor,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Updated: June 2026',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildClauseHeader('1. Acceptance of Terms', primaryTextColor),
            _buildClauseBody(
              'By accessing and using the Foundit platform, you agree to comply with and be bound by these Terms and Conditions. If you do not agree to these terms, please do not use the application.',
              secondaryTextColor,
            ),
            _buildClauseHeader('2. Description of Service', primaryTextColor),
            _buildClauseBody(
              'Foundit provides a digital venue for users to report lost or found items on campus or in general areas. Foundit is only a facilitator and is not responsible for the physical recovery of items or for verifying the identity of posters.',
              secondaryTextColor,
            ),
            _buildClauseHeader('3. User Responsibilities', primaryTextColor),
            _buildClauseBody(
              'You agree to provide true, accurate, and complete information when reporting items. You are prohibited from posting false information, claiming items that do not belong to you, or posting inappropriate or offensive content.',
              secondaryTextColor,
            ),
            _buildClauseHeader('4. Verification and Claiming', primaryTextColor),
            _buildClauseBody(
              'Claimants must prove ownership of any lost item before recovery (such as describing key details not listed online, lock screens, serial numbers, etc.). Foundit is not liable for items returned to incorrect claimants.',
              secondaryTextColor,
            ),
            _buildClauseHeader('5. Limitation of Liability', primaryTextColor),
            _buildClauseBody(
              'In no event shall Foundit, its creators, or administrators be liable for any direct, indirect, incidental, or consequential damages resulting from the loss, theft, damage, or recovery of any item posted on this application.',
              secondaryTextColor,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildClauseHeader(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildClauseBody(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: color,
        height: 1.6,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. PRIVACY POLICY SCREEN
// ---------------------------------------------------------------------------
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryTextColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final scafBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scafBg,
      appBar: AppBar(
        backgroundColor: scafBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: primaryTextColor,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Updated: June 2026',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionHeader('1. Information We Collect', primaryTextColor),
            _buildSectionBody(
              'We collect information you provide directly to us when creating a profile or posting an item. This includes your name, email address, phone number, item descriptions, and photos you upload.',
              secondaryTextColor,
            ),
            _buildSectionHeader('2. How We Use Information', primaryTextColor),
            _buildSectionBody(
              'We use your information to operate the Foundit service, allow communication between finders and owners, and display contact details on posts to facilitate item recovery.',
              secondaryTextColor,
            ),
            _buildSectionHeader('3. Sharing of Information', primaryTextColor),
            _buildSectionBody(
              'Your profile details (name, email, phone) will be displayed to other users who view your item reports, as necessary to contact you about lost/found items. We do not sell or lease your personal information to third parties.',
              secondaryTextColor,
            ),
            _buildSectionHeader('4. Data Security', primaryTextColor),
            _buildSectionBody(
              'We implement reasonable administrative, technical, and physical safeguards to protect your personal information against loss, theft, unauthorized access, or modification.',
              secondaryTextColor,
            ),
            _buildSectionHeader('5. Account Termination', primaryTextColor),
            _buildSectionBody(
              'You can request the deletion of your account and all associated posts at any time. Deleted data will be removed from our systems in accordance with our technical processes.',
              secondaryTextColor,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSectionBody(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: color,
        height: 1.6,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. FEEDBACK SCREEN
// ---------------------------------------------------------------------------
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank you! Feedback submitted with a $_rating-star rating.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1B9B5A),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryTextColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final scafBg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: scafBg,
      appBar: AppBar(
        backgroundColor: scafBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Feedback',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: primaryTextColor,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rate Your Experience',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 12),
              // Stars Rating Row
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(5, (index) {
                  final starVal = index + 1;
                  final isSelected = starVal <= _rating;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = starVal),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: AnimatedScale(
                        scale: isSelected ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: isSelected ? const Color(0xFFF59E0B) : AppColors.inputIcon,
                          size: 40,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),
              Text(
                'Write comments or suggestions',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _commentController,
                maxLines: 5,
                style: GoogleFonts.inter(fontSize: 14, color: primaryTextColor),
                decoration: InputDecoration(
                  hintText: 'Share your thoughts on how we can improve Foundit...',
                  hintStyle: GoogleFonts.inter(
                    color: secondaryTextColor.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: cardBg,
                  contentPadding: const EdgeInsets.all(16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter comments to submit feedback.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryBlueMid, AppColors.primaryBlue],
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
                      onTap: _submitFeedback,
                      child: Center(
                        child: Text(
                          'Submit Feedback',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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
    );
  }
}

// ---------------------------------------------------------------------------
// 4. CONTACT US SCREEN
// ---------------------------------------------------------------------------
class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _msgController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _msgController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent! Our support team will contact you shortly.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF1B9B5A),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryTextColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final scafBg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: scafBg,
      appBar: AppBar(
        backgroundColor: scafBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Contact Us',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: primaryTextColor,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotline details
            Text(
              'Support Hotline & Info',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildContactInfoRow(Icons.mail_rounded, 'support@foundit.com', primaryTextColor),
                  const Divider(height: 24, color: AppColors.inputBorder),
                  _buildContactInfoRow(Icons.call_rounded, '+1 (800) 555-0199', primaryTextColor),
                  const Divider(height: 24, color: AppColors.inputBorder),
                  _buildContactInfoRow(Icons.location_on_rounded, 'Main Admin Block, Campus Central', primaryTextColor),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Send us a Message',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 14),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildContactField(
                    controller: _nameController,
                    label: 'Name',
                    hint: 'Your Full Name',
                    icon: Icons.person_rounded,
                    cardBg: cardBg,
                    textColor: primaryTextColor,
                    hintColor: secondaryTextColor,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildContactField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'name@example.com',
                    icon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    cardBg: cardBg,
                    textColor: primaryTextColor,
                    hintColor: secondaryTextColor,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter your email';
                      if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _msgController,
                    maxLines: 4,
                    style: GoogleFonts.inter(fontSize: 14, color: primaryTextColor),
                    decoration: InputDecoration(
                      hintText: 'Describe your issue or question in detail...',
                      hintStyle: GoogleFonts.inter(
                        color: secondaryTextColor.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: cardBg,
                      contentPadding: const EdgeInsets.all(16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please type a message' : null,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryBlueMid, AppColors.primaryBlue],
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
                          onTap: _sendMessage,
                          child: Center(
                            child: Text(
                              'Send Message',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryBlue, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color cardBg,
    required Color textColor,
    required Color hintColor,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: hintColor.withValues(alpha: 0.5),
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: AppColors.primaryBlue, size: 18),
        filled: true,
        fillColor: cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}

// ---------------------------------------------------------------------------
// 5. SETTINGS SCREEN
// ---------------------------------------------------------------------------
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsOn = true;
  bool _darkModeOn = false;
  bool _isClearingCache = false;

  @override
  void initState() {
    super.initState();
    _darkModeOn = AppState.instance.isDarkMode;
    _notificationsOn = AppState.instance.notificationsEnabled;
  }

  void _clearCache() {
    setState(() {
      _isClearingCache = true;
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isClearingCache = false;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared successfully! (14.2 MB freed)'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF1B9B5A),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryTextColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final scafBg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: scafBg,
      appBar: AppBar(
        backgroundColor: scafBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppState.instance.translate('Settings'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: primaryTextColor,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        children: [
          // Basic Settings Section
          _buildSectionTitle(AppState.instance.translate('General Preferences')),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Notification Toggle
                ListTile(
                  leading: const Icon(Icons.notifications_active_rounded, color: AppColors.primaryBlue),
                  title: Text(AppState.instance.translate('Notifications'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: primaryTextColor)),
                  subtitle: Text('Receive alerts about claim status', style: GoogleFonts.inter(fontSize: 12, color: secondaryTextColor)),
                  trailing: Switch.adaptive(
                    value: _notificationsOn,
                    activeTrackColor: AppColors.primaryBlueMid,
                    activeThumbColor: AppColors.primaryBlue,
                    onChanged: (v) {
                      setState(() {
                        _notificationsOn = v;
                      });
                      AppState.instance.notificationsEnabled = v;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppState.instance.translate(v ? 'Notifications enabled' : 'Notifications disabled')),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: v ? AppColors.primaryBlue : Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1, color: AppColors.inputBorder),
                // Dark Theme Toggle
                ListTile(
                  leading: const Icon(Icons.dark_mode_rounded, color: AppColors.primaryBlue),
                  title: Text(AppState.instance.translate('Dark Mode'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: primaryTextColor)),
                  subtitle: Text(AppState.instance.translate('Switch between light & dark themes'), style: GoogleFonts.inter(fontSize: 12, color: secondaryTextColor)),
                  trailing: Switch.adaptive(
                    value: _darkModeOn,
                    activeTrackColor: AppColors.primaryBlueMid,
                    activeThumbColor: AppColors.primaryBlue,
                    onChanged: (v) {
                      setState(() {
                        _darkModeOn = v;
                      });
                      AppState.instance.toggleTheme(v);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppState.instance.translate(v ? 'Dark mode enabled' : 'Dark mode disabled')),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.primaryBlue,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // User Profile Section
          _buildSectionTitle(AppState.instance.translate('Profile settings')),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded, color: AppColors.primaryBlue),
                  title: Text(AppState.instance.translate('Edit Profile Info'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: primaryTextColor)),
                  subtitle: Text(AppState.instance.translate('View details & account management'), style: GoogleFonts.inter(fontSize: 12, color: secondaryTextColor)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileDetailsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Additional settings
          _buildSectionTitle(AppState.instance.translate('Advanced Preferences')),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Clear Cache
                ListTile(
                  leading: const Icon(Icons.cleaning_services_rounded, color: AppColors.primaryBlue),
                  title: Text(AppState.instance.translate('Clear App Cache'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: primaryTextColor)),
                  subtitle: Text(AppState.instance.translate('Free up storage used by cached images'), style: GoogleFonts.inter(fontSize: 12, color: secondaryTextColor)),
                  trailing: _isClearingCache
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                        )
                      : const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: _isClearingCache ? null : _clearCache,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                Text(
                  AppState.instance.translate('Foundit App'),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppState.instance.translate('Version 1.0.0'),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: secondaryTextColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryBlue,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. PROFILE DETAILS SCREEN (READ ONLY DETAILS + LOGOUT + DELETE ACCOUNT)
// ---------------------------------------------------------------------------
class ProfileDetailsScreen extends StatelessWidget {
  const ProfileDetailsScreen({super.key});

  void _logout(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryTextColor = isDark ? Colors.white70 : AppColors.textSecondary;

    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Confirm Logout',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: primaryTextColor,
            ),
          ),
          content: Text(
            'Are you sure you want to log out of your account?',
            style: GoogleFonts.inter(
              color: secondaryTextColor,
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
                  color: secondaryTextColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                elevation: 0,
              ),
              child: Text(
                'Logout',
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
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primaryBlue,
          ),
        );
      }
    }
  }

  void _deleteAccount(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? Colors.white70 : AppColors.textSecondary;

    final bool? confirm1 = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Delete Account?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE54D2E),
            ),
          ),
          content: Text(
            'Are you sure you want to delete your account? This will erase all your reports and saved bookmarks permanently.',
            style: GoogleFonts.inter(
              color: secondaryTextColor,
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
                  color: secondaryTextColor,
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

    if (confirm1 != true) return;

    if (context.mounted) {
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
              'This action is irreversible. All your post history and chats will be cleared. Do you wish to continue?',
              style: GoogleFonts.inter(
                color: secondaryTextColor,
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
                    color: secondaryTextColor,
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
                  'Confirm Delete',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (confirm2 == true) {
        final messenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);

        final res = await ApiService.deleteAccount();

        // Clear user session token
        ApiService.userToken = null;

        if (res['success'] == true) {
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const SignInScreen()),
            (route) => false,
          );
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Account permanently deleted from database.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Color(0xFFE54D2E),
            ),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Failed to delete account.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryTextColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final scafBg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = Theme.of(context).cardColor;

    final name = AppState.instance.userName.isNotEmpty ? AppState.instance.userName : 'John Doe';
    final email = AppState.instance.userEmail.isNotEmpty ? AppState.instance.userEmail : 'john.doe@example.com';
    final phone = AppState.instance.userPhone.isNotEmpty ? AppState.instance.userPhone : '+1 (123) 456-7890';

    return Scaffold(
      backgroundColor: scafBg,
      appBar: AppBar(
        backgroundColor: scafBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: primaryTextColor,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Info (Read-Only)',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildReadOnlyRow(Icons.person_rounded, 'Name', name, primaryTextColor, secondaryTextColor),
                  const Divider(height: 24, color: AppColors.inputBorder),
                  _buildReadOnlyRow(Icons.email_rounded, 'Email', email, primaryTextColor, secondaryTextColor),
                  const Divider(height: 24, color: AppColors.inputBorder),
                  _buildReadOnlyRow(Icons.phone_iphone_rounded, 'Phone', phone, primaryTextColor, secondaryTextColor),
                ],
              ),
            ),
            const Spacer(),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.primaryBlue.withValues(alpha: 0.3),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: Text(
                      'Logout',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteAccount(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE54D2E), width: 1.5),
                      foregroundColor: const Color(0xFFE54D2E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.delete_forever_rounded, size: 20),
                    label: Text(
                      'Delete Account',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyRow(IconData icon, String label, String value, Color pColor, Color sColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryBlue, size: 18),
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
                  color: sColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: pColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
