import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:splitmate/main.dart';
import 'package:splitmate/screens/add_group_screen.dart';
import 'package:splitmate/services/database_helper.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

/// Waits until the add-group screen has popped (the save is async and
/// can be slow when the machine is loaded), then settles the home list.
Future<void> _waitForGroupCreated(WidgetTester tester) async {
  for (var i = 0;
      i < 10 && find.byType(AddGroupScreen).evaluate().isNotEmpty;
      i++) {
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 500)));
    await tester.pump(const Duration(milliseconds: 500));
  }
  await _settle(tester);
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    DatabaseHelper.instance.testPathOverride = () => inMemoryDatabasePath;
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
    DatabaseHelper.instance.testPathOverride = null;
  });

  Future<void> createGroup(
    WidgetTester tester, {
    String name = 'Goa Trip',
    List<String> members = const ['Asha', 'Ravi', 'Meera'],
  }) async {
    await tester.pumpWidget(const SplitMateApp());
    await _settle(tester);
    await tester.tap(find.text('Create your first group'));
    await _settle(tester);
    await tester.enterText(find.byType(TextFormField).first, name);
    for (final member in members) {
      await tester.enterText(find.byType(TextField).last, member);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
    }
    await tester.tap(find.text('Create group'));
    await _waitForGroupCreated(tester);
    expect(find.text(name), findsOneWidget);
  }

  testWidgets('full flow: expense splits and balances show', (tester) async {
    await createGroup(tester);

    // Open the group and wait for its data to load (empty state proves it).
    await tester.tap(find.text('Goa Trip'));
    for (var i = 0;
        i < 10 && find.text('No expenses yet').evaluate().isEmpty;
        i++) {
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pump(const Duration(milliseconds: 500));
    }
    await _settle(tester);
    expect(find.text('Expenses'), findsOneWidget);

    // Add a ₹300 expense paid by Asha, split equally among all three.
    await tester.tap(find.byType(FloatingActionButton));
    await _settle(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Dinner');
    await tester.enterText(find.byType(TextFormField).last, '300');
    await tester.ensureVisible(find.text('Save expense'));
    await tester.pump();
    await tester.tap(find.text('Save expense'));
    await _settle(tester);

    // Expense shows in the history.
    expect(find.text('Dinner'), findsOneWidget);
    expect(find.text('₹300.00'), findsOneWidget);

    // Balances tab: Asha gets ₹200, Ravi and Meera owe ₹100 each.
    await tester.tap(find.text('Balances'));
    await _settle(tester);
    expect(find.text('gets ₹200.00'), findsOneWidget);
    expect(find.text('owes ₹100.00'), findsWidgets);
    expect(find.text('Suggested settle-ups'), findsOneWidget);
  });
}
