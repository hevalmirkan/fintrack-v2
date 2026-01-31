import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/providers.dart';
import '../../data/services/dashboard_calculation_service.dart';
import '../../domain/entities/dashboard_stats.dart';

part 'dashboard_provider.g.dart';

@riverpod
DashboardCalculationService dashboardCalculationService(Ref ref) {
  return DashboardCalculationService(
    assetRepository: ref.watch(assetRepositoryProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
  );
}

@riverpod
Stream<DashboardStats> dashboardStats(Ref ref) {
  final service = ref.watch(dashboardCalculationServiceProvider);
  return service.getStats();
}
