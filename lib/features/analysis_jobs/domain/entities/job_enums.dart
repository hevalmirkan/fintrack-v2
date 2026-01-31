/// Job execution type
enum JobType {
  oneTime,
  daily,
  weekly,
}

/// Analysis scope - what data to analyze
enum AnalysisScope {
  portfolio, // User's asset portfolio
  watchlist, // Tracked assets (not owned)
  crypto, // Cryptocurrency markets
  forex, // Foreign exchange
  stocks, // Stock markets
}

/// Type of analysis to perform
enum AnalysisType {
  risk, // Risk assessment
  trend, // Trend analysis
  volatility, // Price volatility
}

/// Risk level classification
enum RiskLevel {
  low,
  medium,
  high,
}

/// Extensions for Turkish labels
extension JobTypeExtension on JobType {
  String get label {
    switch (this) {
      case JobType.oneTime:
        return 'Tek Seferlik';
      case JobType.daily:
        return 'Günlük';
      case JobType.weekly:
        return 'Haftalık';
    }
  }
}

extension AnalysisScopeExtension on AnalysisScope {
  String get label {
    switch (this) {
      case AnalysisScope.portfolio:
        return 'Portföy';
      case AnalysisScope.watchlist:
        return 'İzleme Listesi';
      case AnalysisScope.crypto:
        return 'Kripto Paralar';
      case AnalysisScope.forex:
        return 'Döviz';
      case AnalysisScope.stocks:
        return 'Hisseler';
    }
  }
}

extension AnalysisTypeExtension on AnalysisType {
  String get label {
    switch (this) {
      case AnalysisType.risk:
        return 'Risk Analizi';
      case AnalysisType.trend:
        return 'Trend Analizi';
      case AnalysisType.volatility:
        return 'Volatilite Analizi';
    }
  }
}

extension RiskLevelExtension on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.low:
        return 'Düşük Risk';
      case RiskLevel.medium:
        return 'Orta Risk';
      case RiskLevel.high:
        return 'Yüksek Risk';
    }
  }

  String get color {
    switch (this) {
      case RiskLevel.low:
        return 'green';
      case RiskLevel.medium:
        return 'orange';
      case RiskLevel.high:
        return 'red';
    }
  }
}
