import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../assets/domain/entities/asset.dart';
import '../domain/models/wallet.dart';
import '../domain/models/finance_transaction.dart';
import '../domain/models/installment.dart';

/// Finance State - Holds all personal finance data
///
/// USES INT (minor units) for all calculations.
/// Convert to double ONLY for UI display.
class FinanceState {
  final List<Wallet> wallets;
  final List<FinanceTransaction> transactions;
  final List<Installment> installments;
  final List<Asset> assets;
  final bool isLoading;
  final String? error;

  const FinanceState({
    this.wallets = const [],
    this.transactions = const [],
    this.installments = const [],
    this.assets = const [],
    this.isLoading = false,
    this.error,
  });

  /// Total balance in MINOR UNITS (kuruş) - sum of all active wallets
  int get totalBalanceMinor {
    return wallets
        .where((w) => w.isActive)
        .fold<int>(0, (sum, w) => sum + w.balanceMinor);
  }

  /// Monthly income in MINOR UNITS (this month)
  int get monthlyIncomeMinor {
    final now = DateTime.now();
    return transactions
        .where((t) =>
            t.type == FinanceTransactionType.income &&
            t.date.month == now.month &&
            t.date.year == now.year)
        .fold<int>(0, (sum, t) => sum + t.amountMinor);
  }

  /// Monthly expense in MINOR UNITS (this month)
  /// EXCLUDES "Yatırım" (Investment) - those are capital allocation, not consumption
  int get monthlyExpenseMinor {
    final now = DateTime.now();
    return transactions
        .where((t) =>
            t.type == FinanceTransactionType.expense &&
            t.date.month == now.month &&
            t.date.year == now.year &&
            t.category != 'Yatırım' && // Exclude investments
            t.category != 'Investment') // English fallback
        .fold<int>(0, (sum, t) => sum + t.amountMinor);
  }

  /// Net monthly cash flow in MINOR UNITS
  int get monthlyNetFlowMinor => monthlyIncomeMinor - monthlyExpenseMinor;

  /// Recent transactions (last 5, sorted by date descending)
  List<FinanceTransaction> get recentTransactions {
    final sorted = List<FinanceTransaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(5).toList();
  }

  /// Next installment (nearest due date, active and not completed)
  Installment? get nextInstallment {
    final active =
        installments.where((i) => i.isActive && !i.isCompleted).toList();

    if (active.isEmpty) return null;

    active.sort((a, b) {
      final aDate = a.nextPaymentDate;
      final bDate = b.nextPaymentDate;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });

    return active.first;
  }

  /// Active installments count
  int get activeInstallmentCount =>
      installments.where((i) => i.isActive && !i.isCompleted).length;

  /// Total monthly installment payments in MINOR UNITS
  int get monthlyInstallmentTotalMinor {
    return installments
        .where((i) => i.isActive && !i.isCompleted)
        .fold<int>(0, (sum, i) => sum + i.monthlyAmountMinor);
  }

  FinanceState copyWith({
    List<Wallet>? wallets,
    List<FinanceTransaction>? transactions,
    List<Installment>? installments,
    List<Asset>? assets,
    bool? isLoading,
    String? error,
  }) {
    return FinanceState(
      wallets: wallets ?? this.wallets,
      transactions: transactions ?? this.transactions,
      installments: installments ?? this.installments,
      assets: assets ?? this.assets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Finance Notifier - Manages all personal finance state
/// OPTIMISTIC STATE UPDATES: State FIRST, Repo SECOND (non-blocking)
class FinanceNotifier extends Notifier<FinanceState> {
  // ignore: unused_field - DEV ONLY, for future Repository contracts
  static const String _devUserId = 'user_dev_01';

  @override
  FinanceState build() {
    // PHASE 5.9: NO DEFAULT DATA - Fresh install starts empty
    print('[LOGIC] FinanceNotifier.build() - starting with zero data');

    return const FinanceState(
      wallets: [],
      transactions: [],
      installments: [],
      assets: [],
    );
  }

  /// Add wallet - STATE FIRST, no blocking
  Future<void> addWallet(Wallet wallet) async {
    print('[LOGIC] addWallet() called: ${wallet.name}');

    final newWallets = [...state.wallets, wallet];
    state = state.copyWith(wallets: newWallets);

    print(
        '[LOGIC] State updated. Wallet count: ${state.wallets.length}, Total: ${state.totalBalanceMinor}');
  }

  /// Add transaction - STATE FIRST, updates wallet balance if wallet exists
  Future<void> addTransaction(FinanceTransaction transaction) async {
    print(
        '[LOGIC] addTransaction() called: ${transaction.type.name} ${transaction.amountMinor}');

    // Check if wallet exists
    final walletExists = state.wallets.any((w) => w.id == transaction.walletId);
    if (!walletExists) {
      print(
          '[WARN] Wallet not found for ID: ${transaction.walletId}. Transaction will be saved but balance unchanged.');
    }

    // Compute new wallet balance (INT math) - if wallet exists
    // PHASE 1 INFRASTRUCTURE: Use reducesBalance to handle all types correctly
    final updatedWallets = state.wallets.map((w) {
      if (w.id == transaction.walletId) {
        int delta;
        if (transaction.type == FinanceTransactionType.income) {
          delta = transaction.amountMinor; // Income adds to balance
        } else if (transaction.type.reducesBalance) {
          delta =
              -transaction.amountMinor; // Expense/Investment reduces balance
        } else {
          delta =
              0; // Transfer/Adjustment has no net effect (or handled separately)
        }
        print(
            '[LOGIC] Wallet ${w.name}: ${w.balanceMinor} -> ${w.balanceMinor + delta}');
        return w.copyWith(balanceMinor: w.balanceMinor + delta);
      }
      return w;
    }).toList();

    // STATE UPDATE (immutable - new lists)
    state = state.copyWith(
      transactions: [...state.transactions, transaction],
      wallets: updatedWallets,
    );

    print(
        '[LOGIC] State updated. Tx count: ${state.transactions.length}, Total: ${state.totalBalanceMinor}');
  }

  /// Delete transaction WITH WALLET ROLLBACK
  /// Reverses the financial impact before removing
  Future<void> deleteTransaction(String transactionId) async {
    print('[LOGIC] deleteTransaction() called: $transactionId');

    // 1. Find the transaction
    final txIndex = state.transactions.indexWhere((t) => t.id == transactionId);
    if (txIndex == -1) {
      print('[WARN] Transaction not found: $transactionId');
      return;
    }
    final tx = state.transactions[txIndex];

    // 2. ROLLBACK: Reverse the wallet balance
    // Income was +amount → rollback is -amount
    // Expense was -amount → rollback is +amount
    final rollbackDelta = tx.type == FinanceTransactionType.income
        ? -tx.amountMinor // Remove income = subtract
        : tx.amountMinor; // Remove expense = add back

    final updatedWallets = state.wallets.map((w) {
      if (w.id == tx.walletId) {
        print(
            '[LOGIC] Rollback wallet ${w.name}: ${w.balanceMinor} -> ${w.balanceMinor + rollbackDelta}');
        return w.copyWith(balanceMinor: w.balanceMinor + rollbackDelta);
      }
      return w;
    }).toList();

    // 3. Remove transaction from list
    final updatedTransactions =
        state.transactions.where((t) => t.id != transactionId).toList();

    // 4. Update state
    state = state.copyWith(
      transactions: updatedTransactions,
      wallets: updatedWallets,
    );

    print(
        '[LOGIC] Transaction deleted with rollback. Tx count: ${state.transactions.length}, Total: ${state.totalBalanceMinor}');
  }

  /// Edit transaction with FULL REVERT & RE-APPLY strategy
  /// Safe for wallet swaps, amount changes, and type changes
  Future<void> editTransaction(FinanceTransaction updatedTx) async {
    print('[LOGIC] editTransaction() called: ${updatedTx.id}');

    // 1. Find OLD transaction
    final oldTxIndex =
        state.transactions.indexWhere((t) => t.id == updatedTx.id);
    if (oldTxIndex == -1) {
      print('[WARN] Transaction not found for edit: ${updatedTx.id}');
      return;
    }
    final oldTx = state.transactions[oldTxIndex];

    // 2. STEP A: REVERT OLD transaction's effect on OLD wallet
    final oldRollbackDelta = oldTx.type == FinanceTransactionType.income
        ? -oldTx.amountMinor // Remove old income
        : oldTx.amountMinor; // Remove old expense

    var updatedWallets = state.wallets.map((w) {
      if (w.id == oldTx.walletId) {
        print(
            '[LOGIC] Revert OLD wallet ${w.name}: ${w.balanceMinor} -> ${w.balanceMinor + oldRollbackDelta}');
        return w.copyWith(balanceMinor: w.balanceMinor + oldRollbackDelta);
      }
      return w;
    }).toList();

    // 3. STEP B: APPLY NEW transaction's effect on NEW wallet
    // Note: walletId might be different from old!
    final newDelta = updatedTx.type == FinanceTransactionType.income
        ? updatedTx.amountMinor
        : -updatedTx.amountMinor;

    updatedWallets = updatedWallets.map((w) {
      if (w.id == updatedTx.walletId) {
        print(
            '[LOGIC] Apply NEW wallet ${w.name}: ${w.balanceMinor} -> ${w.balanceMinor + newDelta}');
        return w.copyWith(balanceMinor: w.balanceMinor + newDelta);
      }
      return w;
    }).toList();

    // 4. Replace transaction in list
    final updatedTransactions =
        List<FinanceTransaction>.from(state.transactions);
    updatedTransactions[oldTxIndex] = updatedTx;

    // 5. Update state
    state = state.copyWith(
      transactions: updatedTransactions,
      wallets: updatedWallets,
    );

    print(
        '[LOGIC] Transaction edited with revert-apply. Total: ${state.totalBalanceMinor}');
  }

  /// Add asset - STATE FIRST, optional purchase creates transaction
  Future<void> addAsset(
    Asset asset, {
    bool isPurchase = false,
    String? sourceWalletId,
  }) async {
    print('[LOGIC] addAsset() called: ${asset.symbol}, isPurchase=$isPurchase');

    // Purchase: create expense transaction (wallet math in addTransaction)
    if (isPurchase && sourceWalletId != null) {
      final totalCostMinor = (asset.quantityMinor * asset.averagePrice) ~/ 100;
      final tx = FinanceTransaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        walletId: sourceWalletId,
        type: FinanceTransactionType.expense,
        amountMinor: totalCostMinor,
        category: 'Yatırım',
        description: '${asset.symbol} alımı',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await addTransaction(tx);
    }

    // Asset state update
    final existingIndex =
        state.assets.indexWhere((a) => a.symbol == asset.symbol);

    if (existingIndex >= 0) {
      // Merge existing
      final existing = state.assets[existingIndex];
      final totalQty = existing.quantityMinor + asset.quantityMinor;
      final totalCost = (existing.quantityMinor * existing.averagePrice) +
          (asset.quantityMinor * asset.averagePrice);
      final avgPrice = totalQty > 0 ? totalCost ~/ totalQty : 0;

      final updated = existing.copyWith(
        quantityMinor: totalQty,
        averagePrice: avgPrice,
        currentPrice: asset.currentPrice,
      );

      final newAssets = List<Asset>.from(state.assets);
      newAssets[existingIndex] = updated;
      state = state.copyWith(assets: newAssets);
    } else {
      state = state.copyWith(assets: [...state.assets, asset]);
    }

    print('[LOGIC] State updated. Asset count: ${state.assets.length}');
  }

  /// Remove asset - STATE FIRST
  Future<void> removeAsset(String assetId) async {
    print('[LOGIC] removeAsset() called: $assetId');

    state = state.copyWith(
      assets: state.assets.where((a) => a.id != assetId).toList(),
    );

    print('[LOGIC] State updated. Asset count: ${state.assets.length}');
  }

  /// Update wallet balance directly - STATE FIRST
  Future<void> updateWalletBalance(String walletId, int newBalanceMinor) async {
    print('[LOGIC] updateWalletBalance() called: $walletId = $newBalanceMinor');

    final updated = state.wallets.map((w) {
      if (w.id == walletId) return w.copyWith(balanceMinor: newBalanceMinor);
      return w;
    }).toList();

    state = state.copyWith(wallets: updated);

    print('[LOGIC] State updated. Total: ${state.totalBalanceMinor}');
  }

  /// RESET ALL DATA - Clears everything and returns to default state
  /// Used by Settings > Delete All Data
  Future<void> resetData() async {
    print('[LOGIC] resetData() - HARD RESET initiated');

    // Recreate default wallets with 0 balance
    final cashWallet = Wallet(
      id: 'wallet_cash',
      name: 'Nakit',
      type: WalletType.cash,
      balanceMinor: 0, // Reset to 0 balance
      iconName: 'wallet',
      isActive: true,
      createdAt: DateTime.now(),
    );

    final creditCardWallet = Wallet(
      id: 'wallet_credit',
      name: 'Kredi Karti',
      type: WalletType.creditCard,
      balanceMinor: 0,
      iconName: 'credit_card',
      isActive: true,
      createdAt: DateTime.now(),
    );

    // Reset to fresh state
    state = FinanceState(
      wallets: [cashWallet, creditCardWallet],
      transactions: const [],
      installments: const [],
      assets: const [],
    );

    print(
        '[LOGIC] resetData() - State reset complete. Tx: ${state.transactions.length}, Wallets: ${state.wallets.length}');
  }

  /// RESTORE FROM BACKUP - Phase 6
  /// Replaces all data with backup content
  void restoreFromBackup({
    required List<Wallet> wallets,
    required List<FinanceTransaction> transactions,
    required List<Asset> assets,
  }) {
    print(
        '[LOGIC] restoreFromBackup() - Restoring ${wallets.length} wallets, ${transactions.length} tx, ${assets.length} assets');

    state = FinanceState(
      wallets: wallets,
      transactions: transactions,
      installments:
          state.installments, // Keep installments (restored separately)
      assets: assets,
    );

    print('[LOGIC] restoreFromBackup() - Restore complete');
  }
}

/// Main Finance Provider
final financeProvider = NotifierProvider<FinanceNotifier, FinanceState>(() {
  return FinanceNotifier();
});

/// Convenience Providers (all return INT minor units)

/// Total balance in minor units
final totalBalanceMinorProvider = Provider<int>((ref) {
  return ref.watch(financeProvider).totalBalanceMinor;
});

/// Monthly income in minor units
final monthlyIncomeMinorProvider = Provider<int>((ref) {
  return ref.watch(financeProvider).monthlyIncomeMinor;
});

/// Monthly expense in minor units
final monthlyExpenseMinorProvider = Provider<int>((ref) {
  return ref.watch(financeProvider).monthlyExpenseMinor;
});

/// Recent transactions
final recentTransactionsProvider = Provider<List<FinanceTransaction>>((ref) {
  return ref.watch(financeProvider).recentTransactions;
});

/// Next installment
final nextInstallmentProvider = Provider<Installment?>((ref) {
  return ref.watch(financeProvider).nextInstallment;
});
