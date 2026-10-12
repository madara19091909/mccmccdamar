import 'package:echo/core/format.dart';
import 'package:echo/core/icons.dart';
import 'package:echo/data/image_store.dart';
import 'package:echo/data/models/memory.dart';
import 'package:echo/navigation/app_routes.dart';
import 'package:echo/state/memory_controller.dart';
import 'package:echo/widgets/cosmic_background.dart';
import 'package:echo/widgets/glass_card.dart';
import 'package:echo/widgets/importance_stars.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MemoryDetailPage extends StatelessWidget {
  const MemoryDetailPage({super.key, required this.memoryId});

  final String memoryId;

  Future<void> _confirmDelete(BuildContext context, Memory memory) async {
    final controller = context.read<MemoryController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الذكرى؟'),
        content: Text('سيتم حذف "${memory.title}" نهائيًا ولا يمكن التراجع.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            key: const Key('confirm_delete_button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    navigator.pop();
    final ok = await controller.deleteMemory(memory.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'تم حذف الذكرى' : 'تعذّر حذف الذكرى. حاول مرة أخرى.'),
      ),
    );
  }

  void _showImage(BuildContext context, ImageStore store, String name) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          child: Image.file(
            store.fileFor(name),
            errorBuilder: (context, error, stack) => const Padding(
              padding: EdgeInsets.all(40),
              child: Icon(Icons.broken_image_outlined, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MemoryController>();
    final store = context.read<ImageStore>();
    final memory = controller.memoryById(memoryId);
    final theme = Theme.of(context);

    if (memory == null) {
      return const CosmicBackground(
        child: Scaffold(backgroundColor: Colors.transparent),
      );
    }

    final category = controller.categoryById(memory.categoryId);
    final accent = memory.color;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.65);

    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          actions: <Widget>[
            IconButton(
              key: const Key('edit_memory_button'),
              tooltip: 'تعديل',
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => AppRoutes.openMemoryForm(context, memory: memory),
            ),
            IconButton(
              key: const Key('delete_memory_button'),
              tooltip: 'حذف',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _confirmDelete(context, memory),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: <Widget>[
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.18),
                    border: Border.all(color: accent, width: 2),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: accent.withValues(alpha: 0.4),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Icon(iconFor(memory.iconKey), color: accent, size: 36),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                memory.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: <Widget>[
                  if (category != null)
                    Chip(
                      avatar: Icon(iconFor(category.iconKey),
                          size: 16, color: category.color),
                      label: Text(category.name),
                    ),
                  Chip(
                    avatar: const Icon(Icons.event_rounded, size: 16),
                    label: Text(formatDateTime(memory.occurredAt)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Center(child: ImportanceStars(value: memory.importance, size: 22)),
              if (memory.body.isNotEmpty) ...<Widget>[
                const SizedBox(height: 18),
                GlassCard(
                  accent: accent,
                  child: SizedBox(
                    width: double.infinity,
                    child: SelectableText(
                      memory.body,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
                    ),
                  ),
                ),
              ],
              if (memory.tags.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: <Widget>[
                    for (final tag in memory.tags)
                      Chip(label: Text('#$tag')),
                  ],
                ),
              ],
              if (memory.images.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    for (final name in memory.images)
                      GestureDetector(
                        onTap: () => _showImage(context, store, name),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            store.fileFor(name),
                            width: 104,
                            height: 104,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => SizedBox(
                              width: 104,
                              height: 104,
                              child: Icon(Icons.broken_image_outlined,
                                  color: muted),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'أُضيفت ${formatDate(memory.createdAt)}  ·  آخر تعديل ${formatRelative(memory.updatedAt)}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
