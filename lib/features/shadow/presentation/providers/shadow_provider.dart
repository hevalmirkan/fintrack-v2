import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Transaction Model for Shadow Portfolio
class ShadowTransaction {
  final String id;
  final String symbol;
  final String assetName;
  final double price;
  final double amount;
  final DateTime date;
  final String? note;

  const ShadowTransaction({
    required this.id,
    required this.symbol,
    required this.assetName,
    required this.price,
    required this.amount,
    required this.date,
    this.note,
  });

  double get totalValue => price * amount;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'assetName': assetName,
      'price': price,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory ShadowTransaction.fromJson(Map<String, dynamic> json) {
    return ShadowTransaction(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      assetName: json['assetName'] as String,
      price: (json['price'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );
  }
}

/// Derived Asset from grouped transactions
class DerivedAsset {
  final String symbol;
  final String name;
  final double totalAmount;
  final double averagePrice;
  final double totalCost;
  final int transactionCount;

  const DerivedAsset({
    required this.symbol,
    required this.name,
    required this.totalAmount,
    required this.averagePrice,
    required this.totalCost,
    required this.transactionCount,
  });
}

/// Shadow Portfolio Notifier - REACTIVE STATE (Riverpod 3.x pattern)
class ShadowPortfolioNotifier extends Notifier<List<ShadowTransaction>> {
  static const String _storageKey = 'shadow_portfolio_v2';
  static const _uuid = Uuid();

  @override
  List<ShadowTransaction> build() {
    _loadFromStorage();
    return [];
  }

  /// Add a new transaction - IMMUTABLE UPDATE
  Future<ShadowTransaction> addTransaction({
    required String symbol,
    required String assetName,
    required double price,
    required double amount,
    DateTime? date,
    String? note,
  }) async {
    final tx = ShadowTransaction(
      id: _uuid.v4(),
      symbol: symbol.toUpperCase(),
      assetName: assetName,
      price: price,
      amount: amount,
      date: date ?? DateTime.now(),
      note: note,
    );

    // IMMUTABLE UPDATE - triggers UI redraw
    state = [...state, tx];

    await _saveToStorage();
    print(
        '[Portfolio] 📝 Added: ${amount}x $symbol @ \$${price.toStringAsFixed(2)}');

    return tx;
  }

  /// Remove a transaction
  Future<void> removeTransaction(String id) async {
    state = state.where((tx) => tx.id != id).toList();
    await _saveToStorage();
    print('[Portfolio] 🗑️ Removed transaction: $id');
  }

  /// Get all unique symbols in portfolio
  Set<String> get symbols => state.map((tx) => tx.symbol).toSet();

  /// Load from SharedPreferences
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final jsonList = json.decode(jsonString) as List<dynamic>;
        state = jsonList
            .map((j) => ShadowTransaction.fromJson(j as Map<String, dynamic>))
            .toList();
        print('[Portfolio] 📂 Loaded ${state.length} transactions');
      }
    } catch (e) {
      print('[Portfolio] ❌ Load error: $e');
    }
  }

  /// Save to SharedPreferences
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.map((tx) => tx.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
    } catch (e) {
      print('[Portfolio] ❌ Save error: $e');
    }
  }
}

/// Main Portfolio Provider - Notifier (Riverpod 3.x)
final shadowPortfolioProvider =
    NotifierProvider<ShadowPortfolioNotifier, List<ShadowTransaction>>(() {
  return ShadowPortfolioNotifier();
});

/// Derived Assets Provider - Auto-recalculates when portfolio changes
final userAssetsProvider = Provider<List<DerivedAsset>>((ref) {
  final transactions = ref.watch(shadowPortfolioProvider);

  if (transactions.isEmpty) return [];

  // Group by symbol
  final grouped = <String, List<ShadowTransaction>>{};
  for (final tx in transactions) {
    grouped.putIfAbsent(tx.symbol, () => []).add(tx);
  }

  // Calculate derived assets
  return grouped.entries.map((entry) {
    final txList = entry.value;
    final totalAmount = txList.fold<double>(0, (sum, tx) => sum + tx.amount);
    final totalCost = txList.fold<double>(0, (sum, tx) => sum + tx.totalValue);
    final avgPrice = totalAmount > 0 ? totalCost / totalAmount : 0.0;

    return DerivedAsset(
      symbol: entry.key,
      name: txList.first.assetName,
      totalAmount: totalAmount,
      averagePrice: avgPrice,
      totalCost: totalCost,
      transactionCount: txList.length,
    );
  }).toList();
});

/// User's portfolio symbols for Scout VIP matching
final userPortfolioSymbolsProvider = Provider<Set<String>>((ref) {
  return ref
      .watch(shadowPortfolioProvider)
      .map((tx) => tx.symbol.toLowerCase())
      .toSet();
});
