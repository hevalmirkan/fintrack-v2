import 'package:equatable/equatable.dart';

/// Intent for Shadow Transaction - NO trading language
enum ShadowIntent {
  acquire, // User records intent to add to position
  reduce, // User records intent to reduce position
}

extension ShadowIntentExtension on ShadowIntent {
  String get label {
    switch (this) {
      case ShadowIntent.acquire:
        return 'Portföye Ekle';
      case ShadowIntent.reduce:
        return 'Portföyden Çıkar';
    }
  }

  String get shortLabel {
    switch (this) {
      case ShadowIntent.acquire:
        return 'Ekle';
      case ShadowIntent.reduce:
        return 'Çıkar';
    }
  }

  String get emoji {
    switch (this) {
      case ShadowIntent.acquire:
        return '📥';
      case ShadowIntent.reduce:
        return '📤';
    }
  }
}

/// Shadow Transaction - Personal Decision Log
///
/// This is NOT a trade. This is a personal record of a decision.
/// Used for:
/// - Tracking user thoughts and reasoning
/// - Historical performance analysis
/// - Learning from past decisions
class ShadowTransaction extends Equatable {
  final String id;
  final String symbol; // Asset symbol (e.g., BTC, THYAO)
  final String assetName; // Full asset name
  final ShadowIntent intent; // acquire / reduce
  final double referencePrice; // Price at time of decision
  final double amount; // Amount in asset units
  final DateTime date; // When the decision was made
  final String? note; // User's reasoning (optional)
  final Map<String, dynamic>? metadata; // Extra data (source, scores, etc.)

  const ShadowTransaction({
    required this.id,
    required this.symbol,
    required this.assetName,
    required this.intent,
    required this.referencePrice,
    required this.amount,
    required this.date,
    this.note,
    this.metadata,
  });

  /// Total value at time of decision
  double get totalValue => referencePrice * amount;

  /// Create a copy with modifications
  ShadowTransaction copyWith({
    String? id,
    String? symbol,
    String? assetName,
    ShadowIntent? intent,
    double? referencePrice,
    double? amount,
    DateTime? date,
    String? note,
    Map<String, dynamic>? metadata,
  }) {
    return ShadowTransaction(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      assetName: assetName ?? this.assetName,
      intent: intent ?? this.intent,
      referencePrice: referencePrice ?? this.referencePrice,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'assetName': assetName,
      'intent': intent.name,
      'referencePrice': referencePrice,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory ShadowTransaction.fromJson(Map<String, dynamic> json) {
    return ShadowTransaction(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      assetName: json['assetName'] as String,
      intent: ShadowIntent.values.byName(json['intent'] as String),
      referencePrice: (json['referencePrice'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props =>
      [id, symbol, intent, referencePrice, amount, date, note];
}
