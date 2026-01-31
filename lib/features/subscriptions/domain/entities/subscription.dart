import 'package:equatable/equatable.dart';

/// Subscription represents a recurring fixed expense (e.g., Netflix, Spotify)
class Subscription extends Equatable {
  final String id;
  final String title; // "Netflix", "Spotify"
  final int amountMinor; // Amount in minor units (kuruş)
  final int renewalDay; // 1-31 (day of month)
  final String category; // e.g., "Abonelik"
  final String walletId; // Which wallet to deduct from
  final bool isActive;
  final DateTime? lastPaidDate; // When was it last paid?
  final DateTime createdAt;

  const Subscription({
    required this.id,
    required this.title,
    required this.amountMinor,
    required this.renewalDay,
    required this.category,
    required this.walletId,
    this.isActive = true,
    this.lastPaidDate,
    required this.createdAt,
  });

  /// Amount in TL (double)
  double get amount => amountMinor / 100.0;

  /// Check if subscription is due this month
  bool get isDueThisMonth {
    if (!isActive) return false;
    final now = DateTime.now();
    final thisMonthDue = DateTime(now.year, now.month, renewalDay);

    // If never paid, it's due
    if (lastPaidDate == null) return now.day >= renewalDay;

    // If last paid was before this month's due date, it's due
    return lastPaidDate!.isBefore(thisMonthDue) && now.day >= renewalDay;
  }

  /// Copy with modified fields
  Subscription copyWith({
    String? id,
    String? title,
    int? amountMinor,
    int? renewalDay,
    String? category,
    String? walletId,
    bool? isActive,
    DateTime? lastPaidDate,
    DateTime? createdAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      title: title ?? this.title,
      amountMinor: amountMinor ?? this.amountMinor,
      renewalDay: renewalDay ?? this.renewalDay,
      category: category ?? this.category,
      walletId: walletId ?? this.walletId,
      isActive: isActive ?? this.isActive,
      lastPaidDate: lastPaidDate ?? this.lastPaidDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        amountMinor,
        renewalDay,
        category,
        walletId,
        isActive,
        lastPaidDate,
        createdAt,
      ];
}
