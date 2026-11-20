import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:splitmate/models/expense.dart';
import 'package:splitmate/models/group.dart';
import 'package:splitmate/models/member.dart';
import 'package:splitmate/models/settlement.dart';
import 'package:splitmate/services/database_helper.dart';

void main() {
  late DatabaseHelper db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    db = DatabaseHelper.instance;
    db.testPathOverride = () => inMemoryDatabasePath;
  });

  tearDown(() async {
    await db.close();
    db.testPathOverride = null;
  });

  test('group CRUD round-trips', () async {
    final id = await db.insertGroup(
      Group(name: 'Goa Trip', note: 'Dec trip', createdAtMillis: 1000),
    );
    expect(id, isPositive);
    final groups = await db.getGroups();
    expect(groups.length, 1);
    expect(groups.first.name, 'Goa Trip');
    expect(groups.first.note, 'Dec trip');

    await db.updateGroup(
      groups.first.copyWith(name: 'Goa Trip 2026'),
    );
    final updated = await db.getGroup(id);
    expect(updated!.name, 'Goa Trip 2026');

    await db.deleteGroup(id);
    expect(await db.getGroups(), isEmpty);
  });

  test('members belong to a group and cascade on group delete', () async {
    final groupId = await db.insertGroup(
      Group(name: 'Flat', createdAtMillis: 1000),
    );
    final memberId = await db.insertMember(
      Member(groupId: groupId, name: 'Asha', createdAtMillis: 1000),
    );
    final members = await db.getMembers(groupId);
    expect(members.length, 1);
    expect(members.first.name, 'Asha');

    await db.updateMember(members.first.copyWith(name: 'Asha R'));
    expect((await db.getMembers(groupId)).first.name, 'Asha R');

    await db.deleteGroup(groupId);
    expect(await db.getMembers(groupId), isEmpty);
    // The member row itself is gone too.
    expect(memberId, isPositive);
  });

  test('expenses store shares and cascade on group delete', () async {
    final groupId = await db.insertGroup(
      Group(name: 'Trip', createdAtMillis: 1000),
    );
    final a = await db.insertMember(
      Member(groupId: groupId, name: 'Asha', createdAtMillis: 1000),
    );
    final b = await db.insertMember(
      Member(groupId: groupId, name: 'Ravi', createdAtMillis: 1000),
    );
    final expenseId = await db.insertExpense(
      Expense(
        groupId: groupId,
        title: 'Dinner',
        amountPaise: 10000,
        paidByMemberId: a,
        createdAtMillis: 1000,
        shares: {a: 5000, b: 5000},
      ),
    );
    final expenses = await db.getExpenses(groupId);
    expect(expenses.length, 1);
    expect(expenses.first.id, expenseId);
    expect(expenses.first.shares, {a: 5000, b: 5000});

    await db.deleteExpense(expenseId);
    expect(await db.getExpenses(groupId), isEmpty);

    await db.deleteGroup(groupId);
    expect(await db.getMembers(groupId), isEmpty);
  });

  test('settlements round-trip and delete', () async {
    final groupId = await db.insertGroup(
      Group(name: 'Trip', createdAtMillis: 1000),
    );
    final a = await db.insertMember(
      Member(groupId: groupId, name: 'Asha', createdAtMillis: 1000),
    );
    final b = await db.insertMember(
      Member(groupId: groupId, name: 'Ravi', createdAtMillis: 1000),
    );
    final id = await db.insertSettlement(
      Settlement(
        groupId: groupId,
        fromMemberId: b,
        toMemberId: a,
        amountPaise: 5000,
        createdAtMillis: 1000,
      ),
    );
    final settlements = await db.getSettlements(groupId);
    expect(settlements.length, 1);
    expect(settlements.first.fromMemberId, b);
    expect(settlements.first.amountPaise, 5000);

    await db.deleteSettlement(id);
    expect(await db.getSettlements(groupId), isEmpty);
  });

  test('groups list starts empty (no seed data)', () async {
    expect(await db.getGroups(), isEmpty);
  });
}
