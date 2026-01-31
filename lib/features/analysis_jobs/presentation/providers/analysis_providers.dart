import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/analysis_job_repository.dart';
import '../../data/services/analysis_job_runner.dart';
import '../../domain/entities/analysis_job.dart';
import '../../domain/entities/analysis_report.dart';
import '../../../assets/domain/repositories/i_asset_repository.dart';
import '../../../transactions/domain/repositories/i_transaction_repository.dart';
import '../../../insights/domain/services/financial_health_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/di/providers.dart';

// Repository Provider
final analysisJobRepositoryProvider = Provider((ref) {
  return AnalysisJobRepository();
});

// Job Runner Provider
final analysisJobRunnerProvider = Provider((ref) {
  return AnalysisJobRunner(
    assetRepository: ref.watch(assetRepositoryProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
    healthService: FinancialHealthService(
      assetRepository: ref.watch(assetRepositoryProvider),
      transactionRepository: ref.watch(transactionRepositoryProvider),
      installmentRepository: ref.watch(installmentRepositoryProvider),
    ),
  );
});

// Jobs Stream Provider
final analysisJobsProvider = StreamProvider<List<AnalysisJob>>((ref) {
  final repository = ref.watch(analysisJobRepositoryProvider);

  return repository.getJobsStream().handleError((error) {
    print('Error loading jobs: $error');
    return <AnalysisJob>[];
  });
});

// Reports Provider (all reports)
final allReportsProvider = FutureProvider<List<AnalysisReport>>((ref) {
  final repository = ref.watch(analysisJobRepositoryProvider);
  return repository.getAllReports();
});

// Reports for specific job
final jobReportsProvider =
    FutureProvider.family<List<AnalysisReport>, String>((ref, jobId) {
  final repository = ref.watch(analysisJobRepositoryProvider);
  return repository.getReportsForJob(jobId);
});

// Job Actions Provider
final analysisJobActionsProvider = Provider((ref) {
  return AnalysisJobActions(ref);
});

/// Actions for managing analysis jobs
class AnalysisJobActions {
  final Ref _ref;

  AnalysisJobActions(this._ref);

  /// Create a new job
  Future<void> createJob(AnalysisJob job) async {
    final repository = _ref.read(analysisJobRepositoryProvider);

    // Calculate next run
    final jobWithNextRun = job.copyWith(nextRun: job.calculateNextRun());

    await repository.addJob(jobWithNextRun);
  }

  /// Toggle job active status
  Future<void> toggleJobStatus(AnalysisJob job) async {
    final repository = _ref.read(analysisJobRepositoryProvider);
    final updated = job.copyWith(
      isActive: !job.isActive,
      nextRun: !job.isActive ? job.calculateNextRun() : null,
    );
    await repository.updateJob(updated);
  }

  /// Delete job
  Future<void> deleteJob(String jobId) async {
    final repository = _ref.read(analysisJobRepositoryProvider);
    await repository.deleteJob(jobId);
  }

  /// Manually execute a job
  Future<void> executeJob(AnalysisJob job) async {
    final runner = _ref.read(analysisJobRunnerProvider);
    final repository = _ref.read(analysisJobRepositoryProvider);
    final notificationService = NotificationService.instance;

    // Execute job and generate report
    final report = await runner.executeJob(job);

    // Save report
    await repository.addReport(report);

    // Update job last run
    final updated = job.copyWith(
      lastRun: DateTime.now(),
      nextRun: job.calculateNextRun(),
    );
    await repository.updateJob(updated);

    // Send notification if enabled
    if (job.notifyUser) {
      await notificationService.showTestNotification();
      // TODO: Show actual report notification
    }
  }
}
