import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/format_service.dart';
import '../../domain/entities/educational_insight.dart';
import '../../domain/entities/financial_health_score.dart';
import '../../domain/entities/financial_term.dart';
import '../helpers/financial_term_helper.dart';
import '../providers/insights_providers.dart';
import '../widgets/analysis_scorecard.dart';
import '../widgets/daily_term_card.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthScoreAsync = ref.watch(financialHealthScoreProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finansal Analiz'),
        centerTitle: true,
        actions: [
          // Market Board Button
          IconButton(
            icon: const Icon(Icons.candlestick_chart),
            tooltip: 'Piyasa Ekranı',
            onPressed: () => context.push('/market-board'),
          ),
        ],
      ),
      body: healthScoreAsync.when(
        data: (healthScore) => _buildContent(context, healthScore),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Text(
            'Analiz yüklenemedi: $e',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, FinancialHealthScore healthScore) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: Consumer(
        builder: (context, ref, _) {
          final dailyTerm = ref.watch(dailyFinancialTermProvider);
          final scorecardAsync = ref.watch(scorecardMetricsProvider);
          final educationalInsightsAsync =
              ref.watch(educationalInsightsProvider);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Daily Financial Term (NEW!)
              _buildDailyTermCard(dailyTerm),
              const SizedBox(height: 24),

              // Analysis Jobs Card (NEW!)
              _buildAnalysisJobsCard(context),
              const SizedBox(height: 24),

              // Health Score Gauge
              _HealthScoreGauge(
                score: healthScore.score,
                label: healthScore.label,
                color: healthScore.color,
              ),
              const SizedBox(height: 24),

              // Analysis Scorecard (NEW!)
              scorecardAsync.when(
                data: (metrics) => _buildAnalysisScorecard(metrics),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 32),

              // Market Ticker Section
              _buildSectionTitle(context, '📊 Piyasa Durumu'),
              const SizedBox(height: 12),
              const _MarketTickerCarousel(),
              const SizedBox(height: 32),

              // Educational Insights (NEW!)
              _buildSectionTitle(context, '💡 Finansal Koçun'),
              const SizedBox(height: 12),
              educationalInsightsAsync.when(
                data: (insights) => Column(
                  children: insights
                      .map((insight) =>
                          _EducationalInsightCard(insight: insight))
                      .toList(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildDailyTermCard(FinancialTerm term) {
    return DailyTermCard(term: term);
  }

  Widget _buildAnalysisScorecard(Map<String, int> metrics) {
    return AnalysisScorecard(
      overallScore: metrics['overall']!,
      liquidityScore: metrics['liquidity']!,
      debtScore: metrics['debt']!,
      growthScore: metrics['growth']!,
      diversificationScore: metrics['diversification']!,
    );
  }

  Widget _buildAnalysisJobsCard(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/analysis-jobs'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.15),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.auto_graph,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analiz Görevleri',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Otomatik analizler planla ve yönet',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular Health Score Gauge Widget
class _HealthScoreGauge extends StatelessWidget {
  final int score;
  final String label;
  final Color color;

  const _HealthScoreGauge({
    required this.score,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(
            'Finansal Sağlık Skoru',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 24),
          // Circular Progress Gauge
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: _CircularGaugePainter(
                score: score,
                color: color,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      score.toString(),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                    ),
                    Text(
                      '/ 100',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Painter for Circular Gauge
class _CircularGaugePainter extends CustomPainter {
  final int score;
  final Color color;

  _CircularGaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background arc
    final backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.75,
      pi * 1.5,
      false,
      backgroundPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.7), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (score / 100) * pi * 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.75,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Market Ticker Carousel
class _MarketTickerCarousel extends StatelessWidget {
  const _MarketTickerCarousel();

  @override
  Widget build(BuildContext context) {
    // Mock data - in real app, fetch from MarketPriceRepository
    final tickers = [
      {
        'symbol': 'BTC',
        'price': '\$95,234',
        'change': '+2.3%',
        'positive': true
      },
      {
        'symbol': 'ETH',
        'price': '\$3,456',
        'change': '+1.8%',
        'positive': true
      },
      {'symbol': 'USD', 'price': '₺34.20', 'change': '+0.5%', 'positive': true},
      {
        'symbol': 'EUR',
        'price': '₺37.45',
        'change': '-0.2%',
        'positive': false
      },
      {
        'symbol': 'XAU',
        'price': '\$2,050',
        'change': '+0.8%',
        'positive': true
      },
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tickers.length,
        itemBuilder: (context, index) {
          final ticker = tickers[index];
          return _TickerCard(
            symbol: ticker['symbol'] as String,
            price: ticker['price'] as String,
            change: ticker['change'] as String,
            isPositive: ticker['positive'] as bool,
          );
        },
      ),
    );
  }
}

class _TickerCard extends StatelessWidget {
  final String symbol;
  final String price;
  final String change;
  final bool isPositive;

  const _TickerCard({
    required this.symbol,
    required this.price,
    required this.change,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPositive
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            symbol,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            price,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            change,
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Educational Insight Card (NEW!)
class _EducationalInsightCard extends StatelessWidget {
  final EducationalInsight insight;

  const _EducationalInsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final color = _getColorForType(insight.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(insight.icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  insight.headline,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Explanation
          Text(
            insight.explanation,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
          ),
          const SizedBox(height: 12),

          // Financial term badge (NOW TAPPABLE!)
          InkWell(
            onTap: () {
              // Look up and show term details
              _showTermDetail(context, insight.financialTerm);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    insight.financialTerm,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.info_outline, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForType(InsightType type) {
    switch (type) {
      case InsightType.success:
        return Colors.green;
      case InsightType.warning:
        return Colors.orange;
      case InsightType.info:
        return Colors.blue;
      case InsightType.tip:
        return Colors.purple;
      case InsightType.caution:
        return Colors.red;
    }
  }

  void _showTermDetail(BuildContext context, String termName) {
    FinancialTermHelper.showTermByName(context, termName);
  }
}

/// Insight Card Widget
class _InsightCard extends StatelessWidget {
  final Insight insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final color = _getColorForType(insight.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            insight.icon,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForType(InsightType type) {
    switch (type) {
      case InsightType.warning:
        return Colors.red;
      case InsightType.caution:
        return Colors.orange;
      case InsightType.info:
        return Colors.blue;
      case InsightType.tip:
        return Colors.purple;
      case InsightType.success:
        return Colors.green;
    }
  }
}
