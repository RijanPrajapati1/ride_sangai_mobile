import 'package:flutter/material.dart';

/// Centralized color palette. Never hardcode colors outside this file.
class AppColors {
  AppColors._();

  /// Deep enough that white button labels and teal text links stay readable
  /// (about 4:1 on white), and still bright on the dark theme.
  static const primary = Color(0xFF0E9083);
  static const primaryDark = Color(0xFF0B6F66);
  static const primaryLight = Color(0xFFDFF7F4);

  /// The brighter brand teal from the logo, for gradients and decoration
  /// only. Too light to carry white text.
  static const primaryBright = Color(0xFF1FB6A8);

  static const secondary = Color(0xFFFF6B35);
  static const secondaryLight = Color(0xFFFFE7DC);

  static const background = Color(0xFFF5F7F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFEFF3F4);

  static const textPrimary = Color(0xFF16232B);
  static const textSecondary = Color(0xFF5F6E78);
  static const textMuted = Color(0xFF8A979F);

  static const border = Color(0xFFE4E9EB);

  /// Outline of text fields and dropdowns; darker than [border] so empty
  /// fields stay visible on white cards.
  static const inputBorder = Color(0xFFC9D2D6);
  static const inputBorderDark = Color(0xFF3B4A50);
  static const divider = Color(0xFFEDF1F2);

  static const success = Color(0xFF2FB170);
  static const error = Color(0xFFE5484D);
  static const warning = Color(0xFFF5A623);
  static const info = Color(0xFF3B82F6);

  /// Map markers, in the colors people know from Google Maps: the blue
  /// "you are here" dot and the red dropped pin.
  static const mapUserDot = Color(0xFF4285F4);
  static const mapPin = Color(0xFFEA4335);

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

  static const List<Color> heroGradient = [primaryBright, primaryDark];

  /// Behind a ride or place that has no photo: a calm teal dusk that the
  /// [MountainBackdrop] silhouettes sit on.
  static const List<Color> imagePlaceholderGradient = [
    Color(0xFF7FD3C9),
    Color(0xFF1C9C8F),
  ];

  /// Soft shadow under raised cards and floating bars.
  static const shadow = Color(0x1A16232B);
}
