import '../entities/transaction_entity.dart';

abstract class ITransactionRepository {
  Future<List<TransactionEntity>> getTransactions();
  Stream<List<TransactionEntity>> getTransactionsStream(); // Added for UI
  Future<List<TransactionEntity>> getTransactionsByAssetId(String assetId);
  Future<void> addTransaction(TransactionEntity transaction);
  Future<void> deleteTransaction(String id);
}
