import 'package:echo/app.dart';
import 'package:echo/data/db/app_database.dart';
import 'package:echo/data/image_store.dart';
import 'package:echo/data/repositories/sqlite_memory_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('ar');
    final database = await AppDatabase.open();
    final repository = SqliteMemoryRepository(database);
    final imageStore = await FileImageStore.create();
    runApp(EchoApp(repository: repository, imageStore: imageStore));
  } catch (error) {
    debugPrint('ECHO: startup failed (${error.runtimeType})');
    runApp(const _StartupErrorApp());
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                'تعذّر فتح قاعدة بيانات ECHO على هذا الجهاز.\nأعد تشغيل التطبيق، وإن استمرت المشكلة تأكد من توفر مساحة تخزين كافية.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
