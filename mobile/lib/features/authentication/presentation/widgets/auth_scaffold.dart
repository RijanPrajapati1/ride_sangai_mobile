import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/mountain_backdrop.dart';

/// Layout shared by the sign-in screens: a branded header (gradient,
/// mountains, logo, headline) with the form on a rounded sheet below it.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showBack;
  final Widget child;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = false,
  });

  static const _sheetOverlap = 28.0;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appColors;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              _AuthHeader(title: title, subtitle: subtitle, showBack: showBack),
              Transform.translate(
                offset: const Offset(0, -_sheetOverlap),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: tokens.background,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.spaceLg,
                    AppDimensions.spaceLg,
                    AppDimensions.spaceLg,
                    AppDimensions.spaceMd,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: SafeArea(top: false, child: child),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showBack;

  const _AuthHeader({required this.title, required this.subtitle, required this.showBack});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: MountainBackdrop(height: 0.55, showSun: true)),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppDimensions.spaceLg,
              topInset + AppDimensions.spaceSm,
              AppDimensions.spaceLg,
              AppDimensions.spaceXl + AuthScaffold._sheetOverlap,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 48,
                  child: showBack
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.18)),
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: AppDimensions.spaceSm),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: const AppLogo(size: 56),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceLg),
                Text(title, style: AppTextStyles.displayLg.copyWith(color: Colors.white)),
                const SizedBox(height: AppDimensions.spaceXs),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyLg.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
