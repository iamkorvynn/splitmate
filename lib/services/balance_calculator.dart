import '../models/expense.dart';
import '../models/settlement.dart';

/// Pure balance math for SplitMate. No I/O, no Flutter imports,
/// so it is easy to unit test.
///
/// Balances are in paise. A positive balance means the member is owed
/// money by the group; a negative balance means they owe money.
class BalanceCalculator {
  /// Net balance per member id from a list of expenses and settlements.
  static Map<int, int> computeBalances({
    required List<int> memberIds,
    required List<Expense> expenses,
    required List<Settlement> settlements,
  }) {
    final balances = <int, int>{for (final id in memberIds) id: 0};

    for (final expense in expenses) {
      // The payer fronted the whole amount.
      balances[expense.paidByMemberId] =
          (balances[expense.paidByMemberId] ?? 0) + expense.amountPaise;
      // Each participant owes their share.
      for (final entry in expense.shares.entries) {
        balances[entry.key] = (balances[entry.key] ?? 0) - entry.value;
      }
    }

    for (final settlement in settlements) {
      // The debtor pays down what they owe; the creditor is paid back.
      balances[settlement.fromMemberId] =
          (balances[settlement.fromMemberId] ?? 0) + settlement.amountPaise;
      balances[settlement.toMemberId] =
          (balances[settlement.toMemberId] ?? 0) - settlement.amountPaise;
    }

    return balances;
  }

  /// Total spent in the group (sum of all expenses, paise).
  static int totalSpent(List<Expense> expenses) {
    var total = 0;
    for (final expense in expenses) {
      total += expense.amountPaise;
    }
    return total;
  }

  /// Total amount already settled in the group (paise).
  static int totalSettled(List<Settlement> settlements) {
    var total = 0;
    for (final settlement in settlements) {
      total += settlement.amountPaise;
    }
    return total;
  }

  /// Greedy minimum-cash-flow simplification: pair the biggest debtor
  /// with the biggest creditor until every balance is zero.
  /// The number of payments is at most (number of members - 1).
  static List<SuggestedPayment> simplifyDebts(Map<int, int> balances) {
    final creditors = <MapEntry<int, int>>[];
    final debtors = <MapEntry<int, int>>[];

    for (final entry in balances.entries) {
      if (entry.value > 0) {
        creditors.add(entry);
      } else if (entry.value < 0) {
        debtors.add(MapEntry(entry.key, -entry.value));
      }
    }

    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => b.value.compareTo(a.value));

    final payments = <SuggestedPayment>[];
    var i = 0;
    var j = 0;
    final creditorAmounts = creditors.map((e) => e.value).toList();
    final debtorAmounts = debtors.map((e) => e.value).toList();

    while (i < creditors.length && j < debtors.length) {
      final amount = creditorAmounts[i] < debtorAmounts[j]
          ? creditorAmounts[i]
          : debtorAmounts[j];
      payments.add(SuggestedPayment(
        fromMemberId: debtors[j].key,
        toMemberId: creditors[i].key,
        amountPaise: amount,
      ));
      creditorAmounts[i] -= amount;
      debtorAmounts[j] -= amount;
      if (creditorAmounts[i] == 0) i++;
      if (debtorAmounts[j] == 0) j++;
    }

    return payments;
  }
}
