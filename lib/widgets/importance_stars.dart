import 'package:echo/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ImportanceStars extends StatelessWidget {
  const ImportanceStars({super.key, required this.value, this.size = 16});

  final int value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(
        5,
        (i) => Icon(
          i < value ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: AppColors.gold,
        ),
      ),
    );
  }
}
