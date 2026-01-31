// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NotificationSettings)
const notificationSettingsProvider = NotificationSettingsProvider._();

final class NotificationSettingsProvider extends $AsyncNotifierProvider<
    NotificationSettings, NotificationSettingsState> {
  const NotificationSettingsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'notificationSettingsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$notificationSettingsHash();

  @$internal
  @override
  NotificationSettings create() => NotificationSettings();
}

String _$notificationSettingsHash() =>
    r'c1185da58138c2d5abdfbe19f8623a4d509afd82';

abstract class _$NotificationSettings
    extends $AsyncNotifier<NotificationSettingsState> {
  FutureOr<NotificationSettingsState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<NotificationSettingsState>,
        NotificationSettingsState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<NotificationSettingsState>,
            NotificationSettingsState>,
        AsyncValue<NotificationSettingsState>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
