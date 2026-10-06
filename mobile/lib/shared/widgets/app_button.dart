import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: AppDimensions.iconSm), const SizedBox(width: 8)],
              Text(label),
            ],
          );

    // The theme's minimumSize is full-width; drop that when not expanding so the
    // button can sit inside a Row without unbounded-width layout errors.
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: expand
          ? null
          : ElevatedButton.styleFrom(minimumSize: const Size(64, AppDimensions.buttonHeight)),
      child: child,
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class AppOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final Color? color;

  const AppOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: color != null ? BorderSide(color: color!) : null,
        minimumSize: expand ? null : const Size(64, AppDimensions.buttonHeight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: AppDimensions.iconSm), const SizedBox(width: 8)],
          Text(label),
        ],
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class AppTextButtonDanger extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AppTextButtonDanger({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: AppColors.error),
      child: Text(label),
    );
  }
}
