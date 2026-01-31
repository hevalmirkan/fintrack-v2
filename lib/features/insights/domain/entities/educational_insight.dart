import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'financial_health_score.dart';

/// Educational insight with personalized financial coaching
class EducationalInsight extends Equatable {
  final String headline;
  final String explanation;
  final String financialTerm;
  final InsightType type;
  final IconData icon;

  const EducationalInsight({
    required this.headline,
    required this.explanation,
    required this.financialTerm,
    required this.type,
    required this.icon,
  });

  @override
  List<Object?> get props => [headline, explanation, financialTerm, type, icon];
}
