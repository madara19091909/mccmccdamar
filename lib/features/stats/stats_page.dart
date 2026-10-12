import 'package:echo/core/format.dart';
import 'package:echo/core/icons.dart';
import 'package:echo/state/memory_controller.dart';
import 'package:echo/widgets/empty_state.dart';
import 'package:echo/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MemoryController>();
    final theme = Theme.of(context);

    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = controller.stats;
    if (stats.total == 0) {
      return const EmptyState(
        icon: Icons.insights_rounded,
        title: 'لا توجد إحصائيات بعد',
        message: 'ستظهر هنا أرقام حقيقية محسوبة من ذكرياتك فور إضافتها.',
      );
    }

    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    final categories = controller.categories.toList()
      ..sort((a, b) => (stats.perCategory[b.id] ?? 0)
          .compareTo(stats.perCategory[a.id] ?? 0));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'إحصائياتك',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Row(
            children: <Widget>[
              Icon(Icons.bubble_chart_rounded,
                  size: 40, color: theme.colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('إجمالي الذكريات', style: theme.textTheme.bodyMedium),
                    Text(
                      formatNumber(stats.total),
                      style: theme.textTheme.displaySmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text('متوسط الأهمية',
                      style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                  Text(
                    stats.averageImportance.toStringAsFixed(1),
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(child: _Metric(label: 'أُضيفت اليوم', value: stats.addedToday)),
            const SizedBox(width: 10),
            Expanded(
                child: _Metric(label: 'آخر 7 أيام', value: stats.addedLast7Days)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
                child:
                    _Metric(label: 'آخر 30 يومًا', value: stats.addedLast30Days)),
            const SizedBox(width: 10),
            Expanded(child: _Metric(label: 'هذا العام', value: stats.addedThisYear)),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'الذكريات حسب التصنيف',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              for (final category in categories)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(iconFor(category.iconKey),
                              size: 18, color: category.color),
                          const SizedBox(width: 8),
                          Expanded(child: Text(category.name)),
                          Text(
                            formatNumber(stats.perCategory[category.id] ?? 0),
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: (stats.perCategory[category.id] ?? 0) /
                            stats.total,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                        color: category.color,
                        backgroundColor: category.color.withValues(alpha: 0.15),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Row(
            children: <Widget>[
              Icon(Icons.history_rounded, color: theme.colorScheme.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text('آخر نشاط', style: theme.textTheme.bodyMedium),
              ),
              Text(
                stats.lastActivity == null
                    ? '-'
                    : formatRelative(stats.lastActivity!),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatNumber(value),
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
