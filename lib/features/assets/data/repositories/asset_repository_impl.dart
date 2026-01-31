import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../transactions/domain/entities/transaction_enums.dart';
import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_purchase_type.dart';
import '../../domain/repositories/i_asset_repository.dart';

class AssetRepositoryImpl implements IAssetRepository {
  final FirebaseFirestore _firestore;
  final String? _userId;

  AssetRepositoryImpl({
    required FirebaseFirestore firestore,
    required String? userId,
  })  : _firestore = firestore,
        _userId = userId;

  // DEV MODE: Mock user fallback to prevent auth errors
  static const String _mockUserId = 'user_dev_01';

  CollectionReference<Map<String, dynamic>> _getCollection() {
    // Use mock user if not logged in (DEV MODE)
    final effectiveUserId = _userId ?? _mockUserId;
    return _firestore
        .collection('users')
        .doc(effectiveUserId)
        .collection('assets');
  }

  CollectionReference<Map<String, dynamic>> _getTransactionsCollection() {
    // Use mock user if not logged in (DEV MODE)
    final effectiveUserId = _userId ?? _mockUserId;
    return _firestore
        .collection('users')
        .doc(effectiveUserId)
        .collection('transactions');
  }

  @override
  Future<List<Asset>> getAssets() async {
    try {
      final snapshot = await _getCollection().get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      throw RepositoryException('Failed to fetch assets', e);
    }
  }

  @override
  Stream<List<Asset>> getAssetsStream() {
    try {
      if (_userId == null) return const Stream.empty();
      return _getCollection().snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
      });
    } catch (e) {
      return Stream.error(RepositoryException('Stream error', e));
    }
  }

  @override
  Future<Asset?> getAssetById(String id) async {
    try {
      final doc = await _getCollection().doc(id).get();
      if (!doc.exists) return null;
      return _fromFirestore(doc);
    } catch (e) {
      throw RepositoryException('Failed to fetch asset', e);
    }
  }

  @override
  Future<void> addAsset(
    Asset asset, {
    AssetPurchaseType purchaseType = AssetPurchaseType.addToPortfolio,
  }) async {
    try {
      if (purchaseType == AssetPurchaseType.buyNow) {
        // ATOMIC: Add asset + create expense transaction (with merge logic)
        await _addAssetWithTransaction(asset);
      } else {
        // Portfolio addition (with merge logic, no cash impact)
        await _addAssetOnly(asset);
      }
    } catch (e) {
      throw RepositoryException('Failed to add asset', e);
    }
  }

  Future<void> _addAssetWithTransaction(Asset asset) async {
    // Check if asset with same symbol exists
    final existingAsset = await _findAssetBySymbol(asset.symbol);

    if (existingAsset != null) {
      // MERGE: Calculate weighted average cost
      await _mergeAssetWithTransaction(existingAsset, asset);
    } else {
      // NEW: Create fresh asset + transaction
      await _createNewAssetWithTransaction(asset);
    }
  }

  Future<void> _createNewAssetWithTransaction(Asset asset) async {
    final assetRef = _getCollection().doc(); // Generate new ID
    final transactionRef =
        _getTransactionsCollection().doc(); // Generate new ID

    await _firestore.runTransaction((transaction) async {
      // Calculate total cost
      final totalCostMinor = (asset.quantityMinor * asset.averagePrice) ~/ 100;

      // 1. Create Asset
      final assetData = _toFirestore(asset);
      transaction.set(assetRef, assetData);

      // 2. Create Expense Transaction
      final transactionData = {
        'assetId': assetRef.id,
        'title': '${asset.symbol} Satın Alma',
        'category': 'Yatırım',
        'quantityMinor': asset.quantityMinor,
        'pricePerUnitMinor': asset.averagePrice,
        'feeMinor': 0,
        'totalMinor': totalCostMinor,
        'date': Timestamp.fromDate(DateTime.now()),
        'type': TransactionType.expense.name,
        'metadata': {
          'assetId': assetRef.id,
          'symbol': asset.symbol,
        },
      };
      transaction.set(transactionRef, transactionData);
    });
  }

  Future<void> _mergeAssetWithTransaction(
      Asset existingAsset, Asset newAsset) async {
    final assetRef = _getCollection().doc(existingAsset.id);
    final transactionRef = _getTransactionsCollection().doc();

    await _firestore.runTransaction((transaction) async {
      // Calculate weighted average cost
      final oldQty = existingAsset.quantityMinor;
      final oldCost = existingAsset.averagePrice;
      final newQty = newAsset.quantityMinor;
      final newCost = newAsset.averagePrice;

      final totalQty = oldQty + newQty;
      final weightedAvgCost =
          ((oldQty * oldCost) + (newQty * newCost)) ~/ totalQty;

      // 1. Update existing asset
      final updatedAssetData = _toFirestore(existingAsset.copyWith(
        quantityMinor: totalQty,
        averagePrice: weightedAvgCost,
      ));
      transaction.update(assetRef, updatedAssetData);

      // 2. Create expense transaction for new purchase
      final totalCostMinor = (newQty * newCost) ~/ 100;
      final transactionData = {
        'assetId': existingAsset.id,
        'title': '${newAsset.symbol} Ek Alım',
        'category': 'Yatırım',
        'quantityMinor': newQty,
        'pricePerUnitMinor': newCost,
        'feeMinor': 0,
        'totalMinor': totalCostMinor,
        'date': Timestamp.fromDate(DateTime.now()),
        'type': TransactionType.expense.name,
        'metadata': {
          'assetId': existingAsset.id,
          'symbol': newAsset.symbol,
        },
      };
      transaction.set(transactionRef, transactionData);
    });
  }

  Future<void> _addAssetOnly(Asset asset) async {
    // Check if asset with same symbol exists
    final existingAsset = await _findAssetBySymbol(asset.symbol);

    if (existingAsset != null) {
      // MERGE: Update quantity and average cost
      await _mergeAssetOnly(existingAsset, asset);
    } else {
      // NEW: Simple insert, no transaction
      await _getCollection().add(_toFirestore(asset));
    }
  }

  Future<void> _mergeAssetOnly(Asset existingAsset, Asset newAsset) async {
    // Calculate weighted average cost
    final oldQty = existingAsset.quantityMinor;
    final oldCost = existingAsset.averagePrice;
    final newQty = newAsset.quantityMinor;
    final newCost = newAsset.averagePrice;

    final totalQty = oldQty + newQty;
    final weightedAvgCost =
        ((oldQty * oldCost) + (newQty * newCost)) ~/ totalQty;

    // Update existing asset (no transaction created)
    final updatedAsset = existingAsset.copyWith(
      quantityMinor: totalQty,
      averagePrice: weightedAvgCost,
    );

    await updateAsset(updatedAsset);
  }

  Future<Asset?> _findAssetBySymbol(String symbol) async {
    try {
      final snapshot = await _getCollection()
          .where('symbol', isEqualTo: symbol)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return _fromFirestore(snapshot.docs.first);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateAsset(Asset asset) async {
    try {
      await _getCollection().doc(asset.id).update(_toFirestore(asset));
    } catch (e) {
      throw RepositoryException('Failed to update asset', e);
    }
  }

  @override
  Future<void> deleteAsset(String id) async {
    try {
      await _getCollection().doc(id).delete();
    } catch (e) {
      throw RepositoryException('Failed to delete asset', e);
    }
  }

  // --- Mappers ---

  Asset _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Asset(
      id: doc.id,
      symbol: data['symbol'] as String,
      name: data['name'] as String,
      quantityMinor: (data['quantityMinor'] as num?)?.toInt() ?? 0,
      averagePrice: (data['averagePrice'] as num?)?.toInt() ?? 0,
      currentPrice: (data['currentPrice'] as num?)?.toInt() ?? 0,
      lastKnownPrice: (data['lastKnownPrice'] as num?)?.toInt(),
      lastPriceUpdate: data['lastPriceUpdate'] != null
          ? (data['lastPriceUpdate'] as Timestamp).toDate()
          : null,
      apiId: data['apiId'] as String?, // Phase 16B: Heimdall integration
    );
  }

  Map<String, dynamic> _toFirestore(Asset asset) {
    return {
      'symbol': asset.symbol,
      'name': asset.name,
      'quantityMinor': asset.quantityMinor,
      'averagePrice': asset.averagePrice,
      'currentPrice': asset.currentPrice,
      'lastKnownPrice': asset.lastKnownPrice,
      'lastPriceUpdate': asset.lastPriceUpdate != null
          ? Timestamp.fromDate(asset.lastPriceUpdate!)
          : null,
      'apiId': asset.apiId, // Phase 16B: Heimdall integration
    };
  }
}
