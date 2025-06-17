import 'package:flutter/material.dart';

/// App color palette and theme color extensions
class AppColors {
  // Primary color shades
  static const Color primary = Color(0xFFFF0101);
  static const Color primaryDark = Color(0xFFCC0000);
  static const Color primaryLight = Color(0xFFFF3333);
  
  // Secondary colors
  static const Color secondary = Color(0xFF2D2D2D);
  
  // Text colors - using much darker greys for better readability
  static const Color textPrimary = Color(0xFF202020);
  static const Color textSecondary = Color(0xFF404040);  // Darkened considerably
  static const Color readableGrey = Color(0xFF505050);   // Darkened considerably
  
  // Background colors
  static const Color background = Colors.white;
  static const Color surfaceLight = Color(0xFFF5F5F5);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color pending = Color(0xFFFF9800);
  
  // Verification status colors
  static const Color verified = Color(0xFF4CAF50);
  static const Color notVerified = Color(0xFFE53935);
}

/// Extension on ColorScheme to add our custom colors
extension CustomColorScheme on ColorScheme {
  Color get readableGrey => AppColors.readableGrey;
  Color get textSecondary => AppColors.textSecondary;
}
