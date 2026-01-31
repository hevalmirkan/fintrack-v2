import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/providers.dart';
import '../../domain/entities/transaction_entity.dart';

part 'transaction_providers.g.dart';

@Riverpod(keepAlive: true)
Stream<List<TransactionEntity>> transactionList(Ref ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getTransactionsStream(); // Sorted DESC by default in repo
}

@Riverpod(keepAlive: true)
Stream<List<TransactionEntity>> recentTransactions(Ref ref) {
  // Watch the full list and slice the top 5
  // This avoids double fetching unless we specifically wanted a separate query
  final allTransactionsAsync = ref.watch(transactionListProvider);

  return allTransactionsAsync.when(
    data: (transactions) {
      // Assuming stream is already sorted by date DESC from repository logic
      final recent = transactions.take(5).toList();
      return Stream.value(recent);
    },
    loading: () => const Stream.empty(),
    error: (e, st) => Stream.error(e, st),
  );
}
