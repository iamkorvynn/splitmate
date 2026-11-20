import 'package:material_ui/material_ui.dart';

import '../utils/money.dart';

/// Small pill showing a member's balance: green when they are owed,
/// red when they owe, grey when settled.
class BalanceChip extends StatelessWidget {
  final int balancePaise;

  const BalanceChip({super.key, required this.balancePaise});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color background;
    final Color foreground;
    final String label;
    if (balancePaise > 0) {
      background = Colors.green.shade100;
      foreground = Colors.green.shade900;
      label = 'gets ${formatPaise(balancePaise)}';
    } else if (balancePaise < 0) {
      background = Colors.red.shade100;
      foreground = Colors.red.shade900;
      label = 'owes ${formatPaise(-balancePaise)}';
    } else {
      background = colorScheme.surfaceContainerHighest;
      foreground = colorScheme.onSurfaceVariant;
      label = 'settled';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
