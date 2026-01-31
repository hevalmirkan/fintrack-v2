import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/format_service.dart';
import '../../../../core/di/providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

import '../../../transactions/domain/entities/transaction_enums.dart';

class RecentTransactionsWidget extends ConsumerWidget {
  const RecentTransactionsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentTransactionsProvider);
    final formatService = ref.watch(formatServiceProvider);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Son Hareketler',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () => context.push('/transactions'),
                  child: const Text('Tümünü Gör'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            recentAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('Hareket yok.')),
                  );
                }
                return Column(
                  children: transactions.map((t) {
                    final isIncome = t.type == TransactionType.income;
                    final color = isIncome
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.error;
                    final prefix = isIncome ? '+' : '-';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        color: color,
                        size: 20,
                      ),
                      title: Text(t.title ?? t.assetId ?? 'İşlem'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$prefix${formatService.formatCurrency(t.totalMinor)}',
                            style: TextStyle(
                                color: color, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            DateFormat.MMMd('tr').format(t.date),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Hata: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
