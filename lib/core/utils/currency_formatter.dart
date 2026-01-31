/// ====================================================
/// CENTRAL CURRENCY FORMATTER (Single Source of Truth)
/// ====================================================
///
/// RULE: ALL monetary values in the UI MUST use this formatter.
/// FORMAT: Turkish locale → 10.000,00 ₺
///
/// Usage:
///   CurrencyFormatter.format(1000000)     → "10.000,00 ₺"
///   CurrencyFormatter.formatShort(1000000) → "10.000 ₺"
///   CurrencyFormatter.formatFromMinor(100000) → "1.000,00 ₺"
///
/// ====================================================

import 'package:intl/intl.dart';

/// Central currency formatting utility
/// Ensures consistent Turkish locale formatting across the entire app
class CurrencyFormatter {
  // Turkish locale formatter with 2 decimal places
  static final NumberFormat _formatFull = NumberFormat("#,##0.00", "tr_TR");

  // Turkish locale formatter without decimal places
  static final NumberFormat _formatShort = NumberFormat("#,##0", "tr_TR");

  /// Format a major units amount (TRY) with full precision
  /// Input: 1000.50 → Output: "1.000,50 ₺"
  static String format(double amount, {bool showSymbol = true}) {
    final formatted = _formatFull.format(amount);
    return showSymbol ? '$formatted ₺' : formatted;
  }

  /// Format a major units amount (TRY) without decimals
  /// Input: 1000.50 → Output: "1.000 ₺"
  static String formatShort(double amount, {bool showSymbol = true}) {
    final formatted = _formatShort.format(amount);
    return showSymbol ? '$formatted ₺' : formatted;
  }

  /// Format from MINOR units (kuruş) with full precision
  /// Input: 100050 (kuruş) → Output: "1.000,50 ₺"
  static String formatFromMinor(int amountMinor, {bool showSymbol = true}) {
    final amount = amountMinor / 100.0;
    return format(amount, showSymbol: showSymbol);
  }

  /// Format from MINOR units (kuruş) without decimals
  /// Input: 100050 (kuruş) → Output: "1.001 ₺"
  static String formatFromMinorShort(int amountMinor,
      {bool showSymbol = true}) {
    final amount = amountMinor / 100.0;
    return formatShort(amount, showSymbol: showSymbol);
  }

  /// Format with sign prefix (+/-) from major units
  /// Input: 1000 → Output: "+1.000,00 ₺" or "-1.000,00 ₺"
  static String formatWithSign(double amount, {bool showSymbol = true}) {
    final prefix = amount >= 0 ? '+' : '';
    return '$prefix${format(amount, showSymbol: showSymbol)}';
  }

  /// Format with sign prefix from MINOR units
  /// Input: 100000 → Output: "+1.000,00 ₺"
  static String formatFromMinorWithSign(int amountMinor,
      {bool showSymbol = true}) {
    final amount = amountMinor / 100.0;
    return formatWithSign(amount, showSymbol: showSymbol);
  }

  /// Compact format for large numbers (K/M suffixes)
  /// Input: 1500000 → Output: "1,5M ₺"
  static String formatCompact(double amount, {bool showSymbol = true}) {
    String result;
    if (amount.abs() >= 1000000) {
      result = '${(amount / 1000000).toStringAsFixed(1).replaceAll('.', ',')}M';
    } else if (amount.abs() >= 1000) {
      result = '${(amount / 1000).toStringAsFixed(1).replaceAll('.', ',')}K';
    } else {
      result = _formatShort.format(amount);
    }
    return showSymbol ? '$result ₺' : result;
  }

  /// Null-safe format with fallback
  /// Input: null → Output: "0,00 ₺"
  static String formatSafe(double? amount, {bool showSymbol = true}) {
    return format(amount ?? 0.0, showSymbol: showSymbol);
  }

  /// Null-safe format from minor with fallback
  static String formatFromMinorSafe(int? amountMinor,
      {bool showSymbol = true}) {
    return formatFromMinor(amountMinor ?? 0, showSymbol: showSymbol);
  }
}

/// Extension on num for convenient inline formatting
extension CurrencyFormatExtension on num {
  /// Format as Turkish currency
  /// Usage: 1000.0.asCurrency → "1.000,00 ₺"
  String get asCurrency => CurrencyFormatter.format(toDouble());

  /// Format as Turkish currency without decimals
  /// Usage: 1000.0.asCurrencyShort → "1.000 ₺"
  String get asCurrencyShort => CurrencyFormatter.formatShort(toDouble());

  /// Format minor units as currency
  /// Usage: 100000.fromMinor → "1.000,00 ₺"
  String get fromMinor => CurrencyFormatter.formatFromMinor(toInt());

  /// Format minor units as currency without decimals
  String get fromMinorShort => CurrencyFormatter.formatFromMinorShort(toInt());
}
