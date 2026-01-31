import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/assets/data/repositories/asset_repository_impl.dart';
import '../../features/assets/domain/repositories/i_asset_repository.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/i_settings_repository.dart';
import '../../features/transactions/data/repositories/transaction_repository_impl.dart';
import '../../features/transactions/domain/repositories/i_transaction_repository.dart';
import '../../features/installments/data/repositories/installment_repository_impl.dart';
import '../../features/installments/domain/repositories/i_installment_repository.dart';
import '../../features/market/data/repositories/market_price_repository_impl.dart';
import '../../features/market/domain/repositories/i_market_price_repository.dart';
import '../../features/market/data/services/market_price_service.dart';
import '../../features/market/domain/services/i_market_price_service.dart';

part 'providers.g.dart';

// --- Core ---

/// Overridden in main.dart
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError('SharedPreferences not initialized');
}

@Riverpod(keepAlive: true)
FirebaseFirestore firebaseFirestore(Ref ref) {
  return FirebaseFirestore.instance;
}

@Riverpod(keepAlive: true)
FirebaseAuth firebaseAuth(Ref ref) {
  return FirebaseAuth.instance;
}

@Riverpod(keepAlive: true)
Stream<User?> authStateChanges(Ref ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
}

/// Exposes userId as a Stream.
/// Repositories allow String? so we can just watch this or the value.
@Riverpod(keepAlive: true)
Stream<String?> userId(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  return Stream.value(authState.value?.uid);
}

// --- Repositories ---

@Riverpod(keepAlive: true)
ISettingsRepository settingsRepository(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  // We need the current value of userId.
  // We can use StreamProvider, but for a Repository factory, we usually grab the current state.
  // OR we can make the Repository depend on a `Reader` or `Ref` to fetch userId on demand.
  // BUT the prompt said: "Dependencies: ... String? userId".
  // This implies the Repository instance is recreated when userId changes, OR it holds the value.
  // Using .requireValue on a stream inside a Provider body is risky if stream hasn't emitted.
  // Better: watch the authStateChanges (or userIdProvider) which emits immediately (if using standard behavior or initial data).
  // Assuming authStateChanges emits initial state.

  final userAsync = ref.watch(authStateChangesProvider);
  final userId = userAsync.value?.uid;
  // Note: if loading, userId might be null. That's fine, repo handles null.

  return SettingsRepositoryImpl(
    firestore: firestore,
    prefs: prefs,
    userId: userId,
  );
}

// Placeholders for other repos as requested
@Riverpod(keepAlive: true)
IAssetRepository assetRepository(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  // Watch userId stream to react to auth changes
  final userAsync = ref.watch(authStateChangesProvider);
  final userId = userAsync.value?.uid;

  return AssetRepositoryImpl(
    firestore: firestore,
    userId: userId,
  );
}

@Riverpod(keepAlive: true)
ITransactionRepository transactionRepository(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final userAsync = ref.watch(authStateChangesProvider);
  final userId = userAsync.value?.uid;

  return TransactionRepositoryImpl(
    firestore: firestore,
    userId: userId,
  );
}

@Riverpod(keepAlive: true)
IInstallmentRepository installmentRepository(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final userAsync = ref.watch(authStateChangesProvider);
  final userId = userAsync.value?.uid;

  return InstallmentRepositoryImpl(
    firestore: firestore,
    userId: userId,
  );
}

@Riverpod(keepAlive: true)
IMarketPriceRepository marketPriceRepository(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final userAsync = ref.watch(authStateChangesProvider);
  final userId = userAsync.value?.uid;

  return MarketPriceRepositoryImpl(
    firestore: firestore,
    userId: userId,
  );
}

@Riverpod(keepAlive: true)
IMarketPriceService marketPriceService(Ref ref) {
  final repository = ref.watch(marketPriceRepositoryProvider);
  return MarketPriceService(repository: repository);
}
