import 'package:flutter_test/flutter_test.dart';

import 'package:bible_app/src/models/reference.dart';

void main() {
  test('Reference equality and toString', () {
    const a = Reference(translation: 'KJV', bookCode: 'JHN', chapter: 3, verse: 16);
    const b = Reference(translation: 'KJV', bookCode: 'JHN', chapter: 3, verse: 16);
    expect(a, equals(b));
    expect(a.toString(), 'KJV JHN 3:16');
  });
}
