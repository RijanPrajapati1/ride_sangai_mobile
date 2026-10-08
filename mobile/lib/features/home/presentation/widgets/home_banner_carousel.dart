import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/enums/dashboard_category.dart';
import '../../../../shared/widgets/mountain_backdrop.dart';

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
      DashboardCategory.cycling => 'Helmet on, lights charged, brakes checked.',
      DashboardCategory.trekking => 'Climb slowly and share your route before you go.',
      DashboardCategory.hiking => 'Carry enough water and tell someone your plan.',
      DashboardCategory.riding => 'Full gear, a checked bike and a safe gap.',
    };

/// Every banner leads somewhere real: plan a ride, explore places, or the
/// safety checklist for the active activity.
List<HomeBanner> homeBannersFor(
  DashboardCategory category, {
  required VoidCallback onCreate,
  required VoidCallback onExplore,
  required VoidCallback onSafety,
}) {
  final singular = category.activitySingular.toLowerCase();
  return [
    HomeBanner(
      icon: Icons.event_available_rounded,
      title: 'Plan your next $singular',
      subtitle: 'Pick a route and a date. Riders nearby can ask to join you.',
      ctaLabel: 'Create a $singular',
      gradient: AppColors.heroGradient,
      onTap: onCreate,
    ),
    HomeBanner(
      icon: Icons.travel_explore_rounded,
      title: 'Find hidden gems',
      subtitle: 'Viewpoints, waterfalls and tea stops that locals share.',
      ctaLabel: 'Explore places',
      gradient: const [AppColors.info, AppColors.infoDark],
      onTap: onExplore,
    ),
    HomeBanner(
      icon: Icons.health_and_safety_rounded,
      title: 'Safety first',
      subtitle: _safetyTip(category),
      ctaLabel: 'See the checklist',
      gradient: const [AppColors.secondary, AppColors.secondaryDark],
      onTap: onSafety,
    ),
  ];
}

/// Swipeable banners near the top of Home: plan a ride, explore places, and
/// a category-aware safety checklist.
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
          height: 150,
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
                color: active ? AppColors.primary : context.appColors.border,
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
    final radius = BorderRadius.circular(AppDimensions.radiusLg);
    return Material(
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: banner.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: InkWell(
          onTap: banner.onTap,
          child: Stack(
            children: [
              const Positioned.fill(child: MountainBackdrop(height: 0.45)),
              Positioned(
                right: -12,
                top: -10,
                child: Icon(banner.icon, size: 110, color: Colors.white.withValues(alpha: 0.14)),
              ),
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleLg.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 240,
                      child: Text(
                        banner.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySm.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            banner.ctaLabel,
                            style: AppTextStyles.labelSm.copyWith(color: banner.gradient.last, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, color: banner.gradient.last, size: 15),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
