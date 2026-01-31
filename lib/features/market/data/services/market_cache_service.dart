import 'package:hive_flutter/hive_flutter.dart';

/// Market Cache Service - Hive-based local storage for market data
/// Provides instant access to cached quotes for Cache-First UX
class MarketCacheService {
  static const String _boxName = 'market_cache_box';
  static const int _freshnessDurationMinutes = 5;

  Box<Map>? _box;

  /// Initialize the cache (call during app startup)
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<Map>(_boxName);
    print('[MarketCache] ✅ Initialized with ${_box?.length ?? 0} cached items');
  }

  /// Get all cached market data
  /// Returns Map<apiId, CachedQuote>
  Map<String, CachedQuote> getAll() {
    if (_box == null) return {};

    final result = <String, CachedQuote>{};
    for (final key in _box!.keys) {
      final data = _box!.get(key);
      if (data != null) {
        try {
          result[key as String] =
              CachedQuote.fromMap(Map<String, dynamic>.from(data));
        } catch (_) {
          // Skip malformed entries
        }
      }
    }
    return result;
  }

  /// Get a single cached quote
  CachedQuote? get(String apiId) {
    if (_box == null) return null;
    final data = _box!.get(apiId);
    if (data == null) return null;
    try {
      return CachedQuote.fromMap(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }

  /// Save a quote to cache
  Future<void> save(String apiId, double price, double? changePercent) async {
    if (_box == null) return;

    final quote = CachedQuote(
      price: price,
      changePercent: changePercent,
      lastUpdated: DateTime.now(),
    );

    await _box!.put(apiId, quote.toMap());
  }

  /// Save multiple quotes at once (batch operation)
  Future<void> saveAll(Map<String, CachedQuote> quotes) async {
    if (_box == null) return;

    final entries = quotes.map((key, value) => MapEntry(key, value.toMap()));
    await _box!.putAll(entries);
    print('[MarketCache] 💾 Saved ${quotes.length} quotes to cache');
  }

  /// Check if a cached quote is still fresh (< 5 minutes old)
  bool isFresh(String apiId) {
    final quote = get(apiId);
    if (quote == null) return false;

    final age = DateTime.now().difference(quote.lastUpdated);
    return age.inMinutes < _freshnessDurationMinutes;
  }

  /// Clear all cached data
  Future<void> clear() async {
    await _box?.clear();
    print('[MarketCache] 🗑️ Cache cleared');
  }

  /// Get cache stats
  CacheStats getStats() {
    if (_box == null) return CacheStats(total: 0, fresh: 0, stale: 0);

    int fresh = 0;
    int stale = 0;

    for (final key in _box!.keys) {
      if (isFresh(key as String)) {
        fresh++;
      } else {
        stale++;
      }
    }

    return CacheStats(total: _box!.length, fresh: fresh, stale: stale);
  }
}

/// Cached market quote data
class CachedQuote {
  final double price;
  final double? changePercent;
  final DateTime lastUpdated;

  CachedQuote({
    required this.price,
    this.changePercent,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() => {
        'price': price,
        'changePercent': changePercent,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory CachedQuote.fromMap(Map<String, dynamic> map) => CachedQuote(
        price: (map['price'] as num).toDouble(),
        changePercent: (map['changePercent'] as num?)?.toDouble(),
        lastUpdated: DateTime.parse(map['lastUpdated'] as String),
      );

  /// Age of this cached data
  Duration get age => DateTime.now().difference(lastUpdated);

  /// Is this data fresh (< 5 minutes old)?
  bool get isFresh => age.inMinutes < 5;
}

/// Cache statistics
class CacheStats {
  final int total;
  final int fresh;
  final int stale;

  CacheStats({required this.total, required this.fresh, required this.stale});

  @override
  String toString() =>
      'CacheStats(total: $total, fresh: $fresh, stale: $stale)';
}
