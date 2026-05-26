import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/bible_repository.dart';
import '../../models/verse.dart';
import '../bookmarks/bookmark_providers.dart';
import '../highlights/highlight_providers.dart';

final _chapterProvider =
    FutureProvider.family<List<Verse>, (String, String, int)>((ref, key) async {
  final (translation, book, chapter) = key;
  return ref.read(bibleRepositoryProvider).chapter(translation, book, chapter);
});

final _chapterCountProvider =
    FutureProvider.family<int, (String, String)>((ref, key) async {
  final (translation, book) = key;
  return ref.read(bibleRepositoryProvider).chapterCount(translation, book);
});

class ReaderScreen extends ConsumerWidget {
  const ReaderScreen({
    super.key,
    required this.translation,
    required this.bookCode,
    required this.chapter,
  });

  final String translation;
  final String bookCode;
  final int chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versesAsync = ref.watch(_chapterProvider((translation, bookCode, chapter)));
    final maxChapterAsync = ref.watch(_chapterCountProvider((translation, bookCode)));

    return Scaffold(
      appBar: AppBar(
        title: Text('$bookCode $chapter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: versesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (verses) {
          if (verses.isEmpty) {
            return const Center(child: Text('Chapter not available.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: verses.length,
            itemBuilder: (context, i) => _VerseTile(verse: verses[i]),
          );
        },
      ),
      bottomNavigationBar: maxChapterAsync.maybeWhen(
        data: (max) => _ChapterNav(
          translation: translation,
          bookCode: bookCode,
          chapter: chapter,
          maxChapter: max,
        ),
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}

class _VerseTile extends ConsumerWidget {
  const _VerseTile({required this.verse});
  final Verse verse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlightAsync = ref.watch(highlightForVerseProvider(verse));
    final color = highlightAsync.maybeWhen(data: (c) => c, orElse: () => null);

    return InkWell(
      onLongPress: () => _showVerseActions(context, ref, verse),
      child: Container(
        color: color,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyLarge,
            children: [
              TextSpan(
                text: '${verse.verse} ',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              TextSpan(text: verse.text),
            ],
          ),
        ),
      ),
    );
  }

  void _showVerseActions(BuildContext context, WidgetRef ref, Verse v) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark_add_outlined),
              title: const Text('Bookmark'),
              onTap: () {
                ref.read(bookmarkActionsProvider).add(v);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.format_color_fill),
              title: const Text('Highlight'),
              onTap: () async {
                Navigator.of(context).pop();
                final color = await _pickColor(context);
                if (color != null) {
                  await ref.read(highlightActionsProvider).set(v, color);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.format_color_reset),
              title: const Text('Clear highlight'),
              onTap: () {
                ref.read(highlightActionsProvider).clear(v);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<Color?> _pickColor(BuildContext context) {
    const swatches = <Color>[
      Color(0x66FFEB3B),
      Color(0x66A5D6A7),
      Color(0x6690CAF9),
      Color(0x66F48FB1),
      Color(0x66FFAB91),
    ];
    return showModalBottomSheet<Color>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            children: [
              for (final c in swatches)
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(c),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterNav extends StatelessWidget {
  const _ChapterNav({
    required this.translation,
    required this.bookCode,
    required this.chapter,
    required this.maxChapter,
  });

  final String translation;
  final String bookCode;
  final int chapter;
  final int maxChapter;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.chevron_left),
            label: const Text('Prev'),
            onPressed: chapter > 1
                ? () => context.go('/read/$translation/$bookCode/${chapter - 1}')
                : null,
          ),
          Text('$chapter / $maxChapter'),
          TextButton.icon(
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
            onPressed: chapter < maxChapter
                ? () => context.go('/read/$translation/$bookCode/${chapter + 1}')
                : null,
          ),
        ],
      ),
    );
  }
}
