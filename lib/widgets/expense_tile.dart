import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../utils/money.dart';
import 'member_avatar.dart';

/// One row in the expense history list.
class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final String payerName;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const ExpenseTile({
    super.key,
    required this.expense,
    required this.payerName,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM yyyy').format(
      DateTime.fromMillisecondsSinceEpoch(expense.createdAtMillis),
    );
    return ListTile(
      leading: MemberAvatar(name: payerName),
      title: Text(expense.title),
      subtitle: Text('$payerName paid • $date'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatPaise(expense.amountPaise),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Delete expense',
              onPressed: onDelete,
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}
