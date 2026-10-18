import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/home/screens/home_screen.dart';
import '../../features/food_diary/screens/diary_screen.dart';
import '../../features/food_diary/screens/add_meal_screen.dart';
import '../../features/food_diary/screens/meal_detail_screen.dart';
import '../../features/meal_evaluation/screens/meal_result_screen.dart';
import '../../features/meal_evaluation/screens/suggestions_screen.dart';
import '../../features/meal_evaluation/screens/meal_photo_analysis_screen.dart';
import '../../features/meal_evaluation/services/meal_photo_analyzer.dart';
import '../../features/knowledge/screens/knowledge_screen.dart';
import '../../features/knowledge/screens/article_detail_screen.dart';
import '../../features/user_progress/screens/progress_screen.dart';
import '../../features/user_progress/screens/profile_screen.dart';
import '../../features/user_progress/screens/settings_screen.dart';
import '../../features/food_diary/models/meal.dart';
import '../../features/knowledge/models/article.dart';
import '../../shared/services/app_state.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/diary', builder: (_, _) => const DiaryScreen()),
          GoRoute(path: '/learn', builder: (_, _) => const KnowledgeScreen()),
          GoRoute(path: '/progress', builder: (_, _) => const ProgressScreen()),
        ],
      ),
      GoRoute(
        path: '/add-meal',
        builder: (context, state) {
          final mealId = state.uri.queryParameters['mealId'];
          if (mealId != null) {
            final meal = context.read<AppState>().getMealById(mealId);
            if (meal == null) {
              return const InvalidRouteScreen(
                message: 'Bữa ăn này không còn tồn tại.',
              );
            }
            return AddMealScreen(meal: meal);
          }
          final extra = state.extra;
          if (extra == null) return const AddMealScreen();
          if (extra is Meal) return AddMealScreen(meal: extra);
          return const InvalidRouteScreen(
            message: 'Không thể mở dữ liệu bữa ăn.',
          );
        },
      ),
      GoRoute(
        path: '/analyze-meal',
        builder: (_, _) =>
            MealPhotoAnalysisScreen(analyzer: configuredMealPhotoAnalyzer()),
      ),
      GoRoute(
        path: '/meal/:mealId',
        builder: (_, state) =>
            MealDetailScreen(mealId: state.pathParameters['mealId']!),
      ),
      GoRoute(
        path: '/meal-result',
        builder: (_, state) {
          final extra = state.extra;
          if (extra is Meal) return MealResultScreen(meal: extra);
          return const InvalidRouteScreen(
            message: 'Cần có bữa ăn để xem kết quả đánh giá.',
          );
        },
      ),
      GoRoute(
        path: '/suggestions',
        builder: (_, state) {
          final extra = state.extra;
          if (extra == null) return const SuggestionsScreen();
          if (extra is Meal) return SuggestionsScreen(mealId: extra.id);
          return const InvalidRouteScreen(
            message: 'Không thể mở gợi ý cho bữa ăn này.',
          );
        },
      ),
      GoRoute(
        path: '/article',
        builder: (_, state) {
          final extra = state.extra;
          if (extra is Article) return ArticleDetailScreen(article: extra);
          return const InvalidRouteScreen(
            message: 'Cần có bài viết để mở trang này.',
          );
        },
      ),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    ],
  );
}

class InvalidRouteScreen extends StatelessWidget {
  const InvalidRouteScreen({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Không thể mở trang')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    ),
  );
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = ['/', '/diary', '/learn', '/progress'].indexOf(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (i) =>
            context.go(['/', '/diary', '/learn', '/progress'][i]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Nhật ký',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Học hỏi',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Tiến độ',
          ),
        ],
      ),
    );
  }
}
