import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Represents a financial health score with insights
class FinancialHealthScore extends Equatable {
  final int score; // 0-100
  final String label; // "Mükemmel", "İyi", "Orta", "Riskli", "Tehlikeli"
  final Color color; // Visual indicator color
  final List<Insight> insights; // Generated insights

  const FinancialHealthScore({
    required this.score,
    required this.label,
    required this.color,
    required this.insights,
  });

  const FinancialHealthScore.empty()
      : score = 0,
        label = 'Hesaplanıyor',
        color = Colors.grey,
        insights = const [];

  @override
  List<Object?> get props => [score, label, color, insights];
}

/// Individual insight/tip for the user
class Insight extends Equatable {
  final String title;
  final String message;
  final InsightType type;
  final IconData icon;

  const Insight({
    required this.title,
    required this.message,
    required this.type,
    required this.icon,
  });

  @override
  List<Object?> get props => [title, message, type, icon];
}

enum InsightType {
  warning, // Red, urgent
  caution, // Yellow, be careful
  info, // Blue, neutral
  tip, // Green, positive suggestion
  success, // Green, good job
}
