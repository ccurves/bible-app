import 'package:flutter/foundation.dart';

@immutable
class Verse {
  const Verse({
    required this.translation,
    required this.bookCode,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  final String translation;
  final String bookCode;
  final int chapter;
  final int verse;
  final String text;

  factory Verse.fromRow(Map<String, Object?> row) => Verse(
        translation: row['translation']! as String,
        bookCode: row['book_code']! as String,
        chapter: row['chapter']! as int,
        verse: row['verse']! as int,
        text: row['text']! as String,
      );
}

@immutable
class Book {
  const Book({
    required this.code,
    required this.name,
    required this.order,
    required this.testament,
  });

  final String code;
  final String name;
  final int order;
  final String testament; // 'OT' or 'NT'
}

@immutable
class Translation {
  const Translation({
    required this.id,
    required this.abbrev,
    required this.name,
    required this.language,
    required this.license,
  });

  final String id;
  final String abbrev;
  final String name;
  final String language;
  final String license;
}
