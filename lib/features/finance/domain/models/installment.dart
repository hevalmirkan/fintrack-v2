import 'package:equatable/equatable.dart';

/// Installment - Represents a recurring payment plan
///
/// Used for tracking credit card installments, loans, subscriptions
class Installment extends Equatable {
  final String id;
  final String walletId;
  final String title;
  final String? description;
  final int totalAmountMinor; // Total amount in minor units
  final int monthlyAmountMinor; // Monthly payment
  final int totalInstallments; // Total number of payments
  final int paidInstallments; // Number of payments made
  final DateTime startDate;
  final DateTime? endDate;
  final int paymentDayOfMonth; // Day of month for payment (1-28)
  final InstallmentType type;
  final String? category;
  final bool isActive;
  final DateTime createdAt;

  const Installment({
    required this.id,
    required this.walletId,
    required this.title,
    this.description,
    required this.totalAmountMinor,
    required this.monthlyAmountMinor,
    required this.totalInstallments,
    this.paidInstallments = 0,
    required this.startDate,
    this.endDate,
    this.paymentDayOfMonth = 1,
    required this.type,
    this.category,
    this.isActive = true,
    required this.createdAt,
  });

  /// Total amount in major units
  double get totalAmount => totalAmountMinor / 100;

  /// Monthly amount in major units
  double get monthlyAmount => monthlyAmountMinor / 100;

  /// Remaining installments
  int get remainingInstallments => totalInstallments - paidInstallments;

  /// Remaining amount in major units
  double get remainingAmount => remainingInstallments * monthlyAmount;

  /// Progress percentage (0-100)
  double get progressPercent =>
      totalInstallments > 0 ? (paidInstallments / totalInstallments) * 100 : 0;

  /// Is completed
  bool get isCompleted => paidInstallments >= totalInstallments;

  /// Next payment date
  DateTime? get nextPaymentDate {
    if (isCompleted) return null;

    final now = DateTime.now();
    var nextDate = DateTime(
      now.year,
      now.month,
      paymentDayOfMonth,
    );

    // If payment day already passed this month, move to next month
    if (now.day > paymentDayOfMonth) {
      nextDate = DateTime(
        now.year,
        now.month + 1,
        paymentDayOfMonth,
      );
    }

    return nextDate;
  }

  Installment copyWith({
    String? id,
    String? walletId,
    String? title,
    String? description,
    int? totalAmountMinor,
    int? monthlyAmountMinor,
    int? totalInstallments,
    int? paidInstallments,
    DateTime? startDate,
    DateTime? endDate,
    int? paymentDayOfMonth,
    InstallmentType? type,
    String? category,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Installment(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      title: title ?? this.title,
      description: description ?? this.description,
      totalAmountMinor: totalAmountMinor ?? this.totalAmountMinor,
      monthlyAmountMinor: monthlyAmountMinor ?? this.monthlyAmountMinor,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      paidInstallments: paidInstallments ?? this.paidInstallments,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      paymentDayOfMonth: paymentDayOfMonth ?? this.paymentDayOfMonth,
      type: type ?? this.type,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'walletId': walletId,
        'title': title,
        'description': description,
        'totalAmountMinor': totalAmountMinor,
        'monthlyAmountMinor': monthlyAmountMinor,
        'totalInstallments': totalInstallments,
        'paidInstallments': paidInstallments,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'paymentDayOfMonth': paymentDayOfMonth,
        'type': type.name,
        'category': category,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Installment.fromJson(Map<String, dynamic> json) {
    return Installment(
      id: json['id'] as String,
      walletId: json['walletId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      totalAmountMinor: json['totalAmountMinor'] as int,
      monthlyAmountMinor: json['monthlyAmountMinor'] as int,
      totalInstallments: json['totalInstallments'] as int,
      paidInstallments: json['paidInstallments'] as int? ?? 0,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      paymentDayOfMonth: json['paymentDayOfMonth'] as int? ?? 1,
      type: InstallmentType.values.byName(json['type'] as String),
      category: json['category'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        walletId,
        title,
        description,
        totalAmountMinor,
        monthlyAmountMinor,
        totalInstallments,
        paidInstallments,
        startDate,
        endDate,
        paymentDayOfMonth,
        type,
        category,
        isActive,
        createdAt
      ];
}

/// Types of installments
enum InstallmentType {
  creditCard,
  loan,
  subscription,
  other,
}

extension InstallmentTypeExtension on InstallmentType {
  String get displayName {
    switch (this) {
      case InstallmentType.creditCard:
        return 'Kredi Kartı Taksiti';
      case InstallmentType.loan:
        return 'Kredi';
      case InstallmentType.subscription:
        return 'Abonelik';
      case InstallmentType.other:
        return 'Diğer';
    }
  }

  String get icon {
    switch (this) {
      case InstallmentType.creditCard:
        return '💳';
      case InstallmentType.loan:
        return '🏦';
      case InstallmentType.subscription:
        return '🔄';
      case InstallmentType.other:
        return '📋';
    }
  }
}
