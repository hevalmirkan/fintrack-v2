import '../../domain/models/market_asset.dart';

/// Canonical Market Catalog - The Single Source of Truth for Asset IDs
/// All assets here have VERIFIED API IDs that work with their respective sources.
class MarketCatalog {
  MarketCatalog._();

  // ============================================
  // CRYPTO (CoinGecko IDs)
  // ============================================
  static const List<MarketAsset> crypto = [
    MarketAsset(
      id: 'bitcoin',
      symbol: 'BTC',
      name: 'Bitcoin',
      source: MarketSource.coinGecko,
      category: AssetCategory.crypto,
    ),
    MarketAsset(
      id: 'ethereum',
      symbol: 'ETH',
      name: 'Ethereum',
      source: MarketSource.coinGecko,
      category: AssetCategory.crypto,
    ),
    MarketAsset(
      id: 'binancecoin',
      symbol: 'BNB',
      name: 'BNB',
      source: MarketSource.coinGecko,
      category: AssetCategory.crypto,
    ),
    MarketAsset(
      id: 'solana',
      symbol: 'SOL',
      name: 'Solana',
      source: MarketSource.coinGecko,
      category: AssetCategory.crypto,
    ),
    MarketAsset(
      id: 'ripple',
      symbol: 'XRP',
      name: 'Ripple',
      source: MarketSource.coinGecko,
      category: AssetCategory.crypto,
    ),
    MarketAsset(
      id: 'cardano',
      symbol: 'ADA',
      name: 'Cardano',
      source: MarketSource.coinGecko,
      category: AssetCategory.crypto,
    ),
    MarketAsset(
      id: 'avalanche-2',
      symbol: 'AVAX',
      name: 'Avalanche',
      source: MarketSource.coinGecko,
      category: AssetCategory.crypto,
    ),
    MarketAsset(
      id: 'dogecoin',
      symbol: 'DOGE',
      name: 'Dogecoin',
      source: MarketSource.coinGecko,
      category: AssetCategory.crypto,
    ),
    MarketAsset(
      id: 'polkadot',
      symbol: 'DOT',
      name: 'Polkadot',
      source: MarketSource.coinGecko,
      category: AssetCategory.crypto,
    ),
    MarketAsset(
      id: 'chainlink',
      symbol: 'LINK',
      name: 'Chainlink',
      source: MarketSource.coinGecko,
      category: AssetCategory.crypto,
    ),
  ];

  // ============================================
  // FOREX (Yahoo Finance IDs)
  // ============================================
  static const List<MarketAsset> forex = [
    MarketAsset(
      id: 'TRY=X',
      symbol: 'USD/TRY',
      name: 'Dolar/TL',
      source: MarketSource.tradingView,
      category: AssetCategory.forex,
    ),
    MarketAsset(
      id: 'EURTRY=X',
      symbol: 'EUR/TRY',
      name: 'Euro/TL',
      source: MarketSource.tradingView,
      category: AssetCategory.forex,
    ),
    MarketAsset(
      id: 'GBPTRY=X',
      symbol: 'GBP/TRY',
      name: 'Sterlin/TL',
      source: MarketSource.tradingView,
      category: AssetCategory.forex,
    ),
    MarketAsset(
      id: 'EURUSD=X',
      symbol: 'EUR/USD',
      name: 'Euro/Dolar',
      source: MarketSource.tradingView,
      category: AssetCategory.forex,
    ),
  ];

  // ============================================
  // COMMODITIES (Yahoo Finance IDs)
  // ============================================
  static const List<MarketAsset> commodities = [
    MarketAsset(
      id: 'GC=F',
      symbol: 'XAU',
      name: 'Altın (Ons)',
      source: MarketSource.tradingView,
      category: AssetCategory.commodity,
    ),
    MarketAsset(
      id: 'SI=F',
      symbol: 'XAG',
      name: 'Gümüş (Ons)',
      source: MarketSource.tradingView,
      category: AssetCategory.commodity,
    ),
    MarketAsset(
      id: 'CL=F',
      symbol: 'OIL',
      name: 'Petrol (WTI)',
      source: MarketSource.tradingView,
      category: AssetCategory.commodity,
    ),
  ];

  // ============================================
  // BIST (Yahoo Finance IDs - Borsa Istanbul)
  // ============================================
  static const List<MarketAsset> bist = [
    MarketAsset(
      id: 'THYAO.IS',
      symbol: 'THYAO',
      name: 'Türk Hava Yolları',
      source: MarketSource.tradingView,
      category: AssetCategory.bist,
    ),
    MarketAsset(
      id: 'GARAN.IS',
      symbol: 'GARAN',
      name: 'Garanti Bankası',
      source: MarketSource.tradingView,
      category: AssetCategory.bist,
    ),
    MarketAsset(
      id: 'AKBNK.IS',
      symbol: 'AKBNK',
      name: 'Akbank',
      source: MarketSource.tradingView,
      category: AssetCategory.bist,
    ),
    MarketAsset(
      id: 'EREGL.IS',
      symbol: 'EREGL',
      name: 'Ereğli Demir Çelik',
      source: MarketSource.tradingView,
      category: AssetCategory.bist,
    ),
    MarketAsset(
      id: 'KCHOL.IS',
      symbol: 'KCHOL',
      name: 'Koç Holding',
      source: MarketSource.tradingView,
      category: AssetCategory.bist,
    ),
    MarketAsset(
      id: 'SISE.IS',
      symbol: 'SISE',
      name: 'Şişecam',
      source: MarketSource.tradingView,
      category: AssetCategory.bist,
    ),
    MarketAsset(
      id: 'ASELS.IS',
      symbol: 'ASELS',
      name: 'Aselsan',
      source: MarketSource.tradingView,
      category: AssetCategory.bist,
    ),
    MarketAsset(
      id: 'SAHOL.IS',
      symbol: 'SAHOL',
      name: 'Sabancı Holding',
      source: MarketSource.finnhub,
      category: AssetCategory.bist,
    ),
  ];

  /// Get all assets combined
  static List<MarketAsset> get all => [
        ...crypto,
        ...forex,
        ...commodities,
        ...bist,
      ];

  /// Get assets by category
  static List<MarketAsset> byCategory(AssetCategory category) {
    switch (category) {
      case AssetCategory.crypto:
        return crypto;
      case AssetCategory.forex:
        return forex;
      case AssetCategory.commodity:
        return commodities;
      case AssetCategory.bist:
        return bist;
    }
  }

  /// Find asset by symbol (case-insensitive)
  static MarketAsset? findBySymbol(String symbol) {
    final upper = symbol.toUpperCase();
    return all.where((a) => a.symbol.toUpperCase() == upper).firstOrNull;
  }

  /// Find asset by ID
  static MarketAsset? findById(String id) {
    return all.where((a) => a.id == id).firstOrNull;
  }
}
