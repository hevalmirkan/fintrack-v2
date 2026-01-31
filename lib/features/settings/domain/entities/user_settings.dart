import 'package:equatable/equatable.dart';

enum CostAccountingMethod {
  fifo,
  average,
}

class UserSettings extends Equatable {
  final String baseCurrency; // e.g. "USD", "TRY"
  final int baseMinorFactor; // e.g. 2 for cents (10^2), 0 for yen. Default 2?
  final String themeMode; // "light", "dark", "system"
  final bool biometricEnabled;
  final CostAccountingMethod costAccountingMethod;

  const UserSettings({
    required this.baseCurrency,
    required this.baseMinorFactor,
    required this.themeMode,
    required this.biometricEnabled,
    required this.costAccountingMethod,
  });

  factory UserSettings.initial() {
    return const UserSettings(
      baseCurrency: 'USD',
      baseMinorFactor: 2,
      themeMode: 'system',
      biometricEnabled: false,
      costAccountingMethod: CostAccountingMethod.fifo,
    );
  }

  UserSettings copyWith({
    String? baseCurrency,
    int? baseMinorFactor,
    String? themeMode,
    bool? biometricEnabled,
    CostAccountingMethod? costAccountingMethod,
  }) {
    return UserSettings(
      baseCurrency: baseCurrency ?? this.baseCurrency,
      baseMinorFactor: baseMinorFactor ?? this.baseMinorFactor,
      themeMode: themeMode ?? this.themeMode,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      costAccountingMethod: costAccountingMethod ?? this.costAccountingMethod,
    );
  }

  @override
  List<Object?> get props => [
        baseCurrency,
        baseMinorFactor,
        themeMode,
        biometricEnabled,
        costAccountingMethod,
      ];
}
