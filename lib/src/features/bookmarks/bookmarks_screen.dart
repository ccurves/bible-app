import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'bookmark_providers.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarksProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: bookmarksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No bookmarks yet.'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final b = items[i];
              return Dismissible(
                key: ValueKey(b.id),
                background: Container(color: Colors.red.withValues(alpha: 0.2)),
                onDismissed: (_) => ref.read(bookmarkActionsProvider).remove(b.id),
                child: ListTile(
                  title: Text('${b.bookCode} ${b.chapter}:${b.verse}'),
                  subtitle: b.note == null ? null : Text(b.note!),
                  trailing: Text(b.translation),
                  onTap: () =>
                      context.push('/read/${b.translation}/${b.bookCode}/${b.chapter}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
