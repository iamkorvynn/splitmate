import 'package:flutter_test/flutter_test.dart';
import 'package:splitmate/utils/money.dart';

void main() {
  group('parseRupeesToPaise', () {
    test('parses whole rupees', () {
      expect(parseRupeesToPaise('250'), 25000);
    });

    test('parses decimals', () {
      expect(parseRupeesToPaise('250.50'), 25050);
      expect(parseRupeesToPaise('0.01'), 1);
    });

    test('rejects empty, zero, negative and non-numeric input', () {
      expect(parseRupeesToPaise(''), isNull);
      expect(parseRupeesToPaise('   '), isNull);
      expect(parseRupeesToPaise('0'), isNull);
      expect(parseRupeesToPaise('-5'), isNull);
      expect(parseRupeesToPaise('abc'), isNull);
    });
  });

  group('formatPaise', () {
    test('formats whole rupees with two decimals', () {
      expect(formatPaise(25000), '₹250.00');
    });

    test('formats paise remainder', () {
      expect(formatPaise(25050), '₹250.50');
      expect(formatPaise(5), '₹0.05');
    });

    test('formats negative amounts', () {
      expect(formatPaise(-1250), '-₹12.50');
    });

    test('formats zero', () {
      expect(formatPaise(0), '₹0.00');
    });
  });

  group('formatPaisePlain', () {
    test('formats without currency symbol', () {
      expect(formatPaisePlain(25050), '250.50');
      expect(formatPaisePlain(-99), '-0.99');
    });
  });

  group('splitEqually', () {
    test('even split divides exactly', () {
      expect(splitEqually(30000, 3), [10000, 10000, 10000]);
    });

    test('remainder paise go to the first participants', () {
      expect(splitEqually(100, 3), [34, 33, 33]);
      expect(splitEqually(10, 3), [4, 3, 3]);
    });

    test('shares always sum to the total', () {
      for (var total = 1; total < 1000; total++) {
        for (var count = 1; count <= 7; count++) {
          final shares = splitEqually(total, count);
          expect(shares.length, count);
          expect(shares.reduce((a, b) => a + b), total);
          // Shares differ by at most 1 paise.
          expect(shares.reduce((a, b) => a > b ? a : b) -
              shares.reduce((a, b) => a < b ? a : b), lessThanOrEqualTo(1));
        }
      }
    });

    test('zero people returns empty list', () {
      expect(splitEqually(1000, 0), isEmpty);
    });
  });
}
