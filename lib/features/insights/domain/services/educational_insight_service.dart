import 'package:flutter/material.dart';

import '../entities/educational_insight.dart';
import '../entities/financial_health_score.dart';

/// Service that generates educational insights and financial coaching
class EducationalInsightService {
  /// Generate personalized educational insights based on portfolio state
  List<EducationalInsight> generateEducationalInsights(
    Map<String, int> metrics,
    int assetCount,
  ) {
    final List<EducationalInsight> insights = [];

    // Cash reserve insights
    final monthsOfCash = metrics['monthlyExpense']! > 0
        ? metrics['cashBalance']! / metrics['monthlyExpense']!
        : 0.0;

    if (monthsOfCash < 1.0) {
      insights.add(const EducationalInsight(
        headline: 'Acil Durum Fonu Oluştur',
        explanation:
            'Nakit rezervin 1 aydan az. Finansal literatürde bu "Likitide Riski" olarak bilinir. Beklenmedik harcamalar (araba tamiri, sağlık masrafı) için en az 3-6 aylık gider tutarı biriktirmeyi hedefle. Bu birikim senin "Kuru Barutun" olur - acil durumlarda kullanabileceğin hazır para.',
        financialTerm: 'Likitide (Kuru Barut)',
        type: InsightType.warning,
        icon: Icons.warning_amber,
      ));
    } else if (monthsOfCash >= 6.0) {
      insights.add(const EducationalInsight(
        headline: 'Güçlü Nakit Rezervi',
        explanation:
            'Harika! 6 aydan fazla nakit rezervin var. Bu "Yüksek Likitide" demektir. Finansal güvenliğin sağlam. Artık daha yüksek getirili yatırımları (hisse senedi, kripto) değerlendirebilirsin çünkü acil durum fonun hazır.',
        financialTerm: 'Likitide',
        type: InsightType.success,
        icon: Icons.check_circle,
      ));
    } else if (monthsOfCash >= 3.0) {
      insights.add(const EducationalInsight(
        headline: 'İyi Seviyede Nakit',
        explanation:
            'Nakit rezervin 3-6 ay arası. Bu "Orta Likitide" seviyesidir. Çoğu uzman için ideal aralık. Acil durumlar için yeterliyken, fazla paranı nakitte tutup enflasyona kurban etmiyorsun.',
        financialTerm: 'Likitide Dengesi',
        type: InsightType.info,
        icon: Icons.info_outline,
      ));
    }

    // Income/Expense insights
    if (metrics['monthlyIncome']! < metrics['monthlyExpense']!) {
      insights.add(const EducationalInsight(
        headline: 'Gider Kontrolü Gerekli',
        explanation:
            'Giderlerin gelirini aşıyor. Buna "Negatif Nakit Akışı" denir. Bu sürdürülemez bir durum - varlıklarını eritiyorsun. İki çözüm var: (1) Gereksiz harcamaları kes (latte faktörü), (2) Gelir kaynaklarını artır (yan gelir, terfi). Önce giderlerini kategorilere ayır ve en büyük kalem neresi bul.',
        financialTerm: 'Nakit Akışı',
        type: InsightType.warning,
        icon: Icons.trending_down,
      ));
    } else if (metrics['monthlyIncome']! >= metrics['monthlyExpense']! * 1.5) {
      insights.add(const EducationalInsight(
        headline: 'Güçlü Tasarruf Oranı',
        explanation:
            'Gelirin giderlerinin %150\'sinden fazla. Bu "Yüksek Tasarruf Oranı" demektir. Harika! Fazla parayı akıllıca değerlendir: (1) Acil fon yoksa önce onu oluştur, (2) Sonra borçları öde, (3) En son yatırım yap. "İlk kendine öde" prensibini uyguluyorsun.',
        financialTerm: 'Tasarruf Oranı',
        type: InsightType.success,
        icon: Icons.savings,
      ));
    }

    // Diversification insights
    if (assetCount == 0) {
      insights.add(const EducationalInsight(
        headline: 'Yatırıma Başla',
        explanation:
            'Henüz varlığın yok. "Yatırım Yapmamak En Büyük Risk"tir çünkü enflasyon paranın alım gücünü eritir. Küçük miktarlarla da olsa başla. İlk adım: Acil fon oluştur, sonra düşük riskli varlıklardan (endeks fonu, altın) başla. Zaman en büyük müttefikin - erken başlayanlar "Bileşik Faiz" gücünden yararlanır.',
        financialTerm: 'Bileşik Faiz',
        type: InsightType.tip,
        icon: Icons.lightbulb_outline,
      ));
    } else if (assetCount < 3) {
      insights.add(const EducationalInsight(
        headline: 'Portföyünü Çeşitlendir',
        explanation:
            'Portföyün az sayıda varlık içeriyor. Bu "Konsantrasyon Riski" yaratır - tek bir varlık düşerse çok etkilenirsin. Çözüm: "Yumurtalarını Farklı Sepetlere Koy" (çeşitlendirme). Farklı varlık sınıfları ekle: Kripto, altın, hisse, döviz. Her biri farklı zamanlarda yükselir.',
        financialTerm: 'Çeşitlendirme (Diversification)',
        type: InsightType.info,
        icon: Icons.pie_chart_outline,
      ));
    } else if (assetCount >= 5) {
      insights.add(const EducationalInsight(
        headline: 'İyi Çeşitlendirilmiş Portföy',
        explanation:
            'Portföyün 5+ farklı varlık içeriyor. Bu "Dengeli Portföy" demektir. Risk dağılımı yapmışsın - biri düşerken diğeri yükselebilir. Şimdi her varlığın ağırlığına bak: Tek bir varlık %50\'den fazlaysa yine riskli olabilir. "Optimal Oran" genelde hiçbir varlık %30\'u geçmemeli.',
        financialTerm: 'Portföy Dengesi',
        type: InsightType.success,
        icon: Icons.balance,
      ));
    }

    // Debt insights
    final debtRatio = metrics['monthlyIncome']! > 0
        ? metrics['installmentPayments']! / metrics['monthlyIncome']!
        : 0.0;

    if (debtRatio > 2.0) {
      insights.add(const EducationalInsight(
        headline: 'Yüksek Borç Yükü',
        explanation:
            'Taksit borcun aylık gelirin 2 katından fazla. Bu "Yüksek Kaldıraç" riskidir. Finansal literatürde %40\'ın üzeri tehlikeli kabul edilir. Borç senin geleceğini bugüne borçlandırır. Çözüm: "Kar Topu Yöntemi" - en küçük borcu önce öde (motivasyon), sonra büyüklerine geç. Ya da "Çığ Yöntemi" - en yüksek faizliyi önce öde (matematik).',
        financialTerm: 'Kaldıraç Riski',
        type: InsightType.warning,
        icon: Icons.credit_card_off,
      ));
    } else if (debtRatio > 0.5) {
      insights.add(const EducationalInsight(
        headline: 'Borç Yükü Yönetilebilir',
        explanation:
            'Borçların gelirinin %50\'sini götürüyor. "Orta Seviye Kaldıraç" bu. Tehlikeli değil ama rahat da değil. İdeal oran %30\'un altıdır. Borçlarını kontrol altında tut - yeni borç alma, varsa yüksek faizlileri önce öde. Hatırla: "İyi borç" (yatırım için) vs "Kötü borç" (tüketim için) ayrımı yap.',
        financialTerm: 'Borç Servisi Oranı',
        type: InsightType.info,
        icon: Icons.payments,
      ));
    }

    // Asset composition insights (crypto heavy example)
    final totalAssetValue = metrics['totalAssetValue']!;
    if (totalAssetValue > 0) {
      // This is a simplified check - in real implementation,
      // you'd categorize assets by type
      insights.add(const EducationalInsight(
        headline: 'Varlık Dağılımını İncele',
        explanation:
            'Varlıklarının türlerine bak. Çoğu Kripto mu? Bu "Yüksek Volatilite" demektir - fiyatlar hızlı değişir. Çoğu Altın mı? "Düşük Get iri ama Güvenli". İdeal portföy: %60 Hisse/Kripto (büyüme), %20 Altın (değer koruması), %20 Nakit/Tahvil (güvenlik). Yaşına ve risk iştahına göre ayarla.',
        financialTerm: 'Varlık Dağılımı',
        type: InsightType.tip,
        icon: Icons.category,
      ));
    }

    // If no  insights yet, add a positive one
    if (insights.isEmpty) {
      insights.add(const EducationalInsight(
        headline: 'Finansal Yolculuk Başladı',
        explanation:
            'Finansal durumun dengeli görünüyor. Şimdi önemli olan şu princpler: (1) "İlk kendine öde" - gelirin gelir gelmez %10-20 tasarruf et, (2) "Bileşik faiz" gücünden yararlan - erken başla, (3) "Enflasyonu yen" - nakit tutmak paranı eritir, yatırım yap. Küçük adımlar büyük sonuçlar doğurur. Warren Buffett: "Zenginlik bir maraton, sprint değil."',
        financialTerm: 'Finansal Okuryazarlık',
        type: InsightType.success,
        icon: Icons.school,
      ));
    }

    return insights;
  }
}
