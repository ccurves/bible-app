import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

import '../db/database.dart';

/// Imports bundled Bible JSON files into SQLite on first launch.
///
/// Expected asset layout (one file per translation):
///   assets/bibles/manifest.json   -> [{"id":"KJV","file":"kjv.json",...}, ...]
///   assets/bibles/kjv.json        -> see [_TranslationJson] format below
///
/// Translation JSON format:
/// {
///   "id": "KJV",
///   "abbrev": "KJV",
///   "name": "King James Version",
///   "language": "en",
///   "license": "Public Domain",
///   "books": [
///     {
///       "code": "GEN", "name": "Genesis", "order": 1, "testament": "OT",
///       "chapters": [
///         {"number": 1, "verses": [{"number": 1, "text": "In the beginning..."}]}
///       ]
///     }
///   ]
/// }
class BibleImporter {
  BibleImporter(this._db);

  final BibleDb _db;

  Future<void> ensureSeeded() async {
    final existing = await _db.db.query('translations', limit: 1);
    if (existing.isNotEmpty) return;

    final manifestRaw = await _tryLoadAsset('assets/bibles/manifest.json');
    if (manifestRaw == null) return; // No bundled data yet — app runs empty.

    final manifest = (jsonDecode(manifestRaw) as List).cast<Map<String, Object?>>();
    for (final entry in manifest) {
      final file = entry['file']! as String;
      final raw = await rootBundle.loadString('assets/bibles/$file');
      final json = jsonDecode(raw) as Map<String, Object?>;
      await _importTranslation(json);
    }
  }

  Future<String?> _tryLoadAsset(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (_) {
      return null;
    }
  }

  Future<void> _importTranslation(Map<String, Object?> json) async {
    final id = json['id']! as String;
    await _db.db.transaction((txn) async {
      await txn.insert('translations', {
        'id': id,
        'abbrev': json['abbrev'] ?? id,
        'name': json['name'] ?? id,
        'language': json['language'] ?? 'en',
        'license': json['license'] ?? 'Public Domain',
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      final books = (json['books'] as List).cast<Map<String, Object?>>();
      final batch = txn.batch();
      for (final book in books) {
        final code = book['code']! as String;
        batch.insert('books', {
          'translation_id': id,
          'code': code,
          'name': book['name']! as String,
          'book_order': book['order']! as int,
          'testament': book['testament']! as String,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        final chapters = (book['chapters'] as List).cast<Map<String, Object?>>();
        for (final chapter in chapters) {
          final chNum = chapter['number']! as int;
          final verses = (chapter['verses'] as List).cast<Map<String, Object?>>();
          for (final v in verses) {
            final vNum = v['number']! as int;
            final text = v['text']! as String;
            batch.insert('verses', {
              'translation': id,
              'book_code': code,
              'chapter': chNum,
              'verse': vNum,
              'text': text,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
            batch.insert('verses_fts', {
              'text': text,
              'translation': id,
              'book_code': code,
              'chapter': chNum,
              'verse': vNum,
            });
          }
        }
      }
      await batch.commit(noResult: true);
    });
  }
}
