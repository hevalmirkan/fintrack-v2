/// ====================================================
/// PHASE 4 — SHARED EXPENSES DATA MODELS
/// ====================================================
///
/// MASTER CONTRACT:
/// - Expense creates debt
/// - Settlement clears debt
/// - Wallet changes ONLY if currentUser is involved
///
/// BALANCE MEANING:
/// - balance > 0 → Creditor (Alacaklı)
/// - balance < 0 → Debtor (Borçlu)
/// - balance = 0 → Even
/// ====================================================

import 'package:equatable/equatable.dart';

/// ==================== GROUP MEMBER ====================
/// Represents a participant in a shared expense group.
///
/// ⚠️ CRITICAL: Only ONE member per group can have isCurrentUser = true
/// This is the device owner. All others are virtual.
class GroupMember extends Equatable {
  final String id;
  final String name;
  final bool isCurrentUser;

  /// ⚠️ CACHE ONLY — NOT SOURCE OF TRUTH
  /// This is a derived value, recalculated from transactions.
  /// Positive = Creditor (Alacaklı) | Negative = Debtor (Borçlu)
  final double currentBalance;

  const GroupMember({
    required this.id,
    required this.name,
    this.isCurrentUser = false,
    this.currentBalance = 0.0,
  });

  GroupMember copyWith({
    String? id,
    String? name,
    bool? isCurrentUser,
    double? currentBalance,
  }) {
    return GroupMember(
      id: id ?? this.id,
      name: name ?? this.name,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      currentBalance: currentBalance ?? this.currentBalance,
    );
  }

  @override
  List<Object?> get props => [id, name, isCurrentUser, currentBalance];
}

/// ==================== SHARED GROUP ====================
/// A group of people sharing expenses (e.g., "Tatil", "Ev Harcamaları")
class SharedGroup extends Equatable {
  final String id;
  final String title;
  final String currency;
  final List<GroupMember> members;
  final DateTime createdAt;
  final bool isActive;

  const SharedGroup({
    required this.id,
    required this.title,
    this.currency = 'TRY',
    required this.members,
    required this.createdAt,
    this.isActive = true,
  });

  /// Get the current user (device owner)
  GroupMember? get currentUser =>
      members.where((m) => m.isCurrentUser).firstOrNull;

  /// Get member by ID
  GroupMember? getMember(String memberId) =>
      members.where((m) => m.id == memberId).firstOrNull;

  /// Update a member's balance (returns new group with updated member)
  SharedGroup updateMemberBalance(String memberId, double newBalance) {
    return copyWith(
      members: members.map((m) {
        if (m.id == memberId) {
          return m.copyWith(currentBalance: newBalance);
        }
        return m;
      }).toList(),
    );
  }

  SharedGroup copyWith({
    String? id,
    String? title,
    String? currency,
    List<GroupMember>? members,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return SharedGroup(
      id: id ?? this.id,
      title: title ?? this.title,
      currency: currency ?? this.currency,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, currency, members, createdAt, isActive];
}

/// ==================== TRANSACTION TYPE ====================
/// ⚠️ ONLY TWO TYPES — This is a strict contract
enum GroupTransactionType {
  /// 🧾 EXPENSE: Someone paid for the group → Creates debt
  /// Wallet impact: ONLY if payer == currentUser
  expense,

  /// 💸 SETTLEMENT: Debt repayment → Clears debt
  /// Wallet impact: ONLY if currentUser is sender OR receiver
  settlement,
}

/// ==================== GROUP TRANSACTION ====================
/// Represents either an EXPENSE or a SETTLEMENT in a group.
class GroupTransaction extends Equatable {
  final String id;
  final String groupId;
  final GroupTransactionType type;

  /// For EXPENSE: The person who paid
  /// For SETTLEMENT: The person sending money (debtor)
  final String payerId;

  /// ONLY for SETTLEMENT: The person receiving money (creditor)
  /// For EXPENSE: This is null
  final String? receiverId;

  final double amount;
  final DateTime date;
  final String description;
  final DateTime createdAt;

  /// Link to FinanceTransaction if wallet was affected
  final String? financeTransactionId;

  const GroupTransaction({
    required this.id,
    required this.groupId,
    required this.type,
    required this.payerId,
    this.receiverId,
    required this.amount,
    required this.date,
    required this.description,
    required this.createdAt,
    this.financeTransactionId,
  });

  @override
  List<Object?> get props => [
        id,
        groupId,
        type,
        payerId,
        receiverId,
        amount,
        date,
        description,
        createdAt,
        financeTransactionId
      ];
}

/// ==================== TRANSACTION SPLIT ====================
/// ONLY for EXPENSE transactions.
/// Defines how much each member owes for a specific expense.
class TransactionSplit extends Equatable {
  final String transactionId;
  final String memberId;

  /// How much this member owes for this expense
  /// For the payer, this is their share (they owe themselves)
  final double owedAmount;

  const TransactionSplit({
    required this.transactionId,
    required this.memberId,
    required this.owedAmount,
  });

  @override
  List<Object?> get props => [transactionId, memberId, owedAmount];
}

/// ==================== EXCEPTIONS ====================
class SharedExpenseException implements Exception {
  final String message;
  const SharedExpenseException(this.message);
  @override
  String toString() => 'SharedExpenseException: $message';
}

class InvalidSplitException extends SharedExpenseException {
  const InvalidSplitException(super.message);
}

class InvalidSettlementException extends SharedExpenseException {
  const InvalidSettlementException(super.message);
}

class NoCurrentUserException extends SharedExpenseException {
  const NoCurrentUserException()
      : super('Group must have exactly one currentUser');
}
