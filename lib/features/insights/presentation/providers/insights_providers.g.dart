// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insights_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(financialHealthService)
const financialHealthServiceProvider = FinancialHealthServiceProvider._();

final class FinancialHealthServiceProvider extends $FunctionalProvider<
    FinancialHealthService,
    FinancialHealthService,
    FinancialHealthService> with $Provider<FinancialHealthService> {
  const FinancialHealthServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'financialHealthServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$financialHealthServiceHash();

  @$internal
  @override
  $ProviderElement<FinancialHealthService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FinancialHealthService create(Ref ref) {
    return financialHealthService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FinancialHealthService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FinancialHealthService>(value),
    );
  }
}

String _$financialHealthServiceHash() =>
    r'8cee44812e817d19de9430fcd76f2cb42e989824';

@ProviderFor(financialHealthScore)
const financialHealthScoreProvider = FinancialHealthScoreProvider._();

final class FinancialHealthScoreProvider extends $FunctionalProvider<
        AsyncValue<FinancialHealthScore>,
        FinancialHealthScore,
        FutureOr<FinancialHealthScore>>
    with
        $FutureModifier<FinancialHealthScore>,
        $FutureProvider<FinancialHealthScore> {
  const FinancialHealthScoreProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'financialHealthScoreProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$financialHealthScoreHash();

  @$internal
  @override
  $FutureProviderElement<FinancialHealthScore> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<FinancialHealthScore> create(Ref ref) {
    return financialHealthScore(ref);
  }
}

String _$financialHealthScoreHash() =>
    r'4b067a891e1449d20f80e5fe63a34bafda8ffa1a';

@ProviderFor(educationalInsightService)
const educationalInsightServiceProvider = EducationalInsightServiceProvider._();

final class EducationalInsightServiceProvider extends $FunctionalProvider<
    EducationalInsightService,
    EducationalInsightService,
    EducationalInsightService> with $Provider<EducationalInsightService> {
  const EducationalInsightServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'educationalInsightServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$educationalInsightServiceHash();

  @$internal
  @override
  $ProviderElement<EducationalInsightService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EducationalInsightService create(Ref ref) {
    return educationalInsightService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EducationalInsightService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EducationalInsightService>(value),
    );
  }
}

String _$educationalInsightServiceHash() =>
    r'91aed4b50d798d9979e6cef2ebd71d844ad47779';

@ProviderFor(dailyFinancialTerm)
const dailyFinancialTermProvider = DailyFinancialTermProvider._();

final class DailyFinancialTermProvider
    extends $FunctionalProvider<FinancialTerm, FinancialTerm, FinancialTerm>
    with $Provider<FinancialTerm> {
  const DailyFinancialTermProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'dailyFinancialTermProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$dailyFinancialTermHash();

  @$internal
  @override
  $ProviderElement<FinancialTerm> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FinancialTerm create(Ref ref) {
    return dailyFinancialTerm(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FinancialTerm value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FinancialTerm>(value),
    );
  }
}

String _$dailyFinancialTermHash() =>
    r'd67b9878a2a4e5328c8c1194472d91718d0d386a';

@ProviderFor(educationalInsights)
const educationalInsightsProvider = EducationalInsightsProvider._();

final class EducationalInsightsProvider extends $FunctionalProvider<
        AsyncValue<List<EducationalInsight>>,
        List<EducationalInsight>,
        FutureOr<List<EducationalInsight>>>
    with
        $FutureModifier<List<EducationalInsight>>,
        $FutureProvider<List<EducationalInsight>> {
  const EducationalInsightsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'educationalInsightsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$educationalInsightsHash();

  @$internal
  @override
  $FutureProviderElement<List<EducationalInsight>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<EducationalInsight>> create(Ref ref) {
    return educationalInsights(ref);
  }
}

String _$educationalInsightsHash() =>
    r'875dffef9660f9561427dfa93168114ae8c0422e';

@ProviderFor(scorecardMetrics)
const scorecardMetricsProvider = ScorecardMetricsProvider._();

final class ScorecardMetricsProvider extends $FunctionalProvider<
        AsyncValue<Map<String, int>>,
        Map<String, int>,
        FutureOr<Map<String, int>>>
    with $FutureModifier<Map<String, int>>, $FutureProvider<Map<String, int>> {
  const ScorecardMetricsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'scorecardMetricsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$scorecardMetricsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, int>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, int>> create(Ref ref) {
    return scorecardMetrics(ref);
  }
}

String _$scorecardMetricsHash() => r'00abc96f25f841f8b1b6fe009a664b582a8b3095';
