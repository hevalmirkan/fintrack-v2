import 'package:fl_chart/fl_chart.dart';
import '../../../finance/domain/models/finance_transaction.dart';
import '../../../finance/domain/models/wallet.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Time range filter for analysis
enum TimeRange { thisMonth, lastMonth, thisYear }

/// Data model for pie chart
class PieData {
  final String category;
  final double percentage;
  final int amountMinor;
  final bool isOther;

  PieData({
    required this.category,
    required this.percentage,
    required this.amountMinor,
    this.isOther = false,
  });
}

/// Data model for wallet stats
class WalletStats {
  final String walletName;
  final String walletId;
  final WalletType walletType;
  final int totalExpense;
  final double percentage;

  WalletStats({
    required this.walletName,
    required this.walletId,
    required this.walletType,
    required this.totalExpense,
    required this.percentage,
  });
}

/// Data model for net flow
class NetFlowData {
  final int totalIncome;
  final int totalExpense;
  final int net;

  NetFlowData({
    required this.totalIncome,
    required this.totalExpense,
    required this.net,
  });
}

/// Data model for investment behavior stats
class InvestmentStats {
  final int count;
  final double averageAmount;
  final String lastInvestmentDate;
  final String lastAssetName;

  InvestmentStats({
    required this.count,
    required this.averageAmount,
    required this.lastInvestmentDate,
    required this.lastAssetName,
  });
}

/// ====================================================
/// PHASE 5.2 — TREND ANALYSIS DATA MODELS
/// ====================================================

/// Monthly trend data for 6-month bar chart
class MonthlyTrendData {
  final String monthLabel; // "Oca", "Şub", etc.
  final int year;
  final int month; // 1-12
  final int expenseMinor; // Total consumption (excludes investment)
  final int investmentMinor; // Total investment
  final int incomeMinor; // Total income

  MonthlyTrendData({
    required this.monthLabel,
    required this.year,
    required this.month,
    required this.expenseMinor,
    required this.investmentMinor,
    required this.incomeMinor,
  });
}

/// Month overview insights (deterministic, no AI)
class MonthOverview {
  final String topCategory; // "En çok: Gıda"
  final int topCategoryAmount; // Amount in minor units
  final String spendingChange; // "Harcamalar %10 arttı"
  final double spendingChangePercent;
  final String investmentChange; // "Yatırımlar sabit"
  final double investmentChangePercent;
  final int netBalanceMinor; // This month's net

  MonthOverview({
    required this.topCategory,
    required this.topCategoryAmount,
    required this.spendingChange,
    required this.spendingChangePercent,
    required this.investmentChange,
    required this.investmentChangePercent,
    required this.netBalanceMinor,
  });
}

/// Analysis Logic Helper - Pure functions for financial analysis
class AnalysisLogicHelper {
  /// Filter transactions by time range (FULL DAY coverage 00:00:00 - 23:59:59)
  static List<FinanceTransaction> filterTransactions(
    List<FinanceTransaction> transactions,
    TimeRange range,
  ) {
    if (transactions.isEmpty) return [];

    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (range) {
      case TimeRange.thisMonth:
        startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      case TimeRange.lastMonth:
        startDate = DateTime(now.year, now.month - 1, 1, 0, 0, 0);
        endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
      case TimeRange.thisYear:
        startDate = DateTime(now.year, 1, 1, 0, 0, 0);
        endDate = DateTime(now.year, 12, 31, 23, 59, 59);
    }

    return transactions.where((tx) {
      // Compare date only (ignore time component for accuracy)
      final txDateOnly = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final startOnly =
          DateTime(startDate.year, startDate.month, startDate.day);
      final endOnly = DateTime(endDate.year, endDate.month, endDate.day);

      return (txDateOnly.isAtSameMomentAs(startOnly) ||
              txDateOnly.isAfter(startOnly)) &&
          (txDateOnly.isAtSameMomentAs(endOnly) ||
              txDateOnly.isBefore(endOnly));
    }).toList();
  }

  /// Prepare pie chart data from expense transactions
  /// CORRECTLY groups ALL categories → Top 4 + "Diğer" bucket
  /// EXCLUDES "Yatırım" (Investment) - those are capital allocation, not consumption
  static List<PieData> prepareExpensePieData(
      List<FinanceTransaction> transactions) {
    // Filter ONLY expenses, EXCLUDING investments
    final expenses = transactions
        .where((tx) =>
            tx.type == FinanceTransactionType.expense &&
            tx.category != 'Yatırım' && // Exclude investment category
            tx.category != 'Investment') // English fallback
        .toList();

    if (expenses.isEmpty) return [];

    // Group by category - AGGREGATE ALL
    final Map<String, int> categoryTotals = {};
    int totalExpense = 0;

    for (final tx in expenses) {
      final category = tx.category.isNotEmpty ? tx.category : 'Diğer';
      categoryTotals[category] =
          (categoryTotals[category] ?? 0) + tx.amountMinor;
      totalExpense += tx.amountMinor;
    }

    if (totalExpense == 0) return [];

    // Sort by amount descending
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take TOP 4, rest goes to "Diğer"
    final List<PieData> result = [];
    int otherAmount = 0;

    for (int i = 0; i < sortedCategories.length; i++) {
      final entry = sortedCategories[i];
      final percentage = (entry.value / totalExpense) * 100;

      if (i < 4) {
        result.add(PieData(
          category: entry.key,
          percentage: percentage,
          amountMinor: entry.value,
        ));
      } else {
        otherAmount += entry.value;
      }
    }

    // Add "Diğer" if exists
    if (otherAmount > 0) {
      result.add(PieData(
        category: 'Diğer',
        percentage: (otherAmount / totalExpense) * 100,
        amountMinor: otherAmount,
        isOther: true,
      ));
    }

    return result;
  }

  /// Prepare pie chart data for INVESTMENT transactions only
  /// Groups by asset name extracted from description (strips "Varlık Alımı:" prefix)
  static List<PieData> prepareInvestmentPieData(
      List<FinanceTransaction> transactions) {
    // Filter investment transactions:
    // - New: type == investment
    // - Legacy: type == expense with Yatırım category
    final investments = transactions
        .where((tx) =>
            tx.type == FinanceTransactionType.investment ||
            (tx.type == FinanceTransactionType.expense &&
                (tx.category == 'Yatırım' || tx.category == 'Investment')))
        .toList();

    if (investments.isEmpty) return [];

    // Group by asset name (extracted from description)
    final Map<String, int> assetTotals = {};
    int totalInvestment = 0;

    for (final tx in investments) {
      // Extract asset name from description
      String assetName = _extractAssetName(tx.description);
      assetTotals[assetName] = (assetTotals[assetName] ?? 0) + tx.amountMinor;
      totalInvestment += tx.amountMinor;
    }

    if (totalInvestment == 0) return [];

    // Sort by amount descending
    final sortedAssets = assetTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Build result (no "Diğer" grouping - show all assets)
    final List<PieData> result = [];
    for (final entry in sortedAssets) {
      result.add(PieData(
        category: entry.key,
        percentage: (entry.value / totalInvestment) * 100,
        amountMinor: entry.value,
      ));
    }

    return result;
  }

  /// Extract clean asset name from transaction description
  /// Strips "Varlık Alımı: " prefix and "(SYMBOL)" suffix
  static String _extractAssetName(String? description) {
    if (description == null || description.isEmpty) {
      return 'Diğer Yatırım';
    }

    String name = description;

    // Strip "Varlık Alımı: " prefix
    if (name.startsWith('Varlık Alımı: ')) {
      name = name.replaceFirst('Varlık Alımı: ', '');
    }

    // Optional: Strip "(SYMBOL)" suffix for cleaner display
    final bracketIndex = name.lastIndexOf(' (');
    if (bracketIndex > 0) {
      name = name.substring(0, bracketIndex);
    }

    return name.isNotEmpty ? name : 'Diğer Yatırım';
  }

  /// Calculate investment behavior statistics
  /// Returns count, average, and last investment details
  static InvestmentStats calculateInvestmentStats(
      List<FinanceTransaction> transactions) {
    // Filter investment transactions (new type + legacy category)
    final investments = transactions
        .where((tx) =>
            tx.type == FinanceTransactionType.investment ||
            (tx.type == FinanceTransactionType.expense &&
                (tx.category == 'Yatırım' || tx.category == 'Investment')))
        .toList();

    if (investments.isEmpty) {
      return InvestmentStats(
        count: 0,
        averageAmount: 0,
        lastInvestmentDate: 'Yok',
        lastAssetName: '-',
      );
    }

    // Calculate totals
    final count = investments.length;
    final totalMinor =
        investments.fold<int>(0, (sum, tx) => sum + tx.amountMinor);
    final averageAmount =
        (totalMinor / count) / 100.0; // Convert to major units

    // Find most recent investment
    investments.sort((a, b) => b.date.compareTo(a.date));
    final lastInvestment = investments.first;

    // Format date as relative time
    final lastDate = _formatRelativeDate(lastInvestment.date);
    final lastAssetName = _extractAssetName(lastInvestment.description);

    return InvestmentStats(
      count: count,
      averageAmount: averageAmount,
      lastInvestmentDate: lastDate,
      lastAssetName: lastAssetName,
    );
  }

  /// Format date as relative time (e.g., "3 gün önce", "Bugün")
  static String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Bugün';
    } else if (diff.inDays == 1) {
      return 'Dün';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} gün önce';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks hafta önce';
    } else {
      // Format as "12 Oca", "5 Mar" etc.
      const months = [
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
      return '${date.day} ${months[date.month - 1]}';
    }
  }

  /// Prepare wallet stats - Groups expenses by wallet NAME
  /// Shows "Nakit" vs "Kredi Kartı" distribution
  static List<WalletStats> prepareWalletStats(
    List<FinanceTransaction> transactions,
    List<Wallet> wallets,
  ) {
    // Filter ONLY expenses
    final expenses = transactions
        .where((tx) => tx.type == FinanceTransactionType.expense)
        .toList();

    if (expenses.isEmpty || wallets.isEmpty) return [];

    // Group expenses by walletId
    final Map<String, int> walletTotals = {};
    int totalExpense = 0;

    for (final tx in expenses) {
      walletTotals[tx.walletId] =
          (walletTotals[tx.walletId] ?? 0) + tx.amountMinor;
      totalExpense += tx.amountMinor;
    }

    if (totalExpense == 0) return [];

    // Build WalletStats list
    final List<WalletStats> result = [];

    for (final entry in walletTotals.entries) {
      // Find wallet details
      final wallet = wallets.firstWhere(
        (w) => w.id == entry.key,
        orElse: () => wallets.first, // Fallback to first wallet
      );

      result.add(WalletStats(
        walletName: wallet.name,
        walletId: wallet.id,
        walletType: wallet.type,
        totalExpense: entry.value,
        percentage: (entry.value / totalExpense) * 100,
      ));
    }

    // Sort by expense descending
    result.sort((a, b) => b.totalExpense.compareTo(a.totalExpense));

    return result;
  }

  /// Prepare daily expense spots for Line Chart
  /// Aggregates total expense per day (fills missing days with 0)
  static List<FlSpot> prepareDailyStats(
    List<FinanceTransaction> transactions,
    TimeRange range,
  ) {
    // Filter ONLY expenses
    final expenses = transactions
        .where((tx) => tx.type == FinanceTransactionType.expense)
        .toList();

    // Determine days in period
    final now = DateTime.now();
    int daysInPeriod;
    switch (range) {
      case TimeRange.thisMonth:
        daysInPeriod = DateTime(now.year, now.month + 1, 0).day;
      case TimeRange.lastMonth:
        daysInPeriod = DateTime(now.year, now.month, 0).day;
      case TimeRange.thisYear:
        daysInPeriod = 12; // Monthly aggregation for year view
    }

    // Group by day/month
    final Map<int, int> dailyTotals = {};

    for (final tx in expenses) {
      int key;
      if (range == TimeRange.thisYear) {
        key = tx.date.month;
      } else {
        key = tx.date.day;
      }
      dailyTotals[key] = (dailyTotals[key] ?? 0) + tx.amountMinor;
    }

    // Build FlSpot list with ALL days (zeros for missing)
    final List<FlSpot> result = [];
    for (int i = 1; i <= daysInPeriod; i++) {
      result.add(FlSpot(
        i.toDouble(),
        (dailyTotals[i] ?? 0) / 100.0, // Convert to major units
      ));
    }

    return result;
  }

  /// Calculate net flow - Total Income vs Total Expense
  static NetFlowData calculateNetFlow(List<FinanceTransaction> transactions) {
    int totalIncome = 0;
    int totalExpense = 0;

    for (final tx in transactions) {
      if (tx.type == FinanceTransactionType.income) {
        totalIncome += tx.amountMinor;
      } else {
        totalExpense += tx.amountMinor;
      }
    }

    return NetFlowData(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      net: totalIncome - totalExpense,
    );
  }

  /// Calculate total expense in minor units
  static int calculateTotalExpense(List<FinanceTransaction> transactions) {
    return transactions
        .where((tx) => tx.type == FinanceTransactionType.expense)
        .fold(0, (sum, tx) => sum + tx.amountMinor);
  }

  /// Format currency (minor to major with symbol) - Uses central CurrencyFormatter
  static String formatCurrency(int amountMinor) {
    return CurrencyFormatter.formatFromMinorShort(amountMinor);
  }

  // ============================================
  // FINANCIAL COACH LOGIC
  // ============================================

  /// Calculate Liquidity Score (0.0 - 1.0)
  /// Measures how many months of expenses your liquid cash covers
  static double calculateLiquidityScore({
    required List<Wallet> wallets,
    required double monthlyExpense,
  }) {
    // Sum all liquid cash (exclude credit cards, include only positive balances)
    final totalLiquidCash = wallets
        .where((w) => w.type != WalletType.creditCard && w.balanceMinor > 0)
        .fold<int>(0, (sum, w) => sum + w.balanceMinor);

    final liquidTotal = totalLiquidCash / 100.0;
    if (monthlyExpense <= 0) return 1.0; // No expense = full score

    final runwayScore = liquidTotal / monthlyExpense;
    return runwayScore.clamp(0.0, 1.0);
  }

  /// Calculate Debt Ratio (0.0 - 1.0)
  /// Measures total debt as percentage of gross assets
  /// FIXED: ANY wallet with balance < 0 counts as debt, not just credit cards
  static double calculateDebtRatio({
    required List<Wallet> wallets,
    required double totalAssets,
  }) {
    // Sum ALL negative balances as debt (cash overdrawn, credit cards, etc.)
    final totalDebtMinor = wallets
        .where((w) => w.balanceMinor < 0)
        .fold<int>(0, (sum, w) => sum + w.balanceMinor.abs());

    // Sum all positive wallet balances
    final positiveWalletMinor = wallets
        .where((w) => w.balanceMinor > 0)
        .fold<int>(0, (sum, w) => sum + w.balanceMinor);

    // Gross assets = positive wallets + portfolio value
    final grossAssets = (positiveWalletMinor / 100.0) + totalAssets;
    final totalDebt = totalDebtMinor / 100.0;

    // Debt ratio = Debt / (Gross Assets + Debt)
    // This gives 0-1 range where 0.5 means debt equals assets
    final denominator = grossAssets + totalDebt;
    if (denominator <= 0) return 0.0;

    final debtRatio = totalDebt / denominator;
    return debtRatio.clamp(0.0, 1.0);
  }

  /// Get Coach Advice based on financial health metrics
  /// UPGRADED: Now includes Growth, Diversity, Inflation Risk, and Concentration Risk
  /// Rules evaluated in strict priority order - returns FIRST matching rule
  static CoachAdvice getCoachAdvice({
    required double liquidityScore,
    required double debtRatio,
    double growthScore = 0.0,
    double diversityScore = 0.0,
    double totalAssetsTRY = 0.0,
  }) {
    // Priority 1: CRITICAL - Liquidity Risk
    if (liquidityScore < 0.5) {
      return CoachAdvice(
        message: "Acil durum! Nakit rezervin kritik seviyede.",
        severity: CoachSeverity.critical,
      );
    }

    // Priority 2: HIGH - Debt Risk
    if (debtRatio > 0.30) {
      return CoachAdvice(
        message: "Borc yukun artiyor. Harcamalarini gozden gecir.",
        severity: CoachSeverity.warning,
      );
    }

    // Priority 3: Concentration Risk (Single asset dominance)
    if (diversityScore < 0.2 && totalAssetsTRY > 5000) {
      return CoachAdvice(
        message:
            "Risk uyarisi: Tum yumurtalar ayni sepette! Portfoyunu cesitlendir.",
        severity: CoachSeverity.warning,
      );
    }

    // Priority 4: Inflation Risk (Too much cash, not investing)
    if (growthScore < 0.2) {
      return CoachAdvice(
        message: "Paran enflasyonda eriyor. Nakitte cok bekliyorsun.",
        severity: CoachSeverity.warning,
      );
    }

    // Priority 5: SUCCESS - Growth Investor
    if (growthScore > 0.5) {
      return CoachAdvice(
        message: "Tebrikler! Varliklarin senin icin calisiyor.",
        severity: CoachSeverity.success,
      );
    }

    // Priority 6: Default - Balanced
    return CoachAdvice(
      message: "Finansal sagligin dengeli gorunuyor.",
      severity: CoachSeverity.success,
    );
  }

  /// Calculate Growth Score (0.0 - 1.0)
  /// Growth = totalAssets / (usableCash + totalAssets)
  /// Measures what percentage of net worth is invested and working
  static double calculateGrowthScore({
    required double usableCash,
    required double totalAssets,
  }) {
    final total = usableCash + totalAssets;
    if (total <= 0) {
      return 0.0;
    }

    final growthRatio = totalAssets / total;
    return growthRatio.clamp(0.0, 1.0);
  }

  /// Calculate Diversity Score (0.0 - 1.0)
  /// Diversity = 1 - (Largest Asset Value / Total Asset Value)
  /// Higher = more diversified portfolio
  static double calculateDiversityScore({
    required List<double> assetValuesTRY,
  }) {
    if (assetValuesTRY.isEmpty) {
      return 0.0;
    }

    if (assetValuesTRY.length == 1) {
      return 0.0; // Single asset = no diversity
    }

    final totalValue = assetValuesTRY.fold<double>(0, (sum, v) => sum + v);
    if (totalValue <= 0) {
      return 0.0;
    }

    final maxValue = assetValuesTRY.reduce((a, b) => a > b ? a : b);
    final concentrationRatio = maxValue / totalValue;

    // Diversity = 1 - concentration
    return (1 - concentrationRatio).clamp(0.0, 1.0);
  }

  // ============================================================
  // PHASE 5.2 — TREND ANALYSIS METHODS
  // ============================================================

  /// Turkish month abbreviations
  static const List<String> _monthLabels = [
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

  /// Prepare 6-month trend data for bar chart
  /// Returns data for last 6 months including the reference month
  static List<MonthlyTrendData> prepareMonthlyTrendData(
    List<FinanceTransaction> allTransactions,
    DateTime referenceDate,
  ) {
    final List<MonthlyTrendData> result = [];

    // Generate last 6 months (including current)
    for (int i = 5; i >= 0; i--) {
      final targetDate = DateTime(
        referenceDate.year,
        referenceDate.month - i,
        1,
      );
      final year = targetDate.year;
      final month = targetDate.month;
      final monthLabel = _monthLabels[month - 1];

      // Filter transactions for this month
      final monthTransactions = allTransactions
          .where((tx) => tx.date.year == year && tx.date.month == month)
          .toList();

      // Calculate totals
      int expenseTotal = 0;
      int investmentTotal = 0;
      int incomeTotal = 0;

      for (final tx in monthTransactions) {
        switch (tx.type) {
          case FinanceTransactionType.expense:
            // Exclude investment category from consumption
            if (tx.category != 'Yatırım' && tx.category != 'Investment') {
              expenseTotal += tx.amountMinor;
            }
            break;
          case FinanceTransactionType.investment:
            investmentTotal += tx.amountMinor;
            break;
          case FinanceTransactionType.income:
            incomeTotal += tx.amountMinor;
            break;
          default:
            break;
        }
      }

      result.add(MonthlyTrendData(
        monthLabel: monthLabel,
        year: year,
        month: month,
        expenseMinor: expenseTotal,
        investmentMinor: investmentTotal,
        incomeMinor: incomeTotal,
      ));
    }

    return result;
  }

  /// Generate month overview with deterministic insights
  /// STRICTLY NO AI - Pure math comparisons
  static MonthOverview generateMonthOverview(
    List<FinanceTransaction> allTransactions,
    DateTime referenceDate,
  ) {
    // Get this month's transactions
    final thisMonthTxs = allTransactions
        .where((tx) =>
            tx.date.year == referenceDate.year &&
            tx.date.month == referenceDate.month)
        .toList();

    // Get last month's transactions
    final lastMonth = DateTime(referenceDate.year, referenceDate.month - 1, 1);
    final lastMonthTxs = allTransactions
        .where((tx) =>
            tx.date.year == lastMonth.year && tx.date.month == lastMonth.month)
        .toList();

    // Calculate this month's totals
    int thisExpense = 0;
    int thisInvestment = 0;
    int thisIncome = 0;
    final Map<String, int> categoryTotals = {};

    for (final tx in thisMonthTxs) {
      if (tx.type == FinanceTransactionType.expense &&
          tx.category != 'Yatırım' &&
          tx.category != 'Investment') {
        thisExpense += tx.amountMinor;
        categoryTotals[tx.category] =
            (categoryTotals[tx.category] ?? 0) + tx.amountMinor;
      } else if (tx.type == FinanceTransactionType.investment) {
        thisInvestment += tx.amountMinor;
      } else if (tx.type == FinanceTransactionType.income) {
        thisIncome += tx.amountMinor;
      }
    }

    // Calculate last month's totals
    int lastExpense = 0;
    int lastInvestment = 0;

    for (final tx in lastMonthTxs) {
      if (tx.type == FinanceTransactionType.expense &&
          tx.category != 'Yatırım' &&
          tx.category != 'Investment') {
        lastExpense += tx.amountMinor;
      } else if (tx.type == FinanceTransactionType.investment) {
        lastInvestment += tx.amountMinor;
      }
    }

    // Find top category
    String topCategory = 'Veri yok';
    int topCategoryAmount = 0;
    if (categoryTotals.isNotEmpty) {
      final sorted = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topCategory = sorted.first.key;
      topCategoryAmount = sorted.first.value;
    }

    // Calculate spending change
    double spendingChangePercent = 0;
    String spendingChange;
    if (lastExpense == 0 && thisExpense == 0) {
      spendingChange = 'Harcama yok';
    } else if (lastExpense == 0) {
      spendingChange = 'Geçen ay harcama yoktu';
      spendingChangePercent = 100;
    } else {
      spendingChangePercent = ((thisExpense - lastExpense) / lastExpense) * 100;
      if (spendingChangePercent > 5) {
        spendingChange =
            'Harcamalar %${spendingChangePercent.abs().toStringAsFixed(0)} arttı';
      } else if (spendingChangePercent < -5) {
        spendingChange =
            'Harcamalar %${spendingChangePercent.abs().toStringAsFixed(0)} azaldı';
      } else {
        spendingChange = 'Harcamalar sabit';
      }
    }

    // Calculate investment change
    double investmentChangePercent = 0;
    String investmentChange;
    if (lastInvestment == 0 && thisInvestment == 0) {
      investmentChange = 'Yatırım yok';
    } else if (lastInvestment == 0) {
      investmentChange = 'Bu ay yatırım yaptın!';
      investmentChangePercent = 100;
    } else {
      investmentChangePercent =
          ((thisInvestment - lastInvestment) / lastInvestment) * 100;
      if (investmentChangePercent > 5) {
        investmentChange =
            'Yatırımlar %${investmentChangePercent.abs().toStringAsFixed(0)} arttı';
      } else if (investmentChangePercent < -5) {
        investmentChange =
            'Yatırımlar %${investmentChangePercent.abs().toStringAsFixed(0)} azaldı';
      } else {
        investmentChange = 'Yatırımlar sabit';
      }
    }

    // Calculate net balance
    final netBalance = thisIncome - thisExpense - thisInvestment;

    return MonthOverview(
      topCategory: topCategory,
      topCategoryAmount: topCategoryAmount,
      spendingChange: spendingChange,
      spendingChangePercent: spendingChangePercent,
      investmentChange: investmentChange,
      investmentChangePercent: investmentChangePercent,
      netBalanceMinor: netBalance,
    );
  }
}

/// Coach Severity levels for advice cards
enum CoachSeverity { critical, warning, success }

/// Coach Advice data model
class CoachAdvice {
  final String message;
  final CoachSeverity severity;

  CoachAdvice({required this.message, required this.severity});
}
