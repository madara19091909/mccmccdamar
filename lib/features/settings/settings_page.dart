import 'dart:io';

import 'package:echo/core/constants.dart';
import 'package:echo/core/format.dart';
import 'package:echo/navigation/app_routes.dart';
import 'package:echo/services/backup_service.dart';
import 'package:echo/state/memory_controller.dart';
import 'package:echo/state/settings_controller.dart';
import 'package:echo/widgets/glass_card.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _busy = false;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _export() async {
    final backup = context.read<BackupService>();
    setState(() => _busy = true);
    try {
      final dir = await getTemporaryDirectory();
      final file = await backup.exportToFile(dir);
      await Share.shareXFiles(
        <XFile>[XFile(file.path)],
        subject: 'نسخة ECHO الاحتياطية',
      );
    } catch (_) {
      _snack('تعذّر تصدير النسخة الاحتياطية.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final backup = context.read<BackupService>();
    final controller = context.read<MemoryController>();
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['json'],
      );
      if (picked == null || picked.files.isEmpty) return;
      final path = picked.files.single.path;
      if (path == null) {
        _snack('تعذّر قراءة الملف المختار.');
        return;
      }
      setState(() => _busy = true);
      final source = await File(path).readAsString();
      final data = BackupService.parse(source);
      if (!mounted) return;
      final ok = await _confirm(
        title: 'استعادة النسخة الاحتياطية؟',
        message:
            'الملف صالح ويحتوي ${formatNumber(data.memories.length)} ذكرى. سيتم استبدال جميع بياناتك الحالية بمحتواه.',
        confirmLabel: 'استبدال واستعادة',
      );
      if (!ok) return;
      await backup.restoreData(data);
      await controller.load();
      _snack('تمت الاستعادة: ${formatNumber(data.memories.length)} ذكرى.');
    } on BackupFormatException catch (error) {
      _snack(error.message);
    } on FileSystemException {
      _snack('تعذّر قراءة الملف.');
    } catch (_) {
      _snack('فشلت الاستعادة. لم يتم تغيير بياناتك.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearAll() async {
    final controller = context.read<MemoryController>();
    final ok = await _confirm(
      title: 'حذف كل الذكريات؟',
      message:
          'سيتم حذف جميع الذكريات والصور نهائيًا من هذا الجهاز. يُنصح بتصدير نسخة احتياطية أولًا.',
      confirmLabel: 'حذف الكل',
    );
    if (!ok) return;
    final done = await controller.clearAllMemories();
    _snack(done ? 'تم حذف جميع الذكريات.' : 'تعذّر حذف البيانات.');
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.65);

    Widget section(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.secondary,
            ),
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'إعدادات ECHO',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (_busy) ...<Widget>[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
        section('المظهر'),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SegmentedButton<ThemeMode>(
                segments: const <ButtonSegment<ThemeMode>>[
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    label: Text('داكن'),
                    icon: Icon(Icons.dark_mode_rounded),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    label: Text('فاتح'),
                    icon: Icon(Icons.light_mode_rounded),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    label: Text('النظام'),
                    icon: Icon(Icons.phone_android_rounded),
                  ),
                ],
                selected: <ThemeMode>{settings.themeMode},
                onSelectionChanged: (selection) =>
                    settings.setThemeMode(selection.first),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                key: const Key('light_effects_switch'),
                contentPadding: EdgeInsets.zero,
                title: const Text('وضع الأداء الخفيف'),
                subtitle: const Text('يوقف حركة النجوم ويبسّط المؤثرات'),
                value: settings.lightEffects,
                onChanged: settings.setLightEffects,
              ),
            ],
          ),
        ),
        section('إدارة البيانات'),
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.category_rounded),
                title: const Text('إدارة التصنيفات'),
                onTap: () => AppRoutes.openCategories(context),
              ),
              ListTile(
                key: const Key('export_backup_tile'),
                leading: const Icon(Icons.upload_file_rounded),
                title: const Text('تصدير نسخة احتياطية'),
                subtitle: const Text('ملف JSON يتضمن ذكرياتك وصورك'),
                enabled: !_busy,
                onTap: _export,
              ),
              ListTile(
                key: const Key('import_backup_tile'),
                leading: const Icon(Icons.download_rounded),
                title: const Text('استيراد نسخة احتياطية'),
                subtitle: const Text('يتم التحقق من الملف قبل أي تغيير'),
                enabled: !_busy,
                onTap: _import,
              ),
              ListTile(
                leading: Icon(Icons.delete_forever_rounded,
                    color: theme.colorScheme.error),
                title: Text(
                  'حذف كل الذكريات',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: _busy ? null : _clearAll,
              ),
            ],
          ),
        ),
        section('عن التطبيق'),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('$kAppName - الإصدار $kAppVersion',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'عالمك الرقمي الشخصي للذكريات. جميع بياناتك تُحفظ على هذا الجهاز فقط، ولا يُرسل شيء إلى أي خادم.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: muted, height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
