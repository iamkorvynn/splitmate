/// Money helpers for SplitMate.
///
/// All amounts are stored as integer paise (1 rupee = 100 paise) so that
/// splits and balances never suffer floating point rounding errors.
library;

/// Convert a rupee string typed by the user (e.g. "250.50") to paise.
int? parseRupeesToPaise(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;
  final value = double.tryParse(trimmed);
  if (value == null || value <= 0) return null;
  return (value * 100).round();
}

/// Format paise as a rupee amount, e.g. 25050 -> "₹250.50".
String formatPaise(int paise) {
  final sign = paise < 0 ? '-' : '';
  final abs = paise.abs();
  final rupees = abs ~/ 100;
  final remainder = abs % 100;
  return '$sign₹$rupees.${remainder.toString().padLeft(2, '0')}';
}

/// Format paise without the currency symbol, e.g. 25050 -> "250.50".
String formatPaisePlain(int paise) {
  final abs = paise.abs();
  final rupees = abs ~/ 100;
  final remainder = abs % 100;
  return '${paise < 0 ? '-' : ''}$rupees.${remainder.toString().padLeft(2, '0')}';
}

/// Split [totalPaise] equally across [count] people.
///
/// The remainder paise (when the total does not divide evenly) are handed
/// out one paise at a time to the first participants, so the shares always
/// add up to exactly [totalPaise].
List<int> splitEqually(int totalPaise, int count) {
  if (count <= 0) return <int>[];
  final base = totalPaise ~/ count;
  final remainder = totalPaise % count;
  return List<int>.generate(
    count,
    (i) => base + (i < remainder ? 1 : 0),
  );
}
