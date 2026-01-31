import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/market_price.dart';
import '../../domain/repositories/i_market_price_repository.dart';

/// Real API implementation of market price repository
/// Phase 9: Uses CoinGecko for crypto, Frankfurter for forex
class MarketPriceRepositoryImpl implements IMarketPriceRepository {
  final FirebaseFirestore _firestore;
  final String? _userId;
  final http.Client _httpClient;

  MarketPriceRepositoryImpl({
    required FirebaseFirestore firestore,
    required String? userId,
    http.Client? httpClient,
  })  : _firestore = firestore,
        _userId = userId,
        _httpClient = httpClient ?? http.Client();

  CollectionReference<Map<String, dynamic>> _getPricesCollection() {
    if (_userId == null) throw Exception('User not authenticated');
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('market_prices');
  }

  @override
  Future<MarketPrice?> getCachedPrice(String symbol) async {
    try {
      final doc = await _getPricesCollection().doc(symbol.toUpperCase()).get();
      if (!doc.exists) return null;
      return _fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<MarketPrice> fetchAndCachePrice(String symbol) async {
    try {
      // 1. Try to fetch from real API
      final priceMinor = await _fetchFromRealAPI(symbol);

      // 2. Create MarketPrice entity
      final marketPrice = MarketPrice(
        symbol: symbol.toUpperCase(),
        priceMinor: priceMinor,
        timestamp: DateTime.now(),
        source: _getSourceForSymbol(symbol),
      );

      // 3. Cache in Firestore
      await _saveToFirestore(marketPrice);

      return marketPrice;
    } catch (e) {
      // 4. Fallback: Try to load from cache
      final cached = await getCachedPrice(symbol);
      if (cached != null) {
        return cached;
      }

      // 5. No cache available - rethrow error
      throw Exception('Failed to fetch price for $symbol: $e');
    }
  }

  @override
  Stream<MarketPrice?> watchPrice(String symbol) {
    return _getPricesCollection()
        .doc(symbol.toUpperCase())
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return _fromFirestore(doc);
    });
  }

  @override
  Future<void> saveManualPrice(String symbol, int priceMinor) async {
    final marketPrice = MarketPrice(
      symbol: symbol.toUpperCase(),
      priceMinor: priceMinor,
      timestamp: DateTime.now(),
      source: 'manual',
    );
    await _saveToFirestore(marketPrice);
  }

  // ============ PRIVATE HELPERS ============

  /// Fetch price from real APIs based on symbol type
  Future<int> _fetchFromRealAPI(String symbol) async {
    final symbolUpper = symbol.toUpperCase();

    // Crypto: Use CoinGecko
    if (_isCrypto(symbolUpper)) {
      return await _fetchFromCoinGecko(symbolUpper);
    }

    // Forex: Use Frankfurter
    if (_isForex(symbolUpper)) {
      return await _fetchFromFrankfurter(symbolUpper);
    }

    // Fallback for unknown symbols (manual input required)
    throw Exception('Unknown symbol type: $symbol');
  }

  /// Fetch crypto price from CoinGecko (FREE API)
  Future<int> _fetchFromCoinGecko(String symbol) async {
    final coinIds = {
      'BTC': 'bitcoin',
      'ETH': 'ethereum',
      'BNB': 'binancecoin',
      'SOL': 'solana',
      'ADA': 'cardano',
    };

    final coinId = coinIds[symbol];
    if (coinId == null) {
      throw Exception('Crypto symbol $symbol not supported');
    }

    try {
      final url = Uri.parse(
        'https://api.coingecko.com/api/v3/simple/price?ids=$coinId&vs_currencies=usd',
      );

      final response =
          await _httpClient.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('CoinGecko API error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final priceUsd = data[coinId]?['usd'] as num?;

      if (priceUsd == null) {
        throw Exception('Price not found in CoinGecko response');
      }

      // Convert to minor units (cents)
      return (priceUsd * 100).round();
    } catch (e) {
      throw Exception('CoinGecko fetch failed: $e');
    }
  }

  /// Fetch forex rate from Frankfurter (FREE API)
  Future<int> _fetchFromFrankfurter(String symbol) async {
    try {
      // Frankfurter uses EUR as base, we want USD rates
      final url = Uri.parse('https://api.frankfurter.app/latest?from=USD');

      final response =
          await _httpClient.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Frankfurter API error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rates = data['rates'] as Map<String, dynamic>?;

      if (rates == null) {
        throw Exception('Rates not found in Frankfurter response');
      }

      // Special handling for different symbols
      double rate;
      switch (symbol) {
        case 'USD':
          rate = 1.0; // USD to USD
          break;
        case 'EUR':
          rate = (rates['EUR'] as num?)?.toDouble() ?? 0.0;
          break;
        case 'TRY':
          rate = (rates['TRY'] as num?)?.toDouble() ?? 0.0;
          break;
        case 'GBP':
          rate = (rates['GBP'] as num?)?.toDouble() ?? 0.0;
          break;
        default:
          throw Exception('Forex symbol $symbol not supported');
      }

      // Convert to minor units (for exchange rates, we use 1:1 scale)
      return (rate * 100).round();
    } catch (e) {
      throw Exception('Frankfurter fetch failed: $e');
    }
  }

  // Symbol type detection
  bool _isCrypto(String symbol) {
    return ['BTC', 'ETH', 'BNB', 'SOL', 'ADA'].contains(symbol);
  }

  bool _isForex(String symbol) {
    return ['USD', 'EUR', 'TRY', 'GBP'].contains(symbol);
  }

  String _getSourceForSymbol(String symbol) {
    if (_isCrypto(symbol)) return 'coingecko';
    if (_isForex(symbol)) return 'frankfurter';
    return 'unknown';
  }

  Future<void> _saveToFirestore(MarketPrice price) async {
    await _getPricesCollection().doc(price.symbol).set(_toFirestore(price));
  }

  MarketPrice _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MarketPrice(
      symbol: data['symbol'] as String,
      priceMinor: (data['priceMinor'] as num).toInt(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      source: data['source'] as String,
    );
  }

  Map<String, dynamic> _toFirestore(MarketPrice price) {
    return {
      'symbol': price.symbol,
      'priceMinor': price.priceMinor,
      'timestamp': Timestamp.fromDate(price.timestamp),
      'source': price.source,
    };
  }
}
