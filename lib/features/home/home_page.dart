import 'package:echo/core/format.dart';
import 'package:echo/data/models/memory.dart';
import 'package:echo/features/home/echo_world.dart';
import 'package:echo/navigation/app_routes.dart';
import 'package:echo/state/memory_controller.dart';
import 'package:echo/state/settings_controller.dart';
import 'package:echo/widgets/empty_state.dart';
import 'package:echo/widgets/memory_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MemoryController>();
    final settings = context.watch<SettingsController>();
    final theme = Theme.of(context);

    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.errorMessage != null) {
      return EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'تعذّر فتح عالمك',
        message: controller.errorMessage!,
        actionLabel: 'إعادة المحاولة',
        onAction: controller.load,
      );
    }

    final memories = controller.memories;
    final stats = controller.stats;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Row(
            children: <Widget>[
              Icon(Icons.blur_on_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'عالم ECHO',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: <Widget>[
              _StatChip(
                value: formatNumber(stats.total),
                label: 'ذكرى',
                icon: Icons.bubble_chart_rounded,
              ),
              const SizedBox(width: 8),
              _StatChip(
                value: formatNumber(stats.categoriesInUse),
                label: 'تصنيفات',
                icon: Icons.category_rounded,
              ),
              const SizedBox(width: 8),
              _StatChip(
                value: formatNumber(stats.addedLast7Days),
                label: 'هذا الأسبوع',
                icon: Icons.bolt_rounded,
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: EchoWorld(
                  memories: memories,
                  categories: controller.categories,
                  animate: !settings.lightEffects,
                  onOpenMemory: (memory) =>
                      AppRoutes.openMemory(context, memory.id),
                ),
              ),
              if (memories.isEmpty)
                Positioned.fill(
                  child: EmptyState(
                    icon: Icons.auto_awesome_rounded,
                    title: 'عالمك ينتظر أول ذكرى',
                    message:
                        'احفظ لحظة أو فكرة أو إنجازًا، وسترى عالمك يتشكل نجمة بعد نجمة.',
                    actionLabel: 'إضافة أول ذكرى',
                    onAction: () => AppRoutes.openMemoryForm(context),
                  ),
                ),
            ],
          ),
        ),
        if (memories.isNotEmpty) _LatestStrip(memories: memories),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 18, color: theme.colorScheme.secondary),
            const SizedBox(width: 6),
            Text(
              value,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestStrip extends StatelessWidget {
  const _LatestStrip({required this.memories});

  final List<Memory> memories;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<MemoryController>();
    final theme = Theme.of(context);
    final latest = memories.take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
          child: Text(
            'أحدث الذكريات',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 96, 8),
            itemCount: latest.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final memory = latest[index];
              return SizedBox(
                width: 240,
                child: MemoryCard(
                  memory: memory,
                  category: controller.categoryById(memory.categoryId),
                  compact: true,
                  onTap: () => AppRoutes.openMemory(context, memory.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
