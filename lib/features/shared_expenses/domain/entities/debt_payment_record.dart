import 'package:equatable/equatable.dart';

/// DebtPaymentRecord tracks payments (real or virtual) for debt resolution
/// Used for "Mark as Paid" reversibility and partial payment tracking
class DebtPaymentRecord extends Equatable {
  final String id;
  final String groupId;
  final String debtorParticipantId;
  final String creditorParticipantId;
  final int amountMinor;
  final bool isRealPayment; // true = created FinanceTransaction
  final String? transactionId; // Link to FinanceTransaction if real
  final DateTime paidAt;

  const DebtPaymentRecord({
    required this.id,
    required this.groupId,
    required this.debtorParticipantId,
    required this.creditorParticipantId,
    required this.amountMinor,
    required this.isRealPayment,
    this.transactionId,
    required this.paidAt,
  });

  /// Amount in TL for display
  double get amount => amountMinor / 100.0;

  @override
  List<Object?> get props => [
        id,
        groupId,
        debtorParticipantId,
        creditorParticipantId,
        amountMinor,
        isRealPayment,
        transactionId,
        paidAt,
      ];
}
