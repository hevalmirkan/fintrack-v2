// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(transactionList)
const transactionListProvider = TransactionListProvider._();

final class TransactionListProvider extends $FunctionalProvider<
        AsyncValue<List<TransactionEntity>>,
        List<TransactionEntity>,
        Stream<List<TransactionEntity>>>
    with
        $FutureModifier<List<TransactionEntity>>,
        $StreamProvider<List<TransactionEntity>> {
  const TransactionListProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'transactionListProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$transactionListHash();

  @$internal
  @override
  $StreamProviderElement<List<TransactionEntity>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<TransactionEntity>> create(Ref ref) {
    return transactionList(ref);
  }
}

String _$transactionListHash() => r'a92f7d564c54e553e30e178ae1ff680603f87e40';

@ProviderFor(recentTransactions)
const recentTransactionsProvider = RecentTransactionsProvider._();

final class RecentTransactionsProvider extends $FunctionalProvider<
        AsyncValue<List<TransactionEntity>>,
        List<TransactionEntity>,
        Stream<List<TransactionEntity>>>
    with
        $FutureModifier<List<TransactionEntity>>,
        $StreamProvider<List<TransactionEntity>> {
  const RecentTransactionsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'recentTransactionsProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$recentTransactionsHash();

  @$internal
  @override
  $StreamProviderElement<List<TransactionEntity>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<TransactionEntity>> create(Ref ref) {
    return recentTransactions(ref);
  }
}

String _$recentTransactionsHash() =>
    r'f758171ee3678a1247df8cedf5ddc93ba930eb35';
