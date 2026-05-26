import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/bookmarks/bookmarks_screen.dart';
import 'features/home/home_screen.dart';
import 'features/reader/reader_screen.dart';
import 'features/search/search_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/read/:translation/:book/:chapter',
        builder: (context, state) => ReaderScreen(
          translation: state.pathParameters['translation']!,
          bookCode: state.pathParameters['book']!,
          chapter: int.parse(state.pathParameters['chapter']!),
        ),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/bookmarks',
        builder: (context, state) => const BookmarksScreen(),
      ),
    ],
  );
});
