import 'package:equatable/equatable.dart';
import 'participant.dart';

/// SharedExpenseGroup represents a group for tracking shared expenses
/// e.g., "Yaz Tatili", "Ev Harcamaları", "Ahmet ile Borç"
class SharedExpenseGroup extends Equatable {
  final String id;
  final String title;
  final List<Participant> participants;
  final DateTime createdAt;
  final bool isActive;

  const SharedExpenseGroup({
    required this.id,
    required this.title,
    required this.participants,
    required this.createdAt,
    this.isActive = true,
  });

  /// Get the current user participant
  Participant? get currentUser =>
      participants.where((p) => p.isCurrentUser).firstOrNull;

  /// Get participant count
  int get participantCount => participants.length;

  @override
  List<Object?> get props => [id, title, participants, createdAt, isActive];

  SharedExpenseGroup copyWith({
    String? id,
    String? title,
    List<Participant>? participants,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return SharedExpenseGroup(
      id: id ?? this.id,
      title: title ?? this.title,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
