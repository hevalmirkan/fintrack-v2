import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/assets/presentation/screens/add_asset_screen.dart';
import '../../features/assets/presentation/screens/asset_detail_screen.dart';
import '../../features/assets/domain/entities/prefilled_asset_data.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/transactions/presentation/screens/add_transaction_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../../features/installments/presentation/screens/installments_screen.dart';
import '../../features/installments/presentation/screens/add_installment_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/analysis_jobs/presentation/screens/analysis_jobs_screen.dart';
import '../../features/analysis_jobs/presentation/screens/add_analysis_job_screen.dart';
import '../../features/analysis_jobs/presentation/screens/analysis_report_screen.dart';
import '../../features/analysis_jobs/domain/entities/analysis_report.dart';
import '../../features/market/presentation/screens/market_board_screen.dart';
import '../../features/finance/presentation/screens/monthly_summary_screen.dart';
import '../../features/coach/presentation/screens/coach_screen.dart';
import '../../features/goals/presentation/screens/goals_screen.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/assets',
        builder: (context, state) => const DashboardScreen(
            initialTab: 1), // Simplification: Dashboard handles tabs
      ),
      GoRoute(
        path: '/add-asset',
        builder: (context, state) {
          // Accept optional PrefilledAssetData from Market Board
          final prefilledData = state.extra as PrefilledAssetData?;
          return AddAssetScreen(prefilledData: prefilledData);
        },
      ),
      GoRoute(
        path: '/asset-detail/:id',
        builder: (context, state) {
          final assetId = state.pathParameters['id']!;
          return AssetDetailScreen(assetId: assetId);
        },
      ),
      GoRoute(
        path: '/transactions',
        builder: (context, state) => const TransactionsScreen(),
      ),
      GoRoute(
        path: '/add-transaction',
        builder: (context, state) => const AddTransactionScreen(),
      ),
      // Settings route
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      // Analysis Jobs Routes
      GoRoute(
        path: '/analysis-jobs',
        builder: (context, state) => const AnalysisJobsScreen(),
      ),
      GoRoute(
        path: '/add-analysis-job',
        builder: (context, state) => const AddAnalysisJobScreen(),
      ),
      GoRoute(
        path: '/analysis-report',
        builder: (context, state) {
          final report = state.extra as AnalysisReport;
          return AnalysisReportScreen(report: report);
        },
      ),
      GoRoute(
        path: '/installments',
        builder: (context, state) => const InstallmentsScreen(),
      ),
      GoRoute(
        path: '/add-installment',
        builder: (context, state) => const AddInstallmentScreen(),
      ),
      // Market Status (API Debugger)
      GoRoute(
        path: '/market-board',
        builder: (context, state) => const MarketBoardScreen(),
      ),
      // Phase 5.1: Monthly Summary
      GoRoute(
        path: '/monthly-summary',
        builder: (context, state) => const MonthlySummaryScreen(),
      ),
      // Phase 7: AI Coach
      GoRoute(
        path: '/coach',
        builder: (context, state) => const CoachScreen(),
      ),
      // Phase 8: Financial Goals
      GoRoute(
        path: '/goals',
        builder: (context, state) => const GoalsScreen(),
      ),
    ],
  );
}
