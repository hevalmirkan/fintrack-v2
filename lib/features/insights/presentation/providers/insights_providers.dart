import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/educational_insight.dart';
import '../../domain/entities/financial_term.dart';
import '../../domain/services/educational_insight_service.dart';
import '../../domain/services/financial_health_service.dart';
import '../../domain/services/financial_terms_database.dart';
import '../../domain/entities/financial_health_score.dart';

part 'insights_providers.g.dart';

@riverpod
FinancialHealthService financialHealthService(Ref ref) {
  return FinancialHealthService(
    assetRepository: ref.watch(assetRepositoryProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
    installmentRepository: ref.watch(installmentRepositoryProvider),
  );
}

@riverpod
Future<FinancialHealthScore> financialHealthScore(Ref ref) async {
  final service = ref.watch(financialHealthServiceProvider);
  return await service.calculateHealthScore();
}

// NEW: Educational Insight Service
@riverpod
EducationalInsightService educationalInsightService(Ref ref) {
  return EducationalInsightService();
}

// NEW: Daily Financial Term
@riverpod
FinancialTerm dailyFinancialTerm(Ref ref) {
  return FinancialTermsDatabase.getRandomTerm();
}

// NEW: Educational Insights
@riverpod
Future<List<EducationalInsight>> educationalInsights(Ref ref) async {
  final healthScore = await ref.watch(financialHealthScoreProvider.future);
  final service = ref.watch(educationalInsightServiceProvider);
  final assets = await ref.watch(assetRepositoryProvider).getAssets();
  final transactions =
      await ref.watch(transactionRepositoryProvider).getTransactions();

  // Calculate metrics for educational insights
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  int monthlyIncome = 0;
  int monthlyExpense = 0;
  int totalIncome = 0;
  int totalExpense = 0;

  for (final txn in transactions) {
    final isThisMonth =
        txn.date.isAfter(monthStart) && txn.date.isBefore(monthEnd);
    final amount = (txn.totalMinor as num).toInt();

    if (txn.type.name == 'income') {
      totalIncome += amount;
      if (isThisMonth) monthlyIncome += amount;
    } else if (txn.type.name == 'expense') {
      totalExpense += amount;
      if (isThisMonth) monthlyExpense += amount;
    }
  }

  final cashBalance = totalIncome - totalExpense;

  // Total asset value
  int totalAssetValue = 0;
  for (final asset in assets) {
    try {
      final price = (asset.lastKnownPrice ?? asset.currentPrice) as num;
      totalAssetValue +=
          ((asset.quantityMinor as num).toInt() * price.toInt()) ~/ 100;
    } catch (e) {
      continue;
    }
  }

  // Get installments for debt calculation
  final installments = await ref
      .watch(installmentRepositoryProvider)
      .getInstallments()
      .first
      .timeout(const Duration(seconds: 5), onTimeout: () => []);

  int totalInstallmentDebt = 0;
  for (final inst in installments) {
    try {
      final paidAmount = (inst.paidInstallments as num).toInt() *
          (inst.amountPerInstallment as num).toInt();
      final remaining = (inst.totalAmount as num).toInt() - paidAmount;
      totalInstallmentDebt += remaining;
    } catch (e) {
      continue;
    }
  }

  final metrics = {
    'cashBalance': cashBalance,
    'monthlyIncome': monthlyIncome,
    'monthlyExpense': monthlyExpense,
    'totalAssetValue': totalAssetValue,
    'installmentPayments': totalInstallmentDebt,
  };

  return service.generateEducationalInsights(metrics, assets.length);
}

// NEW: Scorecard Metrics
@riverpod
Future<Map<String, int>> scorecardMetrics(Ref ref) async {
  final healthScore = await ref.watch(financialHealthScoreProvider.future);
  final assets = await ref.watch(assetRepositoryProvider).getAssets();
  final transactions =
      await ref.watch(transactionRepositoryProvider).getTransactions();

  // Calculate liquidity score
  int totalIncome = 0;
  int totalExpense = 0;

  for (final txn in transactions) {
    final amount = (txn.totalMinor as num).toInt();
    if (txn.type.name == 'income') {
      totalIncome += amount;
    } else if (txn.type.name == 'expense') {
      totalExpense += amount;
    }
  }

  final cashBalance = totalIncome - totalExpense;

  int totalAssetValue = 0;
  for (final asset in assets) {
    try {
      final price = (asset.lastKnownPrice ?? asset.currentPrice) as num;
      totalAssetValue +=
          ((asset.quantityMinor as num).toInt() * price.toInt()) ~/ 100;
    } catch (e) {
      continue;
    }
  }

  final totalValue = totalAssetValue + cashBalance.abs();

  // Liquidity: cash / total assets
  final liquidityScore = totalValue > 0
      ? ((cashBalance.abs() / totalValue) * 100).clamp(0, 100).toInt()
      : 50;

  // Debt score: inverse of debt ratio
  final installments = await ref
      .watch(installmentRepositoryProvider)
      .getInstallments()
      .first
      .timeout(const Duration(seconds: 5), onTimeout: () => []);

  int totalDebt = 0;
  for (final inst in installments) {
    try {
      final paidAmount = (inst.paidInstallments as num).toInt() *
          (inst.amountPerInstallment as num).toInt();
      final remaining = (inst.totalAmount as num).toInt() - paidAmount;
      totalDebt += remaining;
    } catch (e) {
      continue;
    }
  }

  final debtScore = totalValue > 0
      ? (100 - (totalDebt / totalValue) * 100).clamp(0, 100).toInt()
      : 100;

  // Growth score (mock for now)
  final growthScore = 60;

  // Diversification score
  final diversificationScore = (assets.length * 20).clamp(0, 100);

  return {
    'overall': healthScore.score,
    'liquidity': liquidityScore,
    'debt': debtScore,
    'growth': growthScore,
    'diversification': diversificationScore,
  };
}
