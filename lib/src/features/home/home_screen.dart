import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/bible_repository.dart';
import '../../models/verse.dart';

final _translationsProvider = FutureProvider<List<Translation>>((ref) async {
  return ref.read(bibleRepositoryProvider).translations();
});

final selectedTranslationProvider = StateProvider<String?>((ref) => null);

final _booksProvider = FutureProvider.family<List<Book>, String>((ref, translationId) async {
  return ref.read(bibleRepositoryProvider).books(translationId);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translationsAsync = ref.watch(_translationsProvider);
    final selected = ref.watch(selectedTranslationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () => context.push('/bookmarks'),
          ),
        ],
      ),
      body: translationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (translations) {
          if (translations.isEmpty) {
            return const _EmptyState();
          }
          final current = selected ?? translations.first.id;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  initialValue: current,
                  decoration: const InputDecoration(
                    labelText: 'Translation',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final t in translations)
                      DropdownMenuItem(value: t.id, child: Text('${t.abbrev} — ${t.name}')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(selectedTranslationProvider.notifier).state = v;
                    }
                  },
                ),
              ),
              Expanded(child: _BookList(translationId: current)),
            ],
          );
        },
      ),
    );
  }
}

class _BookList extends ConsumerWidget {
  const _BookList({required this.translationId});
  final String translationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(_booksProvider(translationId));
    return booksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load books: $e')),
      data: (books) => ListView.separated(
        itemCount: books.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final b = books[i];
          return ListTile(
            title: Text(b.name),
            trailing: Text(b.testament, style: Theme.of(context).textTheme.labelSmall),
            onTap: () => context.push('/read/$translationId/${b.code}/1'),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Text(
          'No Bible translations bundled yet.\n\n'
          'Add JSON files to assets/bibles/ and a manifest.json that lists them. '
          'See assets/bibles/sample.json for the expected format.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
