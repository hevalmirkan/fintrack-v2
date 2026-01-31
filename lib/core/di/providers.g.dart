// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridden in main.dart

@ProviderFor(sharedPreferences)
const sharedPreferencesProvider = SharedPreferencesProvider._();

/// Overridden in main.dart

final class SharedPreferencesProvider extends $FunctionalProvider<
    SharedPreferences,
    SharedPreferences,
    SharedPreferences> with $Provider<SharedPreferences> {
  /// Overridden in main.dart
  const SharedPreferencesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'sharedPreferencesProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $ProviderElement<SharedPreferences> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SharedPreferences create(Ref ref) {
    return sharedPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedPreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedPreferences>(value),
    );
  }
}

String _$sharedPreferencesHash() => r'1da48e3cc521b0a322a996edafc5b8267ac91549';

@ProviderFor(firebaseFirestore)
const firebaseFirestoreProvider = FirebaseFirestoreProvider._();

final class FirebaseFirestoreProvider extends $FunctionalProvider<
    FirebaseFirestore,
    FirebaseFirestore,
    FirebaseFirestore> with $Provider<FirebaseFirestore> {
  const FirebaseFirestoreProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'firebaseFirestoreProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$firebaseFirestoreHash();

  @$internal
  @override
  $ProviderElement<FirebaseFirestore> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirebaseFirestore create(Ref ref) {
    return firebaseFirestore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFirestore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFirestore>(value),
    );
  }
}

String _$firebaseFirestoreHash() => r'da44e0544482927855093596d84cb41842b27214';

@ProviderFor(firebaseAuth)
const firebaseAuthProvider = FirebaseAuthProvider._();

final class FirebaseAuthProvider
    extends $FunctionalProvider<FirebaseAuth, FirebaseAuth, FirebaseAuth>
    with $Provider<FirebaseAuth> {
  const FirebaseAuthProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'firebaseAuthProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$firebaseAuthHash();

  @$internal
  @override
  $ProviderElement<FirebaseAuth> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirebaseAuth create(Ref ref) {
    return firebaseAuth(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseAuth value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseAuth>(value),
    );
  }
}

String _$firebaseAuthHash() => r'cb440927c3ab863427fd4b052a8ccba4c024c863';

@ProviderFor(authStateChanges)
const authStateChangesProvider = AuthStateChangesProvider._();

final class AuthStateChangesProvider
    extends $FunctionalProvider<AsyncValue<User?>, User?, Stream<User?>>
    with $FutureModifier<User?>, $StreamProvider<User?> {
  const AuthStateChangesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'authStateChangesProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$authStateChangesHash();

  @$internal
  @override
  $StreamProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<User?> create(Ref ref) {
    return authStateChanges(ref);
  }
}

String _$authStateChangesHash() => r'0a9f36ffcb9a23e7632ec6e1e70179b3e9653a96';

/// Exposes userId as a Stream.
/// Repositories allow String? so we can just watch this or the value.

@ProviderFor(userId)
const userIdProvider = UserIdProvider._();

/// Exposes userId as a Stream.
/// Repositories allow String? so we can just watch this or the value.

final class UserIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  /// Exposes userId as a Stream.
  /// Repositories allow String? so we can just watch this or the value.
  const UserIdProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'userIdProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userIdHash();

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    return userId(ref);
  }
}

String _$userIdHash() => r'5cf1583f4e8c01cb5dd223024317dff7571a5b6b';

@ProviderFor(settingsRepository)
const settingsRepositoryProvider = SettingsRepositoryProvider._();

final class SettingsRepositoryProvider extends $FunctionalProvider<
    ISettingsRepository,
    ISettingsRepository,
    ISettingsRepository> with $Provider<ISettingsRepository> {
  const SettingsRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'settingsRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$settingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ISettingsRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ISettingsRepository create(Ref ref) {
    return settingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ISettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ISettingsRepository>(value),
    );
  }
}

String _$settingsRepositoryHash() =>
    r'ea37defe4e451d366514e9fea15b377b774581bc';

@ProviderFor(assetRepository)
const assetRepositoryProvider = AssetRepositoryProvider._();

final class AssetRepositoryProvider extends $FunctionalProvider<
    IAssetRepository,
    IAssetRepository,
    IAssetRepository> with $Provider<IAssetRepository> {
  const AssetRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'assetRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$assetRepositoryHash();

  @$internal
  @override
  $ProviderElement<IAssetRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IAssetRepository create(Ref ref) {
    return assetRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IAssetRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IAssetRepository>(value),
    );
  }
}

String _$assetRepositoryHash() => r'f202fbee4070c8e804ab3ff68e0ba3899f025bb5';

@ProviderFor(transactionRepository)
const transactionRepositoryProvider = TransactionRepositoryProvider._();

final class TransactionRepositoryProvider extends $FunctionalProvider<
    ITransactionRepository,
    ITransactionRepository,
    ITransactionRepository> with $Provider<ITransactionRepository> {
  const TransactionRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'transactionRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$transactionRepositoryHash();

  @$internal
  @override
  $ProviderElement<ITransactionRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ITransactionRepository create(Ref ref) {
    return transactionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ITransactionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ITransactionRepository>(value),
    );
  }
}

String _$transactionRepositoryHash() =>
    r'ef08c0fad333e5d93da517599f618be36e5fe0b9';

@ProviderFor(installmentRepository)
const installmentRepositoryProvider = InstallmentRepositoryProvider._();

final class InstallmentRepositoryProvider extends $FunctionalProvider<
    IInstallmentRepository,
    IInstallmentRepository,
    IInstallmentRepository> with $Provider<IInstallmentRepository> {
  const InstallmentRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'installmentRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$installmentRepositoryHash();

  @$internal
  @override
  $ProviderElement<IInstallmentRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IInstallmentRepository create(Ref ref) {
    return installmentRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IInstallmentRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IInstallmentRepository>(value),
    );
  }
}

String _$installmentRepositoryHash() =>
    r'e5a63b7e8886e21a11939a11e3c2f6f5b314d1eb';

@ProviderFor(marketPriceRepository)
const marketPriceRepositoryProvider = MarketPriceRepositoryProvider._();

final class MarketPriceRepositoryProvider extends $FunctionalProvider<
    IMarketPriceRepository,
    IMarketPriceRepository,
    IMarketPriceRepository> with $Provider<IMarketPriceRepository> {
  const MarketPriceRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'marketPriceRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$marketPriceRepositoryHash();

  @$internal
  @override
  $ProviderElement<IMarketPriceRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IMarketPriceRepository create(Ref ref) {
    return marketPriceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IMarketPriceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IMarketPriceRepository>(value),
    );
  }
}

String _$marketPriceRepositoryHash() =>
    r'fd7d48e5961172ffa828509e68f41a90db7ed9e8';

@ProviderFor(marketPriceService)
const marketPriceServiceProvider = MarketPriceServiceProvider._();

final class MarketPriceServiceProvider extends $FunctionalProvider<
    IMarketPriceService,
    IMarketPriceService,
    IMarketPriceService> with $Provider<IMarketPriceService> {
  const MarketPriceServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'marketPriceServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$marketPriceServiceHash();

  @$internal
  @override
  $ProviderElement<IMarketPriceService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IMarketPriceService create(Ref ref) {
    return marketPriceService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IMarketPriceService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IMarketPriceService>(value),
    );
  }
}

String _$marketPriceServiceHash() =>
    r'5a8b5428220beb4ed239a87218dff627f78539ae';
