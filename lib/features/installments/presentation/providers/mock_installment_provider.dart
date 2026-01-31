import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/installment.dart';
import '../../../finance/data/finance_provider.dart';
import '../../../finance/domain/models/finance_transaction.dart';

/// Payment type enum for installment payments
enum InstallmentPaymentMode {
  payNow, // Creates real transaction, deducts wallet
  markAsPaid, // Only updates progress, no financial effect
}

/// Virtual payment record for "Mark as Paid" reversibility
class VirtualPayment {
  final String installmentId;
  final int installmentIndex;
  final DateTime markedAt;

  const VirtualPayment({
    required this.installmentId,
    required this.installmentIndex,
    required this.markedAt,
  });
}

/// In-memory Installment State (Mock Data for Testing)
class MockInstallmentState {
  final List<Installment> installments;
  final List<VirtualPayment> virtualPayments; // Track "mark as paid" entries
  final bool isLoading;

  const MockInstallmentState({
    this.installments = const [],
    this.virtualPayments = const [],
    this.isLoading = false,
  });

  MockInstallmentState copyWith({
    List<Installment>? installments,
    List<VirtualPayment>? virtualPayments,
    bool? isLoading,
  }) {
    return MockInstallmentState(
      installments: installments ?? this.installments,
      virtualPayments: virtualPayments ?? this.virtualPayments,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Total monthly installment burden (minor units)
  int get totalMonthlyAmount => installments
      .where((i) => i.isActive)
      .fold(0, (sum, i) => sum + i.monthlyAmount);

  /// Total remaining debt (minor units)
  int get totalRemainingDebt => installments
      .where((i) => i.isActive)
      .fold(0, (sum, i) => sum + i.remainingAmount);

  /// Count of active installments
  int get activeCount => installments.where((i) => i.isActive).length;
}

/// Mock Installment Notifier - IN-MEMORY ONLY
/// Uses Notifier pattern (Riverpod 3.0+)
class MockInstallmentNotifier extends Notifier<MockInstallmentState> {
  @override
  MockInstallmentState build() {
    // PHASE 5.9: NO DEFAULT DATA - Fresh install starts empty
    print('[INSTALLMENT] Starting with zero data');

    return const MockInstallmentState(
      installments: [],
      virtualPayments: [],
    );
  }

  /// Add a new installment plan
  void addInstallment(Installment installment) {
    state = state.copyWith(
      installments: [...state.installments, installment],
    );
    print(
        '[INSTALLMENT] Added: ${installment.title} - ${installment.totalAmount / 100} TL / ${installment.totalInstallments} months');
  }

  /// Pay an installment - WITH REAL TRANSACTION (Fix #1)
  /// Returns the created transaction ID if payNow mode
  Future<String?> payInstallment({
    required String installmentId,
    required InstallmentPaymentMode mode,
    required String walletId,
  }) async {
    final installmentIndex =
        state.installments.indexWhere((i) => i.id == installmentId);
    if (installmentIndex == -1) return null;

    final inst = state.installments[installmentIndex];
    if (inst.paidInstallments >= inst.totalInstallments) return null;

    final newPaid = inst.paidInstallments + 1;
    final isLastPayment = newPaid == inst.totalInstallments;
    final paymentAmount =
        isLastPayment ? inst.remainingAmount : inst.amountPerInstallment;
    final newRemaining = inst.remainingAmount - paymentAmount;

    // Update installment progress
    final updatedInstallment = Installment(
      id: inst.id,
      title: inst.title,
      totalAmount: inst.totalAmount,
      remainingAmount: newRemaining > 0 ? newRemaining : 0,
      totalInstallments: inst.totalInstallments,
      paidInstallments: newPaid,
      amountPerInstallment: inst.amountPerInstallment,
      startDate: inst.startDate,
      nextDueDate: _incrementMonth(inst.nextDueDate),
    );

    final updatedList = [...state.installments];
    updatedList[installmentIndex] = updatedInstallment;

    if (mode == InstallmentPaymentMode.payNow) {
      // 🔴 REAL PAYMENT: Create FinanceTransaction
      final transactionId = 'tx_inst_${DateTime.now().millisecondsSinceEpoch}';
      final transaction = FinanceTransaction(
        id: transactionId,
        walletId: walletId,
        type: FinanceTransactionType.expense,
        amountMinor: paymentAmount,
        category: 'Taksit / Borç',
        title: '${inst.title} - Taksit $newPaid/${inst.totalInstallments}',
        description: 'Taksit ödemesi',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        parentTransactionId: inst.id,
        installmentIndex: newPaid,
      );

      // Add to finance provider (deducts wallet)
      await ref.read(financeProvider.notifier).addTransaction(transaction);

      state = state.copyWith(installments: updatedList);
      print(
          '[INSTALLMENT] REAL PAYMENT: ${inst.title} - Taksit $newPaid - ${paymentAmount / 100} TL deducted');

      return transactionId;
    } else {
      // 🟡 MARK AS PAID: Only update progress, no financial effect
      final virtualPayment = VirtualPayment(
        installmentId: inst.id,
        installmentIndex: newPaid,
        markedAt: DateTime.now(),
      );

      state = state.copyWith(
        installments: updatedList,
        virtualPayments: [...state.virtualPayments, virtualPayment],
      );
      print(
          '[INSTALLMENT] MARKED AS PAID (virtual): ${inst.title} - Taksit $newPaid');

      return null;
    }
  }

  /// Revert a "Mark as Paid" virtual payment
  void revertVirtualPayment(String installmentId, int installmentIndex) {
    final virtualIndex = state.virtualPayments.indexWhere(
      (vp) =>
          vp.installmentId == installmentId &&
          vp.installmentIndex == installmentIndex,
    );
    if (virtualIndex == -1) return;

    final instIndex =
        state.installments.indexWhere((i) => i.id == installmentId);
    if (instIndex == -1) return;

    final inst = state.installments[instIndex];
    final paymentAmount = inst.amountPerInstallment;

    // Revert installment progress
    final revertedInstallment = Installment(
      id: inst.id,
      title: inst.title,
      totalAmount: inst.totalAmount,
      remainingAmount: inst.remainingAmount + paymentAmount,
      totalInstallments: inst.totalInstallments,
      paidInstallments: inst.paidInstallments - 1,
      amountPerInstallment: inst.amountPerInstallment,
      startDate: inst.startDate,
      nextDueDate: _decrementMonth(inst.nextDueDate),
    );

    final updatedInstallments = [...state.installments];
    updatedInstallments[instIndex] = revertedInstallment;

    final updatedVirtual = [...state.virtualPayments];
    updatedVirtual.removeAt(virtualIndex);

    state = state.copyWith(
      installments: updatedInstallments,
      virtualPayments: updatedVirtual,
    );
    print(
        '[INSTALLMENT] REVERTED virtual payment: ${inst.title} - Taksit $installmentIndex');
  }

  /// Delete an installment plan (does NOT delete transactions)
  void deleteInstallment(String installmentId) {
    final updated =
        state.installments.where((i) => i.id != installmentId).toList();
    state = state.copyWith(installments: updated);
    print(
        '[INSTALLMENT] DELETED plan: $installmentId (transactions preserved)');
  }

  DateTime _incrementMonth(DateTime date) {
    int newYear = date.year;
    int newMonth = date.month + 1;
    if (newMonth > 12) {
      newYear++;
      newMonth = 1;
    }
    return DateTime(newYear, newMonth, date.day);
  }

  DateTime _decrementMonth(DateTime date) {
    int newYear = date.year;
    int newMonth = date.month - 1;
    if (newMonth < 1) {
      newYear--;
      newMonth = 12;
    }
    return DateTime(newYear, newMonth, date.day);
  }

  /// RESTORE FROM BACKUP - Phase 6
  void restoreFromBackup(List<Installment> installments) {
    print(
        '[INSTALLMENT] restoreFromBackup() - Restoring ${installments.length} installments');
    state = state.copyWith(
      installments: installments,
      virtualPayments: const [], // Clear virtual payments on restore
    );
    print('[INSTALLMENT] restoreFromBackup() - Restore complete');
  }
}

/// Mock Installment Provider (for testing without Firebase)
final mockInstallmentProvider =
    NotifierProvider<MockInstallmentNotifier, MockInstallmentState>(() {
  return MockInstallmentNotifier();
});

/// Derived: Total monthly installment burden
final totalInstallmentMonthlyProvider = Provider<int>((ref) {
  final installmentState = ref.watch(mockInstallmentProvider);
  return installmentState.totalMonthlyAmount;
});

/// Derived: Total remaining debt
final totalInstallmentDebtProvider = Provider<int>((ref) {
  final installmentState = ref.watch(mockInstallmentProvider);
  return installmentState.totalRemainingDebt;
});
