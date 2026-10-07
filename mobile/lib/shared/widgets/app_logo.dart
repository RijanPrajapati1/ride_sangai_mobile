import 'package:flutter/material.dart';

/// The Yatrix brand mark (teal tile with a bike).
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Yatrix logo',
    );
  }
}
