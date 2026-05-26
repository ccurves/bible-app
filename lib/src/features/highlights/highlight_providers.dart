import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../../data/bible_repository.dart';
import '../../models/verse.dart';

final highlightForVerseProvider =
    FutureProvider.family<Color?, Verse>((ref, v) async {
  final db = await ref.watch(bibleDbProvider.future);
  final rows = await db.db.query(
    'highlights',
    columns: ['color'],
    where: 'translation = ? AND book_code = ? AND chapter = ? AND verse = ?',
    whereArgs: [v.translation, v.bookCode, v.chapter, v.verse],
    limit: 1,
  );
  if (rows.isEmpty) return null;
  return Color(rows.first['color']! as int);
});

final highlightActionsProvider = Provider<HighlightActions>((ref) {
  return HighlightActions(ref);
});

class HighlightActions {
  HighlightActions(this._ref);
  final Ref _ref;

  Future<void> set(Verse v, Color color) async {
    final db = await _ref.read(bibleDbProvider.future);
    await db.db.insert(
      'highlights',
      {
        'translation': v.translation,
        'book_code': v.bookCode,
        'chapter': v.chapter,
        'verse': v.verse,
        'color': color.value,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _ref.invalidate(highlightForVerseProvider(v));
  }

  Future<void> clear(Verse v) async {
    final db = await _ref.read(bibleDbProvider.future);
    await db.db.delete(
      'highlights',
      where: 'translation = ? AND book_code = ? AND chapter = ? AND verse = ?',
      whereArgs: [v.translation, v.bookCode, v.chapter, v.verse],
    );
    _ref.invalidate(highlightForVerseProvider(v));
  }
}
