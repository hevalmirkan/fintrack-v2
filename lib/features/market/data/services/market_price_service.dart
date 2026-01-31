import '../../domain/entities/market_price.dart';
import '../../domain/repositories/i_market_price_repository.dart';
import '../../domain/services/i_market_price_service.dart';

/// Service implementation for fetching market prices
class MarketPriceService implements IMarketPriceService {
  final IMarketPriceRepository _repository;

  MarketPriceService({required IMarketPriceRepository repository})
      : _repository = repository;

  @override
  Future<int> fetchCurrentPrice(String symbol) async {
    final price = await _repository.fetchAndCachePrice(symbol);
    return price.priceMinor;
  }

  @override
  Future<MarketPrice?> getLatestPrice(String symbol) async {
    return await _repository.getCachedPrice(symbol);
  }

  @override
  Future<MarketPrice> refreshPrice(String symbol) async {
    return await _repository.fetchAndCachePrice(symbol);
  }
}
