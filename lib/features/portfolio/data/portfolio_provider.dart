import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../assets/domain/entities/asset.dart';

/// Transaction type - simplified buy/sell
enum TransactionType { buy, sell }

/// Transaction Model for Portfolio
class PortfolioTransaction {
  final String id;
  final String symbol;
  final String assetName;
  final double amount;
  final double price;
  final DateTime date;
  final TransactionType type;
  final String? note;

  const PortfolioTransaction({
    required this.id,
    required this.symbol,
    required this.assetName,
    required this.amount,
    required this.price,
    required this.date,
    required this.type,
    this.note,
  });

  double get totalValue => amount * price;

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'assetName': assetName,
        'amount': amount,
        'price': price,
        'date': date.toIso8601String(),
        'type': type.name,
        'note': note,
      };

  factory PortfolioTransaction.fromJson(Map<String, dynamic> json) {
    return PortfolioTransaction(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      assetName: json['assetName'] as String,
      amount: (json['amount'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      type: TransactionType.values.byName(json['type'] as String),
      note: json['note'] as String?,
    );
  }
}

/// Portfolio Notifier - Holds all transactions (Riverpod 3.x Notifier pattern)
class PortfolioNotifier extends Notifier<List<PortfolioTransaction>> {
  static const String _storageKey = 'portfolio_transactions_v3';
  static const _uuid = Uuid();

  @override
  List<PortfolioTransaction> build() {
    _loadFromStorage();
    return [];
  }

  /// Add a BUY transaction (Portföye Ekle)
  Future<PortfolioTransaction> addBuyTransaction({
    required String symbol,
    required String assetName,
    required double amount,
    required double price,
    DateTime? date,
    String? note,
  }) async {
    final tx = PortfolioTransaction(
      id: _uuid.v4(),
      symbol: symbol.toUpperCase(),
      assetName: assetName,
      amount: amount,
      price: price,
      date: date ?? DateTime.now(),
      type: TransactionType.buy,
      note: note,
    );

    // IMMUTABLE UPDATE - triggers rebuild of all watchers
    state = [...state, tx];
    await _saveToStorage();

    print(
        '[Portfolio] 📥 BUY: ${amount}x $symbol @ \$${price.toStringAsFixed(2)} = \$${tx.totalValue.toStringAsFixed(2)}');
    return tx;
  }

  /// Add a SELL transaction (Portföyden Çıkar)
  Future<PortfolioTransaction> addSellTransaction({
    required String symbol,
    required String assetName,
    required double amount,
    required double price,
    DateTime? date,
    String? note,
  }) async {
    final tx = PortfolioTransaction(
      id: _uuid.v4(),
      symbol: symbol.toUpperCase(),
      assetName: assetName,
      amount: amount,
      price: price,
      date: date ?? DateTime.now(),
      type: TransactionType.sell,
      note: note,
    );

    state = [...state, tx];
    await _saveToStorage();

    print(
        '[Portfolio] 📤 SELL: ${amount}x $symbol @ \$${price.toStringAsFixed(2)}');
    return tx;
  }

  /// Remove a transaction
  Future<void> removeTransaction(String id) async {
    state = state.where((tx) => tx.id != id).toList();
    await _saveToStorage();
    print('[Portfolio] 🗑️ Removed: $id');
  }

  /// Clear all transactions
  Future<void> clearAll() async {
    state = [];
    await _saveToStorage();
    print('[Portfolio] 🧹 Cleared all transactions');
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final jsonList = json.decode(jsonString) as List<dynamic>;
        state = jsonList
            .map(
                (j) => PortfolioTransaction.fromJson(j as Map<String, dynamic>))
            .toList();
        print('[Portfolio] 📂 Loaded ${state.length} transactions');
      }
    } catch (e) {
      print('[Portfolio] ❌ Load error: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.map((tx) => tx.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
      print('[Portfolio] 💾 Saved ${state.length} transactions');
    } catch (e) {
      print('[Portfolio] ❌ Save error: $e');
    }
  }
}

/// Main Portfolio Provider - Notifier (Riverpod 3.x)
final portfolioProvider =
    NotifierProvider<PortfolioNotifier, List<PortfolioTransaction>>(() {
  return PortfolioNotifier();
});

/// ===============================================================
/// THE CRITICAL PART: userAssetsProvider
/// ===============================================================
///
/// This provider WATCHES portfolioProvider and transforms transactions
/// into grouped Asset objects. When transactions change, this
/// automatically recalculates and triggers UI updates.
///
/// UI widgets should watch THIS provider, NOT portfolioProvider directly.
final userAssetsProvider = Provider<List<Asset>>((ref) {
  final transactions = ref.watch(portfolioProvider);

  if (transactions.isEmpty) {
    print('[Portfolio] 📊 No transactions → 0 assets');
    return [];
  }

  // Group transactions by symbol
  final grouped = <String, List<PortfolioTransaction>>{};
  for (final tx in transactions) {
    grouped.putIfAbsent(tx.symbol, () => []).add(tx);
  }

  // Transform each group into an Asset
  final assets = <Asset>[];

  for (final entry in grouped.entries) {
    final symbol = entry.key;
    final txList = entry.value;

    // Calculate net position
    double totalBought = 0;
    double totalBoughtCost = 0;
    double totalSold = 0;

    for (final tx in txList) {
      if (tx.type == TransactionType.buy) {
        totalBought += tx.amount;
        totalBoughtCost += tx.totalValue;
      } else {
        totalSold += tx.amount;
      }
    }

    final netAmount = totalBought - totalSold;

    // Skip if net position is 0 or negative
    if (netAmount <= 0) continue;

    // Calculate weighted average price
    final avgPrice = totalBought > 0 ? totalBoughtCost / totalBought : 0.0;

    // Get asset name from first transaction
    final assetName = txList.first.assetName;

    // Convert to Asset model (prices in minor units = cents)
    assets.add(Asset(
      id: 'portfolio_$symbol',
      symbol: symbol,
      name: assetName,
      averagePrice: (avgPrice * 100).round(), // Convert to cents
      currentPrice: (avgPrice * 100).round(), // Use avg as current for now
      quantityMinor:
          (netAmount * 100000000).round(), // High precision for crypto
      apiId: symbol.toLowerCase(), // For market data lookup
    ));
  }

  print(
      '[Portfolio] 📊 Derived ${assets.length} assets from ${transactions.length} transactions');
  for (final a in assets) {
    print(
        '[Portfolio]   - ${a.symbol}: ${(a.quantityMinor / 100000000).toStringAsFixed(4)} @ avg \$${(a.averagePrice / 100).toStringAsFixed(2)}');
  }

  return assets;
});

/// User's portfolio symbols for Scout VIP matching
final userPortfolioSymbolsProvider = Provider<Set<String>>((ref) {
  final assets = ref.watch(userAssetsProvider);
  return assets.map((a) => a.symbol.toLowerCase()).toSet();
});

/// Total portfolio value (based on average prices)
final portfolioTotalValueProvider = Provider<double>((ref) {
  final assets = ref.watch(userAssetsProvider);
  double total = 0;
  for (final a in assets) {
    final amount = a.quantityMinor / 100000000;
    final price = a.averagePrice / 100;
    total += amount * price;
  }
  return total;
});
