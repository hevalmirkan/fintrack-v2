import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';
import '../../features/assets/domain/entities/holding.dart';

class CalculationService {
  /// Method 1 — convertCurrency
  int convertCurrency(int amountMinor, double rate) {
    if (amountMinor == 0) return 0;
    final amountDec = Decimal.fromInt(amountMinor);
    final rateDec = Decimal.parse(rate.toString());
    final result = amountDec * rateDec;

    // Decimal işlemleri Decimal döner. .toBigInt() GEREKLİ.
    return result.round().toBigInt().toInt();
  }

  /// Method 2 — calculateCostBasis_FIFO
  int calculateCostBasis_FIFO(List<Holding> holdings, int sellQuantityMinor) {
    if (sellQuantityMinor <= 0 || holdings.isEmpty) return 0;

    final sortedHoldings = List<Holding>.from(holdings)
      ..sort((a, b) => a.purchasedAt.compareTo(b.purchasedAt));

    Decimal totalCost = Decimal.zero;
    Decimal remainingSell = Decimal.fromInt(sellQuantityMinor);

    for (final holding in sortedHoldings) {
      if (remainingSell <= Decimal.zero) break;
      final holdingQty = Decimal.fromInt(holding.qtyMinor);
      final holdingCost = Decimal.fromInt(holding.costPerUnitBaseMinor);

      if (holdingQty <= remainingSell) {
        totalCost += holdingQty * holdingCost;
        remainingSell -= holdingQty;
      } else {
        totalCost += remainingSell * holdingCost;
        remainingSell = Decimal.zero;
      }
    }
    // Decimal işlemleri Decimal döner. .toBigInt() GEREKLİ.
    return totalCost.round().toBigInt().toInt();
  }

  /// Method 3 — updateWeightedAverage
  int updateWeightedAverage({
    required int currentQty,
    required int currentAvg,
    required int newQty,
    required int newCost,
  }) {
    final curQtyDec = Decimal.fromInt(currentQty);
    final curAvgDec = Decimal.fromInt(currentAvg);
    final newQtyDec = Decimal.fromInt(newQty);
    final newCostDec = Decimal.fromInt(newCost);

    final totalQty = curQtyDec + newQtyDec;
    if (totalQty == Decimal.zero) return 0;

    final numerator = (curQtyDec * curAvgDec) + (newQtyDec * newCostDec);

    // BÖLME işlemi Rational döner.
    final newAvg = numerator / totalQty;

    // Rational.round() direkt BigInt döner. .toBigInt() GEREKSİZ, SİLİNDİ.
    return newAvg.round().toInt();
  }

  /// Method 4 — projectSavingsMonthly
  int projectSavingsMonthly({
    required int principal,
    required int monthlyContribution,
    required double annualRate,
    required int months,
  }) {
    if (months == 0) return principal;

    final annualRateRat = Rational.parse(annualRate.toString());
    final i = annualRateRat / Rational.fromInt(12);

    final onePlusI = Rational.one + i;
    final onePlusIPowN = onePlusI.pow(months);

    final term1 = Rational.fromInt(principal) * onePlusIPowN;

    Rational term2;
    if (i == Rational.zero) {
      term2 = Rational.fromInt(monthlyContribution) * Rational.fromInt(months);
    } else {
      final numerator = onePlusIPowN - Rational.one;
      term2 = Rational.fromInt(monthlyContribution) * (numerator / i);
    }

    final fv = term1 + term2;

    // Rational işlemleri direkt BigInt döner. .toBigInt() GEREKSİZ, SİLİNDİ.
    return fv.round().toInt();
  }
}
