import '../entities/asset.dart';
import '../entities/asset_purchase_type.dart';

abstract class IAssetRepository {
  Future<List<Asset>> getAssets();
  Stream<List<Asset>> getAssetsStream();
  Future<Asset?> getAssetById(String id);
  Future<void> addAsset(
    Asset asset, {
    AssetPurchaseType purchaseType = AssetPurchaseType.addToPortfolio,
  });
  Future<void> updateAsset(Asset asset);
  Future<void> deleteAsset(String id);
}
