/// ====================================================
/// PHASE 4 STEP 3 — SETTLE DEBT DIALOG
/// ====================================================
///
/// This dialog allows users to settle (pay off) debt within a group.
///
/// CRITICAL WALLET SAFETY RULES:
/// - If currentUser == payer → Wallet decreases
/// - If currentUser == receiver → Wallet increases
/// - If NEITHER is currentUser → NO wallet change
///
/// VALIDATION RULES:
/// - amount > 0
/// - amount <= absolute debtor balance
///
/// PHASE 4 GOLDEN CONTRACT:
/// "Settlement clears debt. Wallet changes only if I am involved."
/// ====================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/shared_expense_models.dart';
import '../providers/shared_expense_provider.dart';

/// Shows settle debt dialog and returns true if debt was settled
Future<bool?> showSettleDebtDialog({
  required BuildContext context,
  required WidgetRef ref,
  required SharedGroup group,
  String? preselectedDebtorId,
  String? preselectedCreditorId,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => SettleDebtDialog(
      group: group,
      preselectedDebtorId: preselectedDebtorId,
      preselectedCreditorId: preselectedCreditorId,
    ),
  );
}

class SettleDebtDialog extends ConsumerStatefulWidget {
  final SharedGroup group;
  final String? preselectedDebtorId;
  final String? preselectedCreditorId;

  const SettleDebtDialog({
    super.key,
    required this.group,
    this.preselectedDebtorId,
    this.preselectedCreditorId,
  });

  @override
  ConsumerState<SettleDebtDialog> createState() => _SettleDebtDialogState();
}

class _SettleDebtDialogState extends ConsumerState<SettleDebtDialog> {
  final _amountController = TextEditingController();

  late String _selectedDebtorId;
  late String _selectedCreditorId;

  @override
  void initState() {
    super.initState();

    // Find members with negative balance (debtors) and positive balance (creditors)
    final debtors =
        widget.group.members.where((m) => m.currentBalance < 0).toList();
    final creditors =
        widget.group.members.where((m) => m.currentBalance > 0).toList();

    // Default debtor: preselected or first debtor or first member
    if (widget.preselectedDebtorId != null) {
      _selectedDebtorId = widget.preselectedDebtorId!;
    } else if (debtors.isNotEmpty) {
      _selectedDebtorId = debtors.first.id;
    } else {
      _selectedDebtorId = widget.group.members.first.id;
    }

    // Default creditor: preselected or first creditor or second member
    if (widget.preselectedCreditorId != null) {
      _selectedCreditorId = widget.preselectedCreditorId!;
    } else if (creditors.isNotEmpty) {
      _selectedCreditorId = creditors.first.id;
    } else if (widget.group.members.length > 1) {
      _selectedCreditorId = widget.group.members.last.id;
    } else {
      _selectedCreditorId = widget.group.members.first.id;
    }

    // Ensure debtor and creditor are different
    if (_selectedDebtorId == _selectedCreditorId &&
        widget.group.members.length > 1) {
      _selectedCreditorId =
          widget.group.members.where((m) => m.id != _selectedDebtorId).first.id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final members = widget.group.members;

    // Get current selections
    final debtor = members.where((m) => m.id == _selectedDebtorId).firstOrNull;
    final creditor =
        members.where((m) => m.id == _selectedCreditorId).firstOrNull;

    // Calculate max payable amount (debtor's absolute balance)
    final maxAmount = debtor != null ? debtor.currentBalance.abs() : 0.0;

    // Determine wallet impact
    final isCurrentUserDebtor = debtor?.isCurrentUser ?? false;
    final isCurrentUserCreditor = creditor?.isCurrentUser ?? false;

    return AlertDialog(
      backgroundColor: const Color(0xFF1E2230),
      title: Row(
        children: [
          const Icon(Icons.swap_horiz, color: Colors.green),
          const SizedBox(width: 8),
          const Text('Borç Öde', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== FROM (DEBTOR) ====================
            const Text('Ödeyen (Borçlu)',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDebtorId,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E2230),
                  items: members
                      .map((m) => DropdownMenuItem(
                            value: m.id,
                            child: _buildMemberItem(m, showBalance: true),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null && v != _selectedCreditorId) {
                      setState(() => _selectedDebtorId = v);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Arrow indicator
            const Center(
              child: Icon(Icons.arrow_downward, color: Colors.grey, size: 20),
            ),

            const SizedBox(height: 8),

            // ==================== TO (CREDITOR) ====================
            const Text('Alan (Alacaklı)',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCreditorId,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E2230),
                  items: members
                      .map((m) => DropdownMenuItem(
                            value: m.id,
                            child: _buildMemberItem(m, showBalance: true),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null && v != _selectedDebtorId) {
                      setState(() => _selectedCreditorId = v);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================== AMOUNT ====================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tutar (₺)',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                if (maxAmount > 0)
                  TextButton(
                    onPressed: () {
                      _amountController.text = maxAmount.toStringAsFixed(2);
                      setState(() {});
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                    ),
                    child: Text(
                      'Tamamını Öde (${CurrencyFormatter.formatShort(maxAmount)})',
                      style: const TextStyle(color: Colors.blue, fontSize: 11),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixText: '₺ ',
                prefixStyle: const TextStyle(color: Colors.green, fontSize: 18),
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (_) => setState(() {}),
            ),

            // Validation helper
            if (maxAmount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Maks: ${CurrencyFormatter.format(maxAmount)}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ),

            const SizedBox(height: 12),

            // ==================== WALLET IMPACT WARNING ====================
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getWalletImpactColor(
                        isCurrentUserDebtor, isCurrentUserCreditor)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getWalletImpactColor(
                          isCurrentUserDebtor, isCurrentUserCreditor)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getWalletImpactIcon(
                        isCurrentUserDebtor, isCurrentUserCreditor),
                    color: _getWalletImpactColor(
                        isCurrentUserDebtor, isCurrentUserCreditor),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getWalletImpactText(
                          isCurrentUserDebtor, isCurrentUserCreditor),
                      style: TextStyle(
                        color: _getWalletImpactColor(
                            isCurrentUserDebtor, isCurrentUserCreditor),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('İptal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _canSubmit() ? _settleDebt : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            disabledBackgroundColor: Colors.grey.shade700,
          ),
          child: const Text('Öde', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildMemberItem(GroupMember m, {bool showBalance = false}) {
    final isDebtor = m.currentBalance < 0;
    final isCreditor = m.currentBalance > 0;

    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: m.isCurrentUser
              ? Colors.orange
              : isDebtor
                  ? Colors.red.shade700
                  : isCreditor
                      ? Colors.green.shade700
                      : Colors.grey,
          child: Text(
            m.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            m.isCurrentUser ? 'Ben' : m.name,
            style: TextStyle(
              color: m.isCurrentUser ? Colors.orange : Colors.white,
              fontWeight: m.isCurrentUser ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
        if (showBalance)
          Text(
            m.currentBalance == 0
                ? CurrencyFormatter.formatShort(0)
                : m.currentBalance > 0
                    ? '+${CurrencyFormatter.formatShort(m.currentBalance)}'
                    : '-${CurrencyFormatter.formatShort(m.currentBalance.abs())}',
            style: TextStyle(
              color: m.currentBalance == 0
                  ? Colors.grey
                  : m.currentBalance > 0
                      ? Colors.green
                      : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Color _getWalletImpactColor(bool isDebtor, bool isCreditor) {
    if (isDebtor) return Colors.red;
    if (isCreditor) return Colors.green;
    return Colors.grey;
  }

  IconData _getWalletImpactIcon(bool isDebtor, bool isCreditor) {
    if (isDebtor) return Icons.remove_circle_outline;
    if (isCreditor) return Icons.add_circle_outline;
    return Icons.info_outline;
  }

  String _getWalletImpactText(bool isDebtor, bool isCreditor) {
    // ================================================================
    // WALLET SAFETY RULES (UI EXPLANATION)
    // ================================================================
    if (isDebtor && isCreditor) {
      return 'Kendinize ödeme yapamazsınız';
    }
    if (isDebtor) {
      return '⚠️ Senin cüzdanından düşecek';
    }
    if (isCreditor) {
      return '✅ Senin cüzdanına eklenecek';
    }
    return 'Cüzdanını etkilemez (3. taraf)';
  }

  bool _canSubmit() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final debtor = widget.group.members
        .where((m) => m.id == _selectedDebtorId)
        .firstOrNull;
    final maxAmount = debtor?.currentBalance.abs() ?? 0;

    // Validation:
    // - amount > 0
    // - amount <= debtor's absolute balance
    // - debtor != creditor
    return amount > 0 &&
        amount <= maxAmount &&
        _selectedDebtorId != _selectedCreditorId;
  }

  void _settleDebt() {
    final amount = double.parse(_amountController.text);

    try {
      // ================================================================
      // CRITICAL: Call provider's settleDebt
      // - Wallet changes ONLY if currentUser is involved
      // - Provider handles this logic internally
      // ================================================================
      ref.read(sharedExpenseProvider.notifier).settleDebt(
            groupId: widget.group.id,
            payerId: _selectedDebtorId,
            receiverId: _selectedCreditorId,
            amount: amount,
          );

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${CurrencyFormatter.formatShort(amount)} ödeme kaydedildi ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } on SharedExpenseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Hata: ${e.message}'), backgroundColor: Colors.red),
      );
    }
  }
}
