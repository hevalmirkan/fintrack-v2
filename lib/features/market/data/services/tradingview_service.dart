import 'dart:convert';
import 'package:http/http.dart' as http;

/// TradingView Scanner API Service
/// Yıldırım hızında piyasa verisi için TradingView tarayıcı API'si
class TradingViewService {
  static final TradingViewService _instance = TradingViewService._internal();
  factory TradingViewService() => _instance;
  TradingViewService._internal();

  // TradingView Scanner endpoint'leri
  static const String _baseUrl = 'https://scanner.tradingview.com';

  // Piyasa endpoint'leri
  static const String _turkeyMarket = 'turkey';
  static const String _cryptoMarket = 'crypto';
  static const String _forexMarket = 'forex';
  static const String _cfdMarket = 'cfd'; // Emtialar için

  // İstenen kolonlar
  static const List<String> _columns = [
    'close', // Güncel fiyat
    'change', // Günlük değişim (mutlak)
    'change_abs', // Mutlak değişim
    'Recommend.All', // Genel tavsiye skoru
  ];

  /// BIST hisseleri için fiyat çek (THYAO, GARAN, vb.)
  Future<Map<String, TradingViewQuote>> fetchBistQuotes(
      List<String> symbols) async {
    if (symbols.isEmpty) return {};

    // BIST: prefixi ekle
    final tickers = symbols.map((s) => 'BIST:$s').toList();

    print('[TradingView] 🇹🇷 BIST sorgusu: ${symbols.join(", ")}');

    return await _fetchFromScanner(_turkeyMarket, tickers, symbols);
  }

  /// Kripto paralar için fiyat çek (BTC, ETH, vb.)
  Future<Map<String, TradingViewQuote>> fetchCryptoQuotes(
      List<String> symbols) async {
    if (symbols.isEmpty) return {};

    // CRYPTO: prefixi + USD suffix ekle
    final tickers = symbols.map((s) => 'CRYPTO:${s}USD').toList();

    print('[TradingView] 🪙 Kripto sorgusu: ${symbols.join(", ")}');

    return await _fetchFromScanner(_cryptoMarket, tickers, symbols);
  }

  /// Döviz kurları için fiyat çek (USD/TRY, EUR/TRY, vb.)
  Future<Map<String, TradingViewQuote>> fetchForexQuotes(
      List<String> symbols) async {
    if (symbols.isEmpty) return {};

    // FX: prefixi ekle (örn: USDTRY -> FX:USDTRY)
    final tickers = symbols.map((s) => 'FX:$s').toList();

    print('[TradingView] 💱 Döviz sorgusu: ${symbols.join(", ")}');

    return await _fetchFromScanner(_forexMarket, tickers, symbols);
  }

  /// Emtialar için fiyat çek (Gold, Silver, Oil)
  Future<Map<String, TradingViewQuote>> fetchCommodityQuotes(
      List<String> symbols) async {
    if (symbols.isEmpty) return {};

    // TVC: prefixi ekle (örn: GOLD -> TVC:GOLD)
    final tickers = symbols.map((s) => 'TVC:$s').toList();

    print('[TradingView] 🏆 Emtia sorgusu: ${symbols.join(", ")}');

    return await _fetchFromScanner(_cfdMarket, tickers, symbols);
  }

  /// Scanner API'den veri çek
  Future<Map<String, TradingViewQuote>> _fetchFromScanner(
    String market,
    List<String> tickers,
    List<String> originalSymbols,
  ) async {
    final url = Uri.parse('$_baseUrl/$market/scan');

    final body = json.encode({
      'symbols': {'tickers': tickers},
      'columns': _columns,
    });

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print('[TradingView] ❌ API Hatası: ${response.statusCode}');
        return {};
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final results = data['data'] as List<dynamic>?;

      if (results == null || results.isEmpty) {
        print('[TradingView] ⚠️ Boş sonuç');
        return {};
      }

      final quotes = <String, TradingViewQuote>{};

      for (int i = 0; i < results.length && i < originalSymbols.length; i++) {
        final row = results[i] as Map<String, dynamic>;
        final symbol = row['s'] as String?;
        final values = row['d'] as List<dynamic>?;

        if (values != null && values.length >= 2) {
          final close = (values[0] as num?)?.toDouble();
          final change = (values[1] as num?)?.toDouble();

          if (close != null) {
            // Orijinal sembolü kullan (BIST: prefix'i olmadan)
            final originalSymbol = originalSymbols[i];
            quotes[originalSymbol] = TradingViewQuote(
              symbol: originalSymbol,
              price: close,
              change: change,
              changePercent: close > 0 && change != null
                  ? (change / (close - change)) * 100
                  : null,
            );
            print(
                '[TradingView] ✅ $originalSymbol: ${close.toStringAsFixed(2)}');
          }
        }
      }

      print(
          '[TradingView] 📊 $market: ${quotes.length}/${originalSymbols.length} başarılı');
      return quotes;
    } catch (e) {
      print('[TradingView] ❌ Hata ($market): $e');
      return {};
    }
  }

  /// Tek bir istek ile tüm varlıkları çek (mixed markets)
  Future<Map<String, TradingViewQuote>> fetchAllQuotes({
    List<String> bistSymbols = const [],
    List<String> cryptoSymbols = const [],
    List<String> forexSymbols = const [],
    List<String> commoditySymbols = const [],
  }) async {
    print('[TradingView] 🚀 Tüm piyasalar yükleniyor...');

    // Paralel olarak tüm piyasaları çek
    final results = await Future.wait([
      fetchBistQuotes(bistSymbols),
      fetchCryptoQuotes(cryptoSymbols),
      fetchForexQuotes(forexSymbols),
      fetchCommodityQuotes(commoditySymbols),
    ]);

    // Sonuçları birleştir
    final allQuotes = <String, TradingViewQuote>{};
    for (final result in results) {
      allQuotes.addAll(result);
    }

    print('[TradingView] ✅ Toplam: ${allQuotes.length} fiyat alındı');
    return allQuotes;
  }
}

/// TradingView'dan gelen fiyat verisi
class TradingViewQuote {
  final String symbol;
  final double price;
  final double? change;
  final double? changePercent;

  TradingViewQuote({
    required this.symbol,
    required this.price,
    this.change,
    this.changePercent,
  });

  @override
  String toString() =>
      'TradingViewQuote($symbol: $price, %${changePercent?.toStringAsFixed(2)})';
}
