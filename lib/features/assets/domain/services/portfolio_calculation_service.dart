import 'package:equatable/equatable.dart';

import '../entities/asset.dart';

/// Represents an asset with calculated profit/loss information
class AssetWithProfitLoss extends Equatable {
  final Asset asset;
  final int totalValue; // Current market value (quantity × price)
  final int costBasis; // Total cost (quantity × averageCost)
  final int profitLoss; // P/L in minor units
  final double profitLossPercentage; // P/L as percentage

  const AssetWithProfitLoss({
    required this.asset,
    required this.totalValue,
    required this.costBasis,
    required this.profitLoss,
    required this.profitLossPercentage,
  });

  bool get isProfit => profitLoss > 0;
  bool get isLoss => profitLoss < 0;
  bool get isBreakEven => profitLoss == 0;

  @override
  List<Object?> get props =>
      [asset, totalValue, costBasis, profitLoss, profitLossPercentage];
}

/// Service for calculating portfolio metrics and profit/loss
class PortfolioCalculationService {
  /// Calculate profit/loss for a single asset
  AssetWithProfitLoss calculateAssetProfitLoss(Asset asset) {
    // Use the best available price (market data or manual)
    final currentPrice = asset.displayPrice;

    // Total Value = (quantity × currentPrice) / 100
    final totalValue = (asset.quantityMinor * currentPrice) ~/ 100;

    // Cost Basis = (quantity × averageCost) / 100
    final costBasis = (asset.quantityMinor * asset.averagePrice) ~/ 100;

    // Profit/Loss
    final profitLoss = totalValue - costBasis;

    // P/L Percentage = ((currentPrice - averageCost) / averageCost) × 100
    final profitLossPercentage = asset.averagePrice != 0
        ? ((currentPrice - asset.averagePrice) / asset.averagePrice) * 100
        : 0.0;

    return AssetWithProfitLoss(
      asset: asset,
      totalValue: totalValue,
      costBasis: costBasis,
      profitLoss: profitLoss,
      profitLossPercentage: profitLossPercentage,
    );
  }

  /// Calculate total portfolio value and P/L
  PortfolioSummary calculatePortfolioSummary(List<Asset> assets) {
    int totalValue = 0;
    int totalCostBasis = 0;

    for (final asset in assets) {
      final assetPL = calculateAssetProfitLoss(asset);
      totalValue += assetPL.totalValue;
      totalCostBasis += assetPL.costBasis;
    }

    final totalProfitLoss = totalValue - totalCostBasis;
    final totalProfitLossPercentage = totalCostBasis != 0
        ? ((totalValue - totalCostBasis) / totalCostBasis) * 100
        : 0.0;

    return PortfolioSummary(
      totalValue: totalValue,
      totalCostBasis: totalCostBasis,
      totalProfitLoss: totalProfitLoss,
      totalProfitLossPercentage: totalProfitLossPercentage,
      assetCount: assets.length,
    );
  }
}

/// Summary of portfolio metrics
class PortfolioSummary extends Equatable {
  final int totalValue;
  final int totalCostBasis;
  final int totalProfitLoss;
  final double totalProfitLossPercentage;
  final int assetCount;

  const PortfolioSummary({
    required this.totalValue,
    required this.totalCostBasis,
    required this.totalProfitLoss,
    required this.totalProfitLossPercentage,
    required this.assetCount,
  });

  bool get isProfit => totalProfitLoss > 0;
  bool get isLoss => totalProfitLoss < 0;

  @override
  List<Object?> get props => [
        totalValue,
        totalCostBasis,
        totalProfitLoss,
        totalProfitLossPercentage,
        assetCount,
      ];
}
