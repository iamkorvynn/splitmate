import 'package:flutter_test/flutter_test.dart';
import 'package:splitmate/models/expense.dart';
import 'package:splitmate/models/settlement.dart';
import 'package:splitmate/services/balance_calculator.dart';

Expense _expense({
  int id = 1,
  int paidBy = 1,
  int amount = 30000,
  Map<int, int> shares = const {1: 10000, 2: 10000, 3: 10000},
}) {
  return Expense(
    id: id,
    groupId: 1,
    title: 'Dinner',
    amountPaise: amount,
    paidByMemberId: paidBy,
    createdAtMillis: 0,
    shares: shares,
  );
}

void main() {
  group('computeBalances', () {
    test('equal split: payer is owed, others owe', () {
      final balances = BalanceCalculator.computeBalances(
        memberIds: [1, 2, 3],
        expenses: [_expense()],
        settlements: [],
      );
      expect(balances[1], 20000);
      expect(balances[2], -10000);
      expect(balances[3], -10000);
    });

    test('balances always sum to zero', () {
      final balances = BalanceCalculator.computeBalances(
        memberIds: [1, 2, 3, 4],
        expenses: [
          _expense(id: 1, paidBy: 1, amount: 40000, shares: const {
            1: 10000,
            2: 10000,
            3: 10000,
            4: 10000,
          }),
          _expense(id: 2, paidBy: 3, amount: 20000, shares: const {
            1: 10000,
            3: 10000,
          }),
        ],
        settlements: [],
      );
      expect(balances.values.reduce((a, b) => a + b), 0);
    });

    test('custom shares are respected', () {
      final balances = BalanceCalculator.computeBalances(
        memberIds: [1, 2],
        expenses: [
          _expense(
            paidBy: 1,
            amount: 10000,
            shares: const {1: 7000, 2: 3000},
          ),
        ],
        settlements: [],
      );
      expect(balances[1], 3000);
      expect(balances[2], -3000);
    });

    test('payer excluded from split keeps the full amount', () {
      final balances = BalanceCalculator.computeBalances(
        memberIds: [1, 2],
        expenses: [
          _expense(paidBy: 1, amount: 10000, shares: const {2: 10000}),
        ],
        settlements: [],
      );
      expect(balances[1], 10000);
      expect(balances[2], -10000);
    });

    test('settlements move balances toward zero', () {
      final balances = BalanceCalculator.computeBalances(
        memberIds: [1, 2, 3],
        expenses: [_expense()],
        settlements: [
          const Settlement(
            groupId: 1,
            fromMemberId: 2,
            toMemberId: 1,
            amountPaise: 10000,
            createdAtMillis: 0,
          ),
        ],
      );
      expect(balances[1], 10000);
      expect(balances[2], 0);
      expect(balances[3], -10000);
    });

    test('full settlement zeroes all balances', () {
      final balances = BalanceCalculator.computeBalances(
        memberIds: [1, 2, 3],
        expenses: [_expense()],
        settlements: [
          const Settlement(
            groupId: 1,
            fromMemberId: 2,
            toMemberId: 1,
            amountPaise: 10000,
            createdAtMillis: 0,
          ),
          const Settlement(
            groupId: 1,
            fromMemberId: 3,
            toMemberId: 1,
            amountPaise: 10000,
            createdAtMillis: 0,
          ),
        ],
      );
      expect(balances.values.every((b) => b == 0), isTrue);
    });

    test('no expenses means zero balances', () {
      final balances = BalanceCalculator.computeBalances(
        memberIds: [1, 2],
        expenses: [],
        settlements: [],
      );
      expect(balances, {1: 0, 2: 0});
    });
  });

  group('totals', () {
    test('totalSpent sums expenses', () {
      expect(
        BalanceCalculator.totalSpent([
          _expense(id: 1, amount: 10000),
          _expense(id: 2, amount: 25000),
        ]),
        35000,
      );
    });

    test('totalSettled sums settlements', () {
      expect(
        BalanceCalculator.totalSettled([
          const Settlement(
            groupId: 1,
            fromMemberId: 2,
            toMemberId: 1,
            amountPaise: 4000,
            createdAtMillis: 0,
          ),
          const Settlement(
            groupId: 1,
            fromMemberId: 3,
            toMemberId: 1,
            amountPaise: 6000,
            createdAtMillis: 0,
          ),
        ]),
        10000,
      );
    });
  });

  group('simplifyDebts', () {
    test('single debtor and creditor produce one payment', () {
      final payments = BalanceCalculator.simplifyDebts({1: 10000, 2: -10000});
      expect(payments.length, 1);
      expect(payments.first.fromMemberId, 2);
      expect(payments.first.toMemberId, 1);
      expect(payments.first.amountPaise, 10000);
    });

    test('chain of debts collapses to fewer payments', () {
      // A is owed 100, B owes 60, C owes 40.
      final payments = BalanceCalculator.simplifyDebts(
        {1: 10000, 2: -6000, 3: -4000},
      );
      expect(payments.length, 2);
      var total = 0;
      for (final p in payments) {
        expect(p.toMemberId, 1);
        total += p.amountPaise;
      }
      expect(total, 10000);
    });

    test('settled balances produce no payments', () {
      expect(BalanceCalculator.simplifyDebts({1: 0, 2: 0}), isEmpty);
    });

    test('payments never exceed members minus one', () {
      final balances = {1: 30000, 2: -10000, 3: -10000, 4: -10000};
      final payments = BalanceCalculator.simplifyDebts(balances);
      expect(payments.length, lessThanOrEqualTo(3));
      // Applying the payments settles everyone.
      final settled = Map<int, int>.from(balances);
      for (final p in payments) {
        settled[p.fromMemberId] = settled[p.fromMemberId]! + p.amountPaise;
        settled[p.toMemberId] = settled[p.toMemberId]! - p.amountPaise;
      }
      expect(settled.values.every((b) => b == 0), isTrue);
    });

    test('complex multi-creditor case settles fully', () {
      final balances = {1: 15000, 2: 5000, 3: -8000, 4: -12000};
      final payments = BalanceCalculator.simplifyDebts(balances);
      final settled = Map<int, int>.from(balances);
      for (final p in payments) {
        settled[p.fromMemberId] = settled[p.fromMemberId]! + p.amountPaise;
        settled[p.toMemberId] = settled[p.toMemberId]! - p.amountPaise;
      }
      expect(settled.values.every((b) => b == 0), isTrue);
      expect(payments.length, lessThanOrEqualTo(3));
    });
  });
}
