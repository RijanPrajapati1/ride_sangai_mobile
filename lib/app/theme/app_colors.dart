import 'package:flutter/material.dart';

/// Centralized color palette. Never hardcode colors outside this file.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF1FB6A8);
  static const primaryDark = Color(0xFF15897E);
  static const primaryLight = Color(0xFFDFF7F4);

  static const secondary = Color(0xFFFF6B35);
  static const secondaryLight = Color(0xFFFFE7DC);

  static const background = Color(0xFFF6F8F9);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF0F3F4);

  static const textPrimary = Color(0xFF16232B);
  static const textSecondary = Color(0xFF6C7B85);
  static const textMuted = Color(0xFF9AA6AD);

  static const border = Color(0xFFE4E9EB);
  static const divider = Color(0xFFEDF1F2);

  static const success = Color(0xFF2FB170);
  static const error = Color(0xFFE5484D);
  static const warning = Color(0xFFF5A623);
  static const info = Color(0xFF3B82F6);

  static const overlay = Color(0x66000000);

  // Dark theme
  static const backgroundDark = Color(0xFF0E1518);
  static const surfaceDark = Color(0xFF172024);
  static const surfaceAltDark = Color(0xFF1E292E);
  static const textPrimaryDark = Color(0xFFF2F5F6);
  static const textSecondaryDark = Color(0xFF9AAAB1);
  static const textMutedDark = Color(0xFF71828A);
  static const borderDark = Color(0xFF2A363B);
  static const dividerDark = Color(0xFF263136);
  static const primaryLightDark = Color(0xFF163430);
  static const secondaryLightDark = Color(0xFF3A2A20);

  static const difficultyEasy = Color(0xFF2FB170);
  static const difficultyModerate = Color(0xFFF5A623);
  static const difficultyHard = Color(0xFFE5484D);

  static const List<Color> heroGradient = [primary, primaryDark];
  static const List<Color> avatarPlaceholderGradient = [
    Color(0xFF1FB6A8),
    Color(0xFFFF6B35),
  ];
}
