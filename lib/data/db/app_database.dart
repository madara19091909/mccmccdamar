import 'package:echo/data/models/memory_category.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  const AppDatabase._();

  static const int schemaVersion = 1;
  static const String fileName = 'echo.db';

  /// Opens (and creates on first launch) the local database.
  ///
  /// [factory] and [path] exist so tests can use an in-memory database.
  static Future<Database> open({DatabaseFactory? factory, String? path}) async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await getDatabasesPath(), fileName);
    return dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: _onCreate,
      ),
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    batch.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        icon TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
    batch.execute('''
      CREATE TABLE memories (
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL DEFAULT '',
        occurred_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        category_id TEXT NOT NULL,
        tags TEXT NOT NULL DEFAULT '[]',
        color INTEGER NOT NULL,
        icon TEXT NOT NULL DEFAULT 'star',
        importance INTEGER NOT NULL DEFAULT 3,
        images TEXT NOT NULL DEFAULT '[]'
      )
    ''');
    batch.execute(
        'CREATE INDEX idx_memories_occurred_at ON memories (occurred_at)');
    batch.execute(
        'CREATE INDEX idx_memories_category ON memories (category_id)');
    batch.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY NOT NULL,
        value TEXT NOT NULL
      )
    ''');
    for (final category in kDefaultCategories) {
      batch.insert('categories', category.toMap());
    }
    await batch.commit(noResult: true);
  }
}
