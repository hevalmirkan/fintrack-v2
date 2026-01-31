import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../entities/shadow_transaction.dart';

/// Shadow Service - Decision Logging System
///
/// NOT a trading platform. This is for:
/// - Recording personal investment decisions
/// - Tracking reasoning and thoughts
/// - Learning from historical decisions
class ShadowService {
  static const String _storageKey = 'shadow_transactions';
  static final ShadowService _instance = ShadowService._internal();
  factory ShadowService() => _instance;
  ShadowService._internal();

  final _uuid = const Uuid();
  List<ShadowTransaction>? _cache;

  /// Add a new shadow transaction
  Future<ShadowTransaction> addTransaction({
    required String symbol,
    required String assetName,
    required ShadowIntent intent,
    required double referencePrice,
    required double amount,
    DateTime? date,
    String? note,
    Map<String, dynamic>? metadata,
  }) async {
    final transaction = ShadowTransaction(
      id: _uuid.v4(),
      symbol: symbol,
      assetName: assetName,
      intent: intent,
      referencePrice: referencePrice,
      amount: amount,
      date: date ?? DateTime.now(),
      note: note,
      metadata: metadata,
    );

    final transactions = await getTransactions();
    transactions.insert(0, transaction); // Add to front (newest first)
    await _saveTransactions(transactions);

    print(
        '[Shadow] 📝 Recorded: ${intent.label} ${amount}x $symbol @ \$${referencePrice.toStringAsFixed(2)}');

    return transaction;
  }

  /// Get all shadow transactions
  Future<List<ShadowTransaction>> getTransactions() async {
    if (_cache != null) return _cache!;

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null || jsonString.isEmpty) {
      _cache = [];
      return _cache!;
    }

    try {
      final jsonList = json.decode(jsonString) as List<dynamic>;
      _cache = jsonList
          .map((j) => ShadowTransaction.fromJson(j as Map<String, dynamic>))
          .toList();
      return _cache!;
    } catch (e) {
      print('[Shadow] ❌ Error loading transactions: $e');
      _cache = [];
      return _cache!;
    }
  }

  /// Get transactions for a specific symbol
  Future<List<ShadowTransaction>> getTransactionsForSymbol(
      String symbol) async {
    final all = await getTransactions();
    return all
        .where((t) => t.symbol.toLowerCase() == symbol.toLowerCase())
        .toList();
  }

  /// Get unique symbols that user has recorded decisions for
  Future<Set<String>> getUserAssetSymbols() async {
    final all = await getTransactions();
    return all.map((t) => t.symbol.toUpperCase()).toSet();
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String id) async {
    final transactions = await getTransactions();
    transactions.removeWhere((t) => t.id == id);
    await _saveTransactions(transactions);
    print('[Shadow] 🗑️ Deleted transaction: $id');
  }

  /// Clear all transactions
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    _cache = [];
    print('[Shadow] 🧹 Cleared all transactions');
  }

  Future<void> _saveTransactions(List<ShadowTransaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = transactions.map((t) => t.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
    _cache = transactions;
  }
}
