import '../../../market/domain/models/market_asset.dart';

/// Data transfer object for pre-filling AddAssetScreen from Market Board
class PrefilledAssetData {
  final String symbol;
  final String name;
  final String apiId;
  final double currentPrice;
  final MarketSource source;

  const PrefilledAssetData({
    required this.symbol,
    required this.name,
    required this.apiId,
    required this.currentPrice,
    required this.source,
  });

  /// Create from MarketQuote
  factory PrefilledAssetData.fromQuote(MarketQuote quote) {
    return PrefilledAssetData(
      symbol: quote.asset.symbol,
      name: quote.asset.name,
      apiId: quote.asset.id,
      currentPrice: quote.price ?? 0.0,
      source: quote.asset.source,
    );
  }
}
