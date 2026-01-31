import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/user_settings.dart';

part 'settings_provider.g.dart';

@riverpod
class Settings extends _$Settings {
  @override
  FutureOr<UserSettings> build() {
    return ref.watch(settingsRepositoryProvider).getSettings();
  }

  Future<void> updateBaseCurrency(String currencyCode) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(settingsRepositoryProvider)
          .updateBaseCurrency(currencyCode);
      return ref.read(settingsRepositoryProvider).getSettings();
    });
  }

  Future<void> updateCostAccountingMethod(CostAccountingMethod method) async {
    // Current state required to copy
    final current = state.value;
    if (current == null) return; // Can't update if not loaded

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final newSettings = current.copyWith(costAccountingMethod: method);
      await ref.read(settingsRepositoryProvider).updateSettings(newSettings);
      return newSettings;
      // Optimization: return newSettings directly since we know it,
      // but fetching ensures truth. We did optimistic update in Repo.
      // Repo might return the cached version.
    });
  }
}
