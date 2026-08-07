import 'package:flutter/material.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/features/home/domain/post_model.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends StatelessWidget {
  final PostModel post;
  final bool hideProductName;
  final String? recipientId;
  final String? recipientName;
  final String? recipientPhotoUrl;
  final String? recipientEmail;

  const ChatScreen({
    super.key,
    required this.post,
    this.hideProductName = false,
    this.recipientId,
    this.recipientName,
    this.recipientPhotoUrl,
    this.recipientEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'Messaging system is disabled',
          style: GoogleFonts.inter(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
