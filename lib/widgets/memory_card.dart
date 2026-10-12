import 'package:echo/core/format.dart';
import 'package:echo/core/icons.dart';
import 'package:echo/data/models/memory.dart';
import 'package:echo/data/models/memory_category.dart';
import 'package:echo/widgets/glass_card.dart';
import 'package:echo/widgets/importance_stars.dart';
import 'package:flutter/material.dart';

class MemoryCard extends StatelessWidget {
  const MemoryCard({
    super.key,
    required this.memory,
    required this.category,
    required this.onTap,
    this.compact = false,
  });

  final Memory memory;
  final MemoryCategory? category;
  final VoidCallback onTap;

  /// Compact cards (home strip) show only the title and one meta line.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = memory.color;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    final meta = <String>[
      if (category != null) category!.name,
      formatDate(memory.occurredAt),
    ].join(' · ');

    final icon = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: accent.withValues(alpha: 0.6)),
      ),
      child: Icon(iconFor(memory.iconKey), color: accent, size: 22),
    );

    final titleText = Text(
      memory.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );

    return GlassCard(
      accent: accent,
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                titleText,
                if (!compact && memory.body.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    memory.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: muted, height: 1.5),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
                if (!compact) ...<Widget>[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      ImportanceStars(value: memory.importance, size: 14),
                      for (final tag in memory.tags.take(3))
                        Text(
                          '#$tag',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: accent),
                        ),
                      if (memory.images.isNotEmpty)
                        Icon(Icons.photo_library_outlined,
                            size: 14, color: muted),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
