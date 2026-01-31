// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portfolio_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(portfolioCalculationService)
const portfolioCalculationServiceProvider =
    PortfolioCalculationServiceProvider._();

final class PortfolioCalculationServiceProvider extends $FunctionalProvider<
    PortfolioCalculationService,
    PortfolioCalculationService,
    PortfolioCalculationService> with $Provider<PortfolioCalculationService> {
  const PortfolioCalculationServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'portfolioCalculationServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$portfolioCalculationServiceHash();

  @$internal
  @override
  $ProviderElement<PortfolioCalculationService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PortfolioCalculationService create(Ref ref) {
    return portfolioCalculationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PortfolioCalculationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PortfolioCalculationService>(value),
    );
  }
}

String _$portfolioCalculationServiceHash() =>
    r'7d8386b9c1dfe3157fce35533f9500ba782f9a78';

@ProviderFor(assetsWithProfitLoss)
const assetsWithProfitLossProvider = AssetsWithProfitLossProvider._();

final class AssetsWithProfitLossProvider extends $FunctionalProvider<
        AsyncValue<List<AssetWithProfitLoss>>,
        List<AssetWithProfitLoss>,
        Stream<List<AssetWithProfitLoss>>>
    with
        $FutureModifier<List<AssetWithProfitLoss>>,
        $StreamProvider<List<AssetWithProfitLoss>> {
  const AssetsWithProfitLossProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'assetsWithProfitLossProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$assetsWithProfitLossHash();

  @$internal
  @override
  $StreamProviderElement<List<AssetWithProfitLoss>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<AssetWithProfitLoss>> create(Ref ref) {
    return assetsWithProfitLoss(ref);
  }
}

String _$assetsWithProfitLossHash() =>
    r'4ca91655682f857ba4cb4babf14afb0a2c5cbeb4';

@ProviderFor(portfolioSummary)
const portfolioSummaryProvider = PortfolioSummaryProvider._();

final class PortfolioSummaryProvider extends $FunctionalProvider<
        AsyncValue<PortfolioSummary>,
        PortfolioSummary,
        FutureOr<PortfolioSummary>>
    with $FutureModifier<PortfolioSummary>, $FutureProvider<PortfolioSummary> {
  const PortfolioSummaryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'portfolioSummaryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$portfolioSummaryHash();

  @$internal
  @override
  $FutureProviderElement<PortfolioSummary> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PortfolioSummary> create(Ref ref) {
    return portfolioSummary(ref);
  }
}

String _$portfolioSummaryHash() => r'0ff0c3cefc5d5b1e262834898688b13a4549c97a';

/// Refresh market price for a specific asset

@ProviderFor(refreshAssetPrice)
const refreshAssetPriceProvider = RefreshAssetPriceFamily._();

/// Refresh market price for a specific asset

final class RefreshAssetPriceProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Refresh market price for a specific asset
  const RefreshAssetPriceProvider._(
      {required RefreshAssetPriceFamily super.from,
      required (
        String,
        String,
      )
          super.argument})
      : super(
          retry: null,
          name: r'refreshAssetPriceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$refreshAssetPriceHash();

  @override
  String toString() {
    return r'refreshAssetPriceProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as (
      String,
      String,
    );
    return refreshAssetPrice(
      ref,
      argument.$1,
      argument.$2,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RefreshAssetPriceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$refreshAssetPriceHash() => r'f5ff65b7042246c27ebd6d2f5eb5726464091225';

/// Refresh market price for a specific asset

final class RefreshAssetPriceFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<void>,
            (
              String,
              String,
            )> {
  const RefreshAssetPriceFamily._()
      : super(
          retry: null,
          name: r'refreshAssetPriceProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Refresh market price for a specific asset

  RefreshAssetPriceProvider call(
    String assetId,
    String symbol,
  ) =>
      RefreshAssetPriceProvider._(argument: (
        assetId,
        symbol,
      ), from: this);

  @override
  String toString() => r'refreshAssetPriceProvider';
}
