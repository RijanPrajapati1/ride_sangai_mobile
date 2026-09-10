import 'package:flutter/material.dart';

import 'responsive_layout.dart';

/// Thin [Scaffold] wrapper that centers and width-constrains content on
/// larger screens while staying full-bleed on phones.
class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool safeArea;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.safeArea = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final content = ResponsiveLayout(child: body);
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: safeArea ? SafeArea(child: content) : content,
    );
  }
}
