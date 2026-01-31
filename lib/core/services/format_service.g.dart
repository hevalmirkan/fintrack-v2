// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'format_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(formatService)
const formatServiceProvider = FormatServiceProvider._();

final class FormatServiceProvider
    extends $FunctionalProvider<FormatService, FormatService, FormatService>
    with $Provider<FormatService> {
  const FormatServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'formatServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$formatServiceHash();

  @$internal
  @override
  $ProviderElement<FormatService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FormatService create(Ref ref) {
    return formatService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FormatService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FormatService>(value),
    );
  }
}

String _$formatServiceHash() => r'804bf701c864c954caa58166411be7b8299be200';
