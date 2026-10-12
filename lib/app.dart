import 'package:echo/core/constants.dart';
import 'package:echo/core/theme/app_theme.dart';
import 'package:echo/data/image_store.dart';
import 'package:echo/data/repositories/memory_repository.dart';
import 'package:echo/navigation/app_shell.dart';
import 'package:echo/services/backup_service.dart';
import 'package:echo/state/memory_controller.dart';
import 'package:echo/state/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

class EchoApp extends StatefulWidget {
  const EchoApp({
    super.key,
    required this.repository,
    required this.imageStore,
  });

  final MemoryRepository repository;
  final ImageStore imageStore;

  @override
  State<EchoApp> createState() => _EchoAppState();
}

class _EchoAppState extends State<EchoApp> {
  late final MemoryController _memories;
  late final SettingsController _settings;
  late final BackupService _backup;

  @override
  void initState() {
    super.initState();
    _memories = MemoryController(
      repository: widget.repository,
      imageStore: widget.imageStore,
    );
    _settings = SettingsController(widget.repository);
    _backup = BackupService(
      repository: widget.repository,
      imageStore: widget.imageStore,
    );
    _memories.load();
    _settings.load();
  }

  @override
  void dispose() {
    _memories.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MemoryController>.value(value: _memories),
        ChangeNotifierProvider<SettingsController>.value(value: _settings),
        Provider<BackupService>.value(value: _backup),
        Provider<ImageStore>.value(value: widget.imageStore),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: kAppName,
            debugShowCheckedModeBanner: false,
            locale: const Locale('ar'),
            supportedLocales: const <Locale>[Locale('ar')],
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: settings.themeMode,
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
