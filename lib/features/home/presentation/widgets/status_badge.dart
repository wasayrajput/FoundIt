import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:foundit/core/state/app_state.dart';

class StatusBadge extends StatelessWidget {
  final bool isLost;

  const StatusBadge({
    super.key,
    required this.isLost,
  });

  @override
  Widget build(BuildContext context) {
    // Red/Orange for Lost, Green for Found
    final Color backgroundColor = isLost 
        ? const Color(0xFFFFF0ED) 
        : const Color(0xFFE8F8F0);
    final Color textColor = isLost 
        ? const Color(0xFFE54D2E) 
        : const Color(0xFF1B9B5A);
    final String text = AppState.instance.translate(isLost ? 'Lost' : 'Found');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
