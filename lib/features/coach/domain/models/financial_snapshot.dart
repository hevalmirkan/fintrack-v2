/// =====================================================
/// FINANCIAL SNAPSHOT — Phase 7: AI Coach
/// =====================================================
/// Privacy-safe aggregated financial data for AI analysis.
/// Contains NO personal data, NO raw transaction descriptions.
/// =====================================================

/// Financial Snapshot for AI Coach consumption
/// Contains aggregated, privacy-safe financial metrics
class FinancialSnapshot {
  final DateTime generatedAt;

  // Monthly totals (current month)
  final double monthlyIncome;
  final double monthlyExpense;
  final double monthlyNet;

  // Previous month for comparison
  final double prevMonthIncome;
  final double prevMonthExpense;

  // Trends
  final double incomeChangePercent;
  final double expenseChangePercent;

  // Category breakdown (Top 5 expenses)
  final List<CategoryBreakdown> topExpenseCategories;
  final List<CategoryBreakdown> topIncomeCategories;

  // Asset summary
  final double totalAssetValue;
  final int assetCount;

  // Wallet summary
  final double totalCashBalance;
  final int walletCount;

  // Debt status (from Shared Expenses)
  final double totalOwed; // What user owes to others
  final double totalOwedToUser; // What others owe to user

  // Installments
  final double monthlyInstallmentPayment;
  final int activeInstallmentCount;

  // Subscriptions
  final double monthlySubscriptionCost;
  final int activeSubscriptionCount;

  const FinancialSnapshot({
    required this.generatedAt,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.monthlyNet,
    required this.prevMonthIncome,
    required this.prevMonthExpense,
    required this.incomeChangePercent,
    required this.expenseChangePercent,
    required this.topExpenseCategories,
    required this.topIncomeCategories,
    required this.totalAssetValue,
    required this.assetCount,
    required this.totalCashBalance,
    required this.walletCount,
    required this.totalOwed,
    required this.totalOwedToUser,
    required this.monthlyInstallmentPayment,
    required this.activeInstallmentCount,
    required this.monthlySubscriptionCost,
    required this.activeSubscriptionCount,
  });

  /// Convert to JSON for AI consumption (privacy-safe)
  Map<String, dynamic> toPromptJson() => {
        'analysis_date': generatedAt.toIso8601String(),
        'currency': 'TRY',
        'current_month': {
          'income': monthlyIncome,
          'expense': monthlyExpense,
          'net': monthlyNet,
        },
        'previous_month': {
          'income': prevMonthIncome,
          'expense': prevMonthExpense,
        },
        'trends': {
          'income_change_percent': incomeChangePercent,
          'expense_change_percent': expenseChangePercent,
        },
        'top_expense_categories': topExpenseCategories
            .map((c) => {
                  'category': c.category,
                  'amount': c.amount,
                  'percent': c.percentOfTotal
                })
            .toList(),
        'top_income_categories': topIncomeCategories
            .map((c) => {
                  'category': c.category,
                  'amount': c.amount,
                  'percent': c.percentOfTotal
                })
            .toList(),
        'assets': {
          'total_value_try': totalAssetValue,
          'count': assetCount,
        },
        'wallets': {
          'total_balance': totalCashBalance,
          'count': walletCount,
        },
        'debts': {
          'user_owes': totalOwed,
          'owed_to_user': totalOwedToUser,
          'net_debt': totalOwed - totalOwedToUser,
        },
        'obligations': {
          'monthly_installments': monthlyInstallmentPayment,
          'active_installment_count': activeInstallmentCount,
          'monthly_subscriptions': monthlySubscriptionCost,
          'active_subscription_count': activeSubscriptionCount,
        },
      };

  /// Empty snapshot for fallback
  static FinancialSnapshot empty() => FinancialSnapshot(
        generatedAt: DateTime.now(),
        monthlyIncome: 0,
        monthlyExpense: 0,
        monthlyNet: 0,
        prevMonthIncome: 0,
        prevMonthExpense: 0,
        incomeChangePercent: 0,
        expenseChangePercent: 0,
        topExpenseCategories: const [],
        topIncomeCategories: const [],
        totalAssetValue: 0,
        assetCount: 0,
        totalCashBalance: 0,
        walletCount: 0,
        totalOwed: 0,
        totalOwedToUser: 0,
        monthlyInstallmentPayment: 0,
        activeInstallmentCount: 0,
        monthlySubscriptionCost: 0,
        activeSubscriptionCount: 0,
      );
}

/// Category breakdown for expense/income analysis
class CategoryBreakdown {
  final String category;
  final double amount;
  final double percentOfTotal;

  const CategoryBreakdown({
    required this.category,
    required this.amount,
    required this.percentOfTotal,
  });
}
