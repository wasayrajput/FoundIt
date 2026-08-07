import 'package:flutter/material.dart';

/// Foundit brand color palette — blue & white tones
class AppColors {
  AppColors._();

  // --- Primary Blues ---
  static const Color primaryBlue       = Color(0xFF1565C0); // Deep brand blue
  static const Color primaryBlueMid    = Color(0xFF1E88E5); // Slightly lighter
  static const Color primaryBlueLight  = Color(0xFF42A5F5); // Accent blue
  static const Color primaryBluePale   = Color(0xFFE3F2FD); // Very light blue tint

  // --- Gradient stops ---
  static const Color gradientStart     = Color(0xFFFFFFFF); // Pure white
  static const Color gradientMid       = Color(0xFFF0F7FF); // Icy blue-white
  static const Color gradientEnd       = Color(0xFFDCEEFA); // Soft blue

  // --- Background ---
  static const Color background        = Color(0xFFF8FBFF); // Off-white with blue hint

  // --- Text ---
  static const Color textPrimary       = Color(0xFF0D1B2A); // Near-black navy
  static const Color textSecondary     = Color(0xFF546E7A); // Muted slate
  static const Color textTagline       = Color(0xFF78909C); // Lighter slate

  // --- Input ---
  static const Color inputFill         = Color(0xFFFFFFFF); // White fill for inputs
  static const Color inputBorder       = Color(0xFFE2E8F0); // Light gray border
  static const Color inputFocusBorder  = primaryBlueMid;    // Focus border
  static const Color inputIcon         = Color(0xFF94A3B8); // Muted icon color

  // --- Loader ---
  static const Color loaderTrack       = Color(0xFFBBDEFB); // Pale blue track
  static const Color loaderActive      = Color(0xFF1565C0); // Same as primary

  // --- Shimmer / glow ---
  static const Color glowBlue          = Color(0x331E88E5); // 20% primary blue
}
