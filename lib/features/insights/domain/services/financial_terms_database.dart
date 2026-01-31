import '../entities/financial_term.dart';

/// Database of financial terms for educational purposes
class FinancialTermsDatabase {
  static const List<FinancialTerm> allTerms = [
    // Investment Terms
    FinancialTerm(
      title: 'Bileşik Faiz',
      definition:
          'Paranın para kazanmasıdır. Kazandığın faiz, ana paraya eklenip tekrar faiz kazanır. Uzun vadede kar topu etkisi yaratır.',
      example:
          '₺100,000\'i %10 faizle 10 yıl biriktirirsen: Basit faiz = ₺200,000, Bileşik faiz = ₺259,374. Fark: ₺59,374!',
      category: 'Yatırım',
    ),
    FinancialTerm(
      title: 'Enflasyon',
      definition:
          'Paranın alım gücünün zamanla erimesidir. Fiyatlar yükselir, aynı parayla daha az şey alabilirsin.',
      example:
          'Bugün ₺100\'e 10 ekmek alırsın. %20 enflasyonla gelecek yıl sadece 8 ekmek alabilirsin. Korunmak için yatırım şart!',
      category: 'Genel',
    ),
    FinancialTerm(
      title: 'Likitide (Kuru Barut)',
      definition:
          'Elindeki hazır nakit veya hızlıca nakde çevirebileceğin varlıklar. Acil durumlarda kullanabilirsin.',
      example:
          'Arabası bozulan kişi: Evin var ama satmak aylar sürer (düşük likitide). Bankada ₺50,000 var, ertesi gün çekip tamir edersin (yüksek likitide).',
      category: 'Bütçe',
    ),
    FinancialTerm(
      title: 'Çeşitlendirme',
      definition:
          'Yumurtalarını farklı sepetlere koymak. Farklı varlıklara yatırım yaparak riski dağıtırsın.',
      example:
          'Sadece kripto alan kişi: Kripto %50 düşer, tüm portföy batar. Kripto, altın, hisse, döviz karışık alanın portföyü dengelidir.',
      category: 'Yatırım',
    ),
    FinancialTerm(
      title: 'Volatilite',
      definition:
          'Bir varlığın fiyatının ne kadar hızlı değiştiğidir. Yüksek = risk, düşük = istikrar.',
      example:
          'Bitcoin: Günde %20 inip çıkabilir (yüksek volatilite). Altın: Yılda %10 değişir (düşük volatilite). Risk iştahına göre seç!',
      category: 'Yatırım',
    ),

    // Debt & Budget Terms
    FinancialTerm(
      title: 'Kaldıraç (Leverage)',
      definition:
          'Borç alarak yatırım yapmak. Kazancını artırabilir ama kaybını da. Çift taraflı kılıçtır.',
      example:
          '₺100,000\'in var. Ev alacaksın: (A) Tamamını öde, (B) ₺50,000 kredi al, kalan ₺50,000\'i hisseye yatır. Ev değer kazanırsa (B) daha karlı. Ama risk de yüksek!',
      category: 'Borç',
    ),
    FinancialTerm(
      title: 'Nakit Akışı',
      definition:
          'Para giriş-çıkışının dengesidir. Pozitif = kazanıyorsun, negatif = eritiyorsun.',
      example:
          'Aylık gelir ₺20,000, gider ₺15,000 = Pozitif ₺5,000 nakit akışı (sürdürülebilir). Gelir ₺20,000, gider ₺25,000 = Negatif (tehlikeli).',
      category: 'Bütçe',
    ),
    FinancialTerm(
      title: 'Borç Servisi Oranı',
      definition:
          'Gelirinin ne kadarı borç ödemeye gidiyor. %40\'tan fazlası tehlikeli kabul edilir.',
      example:
          'Aylık gelir ₺30,000. Kredi taksitleri ₺15,000 = %50 borç servisi. Çok yüksek! Yeni borç alma, varları hızla öde.',
      category: 'Borç',
    ),

    // Market Terms
    FinancialTerm(
      title: 'Boğa Piyasası (Bull Market)',
      definition:
          'Fiyatların sürekli yükseldiği, iyimser piyasa. Yatırımcılar alım yapıyor.',
      example:
          '2020-2021 kripto piyasası: Bitcoin ₺50,000\'den ₺300,000\'e çıktı. Herkes kazandı, yeni yatırımcılar geldi. İyimserlik hakim.',
      category: 'Piyasa',
    ),
    FinancialTerm(
      title: 'Ayı Piyasası (Bear Market)',
      definition:
          'Fiyatların sürekli düştüğü, kötümser piyasa. Yatırımcılar satıyor.',
      example:
          '2022 kripto piyasası: Bitcoin %70 değer kaybetti. Korku hakim, herkes satıyor. Ancak Warren Buffett der ki: Herkes korktuğunda açgözlü ol.',
      category: 'Piyasa',
    ),
    FinancialTerm(
      title: 'Piyasa Kapitalizasyonu',
      definition:
          'Bir şirketin veya coin-in toplam değeri. Fiyat × dolaşımdaki miktar.',
      example:
          'Bitcoin fiyat: \$50,000. Dolaşımda 19M BTC. Piyasa değeri: \$950 milyar. Ethereum: \$250B. BTC daha büyük, genelde daha az riskli.',
      category: 'Yatırım',
    ),

    // Advanced Terms
    FinancialTerm(
      title: 'Dolar Maliyet Ortalaması (DCA)',
      definition:
          'Belirli aralıklarla sabit miktar yatırım yapmak. Zamanlama stresini azaltır.',
      example:
          'Her ay ₺1,000 Bitcoin alıyorsun. Bazı aylar ucuz, bazı pahalı alırsın. Ortalama maliyet dengeli olur. Piyasa zamanlamaya çalışmaktan daha güvenli.',
      category: 'Strateji',
    ),
    FinancialTerm(
      title: 'HODL (Hold On for Dear Life)',
      definition:
          'Kripto argosunda "uzun süre tut" demektir. Kısa vadeli dalgalanmalara aldırmadan bekleme stratejisi.',
      example:
          '2018\'de Bitcoin aldın: \$20,000. 2020\'de \$5,000\'e düştü. Panikte satmadın (HODL). 2021\'de \$65,000 oldu. Sabır kazandırdı!',
      category: 'Strateji',
    ),
    FinancialTerm(
      title: 'FOMO (Fear of Missing Out)',
      definition:
          'Kaçırma korkusu. Bir varlık hızlı yükselirken, geç kalmışım hissiyle yüksek fiyattan alma psikolojisi.',
      example:
          'Herkes Dogecoin aldım diyor, %500 kar etti. Sen de FOMO\'dan alırsın. Sonra %50 düşer. Duygusal karar aldın. Açgözlülük düşmanındir.',
      category: 'Psikoloji',
    ),
    FinancialTerm(
      title: 'Stop Loss (Zarar Durdur)',
      definition:
          'Belirli bir fiyata düşerse otomatik sat emri. Kaybını sınırlandırır.',
      example:
          'BTC ₺100,000\'den aldın. %10 kayıp kabul edilebilir, ₺90,000\'e stop loss koyarsın. Düşerse otomatik satar, daha fazla kaybetmezsin.',
      category: 'Strateji',
    ),

    // Retirement & Long-term
    FinancialTerm(
      title: '%4 Kuralı',
      definition:
          'Emeklilik için: Toplam birikiminin %4\'ünü yıllık harcaman sürdürülebilir kabul edilir.',
      example:
          '₺10 milyon biriktirmişsin. Yılda %4 = ₺400,000 harcayabilirsin. Geri kalanı yatırımda kalıp artmaya devam eder. 30+ yıl sürdürülebilir.',
      category: 'Emeklilik',
    ),
    FinancialTerm(
      title: 'Pasif Gelir',
      definition: 'Aktif çalışmadan kazandığın para. Kira, temettü, faiz gibi.',
      example:
          'Ev kiraya veriyorsun = Aylık ₺15,000 (pasif). İşten maaş = ₺30,000 (aktif). Hedef: Pasif gelir > giderler = Mali özgürlük!',
      category: 'Gelir',
    ),
    FinancialTerm(
      title: 'Finansal Bağımsızlık',
      definition:
          'Pasif gelirin giderlerini karşıladığı nokta. Artık çalışman "zorunlu" değil, "tercih".',
      example:
          'Aylık giderin ₺20,000. Yatırımlarından ₺25,000 pasif gelir. Tebrikler, finansal bağımsızsın! İstersen çalış, istersen seyahat et.',
      category: 'Hedef',
    ),

    // Turkish Market Specific
    FinancialTerm(
      title: 'Döviz Sepeti',
      definition:
          'Farklı dövizlerden oluşan karma. TL\'nin değer kaybına karşı korunma yöntemi.',
      example:
          'Tasarrufunun %50 TL, %25 USD, %25 EUR yap. TL değer kaybederse diğerleri dengeleyebilir. Tek dövize bağımlı olma.',
      category: 'Koruma',
    ),
    FinancialTerm(
      title: 'Altın Hesabı',
      definition:
          'Fiziki altın almadan, gram cinsinden altına yatırım. Bankalarda açılır.',
      example:
          'Evde altın saklamak riskli, çalınabilir. Altın hesabı açarsın, gram bazlı alıp satabilirsin. Güvenli ve likit.',
      category: 'Yatırım',
    ),

    // Tasarruf Oranı (MISSING TERM - ADDED)
    FinancialTerm(
      title: 'Tasarruf Oranı',
      definition:
          'Gelirinin ne kadarını harcamayıp kenara koyduğun orandır. Finansal özgürlüğe giden hızını belirler.',
      example:
          'Aylık gelir ₺30,000, harcama ₺20,000 = ₺10,000 tasarruf. Tasarruf oranı: %33. Yüksek oran = Erken mali özgürlük!',
      category: 'Bütçe',
    ),
  ];

  /// Get random term for "Daily Term" feature
  static FinancialTerm getRandomTerm() {
    final now = DateTime.now();
    final seed = now.year * 1000 + now.month * 100 + now.day;
    final index = seed % allTerms.length;
    return allTerms[index];
  }

  /// Get term by category
  static List<FinancialTerm> getByCategory(String category) {
    return allTerms.where((term) => term.category == category).toList();
  }
}
