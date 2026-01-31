/// ====================================================
/// PHASE 4 — SHARED EXPENSE PROVIDER (FINAL)
/// ====================================================
///
/// MASTER CONTRACT:
/// - Expense creates debt
/// - Settlement clears debt
/// - Wallet changes ONLY if currentUser is involved
///
/// HARD FIX FOR DELETE:
/// - On delete, RESET all balances to 0
/// - REPLAY all remaining transactions
/// - EMIT new state reference
///
/// ====================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/shared_expense_models.dart';
import '../../../finance/data/finance_provider.dart';
import '../../../finance/domain/models/finance_transaction.dart';

/// ==================== STATE ====================
class SharedExpenseState {
  final List<SharedGroup> groups;
  final List<GroupTransaction> transactions;
  final List<TransactionSplit> splits;

  const SharedExpenseState({
    this.groups = const [],
    this.transactions = const [],
    this.splits = const [],
  });

  // ============================================================
  // PHASE 5.3 — COMPUTED GETTERS (READ-ONLY AGGREGATION)
  // ============================================================

  /// Total amount others owe the current user across ALL groups
  /// (Sum of positive currentUser balances)
  double get totalReceivable {
    double total = 0;
    for (final group in groups.where((g) => g.isActive)) {
      final myBalance = group.currentUser?.currentBalance ?? 0;
      if (myBalance > 0) {
        total += myBalance;
      }
    }
    return total;
  }

  /// Total amount the current user owes to others across ALL groups
  /// (Sum of negative currentUser balances, returned as positive)
  double get totalPayable {
    double total = 0;
    for (final group in groups.where((g) => g.isActive)) {
      final myBalance = group.currentUser?.currentBalance ?? 0;
      if (myBalance < 0) {
        total += myBalance.abs();
      }
    }
    return total;
  }

  /// Net position: Positive = You are owed, Negative = You owe
  double get globalNetPosition => totalReceivable - totalPayable;

  /// Aggregate debts by person NAME across all groups
  /// Key = Member name, Value = Net balance (positive = they owe you)
  Map<String, double> get debtsByPerson {
    final Map<String, double> result = {};

    for (final group in groups.where((g) => g.isActive)) {
      final currentUser = group.currentUser;
      if (currentUser == null) continue;

      for (final member in group.members) {
        if (member.isCurrentUser) continue;

        // Member's balance from THEIR perspective
        // If member.balance > 0, they are owed (so I owe them)
        // If member.balance < 0, they owe (so they owe me)
        // We invert for "their debt to me"
        final theirDebtToMe = -member.currentBalance;

        result[member.name] = (result[member.name] ?? 0) + theirDebtToMe;
      }
    }

    return result;
  }

  SharedExpenseState copyWith({
    List<SharedGroup>? groups,
    List<GroupTransaction>? transactions,
    List<TransactionSplit>? splits,
  }) {
    return SharedExpenseState(
      groups: groups ?? this.groups,
      transactions: transactions ?? this.transactions,
      splits: splits ?? this.splits,
    );
  }
}

/// ==================== PROVIDER ====================
final sharedExpenseProvider =
    NotifierProvider<SharedExpenseNotifier, SharedExpenseState>(
        SharedExpenseNotifier.new);

class SharedExpenseNotifier extends Notifier<SharedExpenseState> {
  @override
  SharedExpenseState build() {
    // PHASE 5.9: NO DEFAULT DATA - Fresh install starts empty
    print('[SHARED] Starting with zero data');

    return const SharedExpenseState(
      groups: [],
      transactions: [],
      splits: [],
    );
  }

  // ================================================================
  // HARD FIX: RECALCULATE FROM ZERO
  // ================================================================
  /// Step 1: Reset ALL balances to 0
  /// Step 2: Replay every transaction
  /// Step 3: Return new group with computed balances
  SharedGroup _recalculateFromZero(
    SharedGroup group,
    List<GroupTransaction> allTx,
    List<TransactionSplit> allSplits,
  ) {
    // Get transactions for THIS group only
    final groupTxs = allTx.where((t) => t.groupId == group.id).toList();

    // STEP 1: Reset all balances to 0
    final resetMembers = group.members
        .map((m) => GroupMember(
              id: m.id,
              name: m.name,
              isCurrentUser: m.isCurrentUser,
              currentBalance: 0.0, // HARD RESET
            ))
        .toList();

    var result = SharedGroup(
      id: group.id,
      title: group.title,
      currency: group.currency,
      members: resetMembers,
      createdAt: group.createdAt,
      isActive: group.isActive,
    );

    // STEP 2: Replay each transaction
    for (final tx in groupTxs) {
      if (tx.type == GroupTransactionType.expense) {
        final txSplits =
            allSplits.where((s) => s.transactionId == tx.id).toList();

        double payerShare = 0.0;
        for (final split in txSplits) {
          if (split.memberId == tx.payerId) {
            payerShare = split.owedAmount;
          }
        }

        // Payer: + (total - share)
        final payerBalance =
            (result.getMember(tx.payerId)?.currentBalance ?? 0) +
                (tx.amount - payerShare);
        result = result.updateMemberBalance(tx.payerId, payerBalance);

        // Others: - owedAmount
        for (final split in txSplits) {
          if (split.memberId != tx.payerId) {
            final member = result.getMember(split.memberId);
            if (member != null) {
              final newBalance = member.currentBalance - split.owedAmount;
              result = result.updateMemberBalance(split.memberId, newBalance);
            }
          }
        }
      } else if (tx.type == GroupTransactionType.settlement) {
        // Debtor: + amount
        final debtorBalance =
            (result.getMember(tx.payerId)?.currentBalance ?? 0) + tx.amount;
        result = result.updateMemberBalance(tx.payerId, debtorBalance);

        // Creditor: - amount
        if (tx.receiverId != null) {
          final creditorBalance =
              (result.getMember(tx.receiverId!)?.currentBalance ?? 0) -
                  tx.amount;
          result = result.updateMemberBalance(tx.receiverId!, creditorBalance);
        }
      }
    }

    return result;
  }

  /// Recalculate ALL groups and emit NEW state
  void _recalculateAndEmit({
    List<SharedGroup>? groups,
    List<GroupTransaction>? transactions,
    List<TransactionSplit>? splits,
  }) {
    final allGroups = groups ?? state.groups;
    final allTx = transactions ?? state.transactions;
    final allSplits = splits ?? state.splits;

    // Recalculate each group from zero
    final updatedGroups = allGroups.map((g) {
      return _recalculateFromZero(g, allTx, allSplits);
    }).toList();

    // EMIT NEW STATE (not mutation)
    state = SharedExpenseState(
      groups: updatedGroups,
      transactions: allTx,
      splits: allSplits,
    );
  }

  // ================================================================
  // CREATE GROUP
  // ================================================================
  void createGroup({
    required String title,
    required List<GroupMember> members,
    String currency = 'TRY',
  }) {
    final currentUsers = members.where((m) => m.isCurrentUser).length;
    if (currentUsers != 1) {
      throw const NoCurrentUserException();
    }

    final now = DateTime.now();
    final group = SharedGroup(
      id: 'grp_${now.millisecondsSinceEpoch}',
      title: title,
      currency: currency,
      members: members,
      createdAt: now,
    );

    _recalculateAndEmit(groups: [...state.groups, group]);
    print('[SHARED] Group created: ${group.title}');
  }

  // ================================================================
  // ADD EXPENSE
  // ================================================================
  Future<void> addExpense({
    required String groupId,
    required String payerId,
    required double totalAmount,
    required Map<String, double> splitMap,
    required String description,
  }) async {
    final group = state.groups.where((g) => g.id == groupId).firstOrNull;
    if (group == null) {
      throw SharedExpenseException('Group not found: $groupId');
    }

    final splitSum = splitMap.values.fold(0.0, (sum, v) => sum + v);
    if ((splitSum - totalAmount).abs() > 0.01) {
      throw InvalidSplitException(
        'Split sum ($splitSum) != total ($totalAmount)',
      );
    }

    final payer = group.getMember(payerId);
    if (payer == null) {
      throw SharedExpenseException('Payer not found: $payerId');
    }

    final now = DateTime.now();
    final txId = 'gtx_exp_${now.millisecondsSinceEpoch}';

    final expenseTx = GroupTransaction(
      id: txId,
      groupId: groupId,
      type: GroupTransactionType.expense,
      payerId: payerId,
      receiverId: null,
      amount: totalAmount,
      date: now,
      description: description,
      createdAt: now,
    );

    final newSplits = <TransactionSplit>[];
    for (final entry in splitMap.entries) {
      newSplits.add(TransactionSplit(
        transactionId: txId,
        memberId: entry.key,
        owedAmount: entry.value,
      ));
    }

    // RECALCULATE and emit new state
    _recalculateAndEmit(
      transactions: [...state.transactions, expenseTx],
      splits: [...state.splits, ...newSplits],
    );

    // Wallet: expense type for actual balance decrease
    if (payer.isCurrentUser) {
      final finTxId = 'tx_shared_exp_${now.millisecondsSinceEpoch}';
      final financeTransaction = FinanceTransaction(
        id: finTxId,
        walletId: 'wallet_cash',
        type: FinanceTransactionType.expense,
        amountMinor: (totalAmount * 100).toInt(),
        category: 'Ortak Harcama',
        title: '$description (${group.title})',
        description: 'Grup harcaması - $description',
        date: now,
        createdAt: now,
        tags: ['#Ortak', group.title],
      );

      await ref
          .read(financeProvider.notifier)
          .addTransaction(financeTransaction);
      print('[SHARED] Wallet decreased: $totalAmount TL');
    }

    print('[SHARED] Expense added: $description');
  }

  // ================================================================
  // SETTLE DEBT
  // ================================================================
  Future<void> settleDebt({
    required String groupId,
    required String payerId,
    required String receiverId,
    required double amount,
  }) async {
    final group = state.groups.where((g) => g.id == groupId).firstOrNull;
    if (group == null) {
      throw SharedExpenseException('Group not found: $groupId');
    }

    final debtor = group.getMember(payerId);
    final creditor = group.getMember(receiverId);
    if (debtor == null) throw SharedExpenseException('Debtor not found');
    if (creditor == null) throw SharedExpenseException('Creditor not found');

    if (amount <= 0) {
      throw const InvalidSettlementException('Amount must be > 0');
    }

    final now = DateTime.now();
    final txId = 'gtx_set_${now.millisecondsSinceEpoch}';

    final settlementTx = GroupTransaction(
      id: txId,
      groupId: groupId,
      type: GroupTransactionType.settlement,
      payerId: payerId,
      receiverId: receiverId,
      amount: amount,
      date: now,
      description: '${debtor.name} → ${creditor.name}',
      createdAt: now,
    );

    // RECALCULATE and emit new state
    _recalculateAndEmit(
      transactions: [...state.transactions, settlementTx],
    );

    // Wallet effects
    final currentUser = group.currentUser;
    if (currentUser != null) {
      if (payerId == currentUser.id) {
        // Paying out = expense
        final finTxId = 'tx_shared_set_out_${now.millisecondsSinceEpoch}';
        final financeTransaction = FinanceTransaction(
          id: finTxId,
          walletId: 'wallet_cash',
          type: FinanceTransactionType.expense,
          amountMinor: (amount * 100).toInt(),
          category: 'Ortak Harcama',
          title: 'Borç Ödemesi (${group.title})',
          description: '${debtor.name} → ${creditor.name}',
          date: now,
          createdAt: now,
          tags: ['#Ortak', '#Ödeme', group.title],
        );

        await ref
            .read(financeProvider.notifier)
            .addTransaction(financeTransaction);
        print('[SHARED] Wallet decreased: $amount TL');
      } else if (receiverId == currentUser.id) {
        // Receiving = income
        final finTxId = 'tx_shared_set_in_${now.millisecondsSinceEpoch}';
        final financeTransaction = FinanceTransaction(
          id: finTxId,
          walletId: 'wallet_cash',
          type: FinanceTransactionType.income,
          amountMinor: (amount * 100).toInt(),
          category: 'Ortak Harcama',
          title: 'Borç Tahsilatı (${group.title})',
          description: '${debtor.name} → ${creditor.name}',
          date: now,
          createdAt: now,
          tags: ['#Ortak', '#Tahsilat', group.title],
        );

        await ref
            .read(financeProvider.notifier)
            .addTransaction(financeTransaction);
        print('[SHARED] Wallet increased: $amount TL');
      }
    }

    print('[SHARED] Settlement: ${debtor.name} → ${creditor.name} $amount TL');
  }

  // ================================================================
  // HARD FIX: DELETE TRANSACTION
  // ================================================================
  /// MANDATORY: Reset to 0, replay remaining, emit NEW state
  void deleteTransaction(String groupId, String transactionId) {
    // Remove transaction
    final newTransactions =
        state.transactions.where((t) => t.id != transactionId).toList();

    // Remove associated splits
    final newSplits =
        state.splits.where((s) => s.transactionId != transactionId).toList();

    // HARD FIX: Recalculate from zero with remaining transactions
    _recalculateAndEmit(
      transactions: newTransactions,
      splits: newSplits,
    );

    print(
        '[SHARED] Transaction deleted: $transactionId (balances recalculated from zero)');
  }

  // ================================================================
  // DELETE GROUP
  // ================================================================
  void deleteGroup(String groupId) {
    final newGroups = state.groups.where((g) => g.id != groupId).toList();
    final newTransactions =
        state.transactions.where((t) => t.groupId != groupId).toList();

    // Get transaction IDs from this group to filter splits
    final groupTxIds = state.transactions
        .where((t) => t.groupId == groupId)
        .map((t) => t.id)
        .toSet();
    final newSplits = state.splits
        .where((s) => !groupTxIds.contains(s.transactionId))
        .toList();

    // Emit new state
    state = SharedExpenseState(
      groups: newGroups,
      transactions: newTransactions,
      splits: newSplits,
    );

    print('[SHARED] Group deleted: $groupId');
  }

  // ================================================================
  // HELPERS
  // ================================================================
  SharedGroup? getGroup(String groupId) {
    return state.groups.where((g) => g.id == groupId).firstOrNull;
  }

  List<GroupTransaction> getGroupTransactions(String groupId) {
    return state.transactions.where((t) => t.groupId == groupId).toList();
  }

  List<GroupTransaction> getGroupExpenses(String groupId) {
    return state.transactions
        .where((t) =>
            t.groupId == groupId && t.type == GroupTransactionType.expense)
        .toList();
  }

  void addGroup(SharedGroup group) {
    final currentUsers = group.members.where((m) => m.isCurrentUser).length;
    if (currentUsers != 1) {
      throw const NoCurrentUserException();
    }
    _recalculateAndEmit(groups: [...state.groups, group]);
    print('[SHARED] Group added: ${group.title}');
  }

  Map<String, double> getMemberBalances(String groupId) {
    final group = getGroup(groupId);
    if (group == null) return {};
    return Map.fromEntries(
      group.members.map((m) => MapEntry(m.id, m.currentBalance)),
    );
  }

  /// RESTORE FROM BACKUP - Phase 6
  /// Replaces all shared expense data and recalculates balances
  void restoreFromBackup({
    required List<SharedGroup> groups,
    required List<GroupTransaction> transactions,
    required List<TransactionSplit> splits,
  }) {
    print(
        '[SHARED] restoreFromBackup() - Restoring ${groups.length} groups, ${transactions.length} txs');

    // Use _recalculateAndEmit to ensure balances are computed correctly
    _recalculateAndEmit(
      groups: groups,
      transactions: transactions,
      splits: splits,
    );

    print('[SHARED] restoreFromBackup() - Restore complete');
  }
}
