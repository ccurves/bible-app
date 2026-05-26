import 'package:flutter/foundation.dart';

@immutable
class Reference {
  const Reference({
    required this.translation,
    required this.bookCode,
    required this.chapter,
    this.verse,
  });

  final String translation;
  final String bookCode;
  final int chapter;
  final int? verse;

  Reference copyWith({
    String? translation,
    String? bookCode,
    int? chapter,
    int? verse,
  }) {
    return Reference(
      translation: translation ?? this.translation,
      bookCode: bookCode ?? this.bookCode,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Reference &&
      other.translation == translation &&
      other.bookCode == bookCode &&
      other.chapter == chapter &&
      other.verse == verse;

  @override
  int get hashCode => Object.hash(translation, bookCode, chapter, verse);

  @override
  String toString() => '$translation $bookCode $chapter${verse == null ? '' : ':$verse'}';
}
