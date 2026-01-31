// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../finance/domain/services/monthly_summary_logic.dart';

/// ====================================================
/// PHASE 5.1 — MONTHLY SUMMARY SCREEN (FIXED)
/// ====================================================
///
/// PURPOSE: Answer "Bu ay finansal olarak nasılım?"
/// READ-ONLY: No mutations, pure visualization.
///
/// FIX v2:
/// - Professional Turkish number formatting (₺10.256,00)
/// - State triggers rebuild on month change
/// ====================================================

class MonthlySummaryScreen extends ConsumerStatefulWidget {
  const MonthlySummaryScreen({super.key});

  @override
  ConsumerState<MonthlySummaryScreen> createState() =>
      _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends ConsumerState<MonthlySummaryScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
    print(
        '[SUMMARY_SCREEN] Switched to: ${_selectedMonth.month}/${_selectedMonth.year}');
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    // Don't allow going past current month
    if (next.isBefore(DateTime(now.year, now.month + 1, 1))) {
      setState(() {
        _selectedMonth = next;
      });
      print(
          '[SUMMARY_SCREEN] Switched to: ${_selectedMonth.month}/${_selectedMonth.year}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Create calculator - uses ref.watch internally for reactivity
    final calculator = MonthlySummaryCalculator(ref);
    final data = calculator.calculate(_selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aylık Özet'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Month Navigation
            _buildMonthSelector(),
            const SizedBox(height: 24),

            // Empty state or content
            if (data.isEmpty)
              _buildEmptyState()
            else ...[
              // Hero Card: Net Result
              _buildNetResultCard(data),
              const SizedBox(height: 24),

              // Breakdown Cards
              _buildBreakdownSection(data),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    final now = DateTime.now();
    final isCurrentMonth =
        _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: const Icon(Icons.chevron_left, color: Colors.white),
          ),
          Text(
            formatMonthYear(_selectedMonth),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: isCurrentMonth ? null : _nextMonth,
            icon: Icon(
              Icons.chevron_right,
              color: isCurrentMonth ? Colors.grey.shade600 : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Text(
            'Bu ay için veri yok.',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'İşlem ekledikçe özet burada görünecek.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNetResultCard(MonthlySummaryData data) {
    final isPositive = data.netResultMinor >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;
    final message = isPositive ? 'Bu ay biriktirdin' : 'Bu ay açık verdin';

    // Professional Turkish formatting using central CurrencyFormatter
    final amountText = isPositive
        ? '+${CurrencyFormatter.formatFromMinor(data.netResultMinor)}'
        : '-${CurrencyFormatter.formatFromMinor(-data.netResultMinor)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), Colors.grey.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 12),
          Text(
            amountText,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection(MonthlySummaryData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detaylı Döküm',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),

        // Income
        _buildBreakdownCard(
          icon: Icons.arrow_downward,
          iconColor: Colors.green,
          title: 'Gelir',
          amount: data.totalIncomeMinor,
          isPositive: true,
        ),
        const SizedBox(height: 8),

        // Consumption Expenses
        _buildBreakdownCard(
          icon: Icons.shopping_cart,
          iconColor: Colors.red,
          title: 'Tüketim Harcamaları',
          amount: data.consumptionExpensesMinor,
          isPositive: false,
        ),
        const SizedBox(height: 8),

        // Installments
        _buildBreakdownCard(
          icon: Icons.credit_card,
          iconColor: Colors.orange,
          title: 'Taksitler',
          subtitle: 'Aktif taksit planları',
          amount: data.installmentsMinor,
          isPositive: false,
        ),
        const SizedBox(height: 8),

        // Subscriptions
        _buildBreakdownCard(
          icon: Icons.subscriptions,
          iconColor: Colors.purple,
          title: 'Abonelikler',
          subtitle: 'Aktif abonelikler',
          amount: data.subscriptionsMinor,
          isPositive: false,
        ),
        const SizedBox(height: 8),

        // Investments (Info Only)
        _buildBreakdownCard(
          icon: Icons.trending_up,
          iconColor: Colors.blue,
          title: 'Yatırımlar',
          subtitle: '(Hesaba dahil değil)',
          amount: data.investmentExpensesMinor,
          isPositive: null, // Neutral
        ),
        const SizedBox(height: 8),

        // Shared Expenses Net
        _buildBreakdownCard(
          icon: Icons.group,
          iconColor: Colors.teal,
          title: 'Ortak Harcama (Net)',
          subtitle: data.sharedExpenseNetMinor >= 0
              ? 'Bana borçlular'
              : 'Benim borcum',
          amount: data.sharedExpenseNetMinor.abs(),
          isPositive: data.sharedExpenseNetMinor >= 0,
        ),
      ],
    );
  }

  Widget _buildBreakdownCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required int amount,
    bool? isPositive, // null = neutral
  }) {
    final amountColor = isPositive == null
        ? Colors.blue
        : isPositive
            ? Colors.green
            : Colors.red;

    final prefix = isPositive == null
        ? ''
        : isPositive
            ? '+'
            : '-';

    // Professional Turkish formatting using central CurrencyFormatter
    final formattedAmount =
        '$prefix${CurrencyFormatter.formatFromMinorShort(amount)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            formattedAmount,
            style: TextStyle(
              color: amountColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
