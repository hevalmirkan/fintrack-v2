/// ====================================================
/// PHASE 5.1 — MONTHLY SUMMARY LOGIC (FIXED)
/// ====================================================
///
/// PURPOSE: Separate calculation from UI.
/// This class aggregates data from existing providers.
///
/// RULES:
/// - All amounts in minor units (kuruş)
/// - Investments ≠ Consumption
/// - Read-only: no mutations
///
/// FIX v2: Date filtering confirmed working.
/// Installments/Subscriptions are monthly obligations
/// (not time-stamped), so they show current active total.
/// ====================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/finance_provider.dart';
import '../../domain/models/finance_transaction.dart';
import '../../../installments/presentation/providers/mock_installment_provider.dart';
import '../../../subscriptions/presentation/providers/subscription_provider.dart';
import '../../../shared_expenses/presentation/providers/shared_expense_provider.dart';

// Re-export central formatter for convenience
export '../../../../core/utils/currency_formatter.dart';

/// Data model for monthly summary
class MonthlySummaryData {
  final DateTime month;
  final int totalIncomeMinor;
  final int consumptionExpensesMinor; // Excludes investments
  final int investmentExpensesMinor; // Info only, not subtracted
  final int installmentsMinor; // Monthly installment amounts
  final int subscriptionsMinor; // Active subscriptions total
  final int sharedExpenseNetMinor; // Can be + or -
  final int netResultMinor; // Hero metric

  const MonthlySummaryData({
    required this.month,
    required this.totalIncomeMinor,
    required this.consumptionExpensesMinor,
    required this.investmentExpensesMinor,
    required this.installmentsMinor,
    required this.subscriptionsMinor,
    required this.sharedExpenseNetMinor,
    required this.netResultMinor,
  });

  /// Empty data for months with no transactions
  factory MonthlySummaryData.empty(DateTime month) {
    return MonthlySummaryData(
      month: month,
      totalIncomeMinor: 0,
      consumptionExpensesMinor: 0,
      investmentExpensesMinor: 0,
      installmentsMinor: 0,
      subscriptionsMinor: 0,
      sharedExpenseNetMinor: 0,
      netResultMinor: 0,
    );
  }

  bool get isEmpty =>
      totalIncomeMinor == 0 &&
      consumptionExpensesMinor == 0 &&
      investmentExpensesMinor == 0 &&
      installmentsMinor == 0 &&
      subscriptionsMinor == 0 &&
      sharedExpenseNetMinor == 0;
}

/// Calculator class for monthly summary
/// Note: Uses ref.watch for reactivity in the UI
class MonthlySummaryCalculator {
  final WidgetRef ref;

  MonthlySummaryCalculator(this.ref);

  /// Calculate summary for a given month
  /// IMPORTANT: Call this inside build() so ref.watch triggers rebuilds
  MonthlySummaryData calculate(DateTime selectedMonth) {
    final year = selectedMonth.year;
    final month = selectedMonth.month;

    // Use ref.watch for reactivity
    final financeState = ref.watch(financeProvider);
    final installmentState = ref.watch(mockInstallmentProvider);
    final subscriptionState = ref.watch(subscriptionProvider);
    final sharedState = ref.watch(sharedExpenseProvider);

    // 1. Filter transactions by selected month/year
    final monthTransactions = financeState.transactions
        .where((t) => t.date.year == year && t.date.month == month)
        .toList();

    // Debug print for verification
    print(
        '[SUMMARY] Month: $month/$year, Transactions found: ${monthTransactions.length}');

    // 2. Calculate INCOME (only income type)
    final totalIncome = monthTransactions
        .where((t) => t.type == FinanceTransactionType.income)
        .fold<int>(0, (sum, t) => sum + t.amountMinor);

    // 3. Calculate CONSUMPTION EXPENSES (expense type, EXCLUDE investments)
    final consumptionExpenses = monthTransactions
        .where((t) =>
            t.type == FinanceTransactionType.expense &&
            t.category != 'Yatırım' &&
            t.category != 'Investment')
        .fold<int>(0, (sum, t) => sum + t.amountMinor);

    // 4. Calculate INVESTMENT EXPENSES (info only)
    final investmentExpenses = monthTransactions
        .where((t) =>
            (t.type == FinanceTransactionType.expense ||
                t.type == FinanceTransactionType.investment) &&
            (t.category == 'Yatırım' || t.category == 'Investment'))
        .fold<int>(0, (sum, t) => sum + t.amountMinor);

    // 5. Calculate INSTALLMENTS (monthly burden)
    // Note: Shows CURRENT active installments (they are ongoing obligations)
    final activeInstallments = installmentState.installments
        .where((i) => i.isActive && !i.isFullyPaid)
        .toList();
    final installmentTotal =
        activeInstallments.fold<int>(0, (sum, i) => sum + i.monthlyAmount);

    // 6. Calculate SUBSCRIPTIONS (monthly total for active subs)
    // Note: Shows CURRENT active subscriptions (they are ongoing obligations)
    final subscriptionTotal = subscriptionState.totalMonthlyAmount;

    // 7. Calculate SHARED EXPENSE NET (currentUser's balance across all groups)
    // Positive = owed to me, Negative = I owe
    int sharedNet = 0;
    for (final group in sharedState.groups) {
      final currentUser = group.currentUser;
      if (currentUser != null) {
        // currentBalance: + means owed to me, - means I owe
        sharedNet += (currentUser.currentBalance * 100).toInt();
      }
    }

    // 8. Calculate NET RESULT
    // Net = Income - Consumption - Installments - Subscriptions ± SharedNet
    // Note: Investments are NOT subtracted (they're capital allocation, not loss)
    final netResult = totalIncome -
        consumptionExpenses -
        installmentTotal -
        subscriptionTotal +
        sharedNet;

    return MonthlySummaryData(
      month: selectedMonth,
      totalIncomeMinor: totalIncome,
      consumptionExpensesMinor: consumptionExpenses,
      investmentExpensesMinor: investmentExpenses,
      installmentsMinor: installmentTotal,
      subscriptionsMinor: subscriptionTotal,
      sharedExpenseNetMinor: sharedNet,
      netResultMinor: netResult,
    );
  }
}

/// Helper to format month/year for display
String formatMonthYear(DateTime date) {
  const months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık'
  ];
  return '${months[date.month - 1]} ${date.year}';
}
