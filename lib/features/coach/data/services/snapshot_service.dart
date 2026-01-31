/// =====================================================
/// SNAPSHOT SERVICE — Phase 7: AI Coach
/// =====================================================
/// Aggregates financial data from all providers into a
/// privacy-safe snapshot for AI consumption.
/// =====================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../finance/data/finance_provider.dart';
import '../../../finance/domain/models/finance_transaction.dart';
import '../../../shared_expenses/presentation/providers/shared_expense_provider.dart';
import '../../../subscriptions/presentation/providers/subscription_provider.dart';
import '../../../installments/presentation/providers/mock_installment_provider.dart';
import '../../../assets/presentation/providers/asset_providers.dart';
import '../../domain/models/financial_snapshot.dart';

/// Generates privacy-safe financial snapshots for AI Coach
class SnapshotService {
  final Ref _ref;

  SnapshotService(this._ref);

  /// Generate a complete financial snapshot
  Future<FinancialSnapshot> generateSnapshot() async {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final prevMonth = DateTime(now.year, now.month - 1, 1);

    // Get finance state
    final financeState = _ref.read(financeProvider);
    final transactions = financeState.transactions;

    // Current month transactions
    final currentMonthTx = transactions.where((tx) =>
        tx.date.year == currentMonth.year &&
        tx.date.month == currentMonth.month);

    // Previous month transactions
    final prevMonthTx = transactions.where((tx) =>
        tx.date.year == prevMonth.year && tx.date.month == prevMonth.month);

    // Calculate monthly totals
    final monthlyIncome =
        _sumByType(currentMonthTx, FinanceTransactionType.income);
    final monthlyExpense =
        _sumByType(currentMonthTx, FinanceTransactionType.expense);
    final prevMonthIncome =
        _sumByType(prevMonthTx, FinanceTransactionType.income);
    final prevMonthExpense =
        _sumByType(prevMonthTx, FinanceTransactionType.expense);

    // Calculate change percentages
    final incomeChange = prevMonthIncome > 0
        ? ((monthlyIncome - prevMonthIncome) / prevMonthIncome) * 100
        : 0.0;
    final expenseChange = prevMonthExpense > 0
        ? ((monthlyExpense - prevMonthExpense) / prevMonthExpense) * 100
        : 0.0;

    // Category breakdowns
    final topExpenses = _getCategoryBreakdown(
        currentMonthTx.where((tx) => tx.type == FinanceTransactionType.expense),
        monthlyExpense);
    final topIncome = _getCategoryBreakdown(
        currentMonthTx.where((tx) => tx.type == FinanceTransactionType.income),
        monthlyIncome);

    // Wallet totals
    final totalCash = financeState.totalBalanceMinor / 100.0;
    final walletCount = financeState.wallets.length;

    // Asset totals (try to get from provider)
    double assetValue = 0;
    int assetCount = 0;
    try {
      final assetProvider = _ref.read(totalPortfolioValueTRYProvider);
      assetValue = assetProvider.when(
        data: (v) => v,
        loading: () => 0.0,
        error: (_, __) => 0.0,
      );
      assetCount = financeState.assets.length;
    } catch (_) {}

    // Shared expenses (debt status)
    double totalOwed = 0;
    double totalOwedToUser = 0;
    try {
      final sharedState = _ref.read(sharedExpenseProvider);
      for (final group in sharedState.groups) {
        final currentUser = group.currentUser;
        if (currentUser != null) {
          final balance = currentUser.currentBalance;
          if (balance < 0) {
            totalOwed += balance.abs();
          } else {
            totalOwedToUser += balance;
          }
        }
      }
    } catch (_) {}

    // Subscriptions
    double monthlySubCost = 0;
    int activeSubCount = 0;
    try {
      final subState = _ref.read(subscriptionProvider);
      final activeSubs = subState.subscriptions.where((s) => s.isActive);
      activeSubCount = activeSubs.length;
      monthlySubCost =
          activeSubs.fold(0.0, (sum, s) => sum + s.amountMinor / 100.0);
    } catch (_) {}

    // Installments
    double monthlyInstallment = 0;
    int activeInstCount = 0;
    try {
      final instState = _ref.read(mockInstallmentProvider);
      final activeInst =
          instState.installments.where((i) => i.remainingAmount > 0);
      activeInstCount = activeInst.length;
      monthlyInstallment = activeInst.fold(
          0.0, (sum, i) => sum + i.amountPerInstallment / 100.0);
    } catch (_) {}

    return FinancialSnapshot(
      generatedAt: now,
      monthlyIncome: monthlyIncome,
      monthlyExpense: monthlyExpense,
      monthlyNet: monthlyIncome - monthlyExpense,
      prevMonthIncome: prevMonthIncome,
      prevMonthExpense: prevMonthExpense,
      incomeChangePercent: incomeChange,
      expenseChangePercent: expenseChange,
      topExpenseCategories: topExpenses,
      topIncomeCategories: topIncome,
      totalAssetValue: assetValue,
      assetCount: assetCount,
      totalCashBalance: totalCash,
      walletCount: walletCount,
      totalOwed: totalOwed,
      totalOwedToUser: totalOwedToUser,
      monthlyInstallmentPayment: monthlyInstallment,
      activeInstallmentCount: activeInstCount,
      monthlySubscriptionCost: monthlySubCost,
      activeSubscriptionCount: activeSubCount,
    );
  }

  /// Sum transactions by type
  double _sumByType(
      Iterable<FinanceTransaction> transactions, FinanceTransactionType type) {
    return transactions
        .where((tx) => tx.type == type)
        .fold(0.0, (sum, tx) => sum + tx.amountMinor.abs() / 100.0);
  }

  /// Get top 5 categories by amount
  List<CategoryBreakdown> _getCategoryBreakdown(
      Iterable<FinanceTransaction> transactions, double total) {
    if (total == 0) return [];

    final categoryTotals = <String, double>{};
    for (final tx in transactions) {
      final category = tx.category ?? 'Diğer';
      categoryTotals[category] =
          (categoryTotals[category] ?? 0) + tx.amountMinor.abs() / 100.0;
    }

    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(5)
        .map((e) => CategoryBreakdown(
              category: e.key,
              amount: e.value,
              percentOfTotal: (e.value / total) * 100,
            ))
        .toList();
  }
}

/// Provider for SnapshotService
final snapshotServiceProvider = Provider<SnapshotService>((ref) {
  return SnapshotService(ref);
});

/// Provider for current financial snapshot
final financialSnapshotProvider =
    FutureProvider<FinancialSnapshot>((ref) async {
  final service = ref.read(snapshotServiceProvider);
  return service.generateSnapshot();
});
