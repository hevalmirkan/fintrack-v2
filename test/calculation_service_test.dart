import 'package:test/test.dart';
import 'package:fintrack_v2/core/services/calculation_service.dart';
import 'package:fintrack_v2/features/assets/domain/entities/holding.dart';

void main() {
  late CalculationService service;

  setUp(() {
    service = CalculationService();
  });

  group('convertCurrency', () {
    test('converts correctly', () {
      // 100 native (1.00) * 1.5 rate = 150 base (1.50)
      expect(service.convertCurrency(100, 1.5), 150);
    });

    test('rounds half up', () {
      // 100 * 1.555 = 155.5 -> 156
      // Decimal('100') * Decimal('1.555') = Decimal('155.5')
      // .round() -> BigInt(156)
      // .toInt() -> 156
      expect(service.convertCurrency(100, 1.555), 156);
    });

    test('handles zero', () {
      expect(service.convertCurrency(0, 1.5), 0);
    });
  });

  group('calculateCostBasis_FIFO', () {
    final now = DateTime.now();
    final h1 = Holding(
        qtyMinor: 100,
        costPerUnitBaseMinor: 10,
        purchasedAt: now,
        rateAtPurchase: 1.0);
    final h2 = Holding(
        qtyMinor: 50,
        costPerUnitBaseMinor: 20,
        purchasedAt: now.add(Duration(days: 1)),
        rateAtPurchase: 1.0);

    test('returns 0 for empty holdings', () {
      expect(service.calculateCostBasis_FIFO([], 100), 0);
    });

    test('full consume first holding', () {
      // Sell 100 (all of h1). Cost = 100 * 10 = 1000
      expect(service.calculateCostBasis_FIFO([h1, h2], 100), 1000);
    });

    test('partial consume first holding', () {
      // Sell 50. Cost = 50 * 10 = 500
      expect(service.calculateCostBasis_FIFO([h1, h2], 50), 500);
    });

    test('multi-layer sell', () {
      // Sell 120. (100 * 10) + (20 * 20) = 1000 + 400 = 1400
      expect(service.calculateCostBasis_FIFO([h1, h2], 120), 1400);
    });

    test('oversell (caps at total)', () {
      // Sell 200 (have 150). (100*10) + (50*20) = 1000 + 1000 = 2000
      expect(service.calculateCostBasis_FIFO([h1, h2], 200), 2000);
    });
  });

  group('updateWeightedAverage', () {
    test('returns correct average', () {
      // (100*10 + 100*20) / 200 = 3000 / 200 = 15
      expect(
          service.updateWeightedAverage(
              currentQty: 100, currentAvg: 10, newQty: 100, newCost: 20),
          15);
    });

    test('handles zero total qty', () {
      expect(
          service.updateWeightedAverage(
              currentQty: 0, currentAvg: 0, newQty: 0, newCost: 0),
          0);
    });

    test('rounds half up', () {
      // (10*10 + 10*11) / 20 = 210 / 20 = 10.5 -> 11
      expect(
          service.updateWeightedAverage(
              currentQty: 10, currentAvg: 10, newQty: 10, newCost: 11),
          11);
    });
  });

  group('projectSavingsMonthly', () {
    test('zero months returns principal', () {
      expect(
          service.projectSavingsMonthly(
              principal: 1000,
              monthlyContribution: 100,
              annualRate: 0.1,
              months: 0),
          1000);
    });

    test('zero rate (simple sum)', () {
      // 1000 + 100*12 = 2200
      expect(
          service.projectSavingsMonthly(
              principal: 1000,
              monthlyContribution: 100,
              annualRate: 0.0,
              months: 12),
          2200);
    });

    test('positive rate', () {
      // Principal 1000, Contrib 0, Rate 12% (1% mo), 1 month.
      // 1000 * 1.01 = 1010.
      // Formula: P * (1+i)^n. 1000 * (1.01)^1 = 1010.
      expect(
          service.projectSavingsMonthly(
              principal: 1000,
              monthlyContribution: 0,
              annualRate: 0.12,
              months: 1),
          1010);
    });

    test('rounding', () {
      // Principal 100, Rate 12%, 1 month. 101.
      expect(
          service.projectSavingsMonthly(
              principal: 100,
              monthlyContribution: 0,
              annualRate: 0.12,
              months: 1),
          101);
    });
  });
}
