import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class BibleDb {
  BibleDb._(this._db);

  final Database _db;
  Database get db => _db;

  static Future<BibleDb> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'bible.db');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: _create,
    );
    return BibleDb._(db);
  }

  static Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE translations (
        id TEXT PRIMARY KEY,
        abbrev TEXT NOT NULL,
        name TEXT NOT NULL,
        language TEXT NOT NULL,
        license TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE books (
        translation_id TEXT NOT NULL,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        book_order INTEGER NOT NULL,
        testament TEXT NOT NULL,
        PRIMARY KEY (translation_id, code),
        FOREIGN KEY (translation_id) REFERENCES translations(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE verses (
        translation TEXT NOT NULL,
        book_code TEXT NOT NULL,
        chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL,
        text TEXT NOT NULL,
        PRIMARY KEY (translation, book_code, chapter, verse)
      );
    ''');

    await db.execute('CREATE INDEX idx_verses_lookup ON verses(translation, book_code, chapter);');

    // FTS5 virtual table mirrors verse text for search.
    await db.execute('''
      CREATE VIRTUAL TABLE verses_fts USING fts5(
        text,
        translation UNINDEXED,
        book_code UNINDEXED,
        chapter UNINDEXED,
        verse UNINDEXED,
        tokenize = 'porter unicode61'
      );
    ''');

    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        translation TEXT NOT NULL,
        book_code TEXT NOT NULL,
        chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL,
        note TEXT,
        created_at INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE highlights (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        translation TEXT NOT NULL,
        book_code TEXT NOT NULL,
        chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL,
        color INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        UNIQUE (translation, book_code, chapter, verse)
      );
    ''');
  }

  Future<void> close() => _db.close();
}
