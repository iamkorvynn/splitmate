import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../utils/money.dart';
import 'member_avatar.dart';

/// Bottom sheet showing an expense's full split breakdown.
class ExpenseDetailSheet extends StatelessWidget {
  final Expense expense;
  final String payerName;
  final Map<int, String> memberNames;

  const ExpenseDetailSheet({
    super.key,
    required this.expense,
    required this.payerName,
    required this.memberNames,
  });

  static Future<void> show(
    BuildContext context, {
    required Expense expense,
    required String payerName,
    required Map<int, String> memberNames,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ExpenseDetailSheet(
        expense: expense,
        payerName: payerName,
        memberNames: memberNames,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE, d MMMM yyyy').format(
      DateTime.fromMillisecondsSinceEpoch(expense.createdAtMillis),
    );
    final sortedShares = expense.shares.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            expense.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text('$payerName paid ${formatPaise(expense.amountPaise)} • $date'),
          const SizedBox(height: 20),
          Text(
            'Split',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...sortedShares.map(
            (entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: MemberAvatar(
                name: memberNames[entry.key] ?? 'Unknown',
                radius: 18,
              ),
              title: Text(memberNames[entry.key] ?? 'Unknown'),
              trailing: Text(
                formatPaise(entry.value),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
