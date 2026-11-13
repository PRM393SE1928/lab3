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
import '../../features/user_progress/screens/health_suggestions_screen.dart';
import '../../features/user_progress/screens/settings_screen.dart';
import '../../features/food_diary/models/meal.dart';
import '../../features/knowledge/models/article.dart';
import '../../shared/services/app_state.dart';
import '../../features/meal_planner/screens/meal_planner_screen.dart';
import '../../features/auth/screens/auth_screen.dart';

class AppRouter {
  static GoRouter create({String initialLocation = '/'}) => GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (_, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/diary', builder: (_, _) => const DiaryScreen()),
          GoRoute(path: '/learn', builder: (_, _) => const KnowledgeScreen()),
          GoRoute(path: '/progress', builder: (_, _) => const ProgressScreen()),
          GoRoute(
            path: '/planner',
            builder: (_, _) => const MealPlannerScreen(),
          ),
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
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
        builder: (_, state) {
          final manual = state.uri.queryParameters['manual'] == 'true';
          return MealPhotoAnalysisScreen(
            analyzer: configuredMealPhotoAnalyzer(),
            initialManualMode: manual,
          );
        },
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
      GoRoute(
        path: '/health-suggestions',
        builder: (_, _) => const HealthSuggestionsScreen(),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
      GoRoute(
        path: '/planner/edit',
        builder: (context, state) {
          final id = state.uri.queryParameters['planId'];
          final dateText = state.uri.queryParameters['date'];
          final plan = id == null
              ? null
              : context.read<AppState>().getMealPlanById(id);
          DateTime? date;
          if (dateText != null) date = DateTime.tryParse(dateText);
          return MealPlanEditorScreen(plan: plan, date: date);
        },
      ),
      GoRoute(
        path: '/planner/detail/:planId',
        builder: (_, state) =>
            MealPlanDetailScreen(planId: state.pathParameters['planId']!),
      ),
      GoRoute(
        path: '/planner/shopping',
        builder: (_, _) => const ShoppingListScreen(),
      ),
    ],
  );

  static late GoRouter router;
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
  const AppShell({super.key, required this.child, required this.location});
  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context) {
    const routes = [
      '/',
      '/diary',
      '/learn',
      '/progress',
      '/planner',
      '/profile',
    ];
    final index = routes.indexOf(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (i) {
          context.go(routes[i]);
        },
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
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Kế hoạch',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}
