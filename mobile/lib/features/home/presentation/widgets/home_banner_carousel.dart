import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/dashboard_category.dart';

class HomeBanner {
  final IconData icon;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final List<Color> gradient;
  final VoidCallback? onTap;

  const HomeBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.gradient,
    this.onTap,
  });
}

String _safetyTip(DashboardCategory category) => switch (category) {
      DashboardCategory.cycling => 'Always wear a certified helmet and run lights after dark.',
      DashboardCategory.trekking => 'Check the weather and share your route before high-altitude treks.',
      DashboardCategory.hiking => 'Carry enough water and let someone know your hiking plan.',
      DashboardCategory.riding => 'Wear a certified helmet and check your bike before long rides.',
    };

List<HomeBanner> homeBannersFor(DashboardCategory category, {VoidCallback? onInvite, VoidCallback? onChallenge, VoidCallback? onSafety}) {
  return [
    HomeBanner(
      icon: Icons.group_add_outlined,
      title: 'Ride with friends',
      subtitle: 'Invite friends to Biker Sync and plan your next ${category.activitySingular.toLowerCase()} together.',
      ctaLabel: 'Invite friends',
      gradient: const [AppColors.primary, AppColors.primaryDark],
      onTap: onInvite,
    ),
    HomeBanner(
      icon: Icons.emoji_events_outlined,
      title: "This week's challenge",
      subtitle: 'Join 3 ${category.activityNoun.toLowerCase()} this week to earn the Explorer badge.',
      ctaLabel: 'View challenge',
      gradient: const [AppColors.secondary, Color(0xFFCC4E1F)],
      onTap: onChallenge,
    ),
    HomeBanner(
      icon: Icons.health_and_safety_outlined,
      title: 'Safety first',
      subtitle: _safetyTip(category),
      ctaLabel: 'Read safety tips',
      gradient: const [AppColors.info, Color(0xFF1E4FA6)],
      onTap: onSafety,
    ),
  ];
}

/// Swipeable promo/engagement banners shown near the top of Home, above the
/// activity feed — invite friends, a weekly challenge, a category-aware
/// safety tip.
class HomeBannerCarousel extends StatefulWidget {
  final List<HomeBanner> banners;

  const HomeBannerCarousel({super.key, required this.banners});

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  final _controller = PageController(viewportFraction: 0.92);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 132,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _BannerCard(banner: banner),
              );
            },
          ),
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.banners.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final HomeBanner banner;

  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: banner.onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: banner.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
              child: Icon(banner.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: AppDimensions.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner.title,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    banner.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        banner.ctaLabel,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
