import '../entities/market_price.dart';

/// Repository for managing market price data (both cached and live)
abstract class IMarketPriceRepository {
  /// Get cached price for a symbol from Firestore
  /// Returns null if no cached price exists
  Future<MarketPrice?> getCachedPrice(String symbol);

  /// Fetch price from API and cache it in Firestore
  /// Falls back to cached price if API call fails
  Future<MarketPrice> fetchAndCachePrice(String symbol);

  /// Watch price changes for a symbol (Firestore stream)
  Stream<MarketPrice?> watchPrice(String symbol);

  /// Save a manually entered price
  Future<void> saveManualPrice(String symbol, int priceMinor);
}
