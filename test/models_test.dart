import 'package:flutter_test/flutter_test.dart';
import 'package:splitmate/models/expense.dart';
import 'package:splitmate/models/group.dart';
import 'package:splitmate/models/member.dart';
import 'package:splitmate/models/settlement.dart';

void main() {
  group('Group', () {
    test('toMap/fromMap round-trips', () {
      const group = Group(
        id: 1,
        name: 'Goa Trip',
        note: 'Dec trip',
        createdAtMillis: 1700000000000,
      );
      final restored = Group.fromMap(group.toMap());
      expect(restored.id, 1);
      expect(restored.name, 'Goa Trip');
      expect(restored.note, 'Dec trip');
      expect(restored.createdAtMillis, 1700000000000);
    });

    test('note can be null', () {
      const group = Group(name: 'Flat', createdAtMillis: 1000);
      expect(Group.fromMap(group.toMap()).note, isNull);
    });

    test('copyWith keeps unchanged fields', () {
      const group = Group(id: 2, name: 'A', createdAtMillis: 5);
      final copy = group.copyWith(name: 'B');
      expect(copy.id, 2);
      expect(copy.name, 'B');
      expect(copy.createdAtMillis, 5);
    });
  });

  group('Member', () {
    test('toMap/fromMap round-trips', () {
      const member = Member(
        id: 7,
        groupId: 1,
        name: 'Asha',
        createdAtMillis: 1700000000000,
      );
      final restored = Member.fromMap(member.toMap());
      expect(restored.id, 7);
      expect(restored.groupId, 1);
      expect(restored.name, 'Asha');
      expect(restored.createdAtMillis, 1700000000000);
    });

    test('copyWith renames only the name', () {
      const member = Member(groupId: 1, name: 'Asha', createdAtMillis: 5);
      final copy = member.copyWith(name: 'Asha R');
      expect(copy.name, 'Asha R');
      expect(copy.groupId, 1);
    });
  });

  group('Expense', () {
    test('toMap/fromMap round-trips without shares', () {
      const expense = Expense(
        id: 3,
        groupId: 1,
        title: 'Dinner',
        amountPaise: 30000,
        paidByMemberId: 1,
        createdAtMillis: 1700000000000,
      );
      final restored = Expense.fromMap(expense.toMap());
      expect(restored.id, 3);
      expect(restored.title, 'Dinner');
      expect(restored.amountPaise, 30000);
      expect(restored.paidByMemberId, 1);
    });

    test('shares are preserved by copyWith', () {
      const expense = Expense(
        groupId: 1,
        title: 'Taxi',
        amountPaise: 10000,
        paidByMemberId: 2,
        createdAtMillis: 5,
        shares: {1: 5000, 2: 5000},
      );
      final copy = expense.copyWith(title: 'Cab');
      expect(copy.title, 'Cab');
      expect(copy.shares, {1: 5000, 2: 5000});
    });
  });

  group('Settlement', () {
    test('toMap/fromMap round-trips', () {
      const settlement = Settlement(
        id: 9,
        groupId: 1,
        fromMemberId: 2,
        toMemberId: 1,
        amountPaise: 10000,
        createdAtMillis: 1700000000000,
      );
      final restored = Settlement.fromMap(settlement.toMap());
      expect(restored.id, 9);
      expect(restored.fromMemberId, 2);
      expect(restored.toMemberId, 1);
      expect(restored.amountPaise, 10000);
    });

    test('SuggestedPayment holds the payment triple', () {
      const payment = SuggestedPayment(
        fromMemberId: 2,
        toMemberId: 1,
        amountPaise: 4500,
      );
      expect(payment.fromMemberId, 2);
      expect(payment.toMemberId, 1);
      expect(payment.amountPaise, 4500);
    });
  });
}
