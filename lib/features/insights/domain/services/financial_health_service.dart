import 'dart:async';
import 'package:flutter/material.dart';

import '../../../assets/domain/repositories/i_asset_repository.dart';
import '../../../transactions/domain/repositories/i_transaction_repository.dart';
import '../../../installments/domain/repositories/i_installment_repository.dart';
import '../entities/financial_health_score.dart';

/// Service that calculates financial health score and generates insights
/// with debouncing and safety mechanisms to prevent infinite loops
class FinancialHealthService {
  final IAssetRepository _assetRepository;
  final ITransactionRepository _transactionRepository;
  final IInstallmentRepository _installmentRepository;

  // Debounce timer
  Timer? _debounceTimer;
  final _scoreController = StreamController<FinancialHealthScore>.broadcast();
  FinancialHealthScore? _lastScore;

  FinancialHealthService({
    required IAssetRepository assetRepository,
    required ITransactionRepository transactionRepository,
    required IInstallmentRepository installmentRepository,
  })  : _assetRepository = assetRepository,
        _transactionRepository = transactionRepository,
        _installmentRepository = installmentRepository;

  /// Calculate financial health score based on user's portfolio
  /// This is now a pure Future with timeout protection
  Future<FinancialHealthScore> calculateHealthScore() async {
    try {
      // Fetch all required data with timeout protection
      final assetsFuture = _assetRepository.getAssets().timeout(
            const Duration(seconds: 5),
            onTimeout: () => [],
          );

      final transactionsFuture =
          _transactionRepository.getTransactions().timeout(
                const Duration(seconds: 5),
                onTimeout: () => [],
              );

      final installmentsFuture =
          _installmentRepository.getInstallments().first.timeout(
                const Duration(seconds: 5),
                onTimeout: () => [],
              );

      // Wait for all data in parallel
      final results = await Future.wait([
        assetsFuture,
        transactionsFuture,
        installmentsFuture,
      ]);

      final assets = results[0] as List;
      final transactions = results[1] as List;
      final installments = results[2] as List;

      // If no data, return empty score
      if (assets.isEmpty && transactions.isEmpty) {
        return const FinancialHealthScore.empty();
      }

      // Calculate metrics safely
      final metrics = _calculateMetrics(assets, transactions, installments);

      // Calculate score (0-100)
      int score = 50; // Base score

      // Cash Reserve Score (+20 max)
      score += _scoreCashReserve(
        metrics['cashBalance']!,
        metrics['monthlyExpense']!,
      );

      // Asset Diversification Score (+15 max)
      score += _scoreAssetDiversification(assets.length);

      // Income/Expense Ratio Score (+15 max)
      score += _scoreIncomeExpenseRatio(
        metrics['monthlyIncome']!,
        metrics['monthlyExpense']!,
      );

      // Debt Load Score (-20 max)
      score += _scoreDebtLoad(
        metrics['installmentPayments']!,
        metrics['monthlyIncome']!,
      );

      // Clamp score between 0-100
      score = score.clamp(0, 100);

      // Generate label and color
      final (label, color) = _getLabelAndColor(score);

      // Generate insights
      final insights = _generateInsights(metrics, assets.length);

      return FinancialHealthScore(
        score: score,
        label: label,
        color: color,
        insights: insights,
      );
    } catch (e) {
      // On any error, return empty instead of crashing
      return const FinancialHealthScore.empty();
    }
  }

  /// Calculate all key financial metrics with null safety
  Map<String, int> _calculateMetrics(
    List assets,
    List transactions,
    List installments,
  ) {
    // Get current month boundaries
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // Calculate totals
    int totalIncome = 0;
    int totalExpense = 0;
    int monthlyIncome = 0;
    int monthlyExpense = 0;

    for (final txn in transactions) {
      try {
        final isThisMonth =
            txn.date.isAfter(monthStart) && txn.date.isBefore(monthEnd);

        if (txn.type.name == 'income') {
          totalIncome += (txn.totalMinor as num).toInt();
          if (isThisMonth) monthlyIncome += (txn.totalMinor as num).toInt();
        } else if (txn.type.name == 'expense') {
          totalExpense += (txn.totalMinor as num).toInt();
          if (isThisMonth) monthlyExpense += (txn.totalMinor as num).toInt();
        }
      } catch (e) {
        // Skip malformed transaction
        continue;
      }
    }

    // Cash balance
    final cashBalance = totalIncome - totalExpense;

    // Total asset value
    int totalAssetValue = 0;
    for (final asset in assets) {
      try {
        final price = (asset.lastKnownPrice ?? asset.currentPrice) as num;
        totalAssetValue +=
            ((asset.quantityMinor as num).toInt() * price.toInt()) ~/ 100;
      } catch (e) {
        // Skip malformed asset
        continue;
      }
    }

    // Installment payments (total remaining debt)
    int totalInstallmentDebt = 0;
    for (final inst in installments) {
      try {
        final paidAmount = (inst.paidInstallments as num).toInt() *
            (inst.amountPerInstallment as num).toInt();
        final remaining = (inst.totalAmount as num).toInt() - paidAmount;
        totalInstallmentDebt += remaining;
      } catch (e) {
        // Skip malformed installment
        continue;
      }
    }

    return {
      'cashBalance': cashBalance,
      'monthlyIncome': monthlyIncome,
      'monthlyExpense': monthlyExpense,
      'totalAssetValue': totalAssetValue,
      'installmentPayments': totalInstallmentDebt,
    };
  }

  /// Score cash reserve strength
  int _scoreCashReserve(int cashBalance, int monthlyExpense) {
    if (monthlyExpense == 0) return 0;

    final monthsOfExpenses = cashBalance / monthlyExpense;

    if (monthsOfExpenses >= 6) return 20; // Excellent (6+ months)
    if (monthsOfExpenses >= 3) return 15; // Good (3-6 months)
    if (monthsOfExpenses >= 1) return 10; // Okay (1-3 months)
    if (monthsOfExpenses >= 0.5) return 5; // Weak
    return -10; // Critical
  }

  /// Score asset diversification
  int _scoreAssetDiversification(int assetCount) {
    if (assetCount >= 5) return 15;
    if (assetCount >= 3) return 10;
    if (assetCount >= 1) return 5;
    return 0;
  }

  /// Score income vs expense ratio
  int _scoreIncomeExpenseRatio(int monthlyIncome, int monthlyExpense) {
    if (monthlyExpense == 0) return 0;

    final ratio = monthlyIncome / monthlyExpense;

    if (ratio >= 1.5) return 15; // Income > 150% of expenses
    if (ratio >= 1.2) return 10; // Income > 120% of expenses
    if (ratio >= 1.0) return 5; // Income = expenses
    return -15; // Income < expenses (critical)
  }

  /// Score debt load impact
  int _scoreDebtLoad(int totalDebt, int monthlyIncome) {
    if (monthlyIncome == 0) return 0;

    final debtRatio = totalDebt / monthlyIncome;

    if (debtRatio > 3.0) return -20; // Debt > 3x monthly income
    if (debtRatio > 2.0) return -15;
    if (debtRatio > 1.0) return -10;
    if (debtRatio > 0.5) return -5;
    return 0; // Low debt
  }

  /// Get label and color based on score
  (String, Color) _getLabelAndColor(int score) {
    if (score >= 80) return ('Mükemmel', Colors.green);
    if (score >= 60) return ('İyi', Colors.lightGreen);
    if (score >= 40) return ('Orta', Colors.orange);
    if (score >= 20) return ('Riskli', Colors.deepOrange);
    return ('Tehlikeli', Colors.red);
  }

  /// Generate personalized insights
  List<Insight> _generateInsights(Map<String, int> metrics, int assetCount) {
    final List<Insight> insights = [];

    // Cash reserve insights
    final monthsOfCash = metrics['monthlyExpense']! > 0
        ? metrics['cashBalance']! / metrics['monthlyExpense']!
        : 0.0;

    if (monthsOfCash < 1.0) {
      insights.add(const Insight(
        title: 'Acil Durum Fonu',
        message:
            'Nakit rezerviniz 1 aydan az. Acil durumlar için en az 3-6 aylık gider tutarı biriktirmeyi hedefleyin.',
        type: InsightType.warning,
        icon: Icons.warning_amber,
      ));
    } else if (monthsOfCash >= 6.0) {
      insights.add(const Insight(
        title: 'Güçlü Rezerv',
        message:
            'Harika! 6 aydan fazla nakit rezerviniz var. Finansal güvenliğiniz sağlam.',
        type: InsightType.success,
        icon: Icons.check_circle,
      ));
    }

    // Income/Expense insights
    if (metrics['monthlyIncome']! < metrics['monthlyExpense']!) {
      insights.add(const Insight(
        title: 'Gider Kontrolü',
        message:
            'Giderleriniz gelirinizi aşıyor. Harcamalarınızı gözden geçirin veya gelir kaynaklarını artırmayı düşünün.',
        type: InsightType.warning,
        icon: Icons.trending_down,
      ));
    }

    // Diversification insights
    if (assetCount == 0) {
      insights.add(const Insight(
        title: 'Yatırım Başlangıcı',
        message:
            'Henüz varlığınız yok. Küçük miktarlarla da olsa yatırıma başlamayı düşünün.',
        type: InsightType.tip,
        icon: Icons.lightbulb_outline,
      ));
    } else if (assetCount < 3) {
      insights.add(const Insight(
        title: 'Çeşitlendirme',
        message:
            'Portföyünüz az sayıda varlık içeriyor. Risk dağılımı için farklı varlık sınıfları eklemeyi düşünün.',
        type: InsightType.info,
        icon: Icons.pie_chart_outline,
      ));
    }

    // Debt insights
    final debtRatio = metrics['monthlyIncome']! > 0
        ? metrics['installmentPayments']! / metrics['monthlyIncome']!
        : 0.0;

    if (debtRatio > 2.0) {
      insights.add(const Insight(
        title: 'Yüksek Borç Yükü',
        message:
            'Taksit borcunuz aylık gelirin 2 katından fazla. Borçları ödeme planı oluşturun.',
        type: InsightType.warning,
        icon: Icons.credit_card_off,
      ));
    }

    // If no insights, add a positive one
    if (insights.isEmpty) {
      insights.add(const Insight(
        title: 'İyi Gidiyorsunuz',
        message:
            'Finansal durumunuz dengeli görünüyor. Mevcut disiplininizi sürdürün.',
        type: InsightType.success,
        icon: Icons.thumb_up_outlined,
      ));
    }

    return insights;
  }

  void dispose() {
    _debounceTimer?.cancel();
    _scoreController.close();
  }
}
