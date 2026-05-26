import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../db/database.dart';
import '../models/verse.dart';
import 'bible_importer.dart';

final bibleDbProvider = FutureProvider<BibleDb>((ref) async {
  final db = await BibleDb.open();
  await BibleImporter(db).ensureSeeded();
  return db;
});

final bibleRepositoryProvider = Provider<BibleRepository>((ref) {
  return BibleRepository(ref);
});

class BibleRepository {
  BibleRepository(this._ref);

  final Ref _ref;

  Future<Database> get _db async => (await _ref.read(bibleDbProvider.future)).db;

  Future<List<Translation>> translations() async {
    final rows = await (await _db).query('translations', orderBy: 'abbrev');
    return rows
        .map((r) => Translation(
              id: r['id']! as String,
              abbrev: r['abbrev']! as String,
              name: r['name']! as String,
              language: r['language']! as String,
              license: r['license']! as String,
            ))
        .toList();
  }

  Future<List<Book>> books(String translationId) async {
    final rows = await (await _db).query(
      'books',
      where: 'translation_id = ?',
      whereArgs: [translationId],
      orderBy: 'book_order',
    );
    return rows
        .map((r) => Book(
              code: r['code']! as String,
              name: r['name']! as String,
              order: r['book_order']! as int,
              testament: r['testament']! as String,
            ))
        .toList();
  }

  Future<int> chapterCount(String translationId, String bookCode) async {
    final rows = await (await _db).rawQuery(
      'SELECT MAX(chapter) AS c FROM verses WHERE translation = ? AND book_code = ?',
      [translationId, bookCode],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<List<Verse>> chapter(String translation, String bookCode, int chapter) async {
    final rows = await (await _db).query(
      'verses',
      where: 'translation = ? AND book_code = ? AND chapter = ?',
      whereArgs: [translation, bookCode, chapter],
      orderBy: 'verse',
    );
    return rows.map(Verse.fromRow).toList();
  }

  Future<List<Verse>> search(String query, {String? translation, int limit = 100}) async {
    if (query.trim().isEmpty) return const [];
    final args = <Object?>[query];
    var sql = '''
      SELECT v.translation, v.book_code, v.chapter, v.verse, v.text
      FROM verses_fts f
      JOIN verses v
        ON v.translation = f.translation
       AND v.book_code = f.book_code
       AND v.chapter = f.chapter
       AND v.verse = f.verse
      WHERE verses_fts MATCH ?
    ''';
    if (translation != null) {
      sql += ' AND f.translation = ?';
      args.add(translation);
    }
    sql += ' LIMIT ?';
    args.add(limit);
    final rows = await (await _db).rawQuery(sql, args);
    return rows.map(Verse.fromRow).toList();
  }
}
