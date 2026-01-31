import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/entities/transaction_enums.dart';

/// Data model for category breakdown (pie chart)
class CategoryData {
  final String categoryName;
  final double totalAmount;
  final double percentage;
  final Color color;

  const CategoryData({
    required this.categoryName,
    required this.totalAmount,
    required this.percentage,
    required this.color,
  });
}

/// Data model for monthly expense trend (bar chart)
class MonthlyExpenseData {
  final String monthLabel;
  final double totalExpense;
  final DateTime month;

  const MonthlyExpenseData({
    required this.monthLabel,
    required this.totalExpense,
    required this.month,
  });
}

/// Service for aggregating transaction data into chart-ready datasets
class StatisticsService {
  /// Category color mapping
  static Color _getCategoryColor(String? category) {
    final cat = category?.toLowerCase() ?? '';

    if (cat.contains('market') ||
        cat.contains('gıda') ||
        cat.contains('food')) {
      return Colors.orange;
    } else if (cat.contains('kira') || cat.contains('rent')) {
      return Colors.blue;
    } else if (cat.contains('ulaşım') || cat.contains('transport')) {
      return Colors.teal;
    } else if (cat.contains('restoran') ||
        cat.contains('restaurant') ||
        cat.contains('cafe')) {
      return Colors.red;
    } else if (cat.contains('abonelik') || cat.contains('subscription')) {
      return Colors.purple;
    } else {
      return Colors.grey; // Diğer / Uncategorized
    }
  }

  /// Get expense breakdown by category for current month
  static List<CategoryData> getCategoryBreakdown(
      List<TransactionEntity> transactions) {
    // Get current month boundaries
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // Filter: Expense transactions only, current month only
    final expenseThisMonth = transactions.where((txn) {
      return txn.type == TransactionType.expense &&
          txn.date.isAfter(monthStart) &&
          txn.date.isBefore(monthEnd);
    }).toList();

    // Edge case: no expenses
    if (expenseThisMonth.isEmpty) {
      return [];
    }

    // Group by category and sum amounts
    final Map<String, double> categoryTotals = {};
    double grandTotal = 0;

    for (final txn in expenseThisMonth) {
      final category = txn.category ?? 'Diğer';
      final amount = (txn.totalMinor / 100).toDouble();
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      grandTotal += amount;
    }

    // Edge case: total is 0
    if (grandTotal == 0) {
      return [];
    }

    // Convert to CategoryData list with percentages and colors
    final result = categoryTotals.entries.map((entry) {
      final percentage = (entry.value / grandTotal) * 100;
      return CategoryData(
        categoryName: entry.key,
        totalAmount: entry.value,
        percentage: percentage,
        color: _getCategoryColor(entry.key),
      );
    }).toList();

    // Sort by amount (largest first)
    result.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return result;
  }

  /// Get 6-month expense trend
  static List<MonthlyExpenseData> getSixMonthExpenseTrend(
      List<TransactionEntity> transactions) {
    final now = DateTime.now();
    final monthsList = <MonthlyExpenseData>[];

    // Calculate last 6 months (including current)
    for (int i = 5; i >= 0; i--) {
      final targetMonth = DateTime(now.year, now.month - i, 1);
      final monthStart = DateTime(targetMonth.year, targetMonth.month, 1);
      final monthEnd =
          DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59);

      // Filter expenses for this month
      final expensesInMonth = transactions.where((txn) {
        return txn.type == TransactionType.expense &&
            txn.date.isAfter(monthStart) &&
            txn.date.isBefore(monthEnd);
      }).toList();

      // Sum total
      double total = 0;
      for (final txn in expensesInMonth) {
        total += (txn.totalMinor / 100).toDouble();
      }

      // Get Turkish month label
      final monthLabel = _getTurkishMonthLabel(targetMonth.month);

      monthsList.add(MonthlyExpenseData(
        monthLabel: monthLabel,
        totalExpense: total,
        month: targetMonth,
      ));
    }

    return monthsList;
  }

  /// Get Turkish month abbreviation
  static String _getTurkishMonthLabel(int month) {
    const labels = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara'
    ];
    return labels[month - 1];
  }
}
