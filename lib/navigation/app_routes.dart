import 'package:echo/data/models/memory.dart';
import 'package:echo/features/memory/memory_detail_page.dart';
import 'package:echo/features/memory/memory_form_page.dart';
import 'package:echo/features/settings/categories_page.dart';
import 'package:flutter/material.dart';

/// Central place for pushing screens, with one shared transition.
class AppRoutes {
  const AppRoutes._();

  static Route<T> _route<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static Future<void> openMemory(BuildContext context, String memoryId) {
    return Navigator.of(context)
        .push<void>(_route<void>(MemoryDetailPage(memoryId: memoryId)));
  }

  static Future<bool?> openMemoryForm(BuildContext context, {Memory? memory}) {
    return Navigator.of(context)
        .push<bool>(_route<bool>(MemoryFormPage(initial: memory)));
  }

  static Future<void> openCategories(BuildContext context) {
    return Navigator.of(context)
        .push<void>(_route<void>(const CategoriesPage()));
  }
}
