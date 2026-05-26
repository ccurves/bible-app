import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/bible_repository.dart';
import '../../models/verse.dart';
import '../home/home_screen.dart';

final _queryProvider = StateProvider<String>((ref) => '');

final _resultsProvider = FutureProvider<List<Verse>>((ref) async {
  final query = ref.watch(_queryProvider);
  if (query.trim().length < 2) return const [];
  final translation = ref.watch(selectedTranslationProvider);
  return ref.read(bibleRepositoryProvider).search(query, translation: translation);
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      ref.read(_queryProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(_resultsProvider);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search the Bible',
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
        ),
      ),
      body: resultsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Search failed: $e')),
        data: (results) {
          if (results.isEmpty) {
            return const Center(child: Text('Type to search.'));
          }
          return ListView.separated(
            itemCount: results.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final v = results[i];
              return ListTile(
                title: Text('${v.bookCode} ${v.chapter}:${v.verse}'),
                subtitle: Text(v.text, maxLines: 3, overflow: TextOverflow.ellipsis),
                onTap: () => context.push('/read/${v.translation}/${v.bookCode}/${v.chapter}'),
              );
            },
          );
        },
      ),
    );
  }
}
