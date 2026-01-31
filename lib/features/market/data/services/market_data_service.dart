import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../domain/entities/candle.dart';
import '../../domain/models/market_asset.dart';
import '../static/market_catalog.dart';
import 'market_cache_service.dart';
import 'finnhub_service.dart';
import 'tradingview_turkey_service.dart';

/// HEIMDALL V4 Data Service - HYBRID ENGINE
///
/// Routing Strategy:
/// - BIST (Turkish Stocks) → TradingView Turkey Scanner
/// - Everything Else → Finnhub API
///
/// Both run in parallel for maximum speed
class MarketDataService {
  static final MarketDataService _instance = MarketDataService._internal();
  factory MarketDataService() => _instance;
  MarketDataService._internal();

  // Services
  final MarketCacheService _cacheService = MarketCacheService();
  final FinnhubService _finnhub = FinnhubService();
  final TradingViewTurkeyService _tvTurkey = TradingViewTurkeyService();
  bool _cacheInitialized = false;

  // In-memory quote cache
  final Map<String, MarketQuote> _quoteCache = {};
  DateTime? _lastBoardFetch;

  // Fallback APIs
  static const String _coinGeckoBase = 'https://api.coingecko.com/api/v3';
  static const String _corsProxyBase = 'https://corsproxy.io/?';
  static const String _chromeUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  // ============================================
  // SYMBOL MAPPING: Internal ID -> Finnhub Symbol
  // ============================================

  static const Map<String, String> _cryptoToFinnhub = {
    'bitcoin': 'BINANCE:BTCUSDT',
    'ethereum': 'BINANCE:ETHUSDT',
    'binancecoin': 'BINANCE:BNBUSDT',
    'solana': 'BINANCE:SOLUSDT',
    'ripple': 'BINANCE:XRPUSDT',
    'cardano': 'BINANCE:ADAUSDT',
    'avalanche-2': 'BINANCE:AVAXUSDT',
    'dogecoin': 'BINANCE:DOGEUSDT',
    'polkadot': 'BINANCE:DOTUSDT',
    'chainlink': 'BINANCE:LINKUSDT',
  };

  static const Map<String, String> _forexToFinnhub = {
    'TRY=X': 'OANDA:USD_TRY',
    'EURTRY=X': 'OANDA:EUR_TRY',
    'GBPTRY=X': 'OANDA:GBP_TRY',
    'EURUSD=X': 'OANDA:EUR_USD',
  };

  static const Map<String, String> _commodityToFinnhub = {
    'GC=F': 'OANDA:XAU_USD',
    'SI=F': 'OANDA:XAG_USD',
    'CL=F': 'OANDA:WTICO_USD',
  };

  String? _mapToFinnhub(MarketAsset asset) {
    if (_cryptoToFinnhub.containsKey(asset.id)) {
      return _cryptoToFinnhub[asset.id];
    }
    if (_forexToFinnhub.containsKey(asset.id)) {
      return _forexToFinnhub[asset.id];
    }
    if (_commodityToFinnhub.containsKey(asset.id)) {
      return _commodityToFinnhub[asset.id];
    }
    return asset.id;
  }

  /// Check if asset is BIST (routes to TradingView Turkey)
  bool _isBistAsset(MarketAsset asset) {
    return asset.category == AssetCategory.bist ||
        asset.id.endsWith('.IS') ||
        asset.source == MarketSource.tradingView;
  }

  /// Initialize cache
  Future<void> initCache() async {
    if (_cacheInitialized) return;
    await _cacheService.init();
    _cacheInitialized = true;
  }

  // ============================================
  // STREAM API: Cache-First Data Loading
  // ============================================

  Stream<MarketBoardState> getMarketDataStream(
      {bool forceRefresh = false}) async* {
    final allAssets = MarketCatalog.all;

    // STEP 1: Emit cached data immediately
    if (!forceRefresh && _cacheInitialized) {
      final cachedQuotes = _buildQuotesFromCache(allAssets);
      if (cachedQuotes.isNotEmpty) {
        yield MarketBoardState(
          quotes: cachedQuotes,
          isLoading: true,
          isCached: true,
        );
        print('[HEIMDALL V4] 📋 Emitted ${cachedQuotes.length} cached quotes');
      }
    }

    // STEP 2: Fetch fresh data via hybrid router
    try {
      final freshQuotes = await _fetchHybrid(allAssets);
      _updateCaches(freshQuotes);

      yield MarketBoardState(
        quotes: freshQuotes,
        isLoading: false,
        isCached: false,
      );
      print('[HEIMDALL V4] ✅ Emitted ${freshQuotes.length} fresh quotes');
    } catch (e) {
      print('[HEIMDALL V4] ❌ Fetch failed: $e');
      final cachedQuotes = _buildQuotesFromCache(allAssets);
      yield MarketBoardState(
        quotes: cachedQuotes,
        isLoading: false,
        isCached: true,
        hasError: true,
        errorMessage: e.toString(),
      );
    }
  }

  List<MarketQuote> _buildQuotesFromCache(List<MarketAsset> assets) {
    final quotes = <MarketQuote>[];
    final cached = _cacheService.getAll();

    for (final asset in assets) {
      final cachedQuote = cached[asset.id];
      if (cachedQuote != null) {
        quotes.add(MarketQuote.success(
          asset: asset,
          price: cachedQuote.price,
          changePercent24h: cachedQuote.changePercent,
        ));
      }
    }
    return quotes;
  }

  void _updateCaches(List<MarketQuote> quotes) {
    final cacheUpdates = <String, CachedQuote>{};

    for (final quote in quotes) {
      if (quote.isSuccess) {
        _quoteCache[quote.asset.id] = quote;
        cacheUpdates[quote.asset.id] = CachedQuote(
          price: quote.price!,
          changePercent: quote.changePercent24h,
          lastUpdated: DateTime.now(),
        );
      }
    }

    _cacheService.saveAll(cacheUpdates);
    _lastBoardFetch = DateTime.now();
  }

  // ============================================
  // HYBRID ROUTER (THE CORE)
  // ============================================

  /// Route assets to appropriate service and fetch in parallel
  Future<List<MarketQuote>> _fetchHybrid(List<MarketAsset> assets) async {
    // Split assets by destination
    final bistAssets = <MarketAsset>[];
    final globalAssets = <MarketAsset>[];

    for (final asset in assets) {
      if (_isBistAsset(asset)) {
        bistAssets.add(asset);
      } else {
        globalAssets.add(asset);
      }
    }

    print(
        '[HEIMDALL V4] 🚀 Routing: ${globalAssets.length} global (Finnhub) + ${bistAssets.length} BIST (TradingView Turkey)');

    // Fetch in parallel - if one fails, the other continues
    final results = await Future.wait([
      _fetchGlobalViaFinnhub(globalAssets).catchError((e) {
        print('[HEIMDALL V4] ⚠️ Finnhub failed: $e');
        return <MarketQuote>[];
      }),
      _fetchBistViaTvTurkey(bistAssets).catchError((e) {
        print('[HEIMDALL V4] ⚠️ TV Turkey failed: $e');
        return <MarketQuote>[];
      }),
    ]);

    final allQuotes = <MarketQuote>[];
    allQuotes.addAll(results[0]);
    allQuotes.addAll(results[1]);

    return allQuotes;
  }

  // ============================================
  // FINNHUB: Global Assets (Crypto, Forex, Commodities)
  // ============================================

  Future<List<MarketQuote>> _fetchGlobalViaFinnhub(
      List<MarketAsset> assets) async {
    if (assets.isEmpty) return [];

    final quotes = <MarketQuote>[];

    print(
        '[HEIMDALL V4] 📊 Finnhub: Fetching ${assets.length} global assets...');

    for (final asset in assets) {
      final finnhubSymbol = _mapToFinnhub(asset);

      if (finnhubSymbol == null) {
        quotes.add(MarketQuote.error(asset: asset, message: 'Desteklenmiyor'));
        continue;
      }

      final result = await _finnhub.fetchQuote(finnhubSymbol);

      if (result != null) {
        quotes.add(MarketQuote.success(
          asset: asset,
          price: result.price,
          changePercent24h: result.changePercent,
        ));
      } else {
        // Finnhub failed - try CoinGecko for crypto
        if (asset.category == AssetCategory.crypto) {
          final fallback = await _fetchCoinGeckoFallback(asset);
          if (fallback != null) {
            quotes.add(fallback);
          } else {
            quotes.add(
                MarketQuote.error(asset: asset, message: 'Veri alınamadı'));
          }
        } else {
          quotes
              .add(MarketQuote.error(asset: asset, message: 'Finnhub hatası'));
        }
      }
    }

    final success = quotes.where((q) => q.isSuccess).length;
    print('[HEIMDALL V4] ✅ Finnhub: $success/${quotes.length} başarılı');

    return quotes;
  }

  Future<MarketQuote?> _fetchCoinGeckoFallback(MarketAsset asset) async {
    try {
      final url = Uri.parse(
          '$_coinGeckoBase/simple/price?ids=${asset.id}&vs_currencies=usd&include_24hr_change=true');

      final response = await http.get(url, headers: {
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (!data.containsKey(asset.id)) return null;

      final coinData = data[asset.id] as Map<String, dynamic>;
      final price = (coinData['usd'] as num).toDouble();
      final change = (coinData['usd_24h_change'] as num?)?.toDouble();

      print('[CoinGecko] ✅ ${asset.symbol}: \$${price.toStringAsFixed(2)}');

      return MarketQuote.success(
        asset: asset,
        price: price,
        changePercent24h: change,
      );
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // TRADINGVIEW TURKEY: BIST Stocks
  // ============================================

  Future<List<MarketQuote>> _fetchBistViaTvTurkey(
      List<MarketAsset> bistAssets) async {
    if (bistAssets.isEmpty) return [];

    final quotes = <MarketQuote>[];

    // Extract symbols: THYAO.IS -> THYAO
    final symbols = bistAssets.map((a) {
      final symbol = a.symbol;
      // Remove .IS suffix if present in ID
      return symbol;
    }).toList();

    print(
        '[HEIMDALL V4] 🇹🇷 TV Turkey: Fetching ${bistAssets.length} BIST stocks...');

    final tvResults = await _tvTurkey.fetchBistQuotes(symbols);

    for (final asset in bistAssets) {
      final tvQuote = tvResults[asset.symbol];
      if (tvQuote != null) {
        quotes.add(MarketQuote.success(
          asset: asset,
          price: tvQuote.price,
          changePercent24h: tvQuote.changePercent,
        ));
      } else {
        quotes.add(MarketQuote.error(asset: asset, message: 'BIST verisi yok'));
      }
    }

    final success = quotes.where((q) => q.isSuccess).length;
    print('[HEIMDALL V4] ✅ TV Turkey: $success/${quotes.length} başarılı');

    return quotes;
  }

  // ============================================
  // LEGACY API
  // ============================================

  Future<List<MarketQuote>> fetchMarketBoard(
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _lastBoardFetch != null) {
      final age = DateTime.now().difference(_lastBoardFetch!);
      if (age.inMinutes < 5 && _quoteCache.isNotEmpty) {
        return _quoteCache.values.toList();
      }
    }
    final quotes = await _fetchHybrid(MarketCatalog.all);
    _updateCaches(quotes);
    return quotes;
  }

  MarketQuote? getCachedQuote(String assetId) => _quoteCache[assetId];

  // ============================================
  // CANDLE FETCHING (Argus)
  // ============================================

  Future<List<Candle>> fetchCandlesForAsset({
    required MarketAsset asset,
    int days = 30,
  }) async {
    if (asset.category == AssetCategory.crypto) {
      return await _fetchCoinGeckoCandles(asset.id, days);
    } else {
      return await _fetchYahooCandles(asset.id, days);
    }
  }

  Future<List<Candle>> _fetchCoinGeckoCandles(String coinId, int days) async {
    final url = Uri.parse(
        '$_coinGeckoBase/coins/$coinId/market_chart?vs_currency=usd&days=$days&interval=daily');

    final response = await http.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('CoinGecko error: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final prices = data['prices'] as List<dynamic>;

    final candles = <Candle>[];
    for (final priceData in prices) {
      candles.add(Candle.fromCoinGecko(priceData as List<dynamic>));
    }

    candles.sort((a, b) => b.date.compareTo(a.date));
    return candles;
  }

  Future<List<Candle>> _fetchYahooCandles(String yahooId, int days) async {
    final now = DateTime.now();
    final period2 = now.millisecondsSinceEpoch ~/ 1000;
    final period1 =
        now.subtract(Duration(days: days + 5)).millisecondsSinceEpoch ~/ 1000;

    String urlString =
        'https://query1.finance.yahoo.com/v8/finance/chart/$yahooId?period1=$period1&period2=$period2&interval=1d';

    if (kIsWeb) {
      urlString = '$_corsProxyBase${Uri.encodeComponent(urlString)}';
    }

    final response = await http.get(Uri.parse(urlString), headers: {
      'User-Agent': _chromeUserAgent,
    }).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Yahoo error: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final chart = data['chart'] as Map<String, dynamic>;
    final result = (chart['result'] as List<dynamic>?)?.firstOrNull;

    if (result == null) throw Exception('No data');

    final timestamps = result['timestamp'] as List<dynamic>?;
    final indicators = result['indicators'] as Map<String, dynamic>;
    final quote =
        (indicators['quote'] as List<dynamic>).first as Map<String, dynamic>;
    final opens = quote['open'] as List<dynamic>;
    final highs = quote['high'] as List<dynamic>;
    final lows = quote['low'] as List<dynamic>;
    final closes = quote['close'] as List<dynamic>;
    final volumes = quote['volume'] as List<dynamic>?;

    if (timestamps == null) throw Exception('No timestamps');

    final candles = <Candle>[];
    for (int i = 0; i < timestamps.length; i++) {
      final close = closes[i];
      if (close == null) continue;
      candles.add(Candle.fromYahoo(
        timestamp: timestamps[i] as int,
        open: (opens[i] as num?)?.toDouble(),
        high: (highs[i] as num?)?.toDouble(),
        low: (lows[i] as num?)?.toDouble(),
        close: (close as num).toDouble(),
        volume: (volumes?[i] as num?)?.toDouble(),
      ));
    }

    candles.sort((a, b) => b.date.compareTo(a.date));
    return candles;
  }

  // ============================================
  // TIME MACHINE
  // ============================================

  Future<double?> fetchPriceAtDate({
    required String apiId,
    required MarketSource source,
    required DateTime date,
  }) async {
    try {
      if (source == MarketSource.coinGecko) {
        final formattedDate =
            '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
        final url = Uri.parse(
            '$_coinGeckoBase/coins/$apiId/history?date=$formattedDate');
        final response =
            await http.get(url).timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) return null;
        final data = json.decode(response.body) as Map<String, dynamic>;
        final marketData = data['market_data'] as Map<String, dynamic>?;
        return (marketData?['current_price']?['usd'] as num?)?.toDouble();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void clearCache() {
    _quoteCache.clear();
    _lastBoardFetch = null;
    _cacheService.clear();
  }
}

/// Market board state
class MarketBoardState {
  final List<MarketQuote> quotes;
  final bool isLoading;
  final bool isCached;
  final bool hasError;
  final String? errorMessage;

  const MarketBoardState({
    required this.quotes,
    this.isLoading = false,
    this.isCached = false,
    this.hasError = false,
    this.errorMessage,
  });
}
