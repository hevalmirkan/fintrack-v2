import 'package:equatable/equatable.dart';

/// Wallet - Represents a user's financial account
///
/// Can be a bank account, cash wallet, or digital wallet
class Wallet extends Equatable {
  final String id;
  final String name;
  final WalletType type;
  final String currency;
  final int balanceMinor; // Balance in minor units (kuruş for TL)
  final String? iconName;
  final String? color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    this.currency = 'TRY',
    required this.balanceMinor,
    this.iconName,
    this.color,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// Balance in major units (TL, USD, etc.)
  double get balance => balanceMinor / 100;

  /// Display balance with currency symbol
  String get displayBalance {
    final symbol = currencySymbol;
    return '$symbol${balance.toStringAsFixed(2)}';
  }

  /// Currency symbol
  String get currencySymbol {
    switch (currency) {
      case 'TRY':
        return '₺';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return currency;
    }
  }

  Wallet copyWith({
    String? id,
    String? name,
    WalletType? type,
    String? currency,
    int? balanceMinor,
    String? iconName,
    String? color,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      balanceMinor: balanceMinor ?? this.balanceMinor,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'currency': currency,
        'balanceMinor': balanceMinor,
        'iconName': iconName,
        'color': color,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      name: json['name'] as String,
      type: WalletType.values.byName(json['type'] as String),
      currency: json['currency'] as String? ?? 'TRY',
      balanceMinor: json['balanceMinor'] as int,
      iconName: json['iconName'] as String?,
      color: json['color'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        currency,
        balanceMinor,
        iconName,
        color,
        isActive,
        createdAt,
        updatedAt
      ];
}

/// Types of wallets
enum WalletType {
  cash,
  bankAccount,
  creditCard,
  digitalWallet,
  savings,
  investment,
}

extension WalletTypeExtension on WalletType {
  String get displayName {
    switch (this) {
      case WalletType.cash:
        return 'Nakit';
      case WalletType.bankAccount:
        return 'Banka Hesabı';
      case WalletType.creditCard:
        return 'Kredi Kartı';
      case WalletType.digitalWallet:
        return 'Dijital Cüzdan';
      case WalletType.savings:
        return 'Birikim';
      case WalletType.investment:
        return 'Yatırım';
    }
  }

  String get icon {
    switch (this) {
      case WalletType.cash:
        return '💵';
      case WalletType.bankAccount:
        return '🏦';
      case WalletType.creditCard:
        return '💳';
      case WalletType.digitalWallet:
        return '📱';
      case WalletType.savings:
        return '🐷';
      case WalletType.investment:
        return '📈';
    }
  }
}
