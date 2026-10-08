import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../providers/onboarding_providers.dart';
import '../widgets/onboarding_page.dart';

const _pages = [
  OnboardingPageData(
    icon: Icons.explore_rounded,
    title: 'Find your next adventure',
    description: 'Group rides, treks, hikes and motorbike meetups happening near you.',
    gradient: AppColors.heroGradient,
    highlights: [
      (icon: Icons.wb_twilight_rounded, label: 'Sunrise ride · Sat 5:00 AM'),
      (icon: Icons.groups_rounded, label: '12 riders going'),
    ],
  ),
  OnboardingPageData(
    icon: Icons.groups_rounded,
    title: 'Ride with your crew',
    description: 'Ask to join with one tap, chat with the group and share your trip photos.',
    gradient: [AppColors.info, AppColors.infoDark],
    highlights: [
      (icon: Icons.check_circle_rounded, label: "You're in! See you Saturday"),
      (icon: Icons.chat_bubble_rounded, label: 'Meet at the gate, 6:45'),
    ],
  ),
  OnboardingPageData(
    icon: Icons.landscape_rounded,
    title: 'Discover hidden gems',
    description: 'Viewpoints, waterfalls and tea stops that locals share and review.',
    gradient: [AppColors.secondary, AppColors.secondaryDark],
    highlights: [
      (icon: Icons.star_rounded, label: '4.9 · Lakeside viewpoint'),
      (icon: Icons.bookmark_rounded, label: 'Saved for your next trip'),
    ],
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingControllerProvider).complete();
    if (mounted) context.go(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spaceLg,
                AppDimensions.spaceSm,
                AppDimensions.spaceSm,
                AppDimensions.spaceSm,
              ),
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: const AppLogo(size: 32)),
                    const SizedBox(width: AppDimensions.spaceXs),
                    Text(
                      AppConstants.appName,
                      style: AppTextStyles.titleLg.copyWith(
                        color: context.appColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    // Hidden on the last page, where the main button finishes.
                    if (!isLast) TextButton(onPressed: _finish, child: const Text('Skip')),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => OnboardingPage(data: _pages[i]),
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : context.appColors.border,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spaceLg,
                AppDimensions.spaceLg,
                AppDimensions.spaceLg,
                AppDimensions.spaceMd,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLast) {
                      _finish();
                    } else {
                      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                    }
                  },
                  child: Text(isLast ? 'Get Started' : 'Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
