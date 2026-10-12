import 'package:echo/core/constants.dart';
import 'package:echo/core/format.dart';
import 'package:echo/core/icons.dart';
import 'package:echo/data/image_store.dart';
import 'package:echo/data/models/memory.dart';
import 'package:echo/state/memory_controller.dart';
import 'package:echo/widgets/cosmic_background.dart';
import 'package:echo/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

/// Create (initial == null) or edit a memory.
class MemoryFormPage extends StatefulWidget {
  const MemoryFormPage({super.key, this.initial});

  final Memory? initial;

  @override
  State<MemoryFormPage> createState() => _MemoryFormPageState();
}

class _MemoryFormPageState extends State<MemoryFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  final TextEditingController _tagController = TextEditingController();
  late final ImageStore _imageStore;

  late DateTime _occurredAt;
  late String _categoryId;
  late int _colorValue;
  late String _iconKey;
  late int _importance;
  late List<String> _tags;
  late List<String> _images;

  /// Images copied during this session (deleted if the form is abandoned).
  final List<String> _addedImages = <String>[];

  /// Images that belonged to the memory and were removed (deleted on save).
  final List<String> _removedImages = <String>[];

  bool _saving = false;
  bool _saved = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final memory = widget.initial;
    _imageStore = context.read<ImageStore>();
    _titleController = TextEditingController(text: memory?.title ?? '');
    _bodyController = TextEditingController(text: memory?.body ?? '');
    _occurredAt = memory?.occurredAt ?? DateTime.now();
    _categoryId = memory?.categoryId ?? kFallbackCategoryId;
    _colorValue = memory?.colorValue ?? kPaletteColors.first;
    _iconKey = memory?.iconKey ?? 'star';
    _importance = memory?.importance ?? 3;
    _tags = <String>[...?memory?.tags];
    _images = <String>[...?memory?.images];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    if (!_saved) {
      for (final name in _addedImages) {
        _imageStore.delete(name);
      }
    }
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (!mounted) return;
    setState(() {
      _occurredAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _occurredAt.hour,
        time?.minute ?? _occurredAt.minute,
      );
    });
  }

  void _addTagsFromField() {
    final raw = _tagController.text;
    if (raw.trim().isEmpty) return;
    final parts = raw
        .split(RegExp(r'[,،\n]'))
        .map((t) => t.trim().replaceAll('#', ''))
        .where((t) => t.isNotEmpty);
    setState(() {
      for (final tag in parts) {
        if (_tags.length >= kMaxTagsPerMemory) break;
        if (!_tags.contains(tag)) _tags.add(tag);
      }
      _tagController.clear();
    });
  }

  Future<void> _pickImages() async {
    final messenger = ScaffoldMessenger.of(context);
    final remaining = kMaxImagesPerMemory - _images.length;
    if (remaining <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('وصلت إلى الحد الأقصى من الصور.')),
      );
      return;
    }
    try {
      final picked = await ImagePicker().pickMultiImage(
        imageQuality: 85,
        maxWidth: 2048,
      );
      if (picked.isEmpty || !mounted) return;
      for (final file in picked.take(remaining)) {
        final name = await _imageStore.importFile(file.path);
        _addedImages.add(name);
        _images.add(name);
      }
      if (mounted) setState(() {});
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('تعذّر إضافة الصورة. حاول مرة أخرى.')),
      );
    }
  }

  void _removeImage(String name) {
    setState(() => _images.remove(name));
    if (_addedImages.remove(name)) {
      _imageStore.delete(name);
    } else {
      _removedImages.add(name);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _addTagsFromField();
    setState(() => _saving = true);

    final controller = context.read<MemoryController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final now = DateTime.now();
    final initial = widget.initial;
    final memory = Memory(
      id: initial?.id ?? Memory.newId(),
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      occurredAt: _occurredAt,
      createdAt: initial?.createdAt ?? now,
      updatedAt: now,
      categoryId: _categoryId,
      tags: List<String>.of(_tags),
      colorValue: _colorValue,
      iconKey: _iconKey,
      importance: _importance,
      images: List<String>.of(_images),
    );

    final ok = await controller.saveMemory(
      memory,
      removedImages: List<String>.of(_removedImages),
    );
    if (!mounted) return;
    if (ok) {
      _saved = true;
      navigator.pop(true);
      messenger.showSnackBar(
        SnackBar(content: Text(_isEdit ? 'تم حفظ التعديلات' : 'تمت إضافة الذكرى')),
      );
    } else {
      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('تعذّر حفظ الذكرى. حاول مرة أخرى.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = context.watch<MemoryController>().categories;

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(
            text,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        );

    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(_isEdit ? 'تعديل الذكرى' : 'ذكرى جديدة')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    key: const Key('memory_title_field'),
                    controller: _titleController,
                    maxLength: 120,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'العنوان'),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'العنوان مطلوب'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('memory_body_field'),
                    controller: _bodyController,
                    minLines: 4,
                    maxLines: 10,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      labelText: 'التفاصيل',
                      alignLabelWithHint: true,
                    ),
                  ),
                  label('التاريخ والوقت'),
                  GlassCard(
                    onTap: _pickDateTime,
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.event_rounded,
                            color: theme.colorScheme.secondary),
                        const SizedBox(width: 12),
                        Expanded(child: Text(formatDateTime(_occurredAt))),
                        const Icon(Icons.edit_calendar_rounded, size: 20),
                      ],
                    ),
                  ),
                  label('التصنيف'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final category in categories)
                        ChoiceChip(
                          avatar: Icon(iconFor(category.iconKey),
                              size: 18, color: category.color),
                          label: Text(category.name),
                          selected: category.id == _categoryId,
                          onSelected: (_) =>
                              setState(() => _categoryId = category.id),
                        ),
                    ],
                  ),
                  label('الوسوم'),
                  TextField(
                    controller: _tagController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addTagsFromField(),
                    decoration: InputDecoration(
                      labelText: 'أضف وسمًا',
                      hintText: 'اكتب وسمًا ثم اضغط إدخال',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add_rounded),
                        tooltip: 'إضافة الوسم',
                        onPressed: _addTagsFromField,
                      ),
                    ),
                  ),
                  if (_tags.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: <Widget>[
                        for (final tag in _tags)
                          InputChip(
                            label: Text('#$tag'),
                            onDeleted: () => setState(() => _tags.remove(tag)),
                          ),
                      ],
                    ),
                  ],
                  label('اللون'),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      for (final value in kPaletteColors)
                        _ColorDot(
                          value: value,
                          selected: value == _colorValue,
                          onTap: () => setState(() => _colorValue = value),
                        ),
                    ],
                  ),
                  label('الأيقونة'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final entry in kIconChoices.entries)
                        _IconChoice(
                          icon: entry.value,
                          color: Color(_colorValue),
                          selected: entry.key == _iconKey,
                          onTap: () => setState(() => _iconKey = entry.key),
                        ),
                    ],
                  ),
                  label('درجة الأهمية'),
                  Row(
                    children: <Widget>[
                      for (var i = 1; i <= 5; i++)
                        IconButton(
                          tooltip: 'الأهمية $i',
                          onPressed: () => setState(() => _importance = i),
                          icon: Icon(
                            i <= _importance
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: const Color(0xFFFFC857),
                            size: 30,
                          ),
                        ),
                    ],
                  ),
                  label('الصور'),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      for (final name in _images)
                        _Thumb(
                          store: _imageStore,
                          name: name,
                          onRemove: () => _removeImage(name),
                        ),
                      OutlinedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('إضافة صور'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    key: const Key('save_memory_button'),
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(_isEdit ? 'حفظ التعديلات' : 'حفظ الذكرى'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Color(value),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 3,
          ),
        ),
        child: selected
            ? const Icon(Icons.check_rounded, size: 20, color: Colors.black87)
            : null,
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? color.withValues(alpha: 0.22) : Colors.transparent,
          border: Border.all(
            color: selected
                ? color
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(icon, color: selected ? color : null),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.store,
    required this.name,
    required this.onRemove,
  });

  final ImageStore store;
  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                store.fileFor(name),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) =>
                    const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          PositionedDirectional(
            top: 2,
            end: 2,
            child: InkWell(
              onTap: onRemove,
              child: const CircleAvatar(
                radius: 11,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
