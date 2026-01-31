import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../finance/data/finance_provider.dart';
import '../../../finance/domain/models/finance_transaction.dart';
import '../../../finance/domain/models/wallet.dart';
import '../../../assets/presentation/providers/asset_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'analysis_logic_helper.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TimeRange _selectedRange = TimeRange.thisMonth;
  int _touchedPieIndex = -1;
  int _analysisMode = 0; // 0 = Tüketim (Consumption), 1 = Yatırım (Investment)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        title: const Text('Finansal Analiz',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6200EA),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Finansal Sağlık'),
            Tab(text: 'Harcama Analizi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFinancialHealthTab(),
          _buildExpenseAnalysisTab(),
        ],
      ),
    );
  }

  // ============================================
  // TAB 1: FINANSAL SAĞLIK (REAL DATA Dashboard)
  // ============================================
  Widget _buildFinancialHealthTab() {
    final state = ref.watch(financeProvider);
    final wallets = state.wallets;
    final transactions = state.transactions;

    // Calculate monthly expense (current month)
    final now = DateTime.now();
    final monthlyExpense = transactions
            .where((t) =>
                t.type == FinanceTransactionType.expense &&
                t.date.month == now.month &&
                t.date.year == now.year)
            .fold<int>(0, (sum, t) => sum + t.amountMinor) /
        100.0;

    // 🔴 WATCH: Asset data in TRY (Single Source of Truth)
    final totalAssetsTRYAsync = ref.watch(totalPortfolioValueTRYProvider);
    final totalAssetsTRY = totalAssetsTRYAsync.when(
      data: (v) => v,
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );

    final assetValuesTRYAsync = ref.watch(assetValuesTRYProvider);
    final assetValuesTRY = assetValuesTRYAsync.when(
      data: (v) => v,
      loading: () => <double>[],
      error: (_, __) => <double>[],
    );

    // Calculate cash balance in TRY (positive only - for display)
    final cashBalanceTRY = wallets
            .where((w) => w.balanceMinor > 0)
            .fold<int>(0, (sum, w) => sum + w.balanceMinor) /
        100.0;

    // Calculate NET cash balance (includes negative balances for accurate Growth)
    final netCashBalanceTRY =
        wallets.fold<int>(0, (sum, w) => sum + w.balanceMinor) / 100.0;

    // Total Net Worth = Net Cash + Assets (both in TRY)
    final totalNetWorthTRY = netCashBalanceTRY + totalAssetsTRY;

    // Calculate health metrics
    final liquidityScore = AnalysisLogicHelper.calculateLiquidityScore(
      wallets: wallets,
      monthlyExpense: monthlyExpense,
    );

    final debtRatio = AnalysisLogicHelper.calculateDebtRatio(
      wallets: wallets,
      totalAssets: totalAssetsTRY,
    );

    // Growth and Diversity scores
    // NOTE: Use netCashBalanceTRY for accurate Growth (handles negative cash)
    final growthScore = AnalysisLogicHelper.calculateGrowthScore(
      usableCash: netCashBalanceTRY,
      totalAssets: totalAssetsTRY,
    );

    final diversityScore = AnalysisLogicHelper.calculateDiversityScore(
      assetValuesTRY: assetValuesTRY,
    );

    // Get coach advice based on ALL metrics
    final coachAdvice = AnalysisLogicHelper.getCoachAdvice(
      liquidityScore: liquidityScore,
      debtRatio: debtRatio,
      growthScore: growthScore,
      diversityScore: diversityScore,
      totalAssetsTRY: totalAssetsTRY,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('📊 Detaylı Analiz'),
          const SizedBox(height: 12),
          // Pass all 4 scores
          _buildAnalysisCardWithGrowth(
            liquidityScore: liquidityScore,
            debtRatio: debtRatio,
            growthScore: growthScore,
            diversityScore: diversityScore,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('📈 Piyasa Durumu'),
          const SizedBox(height: 12),
          _buildMarketTicker(),
          const SizedBox(height: 24),
          _buildSectionHeader('🤖 Finansal Koçun'),
          const SizedBox(height: 12),
          _buildCoachCardReal(coachAdvice),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Analysis card with all 4 health metrics: Liquidity, Debt, Growth, Diversity
  Widget _buildAnalysisCardWithGrowth({
    required double liquidityScore,
    required double debtRatio,
    required double growthScore,
    required double diversityScore,
  }) {
    // Determine colors based on values
    Color liquidityColor;
    if (liquidityScore >= 0.7) {
      liquidityColor = Colors.green;
    } else if (liquidityScore >= 0.4) {
      liquidityColor = Colors.orange;
    } else {
      liquidityColor = Colors.red;
    }

    Color debtColor;
    if (debtRatio <= 0.15) {
      debtColor = Colors.green;
    } else if (debtRatio <= 0.30) {
      debtColor = Colors.orange;
    } else {
      debtColor = Colors.red;
    }

    // Growth: Higher = Better (investing more)
    Color growthColor;
    if (growthScore >= 0.50) {
      growthColor = Colors.green;
    } else if (growthScore >= 0.20) {
      growthColor = Colors.orange;
    } else {
      growthColor = Colors.grey;
    }

    // Diversity: Higher = Better (spread across assets)
    Color diversityColor;
    if (diversityScore >= 0.50) {
      diversityColor = Colors.green;
    } else if (diversityScore >= 0.20) {
      diversityColor = Colors.orange;
    } else if (diversityScore > 0) {
      diversityColor = Colors.orange;
    } else {
      diversityColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2230),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildProgressItem(
              'Likitide (Nakit Gücü)', liquidityScore, liquidityColor),
          const SizedBox(height: 16),
          _buildProgressItem('Borç Yükü (Risk)', debtRatio, debtColor),
          const SizedBox(height: 16),
          _buildProgressItem('Büyüme (Varlık Oranı)', growthScore, growthColor),
          const SizedBox(height: 16),
          _buildProgressItem('Çeşitlilik', diversityScore, diversityColor),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            Text('${(value * 100).toInt()}%',
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildMarketTicker() {
    final marketData = [
      {'symbol': 'BTC', 'price': '\$95,180', 'change': '+2.4%', 'isUp': true},
      {'symbol': 'ETH', 'price': '\$3,420', 'change': '+1.8%', 'isUp': true},
      {'symbol': 'USD', 'price': '₺35.80', 'change': '+0.3%', 'isUp': true},
      {'symbol': 'EUR', 'price': '₺38.45', 'change': '-0.2%', 'isUp': false},
      {'symbol': 'XAU', 'price': '\$2,650', 'change': '+0.5%', 'isUp': true},
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: marketData.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = marketData[index];
          return Container(
            width: 110,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2230),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item['symbol'] as String,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(item['price'] as String,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 2),
                Text(item['change'] as String,
                    style: TextStyle(
                        color:
                            (item['isUp'] as bool) ? Colors.green : Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCoachCardReal(CoachAdvice advice) {
    IconData icon;
    String title;
    Color color;

    switch (advice.severity) {
      case CoachSeverity.critical:
        icon = Icons.error_outline;
        title = 'Dikkat! Kritik Durum';
        color = Colors.red;
      case CoachSeverity.warning:
        icon = Icons.warning_amber_rounded;
        title = 'Uyarı';
        color = Colors.orange;
      case CoachSeverity.success:
        icon = Icons.check_circle_outline;
        title = 'Harika Gidiyorsun!';
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 6),
                Text(advice.message,
                    style:
                        TextStyle(color: color.withOpacity(0.8), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // TAB 2: HARCAMA ANALİZİ (Polished Vertical Cards)
  // ============================================
  Widget _buildExpenseAnalysisTab() {
    final state = ref.watch(financeProvider);
    final allTransactions = state.transactions;
    final wallets = state.wallets;

    final filteredTxs =
        AnalysisLogicHelper.filterTransactions(allTransactions, _selectedRange);

    // Conditional data based on mode
    final isInvestmentMode = _analysisMode == 1;

    // Consumption Mode Data
    final pieData = AnalysisLogicHelper.prepareExpensePieData(filteredTxs);
    final walletStats =
        AnalysisLogicHelper.prepareWalletStats(filteredTxs, wallets);
    final totalExpense = AnalysisLogicHelper.calculateTotalExpense(filteredTxs);

    // Investment Mode Data
    final investmentPieData =
        AnalysisLogicHelper.prepareInvestmentPieData(filteredTxs);
    final totalInvestment =
        investmentPieData.fold<int>(0, (sum, p) => sum + p.amountMinor);
    final investmentStats =
        AnalysisLogicHelper.calculateInvestmentStats(filteredTxs);

    // Shared Data
    final netFlow = AnalysisLogicHelper.calculateNetFlow(filteredTxs);
    final dailySpots =
        AnalysisLogicHelper.prepareDailyStats(filteredTxs, _selectedRange);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Filter
          _buildTimeFilter(),
          const SizedBox(height: 12),

          // 🔴 MODE TOGGLE: Tüketim vs Yatırım
          _buildModeToggle(),
          const SizedBox(height: 16),

          // 🆕 PHASE 5.2: Month Overview (Deterministic Insights)
          _buildMonthOverviewCard(allTransactions),
          const SizedBox(height: 16),

          // 🆕 PHASE 5.2: 6-Month Trend Chart
          _buildTrendChartCard(allTransactions),
          const SizedBox(height: 20),

          // CONDITIONAL CONTENT based on mode
          if (!isInvestmentMode) ...[
            // 🍔 CONSUMPTION MODE: Show traditional expense charts

            // Card 1: Category Breakdown (Donut with Legend)
            _buildChartCard(
              title: '🍔 Tüketim Dağılımı',
              height: 280,
              child: pieData.isEmpty
                  ? _buildEmptyState('Bu dönem için tüketim verisi yok')
                  : _buildCategoryDonut(pieData, totalExpense),
            ),
            const SizedBox(height: 16),

            // Card 2: Wallet Split (Nakit vs Kredi)
            _buildChartCard(
              title: '💳 Ödeme Yöntemi',
              height: 200,
              child: walletStats.isEmpty
                  ? _buildEmptyState('Cüzdan verisi yok')
                  : _buildWalletPie(walletStats),
            ),
            const SizedBox(height: 16),

            // Card 3: Net Flow (Income vs Expense Bar)
            _buildChartCard(
              title: '📊 Gelir vs Gider',
              height: 180,
              child: _buildNetFlowBar(netFlow),
            ),
            const SizedBox(height: 16),

            // Card 4: Daily Pulse (Line Chart)
            _buildChartCard(
              title: '📈 Günlük Harcama Trendi',
              height: 220,
              child: dailySpots.isEmpty || dailySpots.every((s) => s.y == 0)
                  ? _buildEmptyState('Günlük veri yok')
                  : _buildDailyPulseLine(dailySpots),
            ),
          ] else ...[
            // 📈 INVESTMENT MODE: Show investment-focused charts

            // Card 1: Total Invested Summary
            _buildInvestmentSummaryCard(totalInvestment),
            const SizedBox(height: 16),

            // Card 2: Investment Breakdown (by Asset)
            _buildChartCard(
              title: '📊 Yatırım Dağılımı',
              height: 280,
              child: investmentPieData.isEmpty
                  ? _buildEmptyState('Bu dönem için yatırım verisi yok')
                  : _buildCategoryDonut(investmentPieData, totalInvestment),
            ),
            const SizedBox(height: 16),

            // Card 3: Investment Behavior Stats (NEW - replaces trend chart)
            _buildInvestmentStatsRow(investmentStats),
          ],

          const SizedBox(height: 50),
        ],
      ),
    );
  }

  /// Mode Toggle: Tüketim (Consumption) vs Yatırım (Investment)
  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2230),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildModeButton(0, '🍔 Tüketim', const Color(0xFFFF6B6B)),
          _buildModeButton(1, '📈 Yatırım', const Color(0xFF00D09C)),
        ],
      ),
    );
  }

  Widget _buildModeButton(int mode, String label, Color activeColor) {
    final isActive = _analysisMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _analysisMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive ? Border.all(color: activeColor, width: 2) : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Investment Summary Card: Big number showing total invested
  Widget _buildInvestmentSummaryCard(int totalMinor) {
    final amount = totalMinor / 100.0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Toplam Yatırım',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₺${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu dönemde yaptığınız yatırımlar',
            style:
                TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Investment Stats Row: 3 cards showing frequency, average, and last investment
  Widget _buildInvestmentStatsRow(InvestmentStats stats) {
    return Row(
      children: [
        // Card 1: Frequency (İşlem Adedi)
        Expanded(
          child: _buildStatCard(
            icon: Icons.history,
            title: 'İşlem Adedi',
            value: '${stats.count} adet',
            color: const Color(0xFF00D09C),
          ),
        ),
        const SizedBox(width: 8),

        // Card 2: Average (Ort. Tutar)
        Expanded(
          child: _buildStatCard(
            icon: Icons.show_chart,
            title: 'Ort. Tutar',
            value: '₺${stats.averageAmount.toStringAsFixed(0)}',
            color: const Color(0xFF6200EA),
          ),
        ),
        const SizedBox(width: 8),

        // Card 3: Last Investment (Son Yatırım)
        Expanded(
          child: _buildStatCard(
            icon: Icons.update,
            title: 'Son Yatırım',
            value: stats.lastAssetName,
            subtitle: stats.lastInvestmentDate,
            color: const Color(0xFF00897B),
          ),
        ),
      ],
    );
  }

  /// Individual stat card widget
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2230),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon with accent color
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          // Title label - light grey for visibility
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade400, // Brighter grey for legibility
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          // Value - WHITE for maximum contrast
          Text(
            value,
            style: const TextStyle(
              color: Colors.white, // Always white for contrast
              fontSize: 18, // Larger for readability
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade500, // Slightly brighter
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // PHASE 5.2 — TREND ANALYSIS UI COMPONENTS
  // ============================================================

  /// Month Overview Card - Deterministic insights at a glance
  Widget _buildMonthOverviewCard(List<FinanceTransaction> allTransactions) {
    final overview = AnalysisLogicHelper.generateMonthOverview(
      allTransactions,
      DateTime.now(),
    );

    // Format net balance
    final netAmount = overview.netBalanceMinor / 100;
    final netColor = overview.netBalanceMinor >= 0 ? Colors.green : Colors.red;
    final netSign = overview.netBalanceMinor >= 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E2230),
            const Color(0xFF161B22),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D3748)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, color: Color(0xFF6200EA), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Bu Ay Özeti',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Insight Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Top Category
              if (overview.topCategory != 'Veri yok')
                _buildInsightChip(
                  '🏆 En çok: ${overview.topCategory}',
                  Colors.orange,
                ),

              // Spending Change
              _buildInsightChip(
                overview.spendingChange,
                overview.spendingChangePercent > 5
                    ? Colors.red
                    : overview.spendingChangePercent < -5
                        ? Colors.green
                        : Colors.grey,
              ),

              // Investment Change
              if (overview.investmentChange != 'Yatırım yok')
                _buildInsightChip(
                  overview.investmentChange,
                  Colors.blue,
                ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFF2D3748)),
          const SizedBox(height: 8),

          // Net Balance Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Net Bakiye',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              Text(
                '$netSign${CurrencyFormatter.format(overview.netBalanceMinor.abs() / 100)}',
                style: TextStyle(
                  color: netColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 6-Month Trend Chart - Bar chart comparing expense vs investment
  Widget _buildTrendChartCard(List<FinanceTransaction> allTransactions) {
    final trendData = AnalysisLogicHelper.prepareMonthlyTrendData(
      allTransactions,
      DateTime.now(),
    );

    // Check if any data exists
    final hasData =
        trendData.any((d) => d.expenseMinor > 0 || d.investmentMinor > 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D3748)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: Color(0xFF00D09C), size: 20),
              const SizedBox(width: 8),
              const Text(
                '6 Aylık Trend',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Legend
          Row(
            children: [
              _buildLegendItem('Tüketim', const Color(0xFFFF6B6B)),
              const SizedBox(width: 16),
              _buildLegendItem('Yatırım', const Color(0xFF4CAF50)),
            ],
          ),
          const SizedBox(height: 16),

          // Chart
          SizedBox(
            height: 180,
            child: hasData
                ? _buildTrendBarChart(trendData)
                : Center(
                    child: Text(
                      'Trend verisi yok',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTrendBarChart(List<MonthlyTrendData> data) {
    // Find max value for scaling
    int maxValue = 1; // Avoid division by zero
    for (final d in data) {
      if (d.expenseMinor > maxValue) maxValue = d.expenseMinor;
      if (d.investmentMinor > maxValue) maxValue = d.investmentMinor;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((d) {
        final expenseHeight = (d.expenseMinor / maxValue) * 140;
        final investmentHeight = (d.investmentMinor / maxValue) * 140;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Bars side by side
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Expense bar (red)
                    Container(
                      width: 14,
                      height: expenseHeight.clamp(4.0, 140.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 2),
                    // Investment bar (green)
                    Container(
                      width: 14,
                      height: investmentHeight.clamp(4.0, 140.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Month label
                Text(
                  d.monthLabel,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeFilter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2230),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildFilterButton('Bu Ay', TimeRange.thisMonth),
          _buildFilterButton('Geçen Ay', TimeRange.lastMonth),
          _buildFilterButton('Yıl', TimeRange.thisYear),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String text, TimeRange range) {
    final isSelected = _selectedRange == range;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRange = range),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6200EA) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard(
      {required String title, required double height, required Widget child}) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2230),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bar_chart_outlined, color: Colors.white24, size: 40),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }

  // Card 1: Category Donut with Legend
  Widget _buildCategoryDonut(List<PieData> data, int totalExpense) {
    return Row(
      children: [
        // Donut Chart with Total in Center
        Expanded(
          flex: 3,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedPieIndex = -1;
                          return;
                        }
                        _touchedPieIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 3,
                  centerSpaceRadius: 45,
                  sections: List.generate(data.length, (i) {
                    final isTouched = i == _touchedPieIndex;
                    final radius = isTouched ? 55.0 : 45.0;
                    final item = data[i];

                    return PieChartSectionData(
                      color: _getPieColor(i, item.isOther),
                      value: item.percentage,
                      title: isTouched
                          ? '${item.percentage.toStringAsFixed(0)}%'
                          : '',
                      radius: radius,
                      titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    );
                  }),
                ),
              ),
              // Center Total
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Toplam',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                  Text(
                    AnalysisLogicHelper.formatCurrency(totalExpense),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Legend
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getPieColor(i, item.isOther),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.category,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${item.percentage.toStringAsFixed(0)}%',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Card 2: Wallet Pie (Nakit vs Kredi)
  Widget _buildWalletPie(List<WalletStats> data) {
    return Row(
      children: [
        // Pie
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              borderData: FlBorderData(show: false),
              sectionsSpace: 3,
              centerSpaceRadius: 25,
              sections: data.asMap().entries.map((entry) {
                final item = entry.value;
                final color = _getWalletColor(item.walletType);

                return PieChartSectionData(
                  color: color,
                  value: item.percentage,
                  title: '${item.percentage.toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 20),
        // Legend
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.map((item) {
              final color = _getWalletColor(item.walletType);
              final icon = item.walletType == WalletType.cash ? '💵' : '💳';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Text('$icon ${item.walletName}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14)),
                    const Spacer(),
                    Text(
                      AnalysisLogicHelper.formatCurrency(item.totalExpense),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Card 3: Net Flow Bar
  Widget _buildNetFlowBar(NetFlowData flow) {
    final maxVal = flow.totalIncome > flow.totalExpense
        ? flow.totalIncome
        : flow.totalExpense;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFlowRow(
            'Gelir', flow.totalIncome, maxVal, const Color(0xFF69F0AE)),
        const SizedBox(height: 16),
        _buildFlowRow(
            'Gider', flow.totalExpense, maxVal, const Color(0xFFFF5252)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: flow.net >= 0
                ? Colors.green.withOpacity(0.15)
                : Colors.red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Net: ${flow.net >= 0 ? '+' : ''}${AnalysisLogicHelper.formatCurrency(flow.net)}',
            style: TextStyle(
              color: flow.net >= 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlowRow(String label, int value, int maxVal, Color color) {
    final ratio = maxVal > 0 ? value / maxVal : 0.0;
    return Row(
      children: [
        SizedBox(
            width: 50,
            child: Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 13))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            AnalysisLogicHelper.formatCurrency(value),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // Card 4: Daily Pulse Line Chart
  Widget _buildDailyPulseLine(List<FlSpot> spots) {
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 4 : 100,
          getDrawingHorizontalLine: (value) =>
              const FlLine(color: Colors.white10, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _selectedRange == TimeRange.thisYear ? 1 : 7,
              getTitlesWidget: (value, meta) {
                if (_selectedRange == TimeRange.thisYear) {
                  const months = [
                    'O',
                    'Ş',
                    'M',
                    'N',
                    'M',
                    'H',
                    'T',
                    'A',
                    'E',
                    'E',
                    'K',
                    'A'
                  ];
                  if (value.toInt() >= 1 && value.toInt() <= 12) {
                    return Text(months[value.toInt() - 1],
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10));
                  }
                } else {
                  return Text('${value.toInt()}',
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 10));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxY * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: const Color(0xFF6200EA),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6200EA).withOpacity(0.4),
                  const Color(0xFF6200EA).withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => const Color(0xFF1E2230),
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final label = _selectedRange == TimeRange.thisYear
                    ? 'Ay ${spot.x.toInt()}'
                    : 'Gün ${spot.x.toInt()}';
                return LineTooltipItem(
                  '$label\n₺${spot.y.toStringAsFixed(0)}',
                  const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Color _getPieColor(int index, bool isOther) {
    if (isOther) return Colors.grey;
    const colors = [
      Color(0xFF6200EA),
      Color(0xFF2962FF),
      Color(0xFF00BFA5),
      Color(0xFFFFAB00),
      Color(0xFFD50000),
    ];
    return colors[index % colors.length];
  }

  Color _getWalletColor(WalletType type) {
    switch (type) {
      case WalletType.cash:
        return const Color(0xFF00E676);
      case WalletType.creditCard:
        return const Color(0xFFFF9800);
      case WalletType.bankAccount:
        return const Color(0xFF2196F3);
      case WalletType.digitalWallet:
        return const Color(0xFF9C27B0);
      case WalletType.savings:
        return const Color(0xFF4CAF50);
      case WalletType.investment:
        return const Color(0xFFFFEB3B);
    }
  }
}
