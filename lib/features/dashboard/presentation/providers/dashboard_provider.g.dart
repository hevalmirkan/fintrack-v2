// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dashboardCalculationService)
const dashboardCalculationServiceProvider =
    DashboardCalculationServiceProvider._();

final class DashboardCalculationServiceProvider extends $FunctionalProvider<
    DashboardCalculationService,
    DashboardCalculationService,
    DashboardCalculationService> with $Provider<DashboardCalculationService> {
  const DashboardCalculationServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'dashboardCalculationServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$dashboardCalculationServiceHash();

  @$internal
  @override
  $ProviderElement<DashboardCalculationService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DashboardCalculationService create(Ref ref) {
    return dashboardCalculationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DashboardCalculationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DashboardCalculationService>(value),
    );
  }
}

String _$dashboardCalculationServiceHash() =>
    r'ae819162e997c511f46873f2de0e420836f1edf0';

@ProviderFor(dashboardStats)
const dashboardStatsProvider = DashboardStatsProvider._();

final class DashboardStatsProvider extends $FunctionalProvider<
        AsyncValue<DashboardStats>, DashboardStats, Stream<DashboardStats>>
    with $FutureModifier<DashboardStats>, $StreamProvider<DashboardStats> {
  const DashboardStatsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'dashboardStatsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$dashboardStatsHash();

  @$internal
  @override
  $StreamProviderElement<DashboardStats> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DashboardStats> create(Ref ref) {
    return dashboardStats(ref);
  }
}

String _$dashboardStatsHash() => r'ed4aeedd4f3f99739c129a7e6991adac782a881b';
