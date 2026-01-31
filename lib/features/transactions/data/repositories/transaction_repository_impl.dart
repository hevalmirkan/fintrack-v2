import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_enums.dart';
import '../../domain/repositories/i_transaction_repository.dart';

class TransactionRepositoryImpl implements ITransactionRepository {
  final FirebaseFirestore _firestore;
  final String? _userId;

  TransactionRepositoryImpl({
    required FirebaseFirestore firestore,
    required String? userId,
  })  : _firestore = firestore,
        _userId = userId;

  static const String _mockUserId = 'user_dev_01';

  CollectionReference<Map<String, dynamic>> _getCollection() {
    final effectiveUserId = _userId ?? _mockUserId;
    return _firestore
        .collection('users')
        .doc(effectiveUserId)
        .collection('transactions');
  }

  @override
  Future<void> addTransaction(TransactionEntity transaction) async {
    await _getCollection().add(_toFirestore(transaction));
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _getCollection().doc(id).delete();
  }

  @override
  Future<List<TransactionEntity>> getTransactions() async {
    final snapshot =
        await _getCollection().orderBy('date', descending: true).get();
    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  @override
  Future<List<TransactionEntity>> getTransactionsByAssetId(
      String assetId) async {
    final snapshot = await _getCollection()
        .where('assetId', isEqualTo: assetId)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  @override
  Stream<List<TransactionEntity>> getTransactionsStream() {
    try {
      if (_userId == null) return const Stream.empty();
      return _getCollection()
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
      });
    } catch (e) {
      // Return empty stream or handle error if needed, but usually letting it bubble via Stream.error is fine
      // For now, consistent with other repos.
      return const Stream.empty();
    }
  }

  // Mapper methods
  Map<String, dynamic> _toFirestore(TransactionEntity transaction) {
    return {
      'assetId': transaction.assetId,
      'title': transaction.title,
      'category': transaction.category,
      'quantityMinor': transaction.quantityMinor,
      'pricePerUnitMinor': transaction.pricePerUnitMinor,
      'feeMinor': transaction.feeMinor,
      'totalMinor': transaction.totalMinor,
      'date': Timestamp.fromDate(transaction.date),
      'type': transaction.type.name, // Enum to String
      'metadata': transaction.metadata,
    };
  }

  TransactionEntity _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TransactionEntity(
      id: doc.id,
      assetId: data['assetId'], // Nullable
      title: data['title'],
      category: data['category'],
      quantityMinor: data['quantityMinor'] ?? 0,
      pricePerUnitMinor: data['pricePerUnitMinor'] ?? 0,
      feeMinor: data['feeMinor'] ?? 0,
      totalMinor: data['totalMinor'] ?? 0,
      date: (data['date'] as Timestamp).toDate(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'buy'),
        orElse: () => TransactionType.buy, // Default for backward compatibility
      ),
      metadata: data['metadata'],
    );
  }
}
