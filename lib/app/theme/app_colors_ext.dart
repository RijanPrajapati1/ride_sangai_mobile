import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Theme-aware surface/text/border tokens. Brand colors (primary, secondary,
/// success/error/warning, difficulty colors, gradients) stay constant across
/// light/dark and are read straight off [AppColors]; everything that must
/// flip between light and dark surfaces lives here instead, so widgets never
/// hardcode a light-only shade.
class AppColorsExt extends ThemeExtension<AppColorsExt> {
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color divider;
  final Color primaryLight;
  final Color secondaryLight;

  const AppColorsExt({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.divider,
    required this.primaryLight,
    required this.secondaryLight,
  });

  static const light = AppColorsExt(
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceAlt: AppColors.surfaceAlt,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    border: AppColors.border,
    divider: AppColors.divider,
    primaryLight: AppColors.primaryLight,
    secondaryLight: AppColors.secondaryLight,
  );

  static const dark = AppColorsExt(
    background: AppColors.backgroundDark,
    surface: AppColors.surfaceDark,
    surfaceAlt: AppColors.surfaceAltDark,
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    textMuted: AppColors.textMutedDark,
    border: AppColors.borderDark,
    divider: AppColors.dividerDark,
    primaryLight: AppColors.primaryLightDark,
    secondaryLight: AppColors.secondaryLightDark,
  );

  @override
  AppColorsExt copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? divider,
    Color? primaryLight,
    Color? secondaryLight,
  }) {
    return AppColorsExt(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      primaryLight: primaryLight ?? this.primaryLight,
      secondaryLight: secondaryLight ?? this.secondaryLight,
    );
  }

  @override
  AppColorsExt lerp(ThemeExtension<AppColorsExt>? other, double t) {
    if (other is! AppColorsExt) return this;
    return AppColorsExt(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      secondaryLight: Color.lerp(secondaryLight, other.secondaryLight, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  /// Theme-aware surface/text/border tokens for the current brightness.
  AppColorsExt get appColors => Theme.of(this).extension<AppColorsExt>() ?? AppColorsExt.light;
}
