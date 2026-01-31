import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../installments/presentation/providers/mock_installment_provider.dart';
import '../../../subscriptions/presentation/providers/subscription_provider.dart';

/// Widget showing future monthly obligations on dashboard
/// Combines: Active Installment Monthly Amounts + Active Subscription Amounts
class FutureObligationsWidget extends ConsumerWidget {
  const FutureObligationsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch installment provider
    final installmentState = ref.watch(mockInstallmentProvider);
    final installmentMonthly = installmentState.totalMonthlyAmount;

    // Watch subscription provider
    final subscriptionState = ref.watch(subscriptionProvider);
    final subscriptionMonthly = subscriptionState.totalMonthlyAmount;

    // Total future obligations
    final totalMonthly = installmentMonthly + subscriptionMonthly;
    final totalFormatted = CurrencyFormatter.formatFromMinorShort(totalMonthly);

    // Counts
    final installmentCount = installmentState.activeCount;
    final subscriptionCount = subscriptionState.activeCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6200EA).withOpacity(0.2),
            const Color(0xFF3700B3).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6200EA).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6200EA).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: Color(0xFF6200EA),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gelecek Ay Sabit Giderler',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      'Taksit + Abonelik',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
              // Total Amount
              Text(
                totalFormatted,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Breakdown Row
          Row(
            children: [
              // Installments
              Expanded(
                child: _buildBreakdownItem(
                  icon: Icons.credit_card,
                  label: 'Taksitler',
                  amount: installmentMonthly,
                  count: installmentCount,
                  color: const Color(0xFF00D09C),
                ),
              ),
              const SizedBox(width: 12),
              // Subscriptions
              Expanded(
                child: _buildBreakdownItem(
                  icon: Icons.subscriptions,
                  label: 'Abonelikler',
                  amount: subscriptionMonthly,
                  count: subscriptionCount,
                  color: const Color(0xFFFF6B6B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem({
    required IconData icon,
    required String label,
    required int amount,
    required int count,
    required Color color,
  }) {
    final formatted = CurrencyFormatter.formatFromMinorShort(amount);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2230),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatted,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            '$count aktif',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
