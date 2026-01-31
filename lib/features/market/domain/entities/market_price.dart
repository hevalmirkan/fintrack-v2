import 'package:equatable/equatable.dart';

/// Represents a market price data point for a financial asset
class MarketPrice extends Equatable {
  final String symbol; // Asset symbol (e.g., "BTC", "ETH", "XAU")
  final int priceMinor; // Price in minor units (cents)
  final DateTime timestamp; // When this price was fetched
  final String source; // Data source identifier (e.g., "coinapi", "manual")

  const MarketPrice({
    required this.symbol,
    required this.priceMinor,
    required this.timestamp,
    required this.source,
  });

  MarketPrice.empty()
      : symbol = '',
        priceMinor = 0,
        timestamp = DateTime.fromMillisecondsSinceEpoch(0),
        source = '';

  @override
  List<Object?> get props => [symbol, priceMinor, timestamp, source];

  // Helper to check if price is stale (older than 1 hour)
  bool get isStale {
    final age = DateTime.now().difference(timestamp);
    return age.inHours > 1;
  }
}
