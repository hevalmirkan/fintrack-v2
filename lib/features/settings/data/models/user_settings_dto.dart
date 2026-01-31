import 'dart:convert';
import '../../domain/entities/user_settings.dart';

class UserSettingsDto {
  final String baseCurrency;
  final int baseMinorFactor;
  final String themeMode;
  final bool biometricEnabled;
  final String costAccountingMethod;

  const UserSettingsDto({
    required this.baseCurrency,
    required this.baseMinorFactor,
    required this.themeMode,
    required this.biometricEnabled,
    required this.costAccountingMethod,
  });

  /// Domain -> DTO
  factory UserSettingsDto.fromDomain(UserSettings settings) {
    return UserSettingsDto(
      baseCurrency: settings.baseCurrency,
      baseMinorFactor: settings.baseMinorFactor,
      themeMode: settings.themeMode,
      biometricEnabled: settings.biometricEnabled,
      costAccountingMethod:
          settings.costAccountingMethod.name.toUpperCase(), // "FIFO", "AVERAGE"
    );
  }

  /// DTO -> Domain
  UserSettings toDomain() {
    return UserSettings(
      baseCurrency: baseCurrency,
      baseMinorFactor: baseMinorFactor,
      themeMode: themeMode,
      biometricEnabled: biometricEnabled,
      costAccountingMethod: _parseAccountingMethod(costAccountingMethod),
    );
  }

  static CostAccountingMethod _parseAccountingMethod(String value) {
    try {
      return CostAccountingMethod.values.firstWhere(
        (e) => e.name.toUpperCase() == value.toUpperCase(),
      );
    } catch (_) {
      return CostAccountingMethod.fifo; // Fallback default
    }
  }

  /// JSON/Firestore -> DTO
  factory UserSettingsDto.fromJson(Map<String, dynamic> json) {
    return UserSettingsDto(
      baseCurrency: json['baseCurrency'] as String? ?? 'USD',
      baseMinorFactor: json['baseMinorFactor'] as int? ?? 2,
      themeMode: json['themeMode'] as String? ?? 'system',
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      costAccountingMethod: json['costAccountingMethod'] as String? ?? 'FIFO',
    );
  }

  /// DTO -> JSON/Firestore
  Map<String, dynamic> toJson() {
    return {
      'baseCurrency': baseCurrency,
      'baseMinorFactor': baseMinorFactor,
      'themeMode': themeMode,
      'biometricEnabled': biometricEnabled,
      'costAccountingMethod': costAccountingMethod,
    };
  }

  // Explicitly for cache storage which uses jsonEncode
  String encode() => jsonEncode(toJson());

  factory UserSettingsDto.decode(String raw) =>
      UserSettingsDto.fromJson(jsonDecode(raw));
}
