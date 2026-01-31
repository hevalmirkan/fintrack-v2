import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/providers.dart';
import '../../domain/entities/installment.dart';

part 'installment_providers.g.dart';

@Riverpod(keepAlive: true)
Stream<List<Installment>> installmentList(Ref ref) {
  final repository = ref.watch(installmentRepositoryProvider);
  return repository.getInstallments();
}

@Riverpod(keepAlive: true)
Stream<int> totalDebt(Ref ref) {
  final installmentsAsync = ref.watch(installmentListProvider);
  return installmentsAsync.when(
    data: (installments) {
      final total = installments.fold<int>(
        0,
        (sum, item) => sum + item.remainingAmount,
      );
      return Stream.value(total);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
}
