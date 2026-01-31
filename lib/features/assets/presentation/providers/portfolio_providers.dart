import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/providers.dart';
import '../../domain/services/portfolio_calculation_service.dart';
import '../../domain/repositories/i_asset_repository.dart';
import '../../../market/domain/repositories/i_market_price_repository.dart';

part 'portfolio_providers.g.dart';

@riverpod
PortfolioCalculationService portfolioCalculationService(Ref ref) {
  return PortfolioCalculationService();
}

@riverpod
Stream<List<AssetWithProfitLoss>> assetsWithProfitLoss(Ref ref) {
  final assetRepo = ref.watch(assetRepositoryProvider);
  final calcService = ref.watch(portfolioCalculationServiceProvider);

  return assetRepo.getAssetsStream().map((assets) {
    return assets.map((asset) {
      return calcService.calculateAssetProfitLoss(asset);
    }).toList();
  });
}

@riverpod
Future<PortfolioSummary> portfolioSummary(Ref ref) async {
  final assetRepo = ref.watch(assetRepositoryProvider);
  final calcService = ref.watch(portfolioCalculationServiceProvider);

  final assets = await assetRepo.getAssets();
  return calcService.calculatePortfolioSummary(assets);
}

/// Refresh market price for a specific asset
@riverpod
Future<void> refreshAssetPrice(
  Ref ref,
  String assetId,
  String symbol,
) async {
  final marketService = ref.watch(marketPriceServiceProvider);
  final assetRepo = ref.watch(assetRepositoryProvider);

  // Fetch latest price
  final latestPrice = await marketService.refreshPrice(symbol);

  // Get current asset
  final asset = await assetRepo.getAssetById(assetId);
  if (asset == null) return;

  // Update asset with new price
  final updatedAsset = asset.copyWith(
    lastKnownPrice: latestPrice.priceMinor,
    lastPriceUpdate: latestPrice.timestamp,
  );

  await assetRepo.updateAsset(updatedAsset);
}
