import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Wraps [Image.network] with a graceful gradient+icon fallback so a failed
/// or missing dummy image URL never breaks the layout.
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData fallbackIcon;
  final BorderRadius? borderRadius;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.pedal_bike,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;
    final placeholder = _Fallback(width: width, height: height, icon: fallbackIcon);

    final child = url == null || url!.isEmpty
        ? placeholder
        : Image.network(
            url!,
            width: width,
            height: height,
            fit: fit,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return SizedBox(
                width: width,
                height: height,
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => placeholder,
          );

    return ClipRRect(borderRadius: radius, child: child);
  }
}

class _Fallback extends StatelessWidget {
  final double? width;
  final double? height;
  final IconData icon;

  const _Fallback({this.width, this.height, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.avatarPlaceholderGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 32),
    );
  }
}
