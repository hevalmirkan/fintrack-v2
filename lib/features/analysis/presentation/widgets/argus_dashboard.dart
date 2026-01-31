import 'package:flutter/material.dart';

import '../../domain/entities/lite_argus_result.dart';
import '../../domain/services/narrative_service.dart';

/// Orion-style Argus Dashboard Widget
/// 3-Layer Layout: Headline -> Coach Voice -> Bento Grid Metrics
class ArgusDashboard extends StatelessWidget {
  final LiteArgusResult result;

  const ArgusDashboard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final narrative = const NarrativeService().generateInsight(result);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Layer 1: Headline (Score + Status Badge)
        _buildHeadlineRow(context, narrative),
        const SizedBox(height: 16),

        // Layer 2: Coach Voice Card
        _buildCoachCard(context, narrative),
        const SizedBox(height: 16),

        // Layer 3: Bento Grid Metrics
        _buildBentoGrid(context),
      ],
    );
  }

  // ============================================
  // LAYER 1: HEADLINE ROW
  // ============================================
  Widget _buildHeadlineRow(BuildContext context, ArgusNarrative narrative) {
    return Row(
      children: [
        // Big Circular Gauge
        _buildCircularGauge(context),
        const SizedBox(width: 20),

        // Status Badge + Headline
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge (Pill-shaped)
              _buildStatusBadge(narrative.status),
              const SizedBox(height: 8),

              // Headline Text
              Row(
                children: [
                  Text(
                    narrative.status.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      narrative.headline,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircularGauge(BuildContext context) {
    final score = result.overallHealth;
    final color = _getScoreColor(score);

    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Circle
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 10,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.grey.withOpacity(0.1)),
            ),
          ),
          // Progress Circle
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 10,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Score Text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toInt().toString(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              Text(
                'SKOR',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ArgusStatus status) {
    final colors = _getStatusColors(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.$1, colors.$2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: colors.$1.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: 2.5,
        ),
      ),
    );
  }

  (Color, Color) _getStatusColors(ArgusStatus status) {
    switch (status) {
      case ArgusStatus.pozitif:
        return (const Color(0xFF059669), const Color(0xFF10B981)); // Green
      case ArgusStatus.riskli:
        return (const Color(0xFFD97706), const Color(0xFFF59E0B)); // Orange
      case ArgusStatus.zayif:
        return (const Color(0xFFDC2626), const Color(0xFFEF4444)); // Red
      case ArgusStatus.notr:
        return (const Color(0xFF6B7280), const Color(0xFF9CA3AF)); // Grey
    }
  }

  // ============================================
  // LAYER 2: COACH VOICE CARD
  // ============================================
  Widget _buildCoachCard(BuildContext context, ArgusNarrative narrative) {
    final statusColors = _getStatusColors(narrative.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColors.$1.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColors.$1.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.record_voice_over,
            color: statusColors.$1,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              narrative.coachSentence,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // LAYER 3: BENTO GRID
  // ============================================
  Widget _buildBentoGrid(BuildContext context) {
    return Row(
      children: [
        // Card A: Trend
        Expanded(
          child: _buildMetricCard(
            context,
            icon: Icons.trending_up,
            label: 'Trend',
            value: result.trendScore,
            invertColor: false,
          ),
        ),
        const SizedBox(width: 8),

        // Card B: Momentum
        Expanded(
          child: _buildMetricCard(
            context,
            icon: Icons.speed,
            label: 'Momentum',
            value: result.momentumScore,
            invertColor: false,
          ),
        ),
        const SizedBox(width: 8),

        // Card C: Risk (Inverted color)
        Expanded(
          child: _buildMetricCard(
            context,
            icon: Icons.warning_amber_rounded,
            label: 'Risk',
            value: result.riskScore,
            invertColor: true,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required double value,
    required bool invertColor,
  }) {
    final color =
        invertColor ? _getInvertedScoreColor(value) : _getScoreColor(value);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          // Mini Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${value.toInt()}%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // HELPERS
  // ============================================
  Color _getScoreColor(double score) {
    if (score >= 70) return const Color(0xFF10B981); // Green
    if (score >= 50) return const Color(0xFFF59E0B); // Orange
    if (score >= 30) return const Color(0xFFF97316); // Deep Orange
    return const Color(0xFFEF4444); // Red
  }

  Color _getInvertedScoreColor(double score) {
    // For Risk: Low is good (green), High is bad (red)
    if (score <= 30) return const Color(0xFF10B981); // Green
    if (score <= 50) return const Color(0xFFF59E0B); // Orange
    if (score <= 70) return const Color(0xFFF97316); // Deep Orange
    return const Color(0xFFEF4444); // Red
  }
}

/// Skeleton/Shimmer widget for loading state
class ArgusDashboardSkeleton extends StatelessWidget {
  const ArgusDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Layer 1 Skeleton
        Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 32,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 24,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Layer 2 Skeleton
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 16),

        // Layer 3 Skeleton
        Row(
          children: List.generate(
            3,
            (index) => Expanded(
              child: Container(
                height: 100,
                margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
