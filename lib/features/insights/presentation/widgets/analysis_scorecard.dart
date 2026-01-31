import 'package:flutter/material.dart';

/// Argus-style analysis scorecard showing 4-quadrant financial health
class AnalysisScorecard extends StatelessWidget {
  final int overallScore;
  final int liquidityScore;
  final int debtScore;
  final int growthScore;
  final int diversificationScore;

  const AnalysisScorecard({
    super.key,
    required this.overallScore,
    required this.liquidityScore,
    required this.debtScore,
    required this.growthScore,
    required this.diversificationScore,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detaylı Analiz',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getScoreColor(overallScore),
                        _getScoreColor(overallScore).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$overallScore/100',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quadrant Metrics
            _buildMetricRow(
              context,
              'Likitide (Nakit Gücü)',
              liquidityScore,
              Icons.water_drop,
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              context,
              'Borç Yükü (Risk)',
              debtScore,
              Icons.credit_card,
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              context,
              'Büyüme (Varlık)',
              growthScore,
              Icons.trending_up,
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              context,
              'Çeşitlilik',
              diversificationScore,
              Icons.pie_chart,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context,
    String label,
    int score,
    IconData icon,
  ) {
    final color = _getScoreColor(score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Text(
              '$score',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 8,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}
