import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/i_settings_repository.dart';
import '../models/user_settings_dto.dart';

class SettingsRepositoryImpl implements ISettingsRepository {
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;
  final String? _userId;

  static const String _cacheKey = 'cached_user_settings';

  SettingsRepositoryImpl({
    required FirebaseFirestore firestore,
    required SharedPreferences prefs,
    required String? userId,
  })  : _firestore = firestore,
        _prefs = prefs,
        _userId = userId;

  @override
  Future<UserSettings> getSettings() async {
    // 1. Try Cache First
    final cachedData = _prefs.getString(_cacheKey);
    if (cachedData != null) {
      try {
        final dto = UserSettingsDto.decode(cachedData);
        return dto.toDomain();
      } catch (e) {
        // Corrupt cache? Ignore and fetch remote.
      }
    }

    // 2. Auth Check
    if (_userId == null) {
      // If we are unauthenticated and NO cache, returning initial settings is safer than throwing?
      // But prompt says "Throws UnauthenticatedException if userId is null".
      // Let's throw if absolutely no data can be retrieved, OR if we strictly follow "Repository implementations MUST check userId".
      // However, usually settings might be local-only for guests?
      // Prompt Rule: "Repository implementations MUST check userId. If null -> throw UnauthenticatedException."
      // This implies explicit authenticated fetch.
      // But what if we want to support offline-first without login?
      // I will follow the strict rule for network operations.
      // BUT if cache existed, we returned it above.
      // If cache missing and no user => throw.
      throw const UnauthenticatedException();
    }

    // 3. Fetch Remote
    try {
      final docStart = _firestore
          .collection('users')
          .doc(_userId)
          .collection('settings')
          .doc('default');
      final doc = await docStart.get();

      if (doc.exists && doc.data() != null) {
        final dto = UserSettingsDto.fromJson(doc.data()!);
        // 4. Update Cache
        await _prefs.setString(_cacheKey, dto.encode());
        return dto.toDomain();
      } else {
        // 5. Default/Initial
        // Should we create it on server? Maybe lazy creation on next save.
        // For now, return initial.
        return UserSettings.initial();
      }
    } catch (e) {
      throw RepositoryException('Failed to fetch settings', e);
    }
  }

  @override
  Future<void> updateSettings(UserSettings settings) async {
    // 1. Convert
    final dto = UserSettingsDto.fromDomain(settings);

    // 2. Optimistic Cache Update
    await _prefs.setString(_cacheKey, dto.encode());

    // 3. Auth Check
    if (_userId == null) {
      // If unauthenticated, we just updated local cache.
      // Should we throw? Prompt says "MUST check userId... throw".
      // So we throw, meaning usage of this repo implies logged in state for sync.
      // But we kept the cache update so it persists locally.
      throw const UnauthenticatedException();
    }

    // 4. Remote Update
    try {
      final docStart = _firestore
          .collection('users')
          .doc(_userId)
          .collection('settings')
          .doc('default');
      await docStart.set(dto.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw RepositoryException('Failed to update settings', e);
    }
  }

  @override
  Future<void> updateBaseCurrency(String currencyCode) async {
    final current = await getSettings(); // This handles cache check
    final updated = current.copyWith(baseCurrency: currencyCode);
    await updateSettings(updated);
  }
}
