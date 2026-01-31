import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../data/services/statistics_service.dart';

/// Pie chart widget showing expense breakdown by category for current month
class ExpensePieChart extends StatelessWidget {
  final List<CategoryData> data;

  const ExpensePieChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    // Empty state
    if (data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Bu ay için gider verisi yok.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate total
    final total = data.fold<double>(0, (sum, item) => sum + item.totalAmount);
    final formatter =
        NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

    return Column(
      children: [
        // Pie Chart with center text
        SizedBox(
          height: 250,
          child: Stack(
            children: [
              PieChart(
                PieChartData(
                  sections: data.map((item) {
                    return PieChartSectionData(
                      value: item.totalAmount,
                      title: '${item.percentage.toStringAsFixed(0)}%',
                      color: item.color,
                      radius: 100,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                ),
              ),
              // Center text
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Toplam Gider',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatter.format(total),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: data.map((item) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${item.categoryName} (${item.percentage.toStringAsFixed(0)}%)',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Educational helper text
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bu grafik yalnızca bu ayki GİDERLERİ gösterir. Yatırımlar dahil değildir.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
