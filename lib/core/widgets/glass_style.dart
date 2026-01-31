/// =====================================================
/// CARBON & MINT DESIGN SYSTEM — v1.0
/// =====================================================
/// Premium FinTech design. Gunmetal dark + Teal accents.
/// Clean, matte, high-end aesthetic.
/// =====================================================

import 'dart:ui';
import 'package:flutter/material.dart';

/// Design tokens for Carbon & Mint
class CarbonTheme {
  CarbonTheme._();

  // CARBON PALETTE (Neutral Rich Dark - NO BLUE)
  static const Color background = Color(0xFF0E1012); // Gunmetal
  static const Color surface = Color(0xFF15171A);
  static const Color surfaceLight = Color(0xFF1A1C20);
  static const Color cardGlass = Color(0x991A1C20); // 60% opacity

  // MINT PALETTE
  static const Color mint = Color(0xFF00BFA5); // Primary accent
  static const Color mintLight = Color(0xFF64FFDA);
  static const Color blueGrey = Color(0xFFCFD8DC);

  // STATUS
  static const Color positive = Color(0xFF00C853);
  static const Color negative = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFB74D);

  // TEXT
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textMuted = Color(0xFF6B7280);

  // GLASS
  static const Color glassBorder = Color(0x14FFFFFF);
  static const Color glassHighlight = Color(0x08FFFFFF);
  static const double glassBlur = 10.0;
  static const double glassRadius = 20.0;
}

/// Premium Carbon Glass Card
class CarbonGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? borderRadius;
  final bool enableBlur;
  final bool isHero;

  const CarbonGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.enableBlur = true,
    this.isHero = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? CarbonTheme.glassRadius;

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CarbonTheme.cardGlass,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: CarbonTheme.glassBorder),
      ),
      child: child,
    );

    if (enableBlur) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: CarbonTheme.glassBlur,
            sigmaY: CarbonTheme.glassBlur,
          ),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Carbon background with subtle ambient light
class CarbonBackground extends StatelessWidget {
  final Widget child;

  const CarbonBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CarbonTheme.background,
      ),
      child: Stack(
        children: [
          // Subtle white ambient light (top-right)
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.03),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Content
          child,
        ],
      ),
    );
  }
}

/// Mint accent text (for hero labels)
class MintLabel extends StatelessWidget {
  final String text;
  final double? fontSize;

  const MintLabel(this.text, {super.key, this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: CarbonTheme.mint,
        fontSize: fontSize ?? 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Change badge with Carbon styling
class CarbonChangeBadge extends StatelessWidget {
  final double percentage;

  const CarbonChangeBadge({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    final isPositive = percentage >= 0;
    final color = isPositive ? CarbonTheme.positive : CarbonTheme.negative;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${percentage.toStringAsFixed(2)}%',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat tile for dashboard
class CarbonStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final bool isPositive;

  const CarbonStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CarbonTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CarbonTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor ?? CarbonTheme.blueGrey,
            size: 20,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color:
                  isPositive ? CarbonTheme.textPrimary : CarbonTheme.negative,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: CarbonTheme.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
