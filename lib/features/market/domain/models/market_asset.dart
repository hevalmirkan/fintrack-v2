import 'package:equatable/equatable.dart';

/// Data source for market data
enum MarketSource {
  coinGecko,
  finnhub,
  tradingView,
  @Deprecated('Use finnhub instead')
  yahoo,
}

extension MarketSourceExtension on MarketSource {
  String get label {
    switch (this) {
      case MarketSource.coinGecko:
        return 'CoinGecko';
      case MarketSource.finnhub:
        return 'Finnhub';
      case MarketSource.tradingView:
        return 'TradingView';
      case MarketSource.yahoo:
        return 'Yahoo';
    }
  }

  String get color {
    switch (this) {
      case MarketSource.coinGecko:
        return '#00D09C'; // Green
      case MarketSource.finnhub:
        return '#D97706'; // Finnhub Orange
      case MarketSource.tradingView:
        return '#2962FF'; // TradingView Blue
      case MarketSource.yahoo:
        return '#7B61FF'; // Purple
    }
  }
}

/// Asset category for grouping
enum AssetCategory {
  crypto,
  bist, // Borsa Istanbul
  forex,
  commodity,
}

extension AssetCategoryExtension on AssetCategory {
  String get label {
    switch (this) {
      case AssetCategory.crypto:
        return 'Kripto';
      case AssetCategory.bist:
        return 'Borsa';
      case AssetCategory.forex:
        return 'Döviz';
      case AssetCategory.commodity:
        return 'Emtia';
    }
  }

  String get emoji {
    switch (this) {
      case AssetCategory.crypto:
        return '🪙';
      case AssetCategory.bist:
        return '📈';
      case AssetCategory.forex:
        return '💱';
      case AssetCategory.commodity:
        return '🥇';
    }
  }
}

/// Canonical market asset with verified API ID
class MarketAsset extends Equatable {
  /// API-specific ID (e.g., 'bitcoin' for CoinGecko, 'THYAO.IS' for Yahoo)
  final String id;

  /// Display ticker symbol (e.g., 'BTC', 'THYAO')
  final String symbol;

  /// Full name of the asset
  final String name;

  /// Data source to use for fetching
  final MarketSource source;

  /// Category for grouping/filtering
  final AssetCategory category;

  const MarketAsset({
    required this.id,
    required this.symbol,
    required this.name,
    required this.source,
    required this.category,
  });

  @override
  List<Object?> get props => [id, symbol, name, source, category];
}

/// Result of fetching market data for a single asset
class MarketQuote {
  final MarketAsset asset;
  final double? price;
  final double? change24h;
  final double? changePercent24h;
  final bool isSuccess;
  final String? errorMessage;
  final DateTime fetchedAt;

  MarketQuote({
    required this.asset,
    this.price,
    this.change24h,
    this.changePercent24h,
    required this.isSuccess,
    this.errorMessage,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  /// Create a success quote
  factory MarketQuote.success({
    required MarketAsset asset,
    required double price,
    double? change24h,
    double? changePercent24h,
  }) {
    return MarketQuote(
      asset: asset,
      price: price,
      change24h: change24h,
      changePercent24h: changePercent24h,
      isSuccess: true,
    );
  }

  /// Create an error quote
  factory MarketQuote.error({
    required MarketAsset asset,
    required String message,
  }) {
    return MarketQuote(
      asset: asset,
      isSuccess: false,
      errorMessage: message,
    );
  }
}
