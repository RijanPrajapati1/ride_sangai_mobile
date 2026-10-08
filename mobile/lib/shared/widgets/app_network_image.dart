import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_ext.dart';
import '../../core/config/app_config.dart';
import 'mountain_backdrop.dart';

/// Wraps [Image.network] with a graceful gradient+icon fallback so a failed
/// or missing image URL never breaks the layout.
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
            AppConfig.mediaUrl(url!),
            width: width,
            height: height,
            fit: fit,
            // A quiet tile while loading; a spinner on every card is noisy.
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(width: width, height: height, color: context.appColors.surfaceAlt);
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
          colors: AppColors.imagePlaceholderGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const MountainBackdrop(height: 0.55),
          Center(child: Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 34)),
        ],
      ),
    );
  }
}
