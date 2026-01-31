// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(assetList)
const assetListProvider = AssetListProvider._();

final class AssetListProvider extends $FunctionalProvider<
        AsyncValue<List<Asset>>, List<Asset>, Stream<List<Asset>>>
    with $FutureModifier<List<Asset>>, $StreamProvider<List<Asset>> {
  const AssetListProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'assetListProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$assetListHash();

  @$internal
  @override
  $StreamProviderElement<List<Asset>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Asset>> create(Ref ref) {
    return assetList(ref);
  }
}

String _$assetListHash() => r'eb1b535fb5a6fc704db47b1b5ba6f63d9ab51865';

@ProviderFor(totalNetWorth)
const totalNetWorthProvider = TotalNetWorthProvider._();

final class TotalNetWorthProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  const TotalNetWorthProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'totalNetWorthProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$totalNetWorthHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return totalNetWorth(ref);
  }
}

String _$totalNetWorthHash() => r'70998c6852c8add2305f99946b9f5852386992db';

/// Total portfolio value in TRY (Turkish Lira)
/// This is the SINGLE SOURCE OF TRUTH for asset valuation in TRY
/// All UI screens and analysis MUST use this, never convert themselves

@ProviderFor(totalPortfolioValueTRY)
const totalPortfolioValueTRYProvider = TotalPortfolioValueTRYProvider._();

/// Total portfolio value in TRY (Turkish Lira)
/// This is the SINGLE SOURCE OF TRUTH for asset valuation in TRY
/// All UI screens and analysis MUST use this, never convert themselves

final class TotalPortfolioValueTRYProvider
    extends $FunctionalProvider<AsyncValue<double>, double, Stream<double>>
    with $FutureModifier<double>, $StreamProvider<double> {
  /// Total portfolio value in TRY (Turkish Lira)
  /// This is the SINGLE SOURCE OF TRUTH for asset valuation in TRY
  /// All UI screens and analysis MUST use this, never convert themselves
  const TotalPortfolioValueTRYProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'totalPortfolioValueTRYProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$totalPortfolioValueTRYHash();

  @$internal
  @override
  $StreamProviderElement<double> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<double> create(Ref ref) {
    return totalPortfolioValueTRY(ref);
  }
}

String _$totalPortfolioValueTRYHash() =>
    r'f405214047990d266b842397e5cdd476b7549a47';

/// Individual asset values in TRY (for diversity calculation)

@ProviderFor(assetValuesTRY)
const assetValuesTRYProvider = AssetValuesTRYProvider._();

/// Individual asset values in TRY (for diversity calculation)

final class AssetValuesTRYProvider extends $FunctionalProvider<
        AsyncValue<List<double>>, List<double>, Stream<List<double>>>
    with $FutureModifier<List<double>>, $StreamProvider<List<double>> {
  /// Individual asset values in TRY (for diversity calculation)
  const AssetValuesTRYProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'assetValuesTRYProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$assetValuesTRYHash();

  @$internal
  @override
  $StreamProviderElement<List<double>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<double>> create(Ref ref) {
    return assetValuesTRY(ref);
  }
}

String _$assetValuesTRYHash() => r'6539053fd1eca6b2c3a29decacde03984fa2142c';
