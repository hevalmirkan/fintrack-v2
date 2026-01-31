/// =====================================================
/// MOBILE MARKET SERVICE — Phase 8.5
/// =====================================================
/// Primary market data service for mobile (v1.0).
/// Uses: Binance (crypto) + Frankfurter (fiat) + Manual (stocks)
/// No API keys required.
/// =====================================================

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/market_asset.dart';
import '../static/market_catalog.dart';
import 'binance_service.dart';
import 'frankfurter_service.dart';
import 'market_cache_service.dart';

/// Mobile-first market service for v1.0
class MobileMarketService {
  static final MobileMarketService _instance = MobileMarketService._internal();
  factory MobileMarketService() => _instance;
  MobileMarketService._internal();

  final BinanceService _binance = BinanceService();
  final FrankfurterService _frankfurter = FrankfurterService();
  final MarketCacheService _cache = MarketCacheService();

  bool _initialized = false;
  DateTime? _lastFetch;

  // Manual price overrides (for stocks)
  final Map<String, double> _manualPrices = {};
  static const String _manualPricesKey = 'manual_stock_prices_v1';

  /// Initialize service
  Future<void> init() async {
    if (_initialized) return;
    await _cache.init();
    await _loadManualPrices();
    _initialized = true;
  }

  /// Fetch all market data (primary method)
  Future<MobileMarketState> fetchAll({bool forceRefresh = false}) async {
    if (!forceRefresh && _lastFetch != null) {
      final age = DateTime.now().difference(_lastFetch!);
      if (age.inMinutes < 2) {
        return _buildStateFromCache();
      }
    }

    final quotes = <String, MobileQuote>{};
    double? usdTryRate;

    // 1. Fetch fiat rates from Frankfurter
    final fiatRates = await _frankfurter.fetchAllRates();
    for (final entry in fiatRates.entries) {
      final currency = entry.key;
      final rate = entry.value;

      // Store USD rate for crypto conversion
      if (currency == 'USD') {
        usdTryRate = rate.rateTry;
      }

      // Map to our forex assets
      final assetId = _fiatToAssetId(currency);
      if (assetId != null) {
        quotes[assetId] = MobileQuote(
          assetId: assetId,
          priceTry: rate.rateTry,
          source: QuoteSource.frankfurter,
        );
      }
    }

    // 2. Fetch crypto from Binance
    final cryptoQuotes = await _binance.fetchAllCrypto();
    for (final entry in cryptoQuotes.entries) {
      final cryptoId = entry.key;
      final quote = entry.value;

      // Convert USD to TRY
      final priceTry = quote.priceUsd * (usdTryRate ?? 35.5); // Fallback rate

      quotes[cryptoId] = MobileQuote(
        assetId: cryptoId,
        priceTry: priceTry,
        priceUsd: quote.priceUsd,
        changePercent24h: quote.changePercent24h,
        source: QuoteSource.binance,
      );
    }

    // 3. Add commodity prices (Gold/Silver via calculation)
    // XAU: Use PAXG from Binance if available, otherwise estimate
    final paxgQuote = await _binance.fetchPrice('PAXGUSDT');
    if (paxgQuote != null && usdTryRate != null) {
      // PAXG is per ounce, convert to gram
      final gramPrice = (paxgQuote.priceUsd * usdTryRate) / 31.1035;
      quotes['GC=F'] = MobileQuote(
        assetId: 'GC=F',
        priceTry: gramPrice,
        priceUsd: paxgQuote.priceUsd / 31.1035,
        source: QuoteSource.binance,
      );
    }

    // 4. Add manual stock prices
    for (final asset in MarketCatalog.bist) {
      final manualPrice = _manualPrices[asset.id];
      if (manualPrice != null) {
        quotes[asset.id] = MobileQuote(
          assetId: asset.id,
          priceTry: manualPrice,
          source: QuoteSource.manual,
        );
      } else {
        // No price available for this stock
        quotes[asset.id] = MobileQuote(
          assetId: asset.id,
          priceTry: 0,
          source: QuoteSource.unavailable,
          error: 'Manuel fiyat girin',
        );
      }
    }

    // Save to cache
    _saveToCache(quotes);
    _lastFetch = DateTime.now();

    return MobileMarketState(
      quotes: quotes,
      lastUpdated: _lastFetch!,
      usdTryRate: usdTryRate,
    );
  }

  /// Build state from cache
  MobileMarketState _buildStateFromCache() {
    final cached = _cache.getAll();
    final quotes = <String, MobileQuote>{};

    for (final entry in cached.entries) {
      quotes[entry.key] = MobileQuote(
        assetId: entry.key,
        priceTry: entry.value.price,
        changePercent24h: entry.value.changePercent,
        source: QuoteSource.cache,
      );
    }

    // Add manual prices
    for (final entry in _manualPrices.entries) {
      quotes[entry.key] = MobileQuote(
        assetId: entry.key,
        priceTry: entry.value,
        source: QuoteSource.manual,
      );
    }

    return MobileMarketState(
      quotes: quotes,
      lastUpdated: _lastFetch ?? DateTime.now(),
      isCached: true,
    );
  }

  void _saveToCache(Map<String, MobileQuote> quotes) {
    final cacheData = <String, CachedQuote>{};
    for (final entry in quotes.entries) {
      if (entry.value.source != QuoteSource.unavailable) {
        cacheData[entry.key] = CachedQuote(
          price: entry.value.priceTry,
          changePercent: entry.value.changePercent24h,
          lastUpdated: DateTime.now(),
        );
      }
    }
    _cache.saveAll(cacheData);
  }

  /// Set manual price for a stock
  Future<void> setManualPrice(String assetId, double price) async {
    _manualPrices[assetId] = price;
    await _saveManualPrices();
  }

  /// Get manual price for a stock
  double? getManualPrice(String assetId) => _manualPrices[assetId];

  /// Clear manual price
  Future<void> clearManualPrice(String assetId) async {
    _manualPrices.remove(assetId);
    await _saveManualPrices();
  }

  Future<void> _loadManualPrices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_manualPricesKey);
      if (json != null) {
        final map = Map<String, dynamic>.from(
          (json.split(',').map((e) {
            final parts = e.split(':');
            return MapEntry(parts[0], double.parse(parts[1]));
          })).fold<Map<String, double>>({}, (map, entry) {
            map[entry.key] = entry.value;
            return map;
          }),
        );
        _manualPrices.addAll(map.cast<String, double>());
      }
    } catch (_) {}
  }

  Future<void> _saveManualPrices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json =
          _manualPrices.entries.map((e) => '${e.key}:${e.value}').join(',');
      await prefs.setString(_manualPricesKey, json);
    } catch (_) {}
  }

  String? _fiatToAssetId(String currency) {
    switch (currency) {
      case 'USD':
        return 'TRY=X';
      case 'EUR':
        return 'EURTRY=X';
      case 'GBP':
        return 'GBPTRY=X';
      default:
        return null;
    }
  }

  /// Get single quote by asset ID
  MobileQuote? getQuote(String assetId) {
    final cached = _cache.get(assetId);
    if (cached != null) {
      return MobileQuote(
        assetId: assetId,
        priceTry: cached.price,
        changePercent24h: cached.changePercent,
        source: QuoteSource.cache,
      );
    }
    return null;
  }
}

/// Quote source indicator
enum QuoteSource {
  binance,
  frankfurter,
  manual,
  cache,
  unavailable,
}

/// Individual quote
class MobileQuote {
  final String assetId;
  final double priceTry;
  final double? priceUsd;
  final double? changePercent24h;
  final QuoteSource source;
  final String? error;

  MobileQuote({
    required this.assetId,
    required this.priceTry,
    this.priceUsd,
    this.changePercent24h,
    required this.source,
    this.error,
  });

  bool get isAvailable => source != QuoteSource.unavailable;
  bool get isManual => source == QuoteSource.manual;
}

/// Market state
class MobileMarketState {
  final Map<String, MobileQuote> quotes;
  final DateTime lastUpdated;
  final bool isCached;
  final double? usdTryRate;

  MobileMarketState({
    required this.quotes,
    required this.lastUpdated,
    this.isCached = false,
    this.usdTryRate,
  });

  MobileQuote? operator [](String assetId) => quotes[assetId];
}
