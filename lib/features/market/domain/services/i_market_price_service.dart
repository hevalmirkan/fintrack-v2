import '../entities/market_price.dart';

/// Service for fetching market prices from external data sources
abstract class IMarketPriceService {
  /// Fetch the current price for a given symbol
  /// Returns price in minor units (cents)
  /// Throws exception if symbol not found or API unavailable
  Future<int> fetchCurrentPrice(String symbol);

  /// Get the latest cached price for a symbol
  /// Returns null if no cached price exists
  Future<MarketPrice?> getLatestPrice(String symbol);

  /// Refresh price and update cache
  /// Returns the updated MarketPrice
  Future<MarketPrice> refreshPrice(String symbol);
}
