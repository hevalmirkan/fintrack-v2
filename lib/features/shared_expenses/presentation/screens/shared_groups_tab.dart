/// ====================================================
/// PHASE 4 STEP 2 — SHARED GROUPS TAB
/// ====================================================
///
/// UI CONTRACT:
/// This screen explains the shared debt clearly,
/// without changing it.
///
/// ❌ NO write actions (Add/Pay buttons)
/// ❌ NO business logic in UI
/// ✅ PURE VISUALIZATION of provider data
/// ====================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/shared_expense_models.dart';
import '../providers/shared_expense_provider.dart';
import 'group_detail_screen.dart';

/// SharedGroupsTab — Group List View
///
/// Displays all active shared expense groups.
/// Tapping a group navigates to GroupDetailScreen.
class SharedGroupsTab extends ConsumerWidget {
  const SharedGroupsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharedState = ref.watch(sharedExpenseProvider);
    final groups = sharedState.groups.where((g) => g.isActive).toList();

    // EMPTY STATE (MANDATORY)
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'Henüz ortak harcama grubun yok.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // DEBT DASHBOARD with Group List
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ============================================================
          // PHASE 5.3 — DEBT DASHBOARD HEADER (3 SCORECARD)
          // ============================================================
          _buildDebtDashboard(sharedState),
          const SizedBox(height: 24),

          // Section Title
          Text(
            'Gruplarım',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // GROUP LIST
          ...groups.map((group) => _GroupCard(group: group)),
        ],
      ),
    );
  }

  /// Debt Dashboard — 3 Cards showing global financial position
  Widget _buildDebtDashboard(SharedExpenseState state) {
    final receivable = state.totalReceivable;
    final payable = state.totalPayable;
    final net = state.globalNetPosition;

    // Determine net card color
    final netColor = net >= 0 ? Colors.green : Colors.red;
    final netIcon = net >= 0 ? Icons.trending_up : Icons.trending_down;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          children: [
            const Icon(Icons.account_balance_wallet,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Borç Durumu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 3 Cards Row
        Row(
          children: [
            // Card 1: Alacaklar (Receivable) - GREEN
            Expanded(
              child: _DebtCard(
                title: 'Alacaklar',
                amount: receivable,
                color: Colors.green,
                icon: Icons.arrow_downward,
              ),
            ),
            const SizedBox(width: 8),

            // Card 2: Borçlar (Payable) - RED
            Expanded(
              child: _DebtCard(
                title: 'Borçlar',
                amount: payable,
                color: Colors.red,
                icon: Icons.arrow_upward,
              ),
            ),
            const SizedBox(width: 8),

            // Card 3: Net Position
            Expanded(
              child: _DebtCard(
                title: 'Genel',
                amount: net.abs(),
                color: netColor,
                icon: netIcon,
                showSign: true,
                isPositive: net >= 0,
              ),
            ),
          ],
        ),

        // Balance message
        if (net == 0)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Borç durumun dengede! 🎉',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Individual Debt Card for dashboard
class _DebtCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final bool showSign;
  final bool isPositive;

  const _DebtCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    this.showSign = false,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final sign = showSign ? (isPositive ? '+' : '-') : '';
    final amountText = '$sign${CurrencyFormatter.formatShort(amount)}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amountText,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// _GroupCard — Individual group card in list
///
/// Shows:
/// - Title: Group name
/// - Subtitle: Member count
/// - Trailing: Current user's net balance (CRITICAL RULE)
class _GroupCard extends StatelessWidget {
  final SharedGroup group;

  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    // Get current user's balance from member object directly
    // ⚠️ CRITICAL: Use ONLY currentUser.currentBalance
    // Do NOT sum or infer from other members
    final currentUser = group.currentUser;
    final double myBalance = currentUser?.currentBalance ?? 0;

    // Determine color based on balance
    final Color balanceColor;
    final String balanceText;

    if (myBalance < 0) {
      // Negative = I owe money = RED
      balanceColor = Colors.red;
      balanceText = '-${CurrencyFormatter.formatShort(-myBalance)}';
    } else if (myBalance > 0) {
      // Positive = I am owed money = GREEN
      balanceColor = Colors.green;
      balanceText = '+${CurrencyFormatter.formatShort(myBalance)}';
    } else {
      // Zero = Even = GREY
      balanceColor = Colors.grey;
      balanceText = CurrencyFormatter.formatShort(0);
    }

    return Card(
      color: const Color(0xFF1E2230),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: balanceColor.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // Title: Group name
        title: Text(
          group.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Subtitle: Member count
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${group.members.length} Üye',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ),
        // Trailing: My Net Status (balance)
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: balanceColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: balanceColor.withOpacity(0.3)),
          ),
          child: Text(
            balanceText,
            style: TextStyle(
              color: balanceColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Interaction: Navigate to GroupDetailScreen
        // ⚠️ MUST use Navigator.push with MaterialPageRoute
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailScreen(group: group),
            ),
          );
        },
      ),
    );
  }
}
