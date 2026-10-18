import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app_lab_2/features/knowledge/screens/article_detail_screen.dart';
import 'package:mobile_app_lab_2/features/knowledge/screens/knowledge_screen.dart';
import 'package:mobile_app_lab_2/shared/services/app_state.dart';
import 'package:mobile_app_lab_2/shared/services/mock_repository.dart';
import 'package:provider/provider.dart';

void main() {
  late AppState state;

  setUp(() {
    state = AppState(MockRepository());
  });

  Future<void> pumpKnowledge(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: KnowledgeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('searches article content and clears the filter', (tester) async {
    await pumpKnowledge(tester);

    await tester.enterText(find.byType(TextField), 'đũa');
    await tester.pump();
    expect(find.text('Niềm vui của việc ăn chậm'), findsOneWidget);
    expect(find.text('Đĩa ăn nhiều màu sắc tự nhiên'), findsNothing);

    await tester.tap(find.text('Đặt lại bộ lọc'));
    await tester.pump();
    expect(find.text('Đĩa ăn nhiều màu sắc tự nhiên'), findsOneWidget);
  });

  testWidgets('filters by topic and marks articles as read', (tester) async {
    await pumpKnowledge(tester);

    await tester.tap(find.text('Đa dạng thực phẩm'));
    await tester.pump();
    expect(find.text('Đĩa ăn nhiều màu sắc tự nhiên'), findsOneWidget);
    expect(find.text('Niềm vui của việc ăn chậm'), findsNothing);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          home: ArticleDetailScreen(article: state.articles[1]),
        ),
      ),
    );
    await tester.pump();
    expect(state.readArticleCount, 1);
  });
}
