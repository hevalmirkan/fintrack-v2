import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

/// TradingView Turkey Scanner Service
/// Specialized for BIST (Borsa Istanbul) stocks only
/// Uses the Turkey-specific scanner endpoint
class TradingViewTurkeyService {
  static final TradingViewTurkeyService _instance =
      TradingViewTurkeyService._internal();
  factory TradingViewTurkeyService() => _instance;
  TradingViewTurkeyService._internal();

  // Turkey-specific scanner endpoint
  static const String _scannerUrl =
      'https://scanner.tradingview.com/turkey/scan';

  // CORS proxy for web platform
  static const String _corsProxy = 'https://corsproxy.io/?';

  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  /// Fetch quotes for BIST stocks
  /// Input: List of symbols like ["THYAO", "GARAN", "AKBNK"]
  /// Returns: Map of symbol -> TvTurkeyQuote
  Future<Map<String, TvTurkeyQuote>> fetchBistQuotes(
      List<String> symbols) async {
    if (symbols.isEmpty) return {};

    final results = <String, TvTurkeyQuote>{};

    // Convert symbols to BIST:SYMBOL format
    final tickers = symbols.map((s) => 'BIST:$s').toList();

    print(
        '[TV Turkey] 🇹🇷 Fetching ${symbols.length} BIST stocks: ${symbols.join(", ")}');

    try {
      final payload = json.encode({
        'symbols': {'tickers': tickers},
        'columns': ['close', 'change'],
      });

      // Use CORS proxy on web platform
      final targetUrl = kIsWeb
          ? '$_corsProxy${Uri.encodeComponent(_scannerUrl)}'
          : _scannerUrl;

      print('[TV Turkey] 🌐 Using ${kIsWeb ? "CORS proxy" : "direct"} request');

      final response = await http
          .post(
            Uri.parse(targetUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (!kIsWeb) 'User-Agent': _userAgent,
              if (!kIsWeb) 'Origin': 'https://www.tradingview.com',
              if (!kIsWeb) 'Referer': 'https://www.tradingview.com/',
            },
            body: payload,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        print('[TV Turkey] ❌ API Error: ${response.statusCode}');
        print('[TV Turkey] Response: ${response.body}');
        return {};
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final rows = data['data'] as List<dynamic>?;

      if (rows == null || rows.isEmpty) {
        print('[TV Turkey] ⚠️ No data returned');
        return {};
      }

      // Parse each row
      for (int i = 0; i < rows.length && i < symbols.length; i++) {
        final row = rows[i] as Map<String, dynamic>;
        final values = row['d'] as List<dynamic>?;
        final tickerInfo = row['s'] as String?;

        if (values != null && values.isNotEmpty) {
          final close = (values[0] as num?)?.toDouble();
          final change =
              values.length > 1 ? (values[1] as num?)?.toDouble() : null;

          if (close != null && close > 0) {
            // Extract symbol from BIST:THYAO -> THYAO
            final symbol = tickerInfo?.replaceFirst('BIST:', '') ?? symbols[i];

            double? changePercent;
            if (change != null && close > 0) {
              // change is absolute, calculate percent
              final prevClose = close - change;
              if (prevClose > 0) {
                changePercent = (change / prevClose) * 100;
              }
            }

            results[symbol] = TvTurkeyQuote(
              symbol: symbol,
              price: close,
              change: change,
              changePercent: changePercent,
            );

            print(
                '[TV Turkey] ✅ $symbol: ₺${close.toStringAsFixed(2)} (${changePercent?.toStringAsFixed(2) ?? "?"}%)');
          }
        }
      }

      print(
          '[TV Turkey] 📊 Success: ${results.length}/${symbols.length} BIST stocks fetched');
      return results;
    } catch (e) {
      print('[TV Turkey] ❌ Error: $e');
      return {};
    }
  }
}

/// Quote data from TradingView Turkey
class TvTurkeyQuote {
  final String symbol;
  final double price;
  final double? change;
  final double? changePercent;

  TvTurkeyQuote({
    required this.symbol,
    required this.price,
    this.change,
    this.changePercent,
  });

  @override
  String toString() =>
      'TvTurkeyQuote($symbol: ₺$price, ${changePercent?.toStringAsFixed(2)}%)';
}
