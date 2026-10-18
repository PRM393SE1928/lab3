import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app_lab_2/features/food_diary/models/food_item.dart';
import 'package:mobile_app_lab_2/features/food_diary/widgets/food_picker_sheet.dart';

void main() {
  const catalog = [
    FoodItem(id: 'oat', name: 'Yến mạch', category: 'breakfast'),
    FoodItem(id: 'salad', name: 'Salad rau củ', category: 'lunch'),
    FoodItem(id: 'fish', name: 'Cá hấp gừng', category: 'dinner'),
  ];

  Widget app({List<FoodItem> initial = const []}) => MaterialApp(
    home: Scaffold(
      body: FoodPickerSheet(catalog: catalog, initialSelection: initial),
    ),
  );

  testWidgets('searches, selects multiple foods and preserves selections', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    await tester.tap(find.text('Yến mạch'));
    await tester.ensureVisible(find.text('Salad rau củ'));
    await tester.tap(find.text('Salad rau củ'));
    await tester.pump();
    expect(find.text('Xong (2)'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'cá');
    expect(find.text('Cá hấp gừng'), findsOneWidget);
    expect(find.text('Yến mạch'), findsWidgets);

    await tester.ensureVisible(find.text('Cá hấp gừng'));
    await tester.tap(find.text('Cá hấp gừng'));
    await tester.pump();
    expect(find.text('Xong (3)'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Bữa tối'));
    expect(find.text('Cá hấp gừng'), findsNWidgets(2));
  });

  testWidgets('category filters and manual item are available', (tester) async {
    await tester.pumpWidget(app());

    await tester.ensureVisible(
      find.byKey(const ValueKey('food-category-breakfast')),
    );
    await tester.tap(find.byKey(const ValueKey('food-category-breakfast')));
    await tester.pump();
    expect(find.text('Yến mạch'), findsOneWidget);
    expect(find.byKey(const ValueKey('food-item-salad')), findsNothing);

    await tester.enterText(find.byType(TextField), 'Món nhà làm');
    await tester.pump();
    await tester.ensureVisible(find.byType(TextButton).last);
    await tester.tap(find.byType(TextButton).last);
    await tester.pump();
    expect(find.text('Món nhà làm'), findsWidgets);
    expect(find.text('Món nhập thủ công'), findsNothing);
    await tester.ensureVisible(find.text('Xong (1)'));
    await tester.tap(find.text('Xong (1)'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel does not return the draft selection', (tester) async {
    List<FoodItem>? result = const [];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showFoodPicker(
                context,
                catalog: catalog,
                initialSelection: const [],
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yến mạch'));
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
