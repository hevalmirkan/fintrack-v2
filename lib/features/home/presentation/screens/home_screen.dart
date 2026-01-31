import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Core utilities
import '../../../../core/utils/currency_formatter.dart';
// Feature imports
import '../../../finance/data/finance_provider.dart';
import '../../../finance/domain/models/finance_transaction.dart';
import '../../../finance/domain/models/wallet.dart';
import '../../../assets/presentation/providers/asset_providers.dart';
import '../widgets/future_obligations_widget.dart';
import '../../../finance/presentation/screens/monthly_summary_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Uses central CurrencyFormatter for consistent Turkish locale formatting
  String _formatCurrency(int amountMinor) =>
      CurrencyFormatter.formatFromMinor(amountMinor);
  String _formatCurrencyDouble(double amount) =>
      CurrencyFormatter.format(amount);

  // Frosted hero card mini stat widget
  Widget _buildMiniStat(String label, double value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            Text(
              CurrencyFormatter.format(value),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// PHASE 5.9: Minimal wallet creation bottom sheet
  /// NO profile data collected - only wallet name + type
  void _showCreateWalletSheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    WalletType selectedType = WalletType.cash;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Yeni Cüzdan',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Wallet Name Input
              const Text('Cüzdan Adı',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Örn: Nakit, Banka Hesabım',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: const Color(0xFF1E2230),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Wallet Type Selector
              const Text('Cüzdan Türü',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: WalletType.values.map((type) {
                  final isSelected = type == selectedType;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.withOpacity(0.2)
                            : const Color(0xFF1E2230),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        '${type.icon} ${type.displayName}',
                        style: TextStyle(
                          color: isSelected ? Colors.blue : Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Create Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Cüzdan adı gerekli'),
                            backgroundColor: Colors.red),
                      );
                      return;
                    }

                    // Create wallet with minimal data
                    final wallet = Wallet(
                      id: 'wallet_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      type: selectedType,
                      balanceMinor: 0, // Start with 0 balance
                      isActive: true,
                      createdAt: DateTime.now(),
                    );

                    ref.read(financeProvider.notifier).addWallet(wallet);
                    Navigator.pop(ctx);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name oluşturuldu ✅'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Oluştur',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Logic katmanını dinliyoruz
    final state = ref.watch(financeProvider);

    // Yardımcı verileri (derived state) alıyoruz
    final monthlyIncome = ref.watch(monthlyIncomeMinorProvider);
    final monthlyExpense = ref.watch(monthlyExpenseMinorProvider);
    final recentTransactions = ref.watch(recentTransactionsProvider);

    // 🔴 SINGLE SOURCE OF TRUTH: Get asset total in TRY (with USD-TRY conversion)
    final assetTotalTRYAsync = ref.watch(totalPortfolioValueTRYProvider);
    final assetTotalTRY = assetTotalTRYAsync.when(
      data: (v) => v,
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );

    // Cash balance in TRY (already in TRY minor units / 100)
    final cashBalanceTRY = state.totalBalanceMinor / 100.0;

    // Combined Net Worth = Cash Balance (TRY) + Asset Value (TRY)
    final totalNetWorthTRY = cashBalanceTRY + assetTotalTRY;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1012), // Carbon gunmetal
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Merhaba 👋',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Text(
              'FinTrack',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        ),
        // REMOVED: Duplicate settings icon - already in parent DashboardScreen AppBar
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // 🆕 PHASE 5.9: EMPTY STATE - No wallets
              if (state.wallets.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          color: Colors.blue.withOpacity(0.5), size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Henüz cüzdanın yok',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Gelir ve giderlerini takip etmek için\nbir cüzdan oluştur',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateWalletSheet(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('Cüzdan Oluştur'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 1. FROSTED HERO CARD (Net Varlık) - Gradient + Glow
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: Theme.of(context).brightness == Brightness.dark
                      ? const LinearGradient(
                          colors: [Color(0xFF1F2833), Color(0xFF141E30)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00BFA5).withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.account_balance_wallet,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Toplam Varlık',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _formatCurrencyDouble(totalNetWorthTRY),
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: totalNetWorthTRY < 0
                            ? const Color(0xFFFF5252)
                            : Colors.white,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildMiniStat('Nakit', cashBalanceTRY),
                        const SizedBox(width: 24),
                        _buildMiniStat('Yatırım', assetTotalTRY),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. YEŞİL VE MAVİ KUTULAR (Kullanılabilir Nakit / Varlıklar)
              // Not: Tasarımda yan yana değil alt alta görünüyor olabilir ama grid yapısı daha uygun.
              // Görseldeki gibi 2x2 Grid yapısı:
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      'Kullanılabilir Nakit',
                      _formatCurrency(state.totalBalanceMinor),
                      // GREEN if positive, RED if negative
                      state.totalBalanceMinor >= 0
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      state.totalBalanceMinor >= 0
                          ? const Color(0xFF1B2A22)
                          : const Color(0xFF2A1B1B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      'Varlıklar',
                      _formatCurrencyDouble(
                          assetTotalTRY), // TRY converted value
                      Colors.blueAccent,
                      const Color(0xFF1A233A), // Koyu mavi bg
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      'Aylık Gelir',
                      _formatCurrency(monthlyIncome),
                      Colors.greenAccent,
                      const Color(0xFF1B2A22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      'Aylık Gider',
                      _formatCurrency(monthlyExpense),
                      Colors.redAccent,
                      const Color(0xFF2A1B1B), // Koyu kırmızı bg
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 🆕 PHASE 3.3: Future Monthly Obligations Widget
              const FutureObligationsWidget(),

              const SizedBox(height: 12),

              // 🆕 PHASE 5.1: Monthly Summary Button
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MonthlySummaryScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade900, Colors.indigo.shade900],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Aylık Özet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios,
                          color: Colors.white70, size: 14),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 🆕 PHASE 7: AI Coach Button
              InkWell(
                onTap: () => context.push('/coach'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade900, Colors.cyan.shade900],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🧠', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text(
                        'AI Koç',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios,
                          color: Colors.white70, size: 14),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 🆕 PHASE 8: Financial Goals Button
              InkWell(
                onTap: () => context.push('/goals'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade900, Colors.orange.shade900],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🎯', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text(
                        'Hedeflerim',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios,
                          color: Colors.white70, size: 14),
                    ],
                  ),
                ),
              ),

              // Hardcoded credit card widget REMOVED - was showing fake static data

              const SizedBox(height: 24),

              // 4. SON İŞLEMLER BAŞLIĞI
              const Text(
                'Son İşlemler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              // 5. SON İŞLEMLER LİSTESİ
              if (recentTransactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Henüz işlem yok',
                      style: TextStyle(color: Colors.grey)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentTransactions.length,
                  itemBuilder: (context, index) {
                    final tx = recentTransactions[index];

                    // PHASE 1: Color based on TransactionType
                    Color amountColor;
                    switch (tx.type) {
                      case FinanceTransactionType.income:
                        amountColor = const Color(0xFF69F0AE); // Green
                        break;
                      case FinanceTransactionType.expense:
                        amountColor = const Color(0xFFFF5252); // Red
                        break;
                      case FinanceTransactionType.investment:
                        amountColor = const Color(0xFF7C4DFF); // Purple
                        break;
                      case FinanceTransactionType.transfer:
                        amountColor = const Color(0xFF64B5F6); // Blue
                        break;
                      case FinanceTransactionType.adjustment:
                        amountColor = Colors.grey;
                        break;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              // Use displayTitle (title if available, else category)
                              tx.displayTitle,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${tx.type.reducesBalance ? '-' : '+'}${_formatCurrency(tx.amountMinor)}',
                            style: TextStyle(
                              color: amountColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 80), // Fab için boşluk
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      String title, String value, Color valueColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: valueColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
