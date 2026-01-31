import 'dart:async';

import '../../../assets/domain/repositories/i_asset_repository.dart';
import '../../../transactions/domain/repositories/i_transaction_repository.dart';
import '../../domain/entities/dashboard_stats.dart';

/// Service that calculates dashboard statistics by combining data from
/// Assets and Transactions repositories with debouncing to prevent excessive updates
class DashboardCalculationService {
  final IAssetRepository _assetRepository;
  final ITransactionRepository _transactionRepository;

  // Debounce timer to prevent rapid recalculations
  Timer? _debounceTimer;
  final _statsController = StreamController<DashboardStats>.broadcast();
  DashboardStats? _lastStats;

  DashboardCalculationService({
    required IAssetRepository assetRepository,
    required ITransactionRepository transactionRepository,
  })  : _assetRepository = assetRepository,
        _transactionRepository = transactionRepository {
    // Initialize reactive calculation
    _initializeReactiveCalculation();
  }

  void _initializeReactiveCalculation() {
    // Listen to asset changes
    _assetRepository.getAssetsStream().listen((_) {
      _scheduleCalculation();
    });

    // Listen to transaction changes
    _transactionRepository.getTransactionsStream().listen((_) {
      _scheduleCalculation();
    });

    // Initial calculation
    _scheduleCalculation();
  }

  void _scheduleCalculation() {
    // Cancel previous timer if exists
    _debounceTimer?.cancel();

    // Schedule new calculation after debounce period
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _calculateAndEmit();
    });
  }

  Future<void> _calculateAndEmit() async {
    try {
      // Fetch all data (with timeout to prevent hanging)
      final assets = await _assetRepository
          .getAssets()
          .timeout(const Duration(seconds: 5));
      final transactions = await _transactionRepository
          .getTransactions()
          .timeout(const Duration(seconds: 5));

      // Calculate total asset value
      int totalAssetValue = 0;
      for (final asset in assets) {
        // Use displayPrice (which includes lastKnownPrice if available)
        final price = (asset.lastKnownPrice ?? asset.currentPrice) as num;
        final quantity = asset.quantityMinor as num;
        totalAssetValue += (quantity.toInt() * price.toInt()) ~/ 100;
      }

      // Get current month boundaries
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Calculate monthly income and expense
      int monthlyIncome = 0;
      int monthlyExpense = 0;
      int totalIncome = 0;
      int totalExpense = 0;

      for (final txn in transactions) {
        final isThisMonth =
            txn.date.isAfter(monthStart) && txn.date.isBefore(monthEnd);

        final amount = (txn.totalMinor as num).toInt();

        if (txn.type.name == 'income') {
          totalIncome += amount;
          if (isThisMonth) monthlyIncome += amount;
        } else if (txn.type.name == 'expense') {
          totalExpense += amount;
          if (isThisMonth) monthlyExpense += amount;
        }
      }

      // Calculate cash balance
      final cashBalance = totalIncome - totalExpense;

      // Calculate net worth
      final netWorth = totalAssetValue + cashBalance;

      final newStats = DashboardStats(
        netWorth: netWorth,
        cashBalance: cashBalance,
        monthlyIncome: monthlyIncome,
        monthlyExpense: monthlyExpense,
        totalAssetValue: totalAssetValue,
      );

      // Only emit if stats changed (prevent unnecessary rebuilds)
      if (_lastStats == null || _lastStats != newStats) {
        _lastStats = newStats;
        if (!_statsController.isClosed) {
          _statsController.add(newStats);
        }
      }
    } catch (e) {
      // On error, emit default stats instead of crashing
      if (!_statsController.isClosed) {
        _statsController.add(const DashboardStats(
          netWorth: 0,
          cashBalance: 0,
          monthlyIncome: 0,
          monthlyExpense: 0,
          totalAssetValue: 0,
        ));
      }
    }
  }

  /// Returns a stream of dashboard statistics that updates whenever
  /// any of the underlying data changes (with debouncing)
  Stream<DashboardStats> getStats() {
    return _statsController.stream;
  }

  void dispose() {
    _debounceTimer?.cancel();
    _statsController.close();
  }
}
