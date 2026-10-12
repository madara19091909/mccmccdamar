import 'package:echo/core/icons.dart';
import 'package:echo/data/models/memory_category.dart';
import 'package:echo/state/memory_controller.dart';
import 'package:echo/widgets/cosmic_background.dart';
import 'package:echo/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  Future<void> _edit(BuildContext context, MemoryCategory? existing) async {
    final controller = context.read<MemoryController>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<MemoryCategory>(
      context: context,
      builder: (dialogContext) => _CategoryDialog(
        initial: existing,
        nextOrder: controller.categories.length,
      ),
    );
    if (result == null) return;
    final ok = await controller.saveCategory(result);
    messenger.showSnackBar(
      SnackBar(content: Text(ok ? 'تم حفظ التصنيف' : 'تعذّر حفظ التصنيف.')),
    );
  }

  Future<void> _delete(BuildContext context, MemoryCategory category) async {
    final controller = context.read<MemoryController>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف التصنيف؟'),
        content: Text(
          'سيتم حذف "${category.name}" ونقل ذكرياته إلى تصنيف "حياتي".',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await controller.deleteCategory(category.id);
    messenger.showSnackBar(
      SnackBar(content: Text(ok ? 'تم حذف التصنيف' : 'تعذّر حذف التصنيف.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MemoryController>();
    final stats = controller.stats;
    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('إدارة التصنيفات')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _edit(context, null),
          icon: const Icon(Icons.add_rounded),
          label: const Text('تصنيف جديد'),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: <Widget>[
              for (final category in controller.categories)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    accent: category.color,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: <Widget>[
                        Icon(iconFor(category.iconKey), color: category.color),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(category.name),
                              Text(
                                '${stats.perCategory[category.id] ?? 0} ذكرى',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'تعديل',
                          icon: const Icon(Icons.edit_rounded),
                          onPressed: () => _edit(context, category),
                        ),
                        if (!category.isProtected)
                          IconButton(
                            tooltip: 'حذف',
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () => _delete(context, category),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({required this.initial, required this.nextOrder});

  final MemoryCategory? initial;
  final int nextOrder;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _nameController;
  late int _colorValue;
  late String _iconKey;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _colorValue = initial?.colorValue ?? kPaletteColors.first;
    _iconKey = initial?.iconKey ?? 'star';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'اسم التصنيف مطلوب');
      return;
    }
    final initial = widget.initial;
    Navigator.of(context).pop(
      initial?.copyWith(name: name, colorValue: _colorValue, iconKey: _iconKey) ??
          MemoryCategory(
            id: 'cat_${DateTime.now().microsecondsSinceEpoch}',
            name: name,
            colorValue: _colorValue,
            iconKey: _iconKey,
            sortOrder: widget.nextOrder,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'تصنيف جديد' : 'تعديل التصنيف'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _nameController,
              maxLength: 30,
              decoration: InputDecoration(
                labelText: 'الاسم',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final value in kPaletteColors)
                  GestureDetector(
                    onTap: () => setState(() => _colorValue = value),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(value),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: value == _colorValue
                              ? Colors.white
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final entry in kIconChoices.entries)
                  ChoiceChip(
                    label: Icon(entry.value, size: 20),
                    selected: entry.key == _iconKey,
                    onSelected: (_) => setState(() => _iconKey = entry.key),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _submit, child: const Text('حفظ')),
      ],
    );
  }
}
