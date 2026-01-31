import 'package:equatable/equatable.dart';

/// Participant in a shared expense group
class Participant extends Equatable {
  final String id;
  final String name;
  final bool isCurrentUser; // True if this is the device owner

  const Participant({
    required this.id,
    required this.name,
    this.isCurrentUser = false,
  });

  @override
  List<Object?> get props => [id, name, isCurrentUser];

  Participant copyWith({
    String? id,
    String? name,
    bool? isCurrentUser,
  }) {
    return Participant(
      id: id ?? this.id,
      name: name ?? this.name,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isCurrentUser': isCurrentUser,
      };

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
        id: json['id'] as String,
        name: json['name'] as String,
        isCurrentUser: json['isCurrentUser'] as bool? ?? false,
      );
}
