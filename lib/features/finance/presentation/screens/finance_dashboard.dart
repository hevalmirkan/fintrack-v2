import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/finance_provider.dart';
import '../../domain/models/finance_transaction.dart';
import '../../domain/models/wallet.dart';

/// Finance Dashboard - Personal Finance Overview
///
/// This is an ISOLATED screen for Phase B-1.
/// NOT replacing HomeScreen yet - accessible via debug route.
///
/// Uses INT (minor units) for all calculations.
/// Converts to double ONLY for display.
class FinanceDashboard extends ConsumerWidget {
  const FinanceDashboard({super.key});

  /// Convert minor units (kuruş) to display string
  String _formatMoney(int amountMinor) {
    final amount = amountMinor / 100.0;
    if (amount.abs() >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeState = ref.watch(financeProvider);
    final recentTx = ref.watch(recentTransactionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Finans',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ayarlar yakında...')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Refresh data
        },
        color: const Color(0xFF00D09C),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Net Cash Balance Card
              _buildBalanceCard(financeState),

              const SizedBox(height: 20),

              // Monthly Flow Cards
              _buildMonthlyFlowCards(financeState),

              const SizedBox(height: 24),

              // Wallets Section
              _buildWalletsSection(financeState.wallets),

              const SizedBox(height: 24),

              // Recent Transactions
              _buildRecentTransactionsSection(context, recentTx),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddTransactionSheet(context);
        },
        backgroundColor: const Color(0xFF00D09C),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'İşlem Ekle',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(FinanceState state) {
    final isPositive = state.totalBalanceMinor >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2332), Color(0xFF0D1117)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF30363D)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D09C).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Net Nakit',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D09C).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${state.wallets.length} hesap',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF00D09C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₺${_formatMoney(state.totalBalanceMinor)}',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.white : Colors.red,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                state.monthlyNetFlowMinor >= 0
                    ? Icons.trending_up
                    : Icons.trending_down,
                color: state.monthlyNetFlowMinor >= 0
                    ? const Color(0xFF00D09C)
                    : Colors.red,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '${state.monthlyNetFlowMinor >= 0 ? '+' : ''}₺${_formatMoney(state.monthlyNetFlowMinor)} bu ay',
                style: TextStyle(
                  fontSize: 14,
                  color: state.monthlyNetFlowMinor >= 0
                      ? const Color(0xFF00D09C)
                      : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyFlowCards(FinanceState state) {
    return Row(
      children: [
        Expanded(
          child: _buildFlowCard(
            title: 'Aylık Gelir',
            amountMinor: state.monthlyIncomeMinor,
            icon: Icons.arrow_downward,
            color: const Color(0xFF00D09C),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFlowCard(
            title: 'Aylık Gider',
            amountMinor: state.monthlyExpenseMinor,
            icon: Icons.arrow_upward,
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _buildFlowCard({
    required String title,
    required int amountMinor,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₺${_formatMoney(amountMinor)}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletsSection(List<Wallet> wallets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hesaplar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Tümü',
                style: TextStyle(color: Color(0xFF00D09C)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: wallets.length,
            itemBuilder: (context, index) {
              return _buildWalletCard(wallets[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWalletCard(Wallet wallet) {
    final isNegative = wallet.balanceMinor < 0;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                wallet.type.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  wallet.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '₺${_formatMoney(wallet.balanceMinor)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isNegative ? Colors.red : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection(
    BuildContext context,
    List<FinanceTransaction> transactions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Son İşlemler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Tümü',
                style: TextStyle(color: Color(0xFF00D09C)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          _buildEmptyTransactions()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length.clamp(0, 5),
            itemBuilder: (context, index) {
              return _buildTransactionRow(transactions[index]);
            },
          ),
      ],
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 12),
            Text(
              'Henüz işlem yok',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionRow(FinanceTransaction tx) {
    final isExpense = tx.type == FinanceTransactionType.expense;
    final color = isExpense ? const Color(0xFFF59E0B) : const Color(0xFF00D09C);
    final dateFormat = DateFormat('dd MMM');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isExpense ? Icons.arrow_upward : Icons.arrow_downward,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Use displayTitle (title if available, else category)
                  tx.displayTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (tx.description != null)
                  Text(
                    tx.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isExpense ? '-' : '+'}₺${_formatMoney(tx.amountMinor)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                dateFormat.format(tx.date),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddTransactionSheet(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('İşlem ekleme yakında aktif olacak'),
        backgroundColor: Color(0xFF7C3AED),
      ),
    );
  }
}
