import 'package:equatable/equatable.dart';

enum InstallmentPaymentType {
  payNow,
  markAsPaid,
}

class Installment extends Equatable {
  final String id;
  final String title;
  final int totalAmount; // Minor units
  final int remainingAmount; // Minor units
  final int totalInstallments;
  final int paidInstallments;
  final int amountPerInstallment; // Minor units (base amount)
  final DateTime startDate;
  final DateTime nextDueDate;

  const Installment({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.remainingAmount,
    required this.totalInstallments,
    required this.paidInstallments,
    required this.amountPerInstallment,
    required this.startDate,
    required this.nextDueDate,
  });

  // ========== DERIVED GETTERS (NOT STORED) ==========

  /// Monthly amount in minor units (DERIVED from totalAmount / totalInstallments)
  int get monthlyAmount =>
      totalInstallments > 0 ? (totalAmount / totalInstallments).round() : 0;

  /// Progress as percentage (0.0 to 1.0)
  double get progress =>
      totalInstallments > 0 ? paidInstallments / totalInstallments : 0.0;

  /// Remaining installments count
  int get remainingInstallments => totalInstallments - paidInstallments;

  /// Is fully paid?
  bool get isFullyPaid => paidInstallments >= totalInstallments;

  /// Is active (not fully paid)?
  bool get isActive => !isFullyPaid;

  @override
  List<Object?> get props => [
        id,
        title,
        totalAmount,
        remainingAmount,
        totalInstallments,
        paidInstallments,
        amountPerInstallment,
        startDate,
        nextDueDate,
      ];
}
