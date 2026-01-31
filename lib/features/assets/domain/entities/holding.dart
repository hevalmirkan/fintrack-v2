class Holding {
  final int qtyMinor;
  final int costPerUnitBaseMinor;
  final DateTime purchasedAt;
  final double rateAtPurchase;

  const Holding({
    required this.qtyMinor,
    required this.costPerUnitBaseMinor,
    required this.purchasedAt,
    required this.rateAtPurchase,
  });

  Holding copyWith({
    int? qtyMinor,
    int? costPerUnitBaseMinor,
    DateTime? purchasedAt,
    double? rateAtPurchase,
  }) {
    return Holding(
      qtyMinor: qtyMinor ?? this.qtyMinor,
      costPerUnitBaseMinor: costPerUnitBaseMinor ?? this.costPerUnitBaseMinor,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      rateAtPurchase: rateAtPurchase ?? this.rateAtPurchase,
    );
  }
}
