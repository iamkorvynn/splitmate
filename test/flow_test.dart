import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:splitmate/main.dart';
import 'package:splitmate/models/expense.dart';
import 'package:splitmate/models/group.dart';
import 'package:splitmate/models/member.dart';
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
Future<void> _waitForPop(WidgetTester tester, Type type) async {
  for (var i = 0; i < 20 && find.byType(type).evaluate().isNotEmpty; i++) {
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump(const Duration(milliseconds: 500));
  }
  await _settle(tester);
}

/// Polls until [finder] matches something, giving slow navigation and
/// DB work time to finish even when the VM is loaded.
Future<void> _waitForVisible(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 20 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump(const Duration(milliseconds: 500));
  }
}

/// Polls until [check] is true (via real async), giving slow DB work
/// time to finish even when the VM is loaded.
Future<void> _waitFor(
  WidgetTester tester,
  Future<bool> Function() check,
) async {
  for (var i = 0; i < 20; i++) {
    final done = await tester.runAsync(check);
    if (done == true) return;
    await tester.pump(const Duration(milliseconds: 500));
  }
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

  Future<void> createGroupViaUi(
    WidgetTester tester, {
    String name = 'Goa Trip',
    List<String> members = const ['Asha', 'Ravi', 'Meera'],
  }) async {
    await tester.pumpWidget(const SplitMateApp());
    await _settle(tester);
    await tester.tap(find.text('Create your first group'));
    await _waitForVisible(tester, find.text('Group name'));
    await tester.enterText(find.byType(TextFormField).first, name);
    for (final member in members) {
      await tester.enterText(find.byType(TextField).last, member);
      await tester.tap(find.byTooltip('Add member'));
      await tester.pump();
    }
    await tester.tap(find.text('Create group'));
    await _waitForPop(tester, AddGroupScreen);
    expect(find.text(name), findsOneWidget);
  }

  /// Seeds a group with three members and one ₹300 dinner expense
  /// (Asha paid, split equally) straight into the database.
  /// Returns the group id.
  Future<int> seedGroupWithExpense(WidgetTester tester) async {
    final groupId = await tester.runAsync(() async {
      final db = DatabaseHelper.instance;
      final now = DateTime.now().millisecondsSinceEpoch;
      final id = await db.insertGroup(
        Group(name: 'Goa Trip', createdAtMillis: now),
      );
      final ids = <int>[];
      for (final name in ['Asha', 'Ravi', 'Meera']) {
        ids.add(await db.insertMember(
          Member(groupId: id, name: name, createdAtMillis: now),
        ));
      }
      await db.insertExpense(
        Expense(
          groupId: id,
          title: 'Dinner',
          amountPaise: 30000,
          paidByMemberId: ids[0],
          createdAtMillis: now,
          shares: {ids[0]: 10000, ids[1]: 10000, ids[2]: 10000},
        ),
      );
      return id;
    });
    return groupId!;
  }

  Future<void> openGroup(WidgetTester tester) async {
    await tester.pumpWidget(const SplitMateApp());
    await _waitForVisible(tester, find.text('Goa Trip'));
    await tester.tap(find.text('Goa Trip'));
    await _waitFor(
      tester,
      () async => find.text('No expenses yet').evaluate().isNotEmpty ||
          find.text('Dinner').evaluate().isNotEmpty,
    );
    await _settle(tester);
  }

  testWidgets('expense form saves a correctly split expense',
      (tester) async {
    // Tall viewport so long forms fit without scrolling.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await createGroupViaUi(tester);
    await tester.tap(find.text('Goa Trip'));
    await _waitFor(
      tester,
      () async => find.text('No expenses yet').evaluate().isNotEmpty,
    );
    await _settle(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await _waitForVisible(tester, find.text('What was it for?'));
    await tester.enterText(find.byType(TextFormField).first, 'Dinner');
    await tester.enterText(find.byType(TextFormField).last, '300');
    await tester.tap(find.text('Save expense'));
    // Assert on the database, not the list reload timing.
    await _waitFor(tester, () async {
      final expenses =
          await DatabaseHelper.instance.getExpenses(1);
      return expenses.isNotEmpty;
    });
    final expenses = await tester.runAsync(
      () => DatabaseHelper.instance.getExpenses(1),
    );
    expect(expenses!.length, 1);
    expect(expenses.first.title, 'Dinner');
    expect(expenses.first.amountPaise, 30000);
    expect(expenses.first.shares.values.reduce((a, b) => a + b), 30000);
    expect(expenses.first.shares.values.toSet(), {10000});
  });

  testWidgets('balances tab shows correct balances and suggestions',
      (tester) async {
    await seedGroupWithExpense(tester);
    await openGroup(tester);

    expect(find.text('Dinner'), findsOneWidget);
    expect(find.text('₹300.00'), findsWidgets);

    await tester.tap(find.text('Balances'));
    await _settle(tester);
    expect(find.text('gets ₹200.00'), findsOneWidget);
    expect(find.text('owes ₹100.00'), findsWidgets);
    expect(find.text('Suggested settle-ups'), findsOneWidget);
  });

  testWidgets('settle all records payments and shows all settled',
      (tester) async {
    await seedGroupWithExpense(tester);
    await openGroup(tester);

    await tester.tap(find.text('Balances'));
    await _settle(tester);
    await tester.ensureVisible(find.text('Settle all at once'));
    await tester.pump();
    await tester.tap(find.text('Settle all at once'));
    await _settle(tester);
    // Confirm dialog.
    await tester.tap(find.text('Settle all').last);
    await _waitFor(
      tester,
      () async => find.text('All settled up!').evaluate().isNotEmpty,
    );
    await _settle(tester);
    expect(find.text('All settled up!'), findsOneWidget);

    final settlements = await tester.runAsync(
      () => DatabaseHelper.instance.getSettlements(1),
    );
    expect(settlements!.length, 2);
    expect(
      settlements.map((s) => s.amountPaise).reduce((a, b) => a + b),
      20000,
    );
  });
}
