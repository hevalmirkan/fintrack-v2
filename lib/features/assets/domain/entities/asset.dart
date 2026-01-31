import 'package:equatable/equatable.dart';

class Asset extends Equatable {
  final String id;
  final String symbol; // Trading symbol (BTC, ETH, XAU, etc.)
  final String name; // Full name
  final int averagePrice; // Average cost basis in minor units
  final int currentPrice; // Current/manual price (for backward compatibility)
  final int quantityMinor; // Quantity in minor units

  // Phase 8: Market data fields
  final int?
      lastKnownPrice; // Last fetched market price (nullable for existing assets)
  final DateTime? lastPriceUpdate; // When market price was last updated

  // Phase 16B: API ID for Heimdall/Argus integration
  final String?
      apiId; // CoinGecko ID (e.g., 'bitcoin') or Yahoo ID (e.g., 'THYAO.IS')

  const Asset({
    required this.id,
    required this.symbol,
    required this.name,
    required this.averagePrice,
    required this.currentPrice,
    required this.quantityMinor,
    this.lastKnownPrice,
    this.lastPriceUpdate,
    this.apiId,
  });

  // Helper to get the best available price
  int get displayPrice => lastKnownPrice ?? currentPrice;

  // Check if market data is available
  bool get hasMarketData => lastKnownPrice != null;

  // Check if live tracking is enabled (has apiId)
  bool get hasLiveTracking => apiId != null && apiId!.isNotEmpty;

  // Copy with method for updates
  Asset copyWith({
    String? id,
    String? symbol,
    String? name,
    int? averagePrice,
    int? currentPrice,
    int? quantityMinor,
    int? lastKnownPrice,
    DateTime? lastPriceUpdate,
    String? apiId,
  }) {
    return Asset(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      averagePrice: averagePrice ?? this.averagePrice,
      currentPrice: currentPrice ?? this.currentPrice,
      quantityMinor: quantityMinor ?? this.quantityMinor,
      lastKnownPrice: lastKnownPrice ?? this.lastKnownPrice,
      lastPriceUpdate: lastPriceUpdate ?? this.lastPriceUpdate,
      apiId: apiId ?? this.apiId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        symbol,
        name,
        averagePrice,
        currentPrice,
        quantityMinor,
        lastKnownPrice,
        lastPriceUpdate,
        apiId,
      ];
}
