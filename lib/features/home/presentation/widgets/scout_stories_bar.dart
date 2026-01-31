import 'package:flutter/material.dart';

import '../../../analysis/domain/services/scout_service.dart';
import '../../../shadow/presentation/widgets/add_transaction_sheet.dart';

/// Scout Stories Bar - Personal Market Radar UI
///
/// Instagram-style horizontal scrollable bar
/// Ring colors indicate signal type:
/// - Green: Portfolio / Strong Trend
/// - Purple: High Momentum
/// - Orange: High Risk
/// - Blue: Watchlist
class ScoutStoriesBar extends StatelessWidget {
  final List<ScoutResult> results;
  final Function(ScoutResult)? onTap;

  const ScoutStoriesBar({
    super.key,
    required this.results,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return _buildEmptyState(context);
    }

    return Container(
      height: 130,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.radar, size: 16, color: Color(0xFF00D09C)),
                const SizedBox(width: 6),
                Text(
                  'Radar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D09C).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${results.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00D09C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: results.length,
              itemBuilder: (context, index) => _ScoutStoryItem(
                result: results[index],
                onTap: () {
                  if (onTap != null) {
                    onTap!(results[index]);
                  } else {
                    _showCouncilSheet(context, results[index]);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.nights_stay_outlined,
                size: 18, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Text(
              'Piyasa şu an sakin',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCouncilSheet(BuildContext context, ScoutResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CouncilBottomSheet(result: result),
    );
  }
}

class _ScoutStoryItem extends StatefulWidget {
  final ScoutResult result;
  final VoidCallback onTap;

  const _ScoutStoryItem({
    required this.result,
    required this.onTap,
  });

  @override
  State<_ScoutStoryItem> createState() => _ScoutStoryItemState();
}

class _ScoutStoryItemState extends State<_ScoutStoryItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.result.shouldPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: 68,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale:
                        widget.result.shouldPulse ? _pulseAnimation.value : 1.0,
                    child: child,
                  );
                },
                child: _buildAvatar(),
              ),
              const SizedBox(height: 6),
              Text(
                widget.result.asset.symbol,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.result.isUserAsset
                      ? const Color(0xFF00D09C)
                      : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                widget.result.label,
                style: TextStyle(
                  fontSize: 9,
                  color: widget.result.ringColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            widget.result.ringColor,
            widget.result.ringColor.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.result.ringColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.result.ringColor.withOpacity(0.1),
          ),
          child: Center(
            child: Text(
              _getAssetEmoji(widget.result.asset.symbol),
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
      ),
    );
  }

  String _getAssetEmoji(String symbol) {
    switch (symbol.toUpperCase()) {
      case 'BTC':
        return '₿';
      case 'ETH':
        return 'Ξ';
      case 'SOL':
        return '◎';
      case 'XRP':
        return '✕';
      case 'DOGE':
        return '🐕';
      case 'ADA':
        return '₳';
      case 'BNB':
        return '◆';
      case 'AVAX':
        return '🔺';
      case 'DOT':
        return '●';
      case 'LINK':
        return '⬡';
      case 'THYAO':
        return '✈️';
      case 'GARAN':
        return '🏦';
      case 'AKBNK':
        return '🏛️';
      case 'SAHOL':
        return '🏢';
      case 'ASELS':
        return '🛡️';
      case 'EREGL':
        return '⚙️';
      case 'KCHOL':
        return '🏗️';
      case 'TUPRS':
        return '🛢️';
      case 'ISCTR':
        return '🏦';
      case 'SISE':
        return '🏭';
      case 'XAU':
        return '🥇';
      case 'XAG':
        return '🥈';
      case 'OIL':
        return '🛢️';
      default:
        return '📈';
    }
  }
}

/// Council Bottom Sheet - Detailed analysis view
class _CouncilBottomSheet extends StatelessWidget {
  final ScoutResult result;

  const _CouncilBottomSheet({required this.result});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHandle(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 20),
                      _buildBentoGrid(context),
                      const SizedBox(height: 20),
                      _buildNarrativeCard(context),
                      const SizedBox(height: 20),
                      _buildCtaButton(context),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                result.ringColor,
                result.ringColor.withOpacity(0.6),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: result.ringColor.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              result.narrative.emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    result.asset.symbol,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: result.ringColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      result.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: result.ringColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                result.asset.name,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              if (result.lastPrice != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatPrice(result.lastPrice!),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (result.changePercent != null) ...[
                      const SizedBox(width: 8),
                      _buildChangeChip(result.changePercent!),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChangeChip(double change) {
    final isPositive = change >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPositive
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isPositive ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  Widget _buildBentoGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BentoTile(
            label: 'Trend',
            value: result.argusData.trendScore,
            icon: Icons.trending_up,
            color: _getTrendColor(result.argusData.trendScore),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _BentoTile(
            label: 'Momentum',
            value: result.argusData.momentumScore,
            icon: Icons.speed,
            color: _getMomentumColor(result.argusData.momentumScore),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _BentoTile(
            label: 'Risk',
            value: result.argusData.riskScore,
            icon: Icons.warning_amber,
            color: _getRiskColor(result.argusData.riskScore),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrativeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            result.ringColor.withOpacity(0.08),
            result.ringColor.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: result.ringColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: result.ringColor),
              const SizedBox(width: 8),
              Text(
                'Konsey Görüşü',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.narrative.headline,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: result.ringColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.narrative.body,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return '\$${price.toStringAsFixed(0)}';
    } else if (price >= 1) {
      return '\$${price.toStringAsFixed(2)}';
    } else {
      return '\$${price.toStringAsFixed(4)}';
    }
  }

  Color _getTrendColor(int score) {
    if (score >= 65) return const Color(0xFF00D09C);
    if (score >= 45) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Color _getMomentumColor(int score) {
    if (score >= 70) return const Color(0xFF7C3AED);
    if (score >= 50) return const Color(0xFF3B82F6);
    return const Color(0xFF6B7280);
  }

  Color _getRiskColor(int score) {
    if (score >= 70) return const Color(0xFFEF4444);
    if (score >= 45) return const Color(0xFFF59E0B);
    return const Color(0xFF00D09C);
  }

  Widget _buildCtaButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          // Close this sheet first
          Navigator.of(context).pop();
          // Open the AddTransactionSheet
          AddTransactionSheet.show(
            context,
            symbol: result.asset.symbol,
            assetName: result.asset.name,
            currentPrice: result.lastPrice ?? 0,
          );
        },
        icon: const Icon(Icons.edit_note, size: 22),
        label: const Text(
          'Portföye İşle',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00D09C),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class _BentoTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _BentoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
