/// ====================================================
/// PHASE 4 — GROUP DETAIL SCREEN (WITH DELETE FEATURE)
/// ====================================================
///
/// UI CONTRACT:
/// This screen explains the shared debt clearly.
///
/// FEATURES:
/// - Bottom action bar with "Harcama Ekle" and "Borç Öde" buttons
/// - Delete group action in AppBar
/// - Delete individual transactions (with confirmation)
///
/// CRITICAL:
/// - After delete, balances are recalculated from scratch
/// - UI updates immediately
/// ====================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/shared_expense_models.dart';
import '../providers/shared_expense_provider.dart';
import 'add_shared_expense_screen.dart';
import 'settle_debt_dialog.dart';

/// GroupDetailScreen — Group Dashboard
///
/// Shows detailed view of a shared expense group:
/// - Header with net status
/// - Member balances
/// - Activity feed (transactions)
class GroupDetailScreen extends ConsumerWidget {
  final SharedGroup group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch provider for live updates
    final sharedState = ref.watch(sharedExpenseProvider);

    // Get current group state (may have been updated)
    final currentGroup =
        sharedState.groups.where((g) => g.id == group.id).firstOrNull ?? group;

    // Get transactions for this group, sorted by date DESC
    final transactions = ref
        .read(sharedExpenseProvider.notifier)
        .getGroupTransactions(currentGroup.id)
      ..sort((a, b) => b.date.compareTo(a.date)); // Newest first

    // Current user's balance for header
    final currentUser = currentGroup.currentUser;
    final double myBalance = currentUser?.currentBalance ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: Text(
          currentGroup.title,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        // DELETE GROUP ACTION
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: 'Grubu Sil',
            onPressed: () => _confirmDeleteGroup(context, ref, currentGroup),
          ),
        ],
      ),
      // ==================== BOTTOM ACTION BAR ====================
      // Phase 4 Step 3: Action buttons for interactive operations
      bottomNavigationBar: _buildActionBar(context, ref, currentGroup),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== HEADER ====================
            _buildHeader(myBalance),

            const Divider(color: Colors.grey, height: 1),

            // ==================== PHASE 5.3: DEBT SENTENCES ====================
            _buildDebtSentences(currentGroup),

            const Divider(color: Colors.grey, height: 1),

            // ==================== SECTION A: MEMBER BALANCES ====================
            _buildMemberBalancesSection(currentGroup),

            const SizedBox(height: 8),
            const Divider(color: Colors.grey, height: 1),

            // ==================== SECTION B: ACTIVITY FEED ====================
            _buildActivityFeedSection(currentGroup, transactions),

            // Bottom padding for action bar
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  /// Bottom Action Bar — Harcama Ekle + Borç Öde
  Widget _buildActionBar(
      BuildContext context, WidgetRef ref, SharedGroup currentGroup) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: Border(
          top: BorderSide(color: Colors.grey.shade800),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Button 1 — PRIMARY: Harcama Ekle
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddSharedExpenseScreen(group: currentGroup),
                    ),
                  );
                },
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Harcama Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Button 2 — SECONDARY: Borç Öde
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  showSettleDebtDialog(
                    context: context,
                    ref: ref,
                    group: currentGroup,
                  );
                },
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Borç Öde'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header — My Net Status Text
  Widget _buildHeader(double myBalance) {
    // Determine status text and color
    final Color statusColor;
    final String statusText;

    if (myBalance < 0) {
      // Negative = I owe money = RED
      statusColor = Colors.red;
      statusText =
          'Toplamda ${CurrencyFormatter.formatShort(-myBalance)} borçlusun';
    } else if (myBalance > 0) {
      // Positive = I am owed money = GREEN
      statusColor = Colors.green;
      statusText =
          'Toplamda ${CurrencyFormatter.formatShort(myBalance)} alacaklısın';
    } else {
      // Zero = Even = GREY
      statusColor = Colors.grey;
      statusText = 'Grupta dengedesin';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
      ),
      child: Column(
        children: [
          Icon(
            myBalance < 0
                ? Icons.arrow_downward
                : myBalance > 0
                    ? Icons.arrow_upward
                    : Icons.check_circle,
            color: statusColor,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PHASE 5.3 — DEBT SENTENCES
  // ============================================================

  /// Debt Sentences — Natural language debt statements
  /// STAR TOPOLOGY: Show only direct debts involving currentUser
  ///
  /// If I owe money (negative balance): Show who I owe to (creditors)
  /// If I'm owed money (positive balance): Show who owes me (debtors)
  Widget _buildDebtSentences(SharedGroup currentGroup) {
    final currentUser = currentGroup.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    final otherMembers =
        currentGroup.members.where((m) => !m.isCurrentUser).toList();

    if (otherMembers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Bu grupta başka üye yok.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final myBalance = currentUser.currentBalance;
    final List<Widget> sentences = [];

    // STAR TOPOLOGY LOGIC:
    // Only show debts that directly involve ME
    if (myBalance < 0) {
      // I OWE MONEY (negative balance) → Find creditors (positive balance)
      // My debt is distributed to those who have positive balance
      final creditors =
          otherMembers.where((m) => m.currentBalance > 0).toList();

      if (creditors.isEmpty) {
        // Edge case: I owe but no clear creditor
        sentences.add(_DebtSentenceRow(
          icon: Icons.arrow_upward,
          color: Colors.red,
          text:
              'Grupta ${CurrencyFormatter.format(myBalance.abs())} borcun var.',
        ));
      } else {
        // Calculate my share to each creditor proportionally
        final totalPositive =
            creditors.fold<double>(0, (sum, m) => sum + m.currentBalance);

        for (final creditor in creditors) {
          // My debt to this creditor = |myBalance| * (creditor.balance / totalPositive)
          final myDebtToThem =
              myBalance.abs() * (creditor.currentBalance / totalPositive);

          if (myDebtToThem > 0.01) {
            sentences.add(_DebtSentenceRow(
              icon: Icons.arrow_upward,
              color: Colors.red,
              text:
                  'Sen, ${creditor.name} kişisine ${CurrencyFormatter.format(myDebtToThem)} borçlusun.',
            ));
          }
        }
      }
    } else if (myBalance > 0) {
      // I AM OWED MONEY (positive balance) → Find debtors (negative balance)
      final debtors = otherMembers.where((m) => m.currentBalance < 0).toList();

      if (debtors.isEmpty) {
        // Edge case: I'm owed but no clear debtor
        sentences.add(_DebtSentenceRow(
          icon: Icons.arrow_downward,
          color: Colors.green,
          text: 'Grupta ${CurrencyFormatter.format(myBalance)} alacağın var.',
        ));
      } else {
        // Calculate each debtor's share to me proportionally
        final totalNegative =
            debtors.fold<double>(0, (sum, m) => sum + m.currentBalance.abs());

        for (final debtor in debtors) {
          // Their debt to me = myBalance * (|debtor.balance| / totalNegative)
          final theirDebtToMe =
              myBalance * (debtor.currentBalance.abs() / totalNegative);

          if (theirDebtToMe > 0.01) {
            sentences.add(_DebtSentenceRow(
              icon: Icons.arrow_downward,
              color: Colors.green,
              text:
                  '${debtor.name}, sana ${CurrencyFormatter.format(theirDebtToMe)} borçlu.',
            ));
          }
        }
      }
    }

    // If no debts (balance == 0), show balanced state
    if (sentences.isEmpty) {
      sentences.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.grey, size: 18),
              const SizedBox(width: 8),
              Text(
                'Bu grupta borç durumun dengede! 🎉',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Borç Durumu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...sentences,
        ],
      ),
    );
  }

  /// Section A — Member Balances (Horizontal List)
  Widget _buildMemberBalancesSection(SharedGroup currentGroup) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'Üye Bakiyeleri',
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal Member List
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: currentGroup.members.length,
              itemBuilder: (context, index) {
                final member = currentGroup.members[index];
                return _MemberBalanceCard(member: member);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Section B — Activity Feed (Transactions sorted by date DESC)
  Widget _buildActivityFeedSection(
    SharedGroup currentGroup,
    List<GroupTransaction> transactions,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'Hareketler',
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // EMPTY FEED STATE (MANDATORY)
          if (transactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.grey.shade600),
                    const SizedBox(height: 8),
                    Text(
                      'Henüz hareket yok.',
                      style:
                          TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

          // Transaction List
          ...transactions.map((tx) => _TransactionFeedItem(
                transaction: tx,
                group: currentGroup,
              )),
        ],
      ),
    );
  }

  /// Confirm Delete Group Dialog
  void _confirmDeleteGroup(
      BuildContext context, WidgetRef ref, SharedGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2230),
        title: const Text('Grubu Sil?', style: TextStyle(color: Colors.white)),
        content: Text(
          '"${group.title}" grubu ve tüm hareketleri silinecek.\n\nBu işlem geri alınamaz.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // Delete via provider
              ref.read(sharedExpenseProvider.notifier).deleteGroup(group.id);
              // Close dialog and go back
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to list
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${group.title} silindi'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// _MemberBalanceCard — Individual member card in horizontal list
///
/// Shows:
/// - Avatar with initials
/// - Name (with "(You)" label for currentUser)
/// - Balance value with color
class _MemberBalanceCard extends StatelessWidget {
  final GroupMember member;

  const _MemberBalanceCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final double balance = member.currentBalance;

    // Balance color rules (STRICT)
    // > 0 = Alacaklı = GREEN
    // < 0 = Borçlu = RED
    // = 0 = Dengede = GREY
    final Color balanceColor;
    final String balanceText;

    if (balance > 0) {
      balanceColor = Colors.green;
      balanceText = '+${CurrencyFormatter.formatShort(balance)}';
    } else if (balance < 0) {
      balanceColor = Colors.red;
      balanceText = '-${CurrencyFormatter.formatShort(-balance)}';
    } else {
      balanceColor = Colors.grey;
      balanceText = '₺0';
    }

    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2230),
        borderRadius: BorderRadius.circular(12),
        // Current User Highlight (MANDATORY)
        // Using border highlight
        border: member.isCurrentUser
            ? Border.all(color: Colors.orange, width: 2)
            : Border.all(color: Colors.grey.shade700, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar with initials
          CircleAvatar(
            radius: 18,
            backgroundColor:
                member.isCurrentUser ? Colors.orange : Colors.grey.shade700,
            child: Text(
              member.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Name (with "(You)" label for currentUser)
          Text(
            member.isCurrentUser ? 'Sen' : member.name,
            style: TextStyle(
              color: member.isCurrentUser ? Colors.orange : Colors.white,
              fontSize: 12,
              fontWeight:
                  member.isCurrentUser ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Balance value
          Text(
            balanceText,
            style: TextStyle(
              color: balanceColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// _TransactionFeedItem — Individual transaction in activity feed
///
/// EXPENSE: 🧾 "Ahmet, Yemek için ₺3.000 ödedi."
/// SETTLEMENT: 💸 "Mehmet → Ahmet'e ₺500 ödedi."
///
/// DELETE FEATURE: Each item has a delete button with confirmation
class _TransactionFeedItem extends ConsumerWidget {
  final GroupTransaction transaction;
  final SharedGroup group;

  const _TransactionFeedItem({
    required this.transaction,
    required this.group,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isExpense = transaction.type == GroupTransactionType.expense;

    // Get payer name
    final payer =
        group.members.where((m) => m.id == transaction.payerId).firstOrNull;
    final payerName = payer?.name ?? 'Unknown';

    // Build description text based on transaction type
    final String descriptionText;
    final IconData icon;
    final Color iconColor;

    if (isExpense) {
      // EXPENSE: "Ahmet, Yemek için ₺3.000 ödedi."
      icon = Icons.receipt_long;
      iconColor = Colors.orange;
      descriptionText =
          '$payerName, ${transaction.description} için ${CurrencyFormatter.formatShort(transaction.amount)} ödedi.';
    } else {
      // SETTLEMENT: "Mehmet → Ahmet'e ₺500 ödedi."
      icon = Icons.swap_horiz;
      iconColor = Colors.green;

      final receiver = group.members
          .where((m) => m.id == transaction.receiverId)
          .firstOrNull;
      final receiverName = receiver?.name ?? 'Unknown';

      descriptionText =
          '$payerName → $receiverName\'e ${CurrencyFormatter.formatShort(transaction.amount)} ödedi.';
    }

    // Format date
    final dateStr = _formatDate(transaction.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2230),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  descriptionText,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),

          // DELETE BUTTON
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
            tooltip: 'Sil',
            onPressed: () => _confirmDeleteTransaction(context, ref),
          ),
        ],
      ),
    );
  }

  /// Confirm Delete Transaction Dialog
  void _confirmDeleteTransaction(BuildContext context, WidgetRef ref) {
    final typeText =
        transaction.type == GroupTransactionType.expense ? 'Harcama' : 'Ödeme';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2230),
        title: Text('$typeText Silinsin mi?',
            style: const TextStyle(color: Colors.white)),
        content: Text(
          'Bu işlem silinecek ve bakiyeler yeniden hesaplanacak.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // Delete via provider (recalculates balances)
              ref
                  .read(sharedExpenseProvider.notifier)
                  .deleteTransaction(group.id, transaction.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('İşlem silindi (bakiyeler güncellendi)'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Format date as "14 Ocak 2026, 16:45"
  String _formatDate(DateTime date) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Individual Debt Sentence Row — Phase 5.3
class _DebtSentenceRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _DebtSentenceRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
