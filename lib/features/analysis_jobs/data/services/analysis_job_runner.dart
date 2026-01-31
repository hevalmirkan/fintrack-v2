import 'package:uuid/uuid.dart';

import '../../domain/entities/analysis_job.dart';
import '../../domain/entities/analysis_report.dart';
import '../../domain/entities/job_enums.dart';
import '../../../assets/domain/repositories/i_asset_repository.dart';
import '../../../transactions/domain/repositories/i_transaction_repository.dart';
import '../../../insights/domain/services/financial_health_service.dart';

/// Service responsible for executing analysis jobs and generating reports
class AnalysisJobRunner {
  final IAssetRepository _assetRepository;
  final ITransactionRepository _transactionRepository;
  final FinancialHealthService _healthService;

  AnalysisJobRunner({
    required IAssetRepository assetRepository,
    required ITransactionRepository transactionRepository,
    required FinancialHealthService healthService,
  })  : _assetRepository = assetRepository,
        _transactionRepository = transactionRepository,
        _healthService = healthService;

  /// Execute a job and generate a report
  Future<AnalysisReport> executeJob(AnalysisJob job) async {
    try {
      // Fetch required data based on scopes
      final assets = await _assetRepository.getAssets();
      final transactions = await _transactionRepository.getTransactions();

      // Perform analysis based on analysis types
      final highlights = <String>[];
      RiskLevel overallRisk = RiskLevel.low;
      String summaryTitle = '';
      String summaryText = '';

      // Risk Analysis
      if (job.analysisTypes.contains(AnalysisType.risk)) {
        final riskAnalysis = await _analyzeRisk(assets, transactions);
        highlights.addAll(riskAnalysis.highlights);
        if (riskAnalysis.level.index > overallRisk.index) {
          overallRisk = riskAnalysis.level;
        }
      }

      // Trend Analysis
      if (job.analysisTypes.contains(AnalysisType.trend)) {
        final trendAnalysis = _analyzeTrend(transactions);
        highlights.addAll(trendAnalysis);
      }

      // Volatility Analysis
      if (job.analysisTypes.contains(AnalysisType.volatility)) {
        final volatilityAnalysis = _analyzeVolatility(assets);
        highlights.addAll(volatilityAnalysis);
      }

      // Generate summary
      summaryTitle = _generateSummaryTitle(overallRisk, job.analysisTypes);
      summaryText = _generateSummaryText(
        overallRisk,
        highlights.length,
        job.analysisTypes,
      );

      // Create report
      return AnalysisReport(
        id: const Uuid().v4(),
        jobId: job.id,
        jobName: job.name,
        createdAt: DateTime.now(),
        summaryTitle: summaryTitle,
        summaryText: summaryText,
        riskLevel: overallRisk,
        highlights: highlights,
      );
    } catch (e) {
      // Return error report
      return AnalysisReport(
        id: const Uuid().v4(),
        jobId: job.id,
        jobName: job.name,
        createdAt: DateTime.now(),
        summaryTitle: 'Analiz Hatası',
        summaryText:
            'Analiz sırasında bir hata oluştu. Lütfen daha sonra tekrar deneyin.',
        riskLevel: RiskLevel.medium,
        highlights: ['Hata: ${e.toString()}'],
      );
    }
  }

  /// Analyze portfolio risk
  Future<({RiskLevel level, List<String> highlights})> _analyzeRisk(
    List<dynamic> assets,
    List<dynamic> transactions,
  ) async {
    final highlights = <String>[];
    var riskLevel = RiskLevel.low;

    // Calculate portfolio concentration
    if (assets.length == 1) {
      highlights
          .add('Portföyünüz tek varlıktan oluşuyor - diversifikasyon önerilir');
      riskLevel = RiskLevel.high;
    } else if (assets.length < 3) {
      highlights.add(
          'Portföyünüzde ${assets.length} varlık var - daha fazla çeşitlendirme düşünülebilir');
      riskLevel = RiskLevel.medium;
    } else {
      highlights.add(
          'Portföyünüz ${assets.length} varlık ile iyi diversifiye edilmiş');
    }

    // Check recent losses
    final recentExpenses = transactions
        .where((t) => t.type.toString().contains('expense'))
        .take(10)
        .length;

    if (recentExpenses > 7) {
      highlights.add('Son işlemlerinizde yüksek oranda gider var');
      if (riskLevel.index < RiskLevel.medium.index) {
        riskLevel = RiskLevel.medium;
      }
    }

    return (level: riskLevel, highlights: highlights);
  }

  /// Analyze spending trends
  List<String> _analyzeTrend(List<dynamic> transactions) {
    final highlights = <String>[];

    final now = DateTime.now();
    final lastMonth = now.subtract(const Duration(days: 30));

    final recentExpenses = transactions
        .where((t) =>
            t.type.toString().contains('expense') &&
            (t.date as DateTime).isAfter(lastMonth))
        .length;

    final recentIncome = transactions
        .where((t) =>
            t.type.toString().contains('income') &&
            (t.date as DateTime).isAfter(lastMonth))
        .length;

    if (recentExpenses > recentIncome * 1.5) {
      highlights.add('Son 30 günde giderler gelirlerden %50 daha fazla');
    } else if (recentIncome > recentExpenses) {
      highlights.add('Gelirleriniz giderlerinizden fazla - olumlu trend');
    }

    highlights.add(
        'Son 30 günde $recentExpenses gider, $recentIncome gelir kaydedildi');

    return highlights;
  }

  /// Analyze portfolio volatility
  List<String> _analyzeVolatility(List<dynamic> assets) {
    final highlights = <String>[];

    if (assets.isEmpty) {
      highlights.add('Henüz portföyünüzde varlık bulunmuyor');
      return highlights;
    }

    // Count crypto assets (typically more volatile)
    final cryptoCount = assets.where((a) {
      final symbol = (a.symbol as String? ?? '').toUpperCase();
      return symbol.contains('BTC') ||
          symbol.contains('ETH') ||
          symbol.contains('USDT');
    }).length;

    if (cryptoCount > assets.length * 0.7) {
      highlights.add(
          'Portföyünüzün %${(cryptoCount / assets.length * 100).toInt()}\'i kripto varlıklardan oluşuyor - yüksek volatilite');
    } else if (cryptoCount > 0) {
      highlights.add('Portföyünüzde $cryptoCount kripto varlık bulunuyor');
    }

    return highlights;
  }

  /// Generate summary title based on risk level
  String _generateSummaryTitle(RiskLevel risk, List<AnalysisType> types) {
    switch (risk) {
      case RiskLevel.low:
        return 'Finansal Durum İyi Görünüyor';
      case RiskLevel.medium:
        return 'Dikkat Edilmesi Gereken Noktalar Var';
      case RiskLevel.high:
        return 'Yüksek Risk Tespit Edildi';
    }
  }

  /// Generate summary text
  String _generateSummaryText(
    RiskLevel risk,
    int highlightCount,
    List<AnalysisType> types,
  ) {
    final analysisTypes = types.map((t) => t.label).join(', ');

    switch (risk) {
      case RiskLevel.low:
        return 'Analiz sonuçlarına göre finansal durumunuz dengeli görünüyor. $highlightCount önemli nokta tespit edildi. Analiz kapsamı: $analysisTypes.';
      case RiskLevel.medium:
        return 'Analiz bazı dikkat edilmesi gereken noktalar ortaya çıkardı. Aşağıdaki $highlightCount detayı incelemeniz önerilir. Analiz kapsamı: $analysisTypes.';
      case RiskLevel.high:
        return 'Analiz önemli risk faktörleri tespit etti. $highlightCount kritik nokta bulundu. Acil önlem almanız gerekebilir. Analiz kapsamı: $analysisTypes.';
    }
  }
}
