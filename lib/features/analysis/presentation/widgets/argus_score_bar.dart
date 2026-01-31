import 'package:flutter/material.dart';

/// Horizontal score bar widget for trend, momentum, and risk
class ArgusScoreBar extends StatelessWidget {
  final String label;
  final double score;
  final bool isRisk; // If true, reverses color logic (high score = red)

  const ArgusScoreBar({
    super.key,
    required this.label,
    required this.score,
    this.isRisk = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final valueLabel = _getValueLabel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              valueLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // Background
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Progress
              FractionallySizedBox(
                widthFactor: (score / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getColor() {
    if (isRisk) {
      // Risk: High score = Red (bad)
      if (score >= 70) return Colors.red;
      if (score >= 40) return Colors.orange;
      return Colors.green;
    } else {
      // Normal: High score = Green (good)
      if (score >= 70) return Colors.green;
      if (score >= 40) return Colors.orange;
      return Colors.red;
    }
  }

  String _getValueLabel() {
    final value = score.toInt();
    if (isRisk) {
      if (value >= 70) return 'Yüksek ($value/100)';
      if (value >= 40) return 'Orta ($value/100)';
      return 'Düşük ($value/100)';
    } else {
      if (value >= 70) return 'Güçlü ($value/100)';
      if (value >= 40) return 'Nötr ($value/100)';
      return 'Zayıf ($value/100)';
    }
  }
}
