import 'package:echo/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Space-like gradient behind every screen.
class CosmicBackground extends StatelessWidget {
  const CosmicBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: dark
            ? const RadialGradient(
                center: Alignment(0.6, -0.8),
                radius: 1.4,
                colors: <Color>[Color(0xFF1B1550), AppColors.space],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0xFFF4F2FF), Color(0xFFE7F7F5)],
              ),
      ),
      child: child,
    );
  }
}
