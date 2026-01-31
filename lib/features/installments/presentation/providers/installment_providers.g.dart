// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installment_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(installmentList)
const installmentListProvider = InstallmentListProvider._();

final class InstallmentListProvider extends $FunctionalProvider<
        AsyncValue<List<Installment>>,
        List<Installment>,
        Stream<List<Installment>>>
    with
        $FutureModifier<List<Installment>>,
        $StreamProvider<List<Installment>> {
  const InstallmentListProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'installmentListProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$installmentListHash();

  @$internal
  @override
  $StreamProviderElement<List<Installment>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Installment>> create(Ref ref) {
    return installmentList(ref);
  }
}

String _$installmentListHash() => r'2acfa073f175177b6a4de16e803cf3a8acdd3664';

@ProviderFor(totalDebt)
const totalDebtProvider = TotalDebtProvider._();

final class TotalDebtProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  const TotalDebtProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'totalDebtProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$totalDebtHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return totalDebt(ref);
  }
}

String _$totalDebtHash() => r'7da59d9be32c0e3e12a0babce66bc64c1c04fd7a';
