import 'package:equatable/equatable.dart';

/// Represents a single price candle (OHLCV data)
class Candle extends Equatable {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double? volume;

  const Candle({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume,
  });

  /// Create from CoinGecko market_chart response
  /// CoinGecko returns [timestamp, price] arrays
  factory Candle.fromCoinGecko(List<dynamic> priceData, {double? volume}) {
    final timestamp = priceData[0] as int;
    final price = (priceData[1] as num).toDouble();

    return Candle(
      date: DateTime.fromMillisecondsSinceEpoch(timestamp),
      open: price,
      high: price,
      low: price,
      close: price,
      volume: volume,
    );
  }

  /// Create from Yahoo Finance chart response
  factory Candle.fromYahoo({
    required int timestamp,
    required double? open,
    required double? high,
    required double? low,
    required double? close,
    double? volume,
  }) {
    final price = close ?? open ?? 0.0;
    return Candle(
      date: DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
      open: open ?? price,
      high: high ?? price,
      low: low ?? price,
      close: close ?? price,
      volume: volume,
    );
  }

  @override
  List<Object?> get props => [date, open, high, low, close, volume];

  @override
  String toString() =>
      'Candle(${date.toIso8601String()}, O:$open H:$high L:$low C:$close)';
}
