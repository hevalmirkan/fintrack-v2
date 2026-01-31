import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/subscription.dart';
import '../../../finance/data/finance_provider.dart';
import '../../../finance/domain/models/finance_transaction.dart';

/// In-memory Subscription State
class SubscriptionState {
  final List<Subscription> subscriptions;
  final bool isLoading;

  const SubscriptionState({
    this.subscriptions = const [],
    this.isLoading = false,
  });

  SubscriptionState copyWith({
    List<Subscription>? subscriptions,
    bool? isLoading,
  }) {
    return SubscriptionState(
      subscriptions: subscriptions ?? this.subscriptions,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Total monthly subscription cost (minor units)
  int get totalMonthlyAmount => subscriptions
      .where((s) => s.isActive)
      .fold(0, (sum, s) => sum + s.amountMinor);

  /// Count of active subscriptions
  int get activeCount => subscriptions.where((s) => s.isActive).length;

  /// Subscriptions due this month
  List<Subscription> get dueSubscriptions =>
      subscriptions.where((s) => s.isDueThisMonth).toList();
}

/// Subscription Notifier - IN-MEMORY ONLY (No persistence)
/// Uses Notifier pattern (Riverpod 3.0+)
class SubscriptionNotifier extends Notifier<SubscriptionState> {
  @override
  SubscriptionState build() {
    // PHASE 5.9: NO DEFAULT DATA - Fresh install starts empty
    print('[SUBSCRIPTION] Starting with zero data');
    return const SubscriptionState(subscriptions: []);
  }

  /// Add a new subscription
  void addSubscription(Subscription subscription) {
    // Ensure immediate reactivity by creating new list
    final newList = List<Subscription>.from(state.subscriptions)
      ..add(subscription);
    state = state.copyWith(subscriptions: newList);
    print(
        '[SUBSCRIPTION] Added: ${subscription.title} - ₺${subscription.amountMinor / 100}');
  }

  /// Pay subscription for current month (creates REAL transaction)
  Future<String?> paySubscription({
    required String subscriptionId,
    required String walletId,
  }) async {
    final subIndex =
        state.subscriptions.indexWhere((s) => s.id == subscriptionId);
    if (subIndex == -1) return null;

    final sub = state.subscriptions[subIndex];

    // Check if already paid this month
    if (_isPaidThisMonth(sub)) {
      print('[SUBSCRIPTION] Already paid this month: ${sub.title}');
      return null;
    }

    // Create REAL transaction
    final transactionId = 'tx_sub_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final transaction = FinanceTransaction(
      id: transactionId,
      walletId: walletId,
      type: FinanceTransactionType.expense,
      amountMinor: sub.amountMinor,
      category: sub.category,
      title: '${sub.title} - Abonelik Ödemesi',
      description: 'Aylık abonelik',
      date: now,
      createdAt: now,
      isRecurring: true,
    );

    // Add to finance provider (deducts wallet)
    await ref.read(financeProvider.notifier).addTransaction(transaction);

    // Update subscription's lastPaidDate
    final updatedSub = sub.copyWith(lastPaidDate: now);
    final updatedList = List<Subscription>.from(state.subscriptions);
    updatedList[subIndex] = updatedSub;
    state = state.copyWith(subscriptions: updatedList);

    print(
        '[SUBSCRIPTION] PAID: ${sub.title} - ₺${sub.amountMinor / 100} deducted');
    return transactionId;
  }

  /// Check if subscription was paid this month
  bool _isPaidThisMonth(Subscription sub) {
    if (sub.lastPaidDate == null) return false;
    final now = DateTime.now();
    return sub.lastPaidDate!.year == now.year &&
        sub.lastPaidDate!.month == now.month;
  }

  /// Check if a specific subscription was paid this month (public)
  bool isPaidThisMonth(String subscriptionId) {
    final sub = state.subscriptions.firstWhere(
      (s) => s.id == subscriptionId,
      orElse: () => Subscription(
        id: '',
        title: '',
        amountMinor: 0,
        renewalDay: 1,
        category: '',
        walletId: '',
        createdAt: DateTime.now(),
      ),
    );
    if (sub.id.isEmpty) return false;
    return _isPaidThisMonth(sub);
  }

  /// Skip subscription for this month (no transaction, no deactivation)
  void skipSubscription(String subscriptionId) {
    // Skip does nothing but log - subscription remains active for next month
    print(
        '[SUBSCRIPTION] SKIPPED: $subscriptionId (will be due again next month)');
  }

  /// Toggle active status
  void toggleActive(String subscriptionId) {
    final updated = state.subscriptions.map((sub) {
      if (sub.id == subscriptionId) {
        return sub.copyWith(isActive: !sub.isActive);
      }
      return sub;
    }).toList();
    state = state.copyWith(subscriptions: updated);
  }

  /// Mark as paid (legacy - updates UI only, no transaction)
  void markAsPaid(String subscriptionId) {
    final updated = state.subscriptions.map((sub) {
      if (sub.id == subscriptionId) {
        return sub.copyWith(lastPaidDate: DateTime.now());
      }
      return sub;
    }).toList();
    state = state.copyWith(subscriptions: updated);
    print('[SUBSCRIPTION] Marked paid (virtual): $subscriptionId');
  }

  /// Delete subscription (does NOT delete past transactions)
  void deleteSubscription(String subscriptionId) {
    final updated =
        state.subscriptions.where((s) => s.id != subscriptionId).toList();
    state = state.copyWith(subscriptions: updated);
    print(
        '[SUBSCRIPTION] DELETED: $subscriptionId (past transactions preserved)');
  }

  /// RESTORE FROM BACKUP - Phase 6
  void restoreFromBackup(List<Subscription> subscriptions) {
    print(
        '[SUBSCRIPTION] restoreFromBackup() - Restoring ${subscriptions.length} subscriptions');
    state = state.copyWith(subscriptions: subscriptions);
    print('[SUBSCRIPTION] restoreFromBackup() - Restore complete');
  }
}

/// Provider for subscription state
final subscriptionProvider =
    NotifierProvider<SubscriptionNotifier, SubscriptionState>(() {
  return SubscriptionNotifier();
});

/// Derived provider: Total monthly subscription cost
final totalSubscriptionCostProvider = Provider<int>((ref) {
  final subscriptionState = ref.watch(subscriptionProvider);
  return subscriptionState.totalMonthlyAmount;
});

/// Derived provider: Due subscriptions
final dueSubscriptionsProvider = Provider<List<Subscription>>((ref) {
  final subscriptionState = ref.watch(subscriptionProvider);
  return subscriptionState.dueSubscriptions;
});
