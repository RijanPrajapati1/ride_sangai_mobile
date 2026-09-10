import 'package:flutter/material.dart';

/// Constrains content to a comfortable reading width on tablets/desktop
/// while remaining full-width on phones, avoiding the need for per-screen
/// breakpoint handling.
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveLayout({super.key, required this.child, this.maxWidth = 640});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= maxWidth) return child;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}
