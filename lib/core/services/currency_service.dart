import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Currency enum for type safety
enum Currency {
  TRY, // Turkish Lira (base)
  USD, // US Dollar
  EUR, // Euro
  GBP, // British Pound
  GOLD, // Gold (gram)
  BTC, // Bitcoin
  ETH, // Ethereum
}

/// Currency Service - Fetches live exchange rates with caching and fallback
///
/// APIs Used:
/// - Frankfurter API: USD, EUR, GBP → TRY
/// - CoinGecko: BTC, ETH → TRY
/// - Mock: GOLD → TRY
///
/// Design Principles:
/// - Single session cache (no persistence)
/// - Fallback to mock rates on error
/// - Never blocks or crashes
class CurrencyService {
  // Singleton pattern
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  // ============================================================
  // CACHE - Session-based, cleared on app restart
  // ============================================================
  final Map<Currency, double> _rateCache = {};
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 30);

  // ============================================================
  // FALLBACK MOCK RATES (if all APIs fail)
  // ============================================================
  static const Map<Currency, double> _mockRates = {
    Currency.TRY: 1.0,
    Currency.USD: 35.5, // 1 USD = 35.5 TRY
    Currency.EUR: 38.2, // 1 EUR = 38.2 TRY
    Currency.GBP: 44.8, // 1 GBP = 44.8 TRY
    Currency.GOLD: 2950.0, // 1 gram gold = 2950 TRY
    Currency.BTC: 3130000.0, // 1 BTC = ~3.13M TRY
    Currency.ETH: 105000.0, // 1 ETH = ~105K TRY
  };

  // ============================================================
  // PUBLIC API
  // ============================================================

  /// Get exchange rate from [from] currency to TRY
  /// Returns the rate (how many TRY per 1 unit of [from])
  ///
  /// Example: getRate(Currency.USD) returns 35.5 (1 USD = 35.5 TRY)
  Future<double> getRate(Currency from) async {
    // TRY to TRY is always 1.0
    if (from == Currency.TRY) return 1.0;

    // Check cache first
    if (_isCacheValid() && _rateCache.containsKey(from)) {
      debugPrint('[CURRENCY] Cache hit for $from: ${_rateCache[from]}');
      return _rateCache[from]!;
    }

    // Fetch fresh rates
    try {
      final rate = await _fetchRate(from);
      _rateCache[from] = rate;
      _lastFetchTime = DateTime.now();
      debugPrint('[CURRENCY] Live rate for $from: $rate');
      return rate;
    } catch (e) {
      debugPrint('[CURRENCY] API failed for $from, using fallback: $e');
      return _mockRates[from] ?? 1.0;
    }
  }

  /// Convert amount from [from] currency to TRY minor units (kuruş)
  Future<int> convertToTRYMinor(double amount, Currency from) async {
    final rate = await getRate(from);
    final amountInTRY = amount * rate;
    return (amountInTRY * 100).round();
  }

  /// Get formatted rate display text
  Future<String> getRateDisplayText(Currency from) async {
    if (from == Currency.TRY) return '';

    final rate = await getRate(from);
    final symbol = _getCurrencySymbol(from);

    // Format rate nicely
    String formattedRate;
    if (rate >= 10000) {
      formattedRate = '${(rate / 1000).toStringAsFixed(1)}K';
    } else {
      formattedRate = rate.toStringAsFixed(2);
    }

    return 'Kur: 1 $symbol = ₺$formattedRate';
  }

  /// Get approximate TRY text for preview
  Future<String> getApproximateTRYText(double amount, Currency from) async {
    if (from == Currency.TRY || amount <= 0) return '';

    final rate = await getRate(from);
    final amountInTRY = amount * rate;

    // Format with thousand separators
    final formatted = _formatCurrency(amountInTRY);
    return '≈ ₺$formatted';
  }

  /// Check if rates are fresh (within cache duration)
  bool _isCacheValid() {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  // ============================================================
  // PRIVATE - API IMPLEMENTATIONS
  // ============================================================

  Future<double> _fetchRate(Currency from) async {
    switch (from) {
      case Currency.USD:
      case Currency.EUR:
      case Currency.GBP:
        return await _fetchFrankfurterRate(from);
      case Currency.BTC:
      case Currency.ETH:
        return await _fetchCoinGeckoRate(from);
      case Currency.GOLD:
        return _mockRates[Currency.GOLD]!; // Mock for now
      case Currency.TRY:
        return 1.0;
    }
  }

  /// Frankfurter API - Free, no API key, reliable
  /// https://www.frankfurter.app/docs/
  ///
  /// Note: Frankfurter uses EUR as base, so we need to calculate TRY via EUR
  Future<double> _fetchFrankfurterRate(Currency from) async {
    try {
      // Frankfurter API - get rates to TRY
      final fromCode = from.name; // USD, EUR, GBP
      final url = 'https://api.frankfurter.app/latest?from=$fromCode&to=TRY';

      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        final tryRate = rates['TRY'];

        if (tryRate != null) {
          return (tryRate as num).toDouble();
        }
      }

      throw Exception('Invalid Frankfurter response');
    } catch (e) {
      debugPrint('[CURRENCY] Frankfurter API error: $e');
      rethrow;
    }
  }

  /// CoinGecko API - Free, no API key, rate limited
  /// https://www.coingecko.com/en/api/documentation
  Future<double> _fetchCoinGeckoRate(Currency from) async {
    try {
      final coinId = from == Currency.BTC ? 'bitcoin' : 'ethereum';
      final url =
          'https://api.coingecko.com/api/v3/simple/price?ids=$coinId&vs_currencies=try';

      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coinData = data[coinId] as Map<String, dynamic>?;

        if (coinData != null && coinData['try'] != null) {
          return (coinData['try'] as num).toDouble();
        }
      }

      throw Exception('Invalid CoinGecko response');
    } catch (e) {
      debugPrint('[CURRENCY] CoinGecko API error: $e');
      rethrow;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _getCurrencySymbol(Currency currency) {
    switch (currency) {
      case Currency.TRY:
        return '₺';
      case Currency.USD:
        return '\$';
      case Currency.EUR:
        return '€';
      case Currency.GBP:
        return '£';
      case Currency.GOLD:
        return 'gr';
      case Currency.BTC:
        return '₿';
      case Currency.ETH:
        return 'Ξ';
    }
  }

  String _formatCurrency(double amount) {
    // Simple TR formatting: 1.234,56
    final parts = amount.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    // Add thousand separators
    final buffer = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(integerPart[i]);
    }

    return '${buffer.toString()},$decimalPart';
  }

  /// Map string currency code to Currency enum
  static Currency? fromString(String code) {
    switch (code.toUpperCase()) {
      case 'TRY':
        return Currency.TRY;
      case 'USD':
        return Currency.USD;
      case 'EUR':
        return Currency.EUR;
      case 'GBP':
        return Currency.GBP;
      case 'GOLD/GR':
      case 'GOLD':
        return Currency.GOLD;
      case 'BTC':
        return Currency.BTC;
      case 'ETH':
        return Currency.ETH;
      default:
        return null;
    }
  }
}
