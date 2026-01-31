import 'transaction_enums.dart';

class TransactionEntity {
  final String id;
  final String? assetId; // Nullable for income/expense
  final String? title; // For income/expense
  final String? category; // For income/expense

  final int quantityMinor;
  final int pricePerUnitMinor;
  final int feeMinor;
  final int totalMinor;

  final DateTime date;
  final TransactionType type;
  final Map<String, dynamic>? metadata;

  const TransactionEntity({
    required this.id,
    this.assetId,
    this.title,
    this.category,
    this.quantityMinor = 0,
    this.pricePerUnitMinor = 0,
    this.feeMinor = 0,
    required this.totalMinor,
    required this.date,
    required this.type,
    this.metadata,
  });
}
