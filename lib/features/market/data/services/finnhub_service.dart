import 'dart:convert';
import 'package:http/http.dart' as http;

/// Finnhub.io API Service
/// Free tier: 60 API calls/minute
class FinnhubService {
  static final FinnhubService _instance = FinnhubService._internal();
  factory FinnhubService() => _instance;
  FinnhubService._internal();

  // API Configuration
  static const String _baseUrl = 'https://finnhub.io/api/v1';
  static const String _apiKey = 'd57f5lhr01qrcrnb69i0d57f5lhr01qrcrnb69ig';
  static const Duration _rateDelay = Duration(milliseconds: 300);

  /// Fetch current price for a single symbol
  /// Returns null if request fails or no data
  Future<FinnhubQuote?> fetchQuote(String finnhubSymbol) async {
    try {
      final url =
          Uri.parse('$_baseUrl/quote?symbol=$finnhubSymbol&token=$_apiKey');

      print('[Finnhub] 📊 Fetching: $finnhubSymbol');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      // Rate limit prevention
      await Future.delayed(_rateDelay);

      if (response.statusCode != 200) {
        print('[Finnhub] ❌ $finnhubSymbol: API ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      // Finnhub response: c = current, d = change, dp = percent change, h = high, l = low, o = open, pc = previous close
      final currentPrice = (data['c'] as num?)?.toDouble();
      final percentChange = (data['dp'] as num?)?.toDouble();
      final previousClose = (data['pc'] as num?)?.toDouble();

      // Check for valid data (Finnhub returns 0 for unsupported symbols)
      if (currentPrice == null || currentPrice == 0) {
        print('[Finnhub] ⚠️ $finnhubSymbol: No price data (c=0)');
        return null;
      }

      print(
          '[Finnhub] ✅ $finnhubSymbol: \$${currentPrice.toStringAsFixed(2)} (${percentChange?.toStringAsFixed(2)}%)');

      return FinnhubQuote(
        symbol: finnhubSymbol,
        price: currentPrice,
        changePercent: percentChange,
        previousClose: previousClose,
      );
    } catch (e) {
      print('[Finnhub] ❌ $finnhubSymbol: $e');
      return null;
    }
  }

  /// Batch fetch quotes for multiple symbols
  Future<Map<String, FinnhubQuote>> fetchBatch(
      List<String> finnhubSymbols) async {
    final results = <String, FinnhubQuote>{};

    print('[Finnhub] 🚀 Batch fetching ${finnhubSymbols.length} symbols');

    for (final symbol in finnhubSymbols) {
      final quote = await fetchQuote(symbol);
      if (quote != null) {
        results[symbol] = quote;
      }
    }

    print(
        '[Finnhub] ✅ Batch complete: ${results.length}/${finnhubSymbols.length} successful');
    return results;
  }
}

/// Quote data from Finnhub
class FinnhubQuote {
  final String symbol;
  final double price;
  final double? changePercent;
  final double? previousClose;

  FinnhubQuote({
    required this.symbol,
    required this.price,
    this.changePercent,
    this.previousClose,
  });

  @override
  String toString() =>
      'FinnhubQuote($symbol: \$$price, ${changePercent?.toStringAsFixed(2)}%)';
}
