import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_ext.dart';
import '../../app/theme/app_text_styles.dart';
import 'app_network_image.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final Widget? badge;

  const AppAvatar({
    super.key,
    required this.imageUrl,
    required this.name,
    this.size = 44,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = ClipOval(
      child: (imageUrl == null || imageUrl!.isEmpty)
          ? _Initials(name: name, size: size)
          : AppNetworkImage(
              url: imageUrl,
              width: size,
              height: size,
              fallbackIcon: Icons.person,
            ),
    );

    if (badge == null) return SizedBox(width: size, height: size, child: avatar);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(right: -2, bottom: -2, child: badge!),
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String name;
  final double size;

  const _Initials({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).take(2).map((e) => e[0]).join().toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: context.appColors.primaryLight, shape: BoxShape.circle),
      child: Text(
        initials,
        style: AppTextStyles.titleMd.copyWith(
          color: AppColors.primary,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}
