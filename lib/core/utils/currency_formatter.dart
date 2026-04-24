import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '৳',
    decimalDigits: 0,
  );

  static final NumberFormat _decimalFormat = NumberFormat.currency(
    symbol: '৳',
    decimalDigits: 2,
  );

  /// Formats a double amount into a currency string with 0 decimals by default.
  /// Example: 1000.0 -> ৳1,000
  static String format(double amount, {bool showDecimals = false}) {
    if (showDecimals) {
      return _decimalFormat.format(amount);
    }
    return _currencyFormat.format(amount);
  }

  /// Formats a double amount into a currency string with the sign prefix.
  /// Example: 1000.0, isExpense: true -> -৳1,000
  static String formatWithSign(double amount, bool isExpense, {bool showDecimals = false}) {
    final formatted = format(amount, showDecimals: showDecimals);
    return "${isExpense ? '-' : '+'}$formatted";
  }
}
