/// =====================================================
/// FINANCIAL GOAL MODEL — Phase 8
/// =====================================================
/// Virtual financial goals for motivation tracking.
/// Goals do NOT deduct money from real wallets.
/// =====================================================

import 'package:uuid/uuid.dart';

/// A virtual financial goal for savings motivation
class FinancialGoal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final String icon; // Emoji like "🚗", "💻", "🏠"
  final int colorValue; // Color as int
  final bool isCompleted;
  final DateTime createdAt;

  FinancialGoal({
    String? id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
    this.targetDate,
    this.icon = '🎯',
    this.colorValue = 0xFF6366F1, // Default indigo
    this.isCompleted = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Progress percentage (0-100)
  double get progressPercent {
    if (targetAmount <= 0) return 0;
    return ((currentAmount / targetAmount) * 100).clamp(0, 100);
  }

  /// Remaining amount to reach goal
  double get remainingAmount =>
      (targetAmount - currentAmount).clamp(0, double.infinity);

  /// Check if goal is achieved
  bool get isAchieved => currentAmount >= targetAmount;

  /// Calculate estimated completion date based on savings rate
  DateTime? estimateCompletionDate() {
    if (currentAmount <= 0 || isAchieved) return null;

    final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
    if (daysSinceCreation < 1) return null;

    final dailyRate = currentAmount / daysSinceCreation;
    if (dailyRate <= 0) return null;

    final daysRemaining = (remainingAmount / dailyRate).ceil();
    return DateTime.now().add(Duration(days: daysRemaining));
  }

  /// Get estimated months until completion
  int? estimateMonthsRemaining() {
    final estDate = estimateCompletionDate();
    if (estDate == null) return null;

    final daysRemaining = estDate.difference(DateTime.now()).inDays;
    return (daysRemaining / 30).ceil();
  }

  /// Create a copy with updated fields
  FinancialGoal copyWith({
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? icon,
    int? colorValue,
    bool? isCompleted,
  }) {
    return FinancialGoal(
      id: id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'targetDate': targetDate?.toIso8601String(),
        'icon': icon,
        'colorValue': colorValue,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Create from JSON
  factory FinancialGoal.fromJson(Map<String, dynamic> json) => FinancialGoal(
        id: json['id'] as String,
        title: json['title'] as String,
        targetAmount: (json['targetAmount'] as num).toDouble(),
        currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0,
        targetDate: json['targetDate'] != null
            ? DateTime.tryParse(json['targetDate'] as String)
            : null,
        icon: json['icon'] as String? ?? '🎯',
        colorValue: json['colorValue'] as int? ?? 0xFF6366F1,
        isCompleted: json['isCompleted'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );
}

/// Preset goal templates for quick creation
class GoalPresets {
  static List<Map<String, dynamic>> get presets => [
        {'title': 'Acil Durum Fonu', 'icon': '🆘', 'color': 0xFFEF4444},
        {'title': 'Tatil', 'icon': '✈️', 'color': 0xFF3B82F6},
        {'title': 'Yeni Araba', 'icon': '🚗', 'color': 0xFF10B981},
        {'title': 'Ev', 'icon': '🏠', 'color': 0xFFF59E0B},
        {'title': 'Laptop / Teknoloji', 'icon': '💻', 'color': 0xFF8B5CF6},
        {'title': 'Eğitim', 'icon': '📚', 'color': 0xFF06B6D4},
        {'title': 'Düğün', 'icon': '💒', 'color': 0xFFEC4899},
        {'title': 'Yatırım Sermayesi', 'icon': '📈', 'color': 0xFF22C55E},
      ];
}
