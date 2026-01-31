import 'package:equatable/equatable.dart';

/// SharedExpense represents a single expense within a group
/// e.g., "Akşam Yemeği" paid by "Ahmet" for 3000 TL
class SharedExpense extends Equatable {
  final String id;
  final String groupId;
  final String title;
  final int totalAmountMinor; // Amount in kuruş (minor units)
  final String paidByParticipantId; // Who paid for this expense
  final DateTime date;
  final DateTime createdAt;

  const SharedExpense({
    required this.id,
    required this.groupId,
    required this.title,
    required this.totalAmountMinor,
    required this.paidByParticipantId,
    required this.date,
    required this.createdAt,
  });

  /// Amount in TL (double) for display
  double get amount => totalAmountMinor / 100.0;

  @override
  List<Object?> get props => [
        id,
        groupId,
        title,
        totalAmountMinor,
        paidByParticipantId,
        date,
        createdAt,
      ];

  SharedExpense copyWith({
    String? id,
    String? groupId,
    String? title,
    int? totalAmountMinor,
    String? paidByParticipantId,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return SharedExpense(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      totalAmountMinor: totalAmountMinor ?? this.totalAmountMinor,
      paidByParticipantId: paidByParticipantId ?? this.paidByParticipantId,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
