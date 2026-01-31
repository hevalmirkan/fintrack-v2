/// ====================================================
/// PHASE 6 — CSV EXPORT SERVICE
/// ====================================================
///
/// Exports transaction history to CSV format for Excel/Numbers.
///
/// Formatting Rules:
/// - Delimiter: ;
/// - Encoding: UTF-8 with BOM (for Turkish char support in Excel)
/// - Amounts in TRY (formatted consistently)
/// ====================================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

// Conditional import for web download
import 'web_download_stub.dart'
    if (dart.library.html) 'web_download_helper.dart';

import '../../features/finance/data/finance_provider.dart';
import '../../features/finance/domain/models/finance_transaction.dart';

/// CSV Export Service
class CsvExportService {
  // UTF-8 BOM for Excel Turkish support
  static const String _bom = '\uFEFF';
  static const String _delimiter = ';';

  /// Generate CSV content from transactions
  static String generateCsv(WidgetRef ref) {
    final financeState = ref.read(financeProvider);
    final transactions = financeState.transactions;
    final wallets = financeState.wallets;

    // Create wallet lookup for names
    final walletNames = <String, String>{
      for (final w in wallets) w.id: w.name,
    };

    final buffer = StringBuffer();

    // Add BOM for Excel
    buffer.write(_bom);

    // Header row
    buffer.writeln([
      'Tarih',
      'Tip',
      'Kategori',
      'Tutar',
      'Açıklama',
      'Cüzdan',
    ].join(_delimiter));

    // Sort transactions by date (newest first)
    final sortedTxs = List<FinanceTransaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Data rows
    for (final tx in sortedTxs) {
      final date = _formatDate(tx.date);
      final type = _getTypeDisplayName(tx.type);
      final category = tx.category;
      final amount = _formatAmount(tx.amountMinor, tx.type);
      final description = _escapeForCsv(tx.title ?? '');
      final wallet = walletNames[tx.walletId] ?? 'Bilinmeyen';

      buffer.writeln([
        date,
        type,
        category,
        amount,
        description,
        wallet,
      ].join(_delimiter));
    }

    return buffer.toString();
  }

  /// Export CSV file (share on mobile, download on web)
  static Future<bool> exportCsvFile(WidgetRef ref) async {
    try {
      final csvContent = generateCsv(ref);
      final fileName =
          'fintrack_report_${_formatDateForFilename(DateTime.now())}.csv';

      if (kIsWeb) {
        // Web: Use conditionally imported dart:html helper
        downloadFileWeb(fileName, csvContent, 'text/csv');
        print('[CSV] Web export triggered: $fileName');
        return true;
      } else {
        // Mobile: Save to temp and share
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(csvContent, encoding: utf8);

        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'FinTrack Rapor - ${_formatDateForDisplay(DateTime.now())}',
        );
        return true;
      }
    } catch (e) {
      print('[CSV] Export failed: $e');
      return false;
    }
  }

  // ============================================================
  // FORMATTING HELPERS
  // ============================================================

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  static String _getTypeDisplayName(FinanceTransactionType type) {
    switch (type) {
      case FinanceTransactionType.income:
        return 'Gelir';
      case FinanceTransactionType.expense:
        return 'Gider';
      case FinanceTransactionType.investment:
        return 'Yatırım';
      case FinanceTransactionType.transfer:
        return 'Transfer';
      case FinanceTransactionType.adjustment:
        return 'Düzeltme';
    }
  }

  static String _formatAmount(int amountMinor, FinanceTransactionType type) {
    final amount = amountMinor / 100.0;
    final sign = type == FinanceTransactionType.expense ||
            type == FinanceTransactionType.investment
        ? '-'
        : '';
    // Use comma as decimal separator for Turkish locale
    final formatted = amount.toStringAsFixed(2).replaceAll('.', ',');
    return '$sign$formatted ₺';
  }

  static String _escapeForCsv(String value) {
    // Escape quotes and handle special characters
    if (value.contains(_delimiter) ||
        value.contains('"') ||
        value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static String _formatDateForFilename(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  static String _formatDateForDisplay(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
