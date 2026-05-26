import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/bible_repository.dart';
import '../../db/database.dart';
import '../../models/verse.dart';

class BookmarkRecord {
  BookmarkRecord({
    required this.id,
    required this.translation,
    required this.bookCode,
    required this.chapter,
    required this.verse,
    required this.note,
    required this.createdAt,
  });

  final int id;
  final String translation;
  final String bookCode;
  final int chapter;
  final int verse;
  final String? note;
  final DateTime createdAt;
}

final bookmarksProvider = FutureProvider<List<BookmarkRecord>>((ref) async {
  final db = await ref.watch(bibleDbProvider.future);
  return _loadBookmarks(db);
});

Future<List<BookmarkRecord>> _loadBookmarks(BibleDb db) async {
  final rows = await db.db.query('bookmarks', orderBy: 'created_at DESC');
  return rows
      .map((r) => BookmarkRecord(
            id: r['id']! as int,
            translation: r['translation']! as String,
            bookCode: r['book_code']! as String,
            chapter: r['chapter']! as int,
            verse: r['verse']! as int,
            note: r['note'] as String?,
            createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at']! as int),
          ))
      .toList();
}

final bookmarkActionsProvider = Provider<BookmarkActions>((ref) {
  return BookmarkActions(ref);
});

class BookmarkActions {
  BookmarkActions(this._ref);
  final Ref _ref;

  Future<void> add(Verse v, {String? note}) async {
    final db = await _ref.read(bibleDbProvider.future);
    await db.db.insert('bookmarks', {
      'translation': v.translation,
      'book_code': v.bookCode,
      'chapter': v.chapter,
      'verse': v.verse,
      'note': note,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    _ref.invalidate(bookmarksProvider);
  }

  Future<void> remove(int id) async {
    final db = await _ref.read(bibleDbProvider.future);
    await db.db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
    _ref.invalidate(bookmarksProvider);
  }
}
