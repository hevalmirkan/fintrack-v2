import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/analysis_job.dart';
import '../../domain/entities/job_enums.dart';
import '../providers/analysis_providers.dart';

/// Screen displaying list of analysis jobs
class AnalysisJobsScreen extends ConsumerWidget {
  const AnalysisJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(analysisJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analiz Görevleri'),
      ),
      body: jobsAsync.when(
        data: (jobs) => jobs.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: jobs.length,
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  return _JobCard(job: job);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Hata: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-analysis-job'),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Görev'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 24),
          Text(
            'Henüz analiz görevi yok',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Finansal verilerinizi düzenli olarak analiz etmek için\notomatik görevler oluşturabilirsiniz',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => context.push('/add-analysis-job'),
            icon: const Icon(Icons.add),
            label: const Text('İlk Görevi Oluştur'),
          ),
        ],
      ),
    );
  }
}

class _JobCard extends ConsumerWidget {
  final AnalysisJob job;

  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd MMM HH:mm', 'tr_TR');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showJobActions(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  _StatusBadge(isActive: job.isActive),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    job.type.label,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (job.nextRun != null) ...[
                    Icon(
                      Icons.event,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Sonraki: ${dateFormat.format(job.nextRun!)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...job.scopes.map((scope) => Chip(
                        label: Text(
                          scope.label,
                          style: const TextStyle(fontSize: 11),
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJobActions(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd MMM HH:mm', 'tr_TR');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(job.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Çalışma Sıklığı: ${job.type.label}'),
            const SizedBox(height: 8),
            if (job.lastRun != null)
              Text('Son Çalışma: ${dateFormat.format(job.lastRun!)}')
            else
              const Text('Henüz çalıştırılmadı'),
            if (job.nextRun != null) ...[
              const SizedBox(height: 4),
              Text('Sonraki Çalışma: ${dateFormat.format(job.nextRun!)}'),
            ],
          ],
        ),
        actions: [
          // View Report Button (only if job has been executed)
          if (job.lastRun != null)
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);

                // Show loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Rapor yükleniyor...'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );

                try {
                  // Fetch the latest report for this job
                  final reports = await ref
                      .read(analysisJobRepositoryProvider)
                      .getReportsForJob(job.id);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();

                    if (reports.isNotEmpty) {
                      // Navigate to the most recent report
                      context.push('/analysis-report', extra: reports.first);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Rapor bulunamadı'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.assessment),
              label: const Text('Raporu Gör'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),

          const SizedBox(width: 8),

          // Run Now Button
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Show loading
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Text('Analiz başlatılıyor...'),
                    ],
                  ),
                  duration: Duration(hours: 1), // Keep until we dismiss
                ),
              );

              try {
                // Execute the job
                await ref.read(analysisJobActionsProvider).executeJob(job);

                // Refresh the jobs list to show updated status
                ref.invalidate(analysisJobsProvider);

                // Dismiss loading, show success
                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 12),
                          Text('Analiz tamamlandı!'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Şimdi Çalıştır'),
          ),
          // Close Button
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.pause_circle,
            size: 14,
            color: isActive ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Aktif' : 'Duraklatıldı',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
