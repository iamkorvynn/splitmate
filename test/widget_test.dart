import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:splitmate/main.dart';
import 'package:splitmate/services/database_helper.dart';
import 'package:splitmate/widgets/balance_chip.dart';
import 'package:splitmate/widgets/member_avatar.dart';

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

  testWidgets('home shows empty state with no groups', (tester) async {
    await tester.pumpWidget(const SplitMateApp());
    await tester.pumpAndSettle();

    expect(find.text('SplitMate'), findsOneWidget);
    expect(find.text('No groups yet'), findsOneWidget);
    expect(find.text('Create your first group'), findsOneWidget);
  });

  testWidgets('tapping create opens the add-group screen', (tester) async {
    await tester.pumpWidget(const SplitMateApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create your first group'));
    await tester.pumpAndSettle();

    expect(find.text('New group'), findsOneWidget);
    expect(find.text('Group name'), findsOneWidget);
    expect(find.text('Members'), findsOneWidget);
  });

  testWidgets('creating a group shows it on the home screen', (tester) async {
    await tester.pumpWidget(const SplitMateApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create your first group'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Goa Trip');
    await tester.enterText(find.byType(TextField).last, 'Asha');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    await tester.enterText(find.byType(TextField).last, 'Ravi');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    await tester.tap(find.text('Create group'));
    await tester.pumpAndSettle();

    expect(find.text('Goa Trip'), findsOneWidget);
    expect(find.text('No groups yet'), findsNothing);
  });

  testWidgets('MemberAvatar shows initials', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MemberAvatar(name: 'Asha Rao'),
        ),
      ),
    );
    expect(find.text('AR'), findsOneWidget);
  });

  testWidgets('BalanceChip labels gets / owes / settled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              BalanceChip(balancePaise: 1250),
              BalanceChip(balancePaise: -500),
              BalanceChip(balancePaise: 0),
            ],
          ),
        ),
      ),
    );
    expect(find.text('gets ₹12.50'), findsOneWidget);
    expect(find.text('owes ₹5.00'), findsOneWidget);
    expect(find.text('settled'), findsOneWidget);
  });
}
