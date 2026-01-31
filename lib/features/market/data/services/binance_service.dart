/// =====================================================
/// BINANCE SERVICE — Phase 8.5: Direct Crypto Prices
/// =====================================================
/// No API key required. Uses public Binance API.
/// Fetches real-time crypto prices in USDT.
/// =====================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Result from Binance API
class BinanceQuote {
  final String symbol;
  final double priceUsd;
  final double? changePercent24h;

  BinanceQuote({
    required this.symbol,
    required this.priceUsd,
    this.changePercent24h,
  });
}

/// Binance Public API Service (No API Key Required)
class BinanceService {
  static const String _baseUrl = 'https://api.binance.com/api/v3';

  /// v1.0 Locked Set - Top 5 Crypto
  static const Map<String, String> supportedCrypto = {
    'bitcoin': 'BTCUSDT',
    'ethereum': 'ETHUSDT',
    'binancecoin': 'BNBUSDT',
    'solana': 'SOLUSDT',
    'ripple': 'XRPUSDT',
  };

  /// Fetch single crypto price
  Future<BinanceQuote?> fetchPrice(String binanceSymbol) async {
    try {
      // Get current price
      final priceUrl =
          Uri.parse('$_baseUrl/ticker/price?symbol=$binanceSymbol');
      final priceResponse =
          await http.get(priceUrl).timeout(const Duration(seconds: 10));

      if (priceResponse.statusCode != 200) return null;

      final priceData = json.decode(priceResponse.body) as Map<String, dynamic>;
      final price = double.tryParse(priceData['price'] as String) ?? 0;

      // Get 24h change
      final statsUrl = Uri.parse('$_baseUrl/ticker/24hr?symbol=$binanceSymbol');
      final statsResponse =
          await http.get(statsUrl).timeout(const Duration(seconds: 10));

      double? changePercent;
      if (statsResponse.statusCode == 200) {
        final statsData =
            json.decode(statsResponse.body) as Map<String, dynamic>;
        changePercent =
            double.tryParse(statsData['priceChangePercent'] as String);
      }

      return BinanceQuote(
        symbol: binanceSymbol,
        priceUsd: price,
        changePercent24h: changePercent,
      );
    } catch (e) {
      return null;
    }
  }

  /// Fetch all supported crypto prices at once
  Future<Map<String, BinanceQuote>> fetchAllCrypto() async {
    final results = <String, BinanceQuote>{};

    try {
      // Batch fetch using ticker/24hr for all symbols
      final symbols = supportedCrypto.values.toList();
      final symbolsJson = json.encode(symbols);

      final url = Uri.parse('$_baseUrl/ticker/24hr?symbols=$symbolsJson');
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;

        for (final item in data) {
          final symbolData = item as Map<String, dynamic>;
          final symbol = symbolData['symbol'] as String;
          final price = double.tryParse(symbolData['lastPrice'] as String) ?? 0;
          final change =
              double.tryParse(symbolData['priceChangePercent'] as String);

          // Map back to our internal ID
          final internalId = supportedCrypto.entries
              .firstWhere((e) => e.value == symbol,
                  orElse: () => MapEntry(symbol, symbol))
              .key;

          results[internalId] = BinanceQuote(
            symbol: symbol,
            priceUsd: price,
            changePercent24h: change,
          );
        }
      }
    } catch (e) {
      // Fallback: fetch individually
      for (final entry in supportedCrypto.entries) {
        final quote = await fetchPrice(entry.value);
        if (quote != null) {
          results[entry.key] = quote;
        }
      }
    }

    return results;
  }

  /// Check if we support this crypto ID
  bool isSupported(String cryptoId) => supportedCrypto.containsKey(cryptoId);

  /// Get Binance symbol from our internal ID
  String? getBinanceSymbol(String cryptoId) => supportedCrypto[cryptoId];
}
