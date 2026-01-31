import 'package:equatable/equatable.dart';

/// Financial term with definition and practical example
class FinancialTerm extends Equatable {
  final String title;
  final String definition;
  final String example;
  final String category; // "Yatırım", "Borç", "Bütçe", etc.

  const FinancialTerm({
    required this.title,
    required this.definition,
    required this.example,
    required this.category,
  });

  @override
  List<Object?> get props => [title, definition, example, category];
}
