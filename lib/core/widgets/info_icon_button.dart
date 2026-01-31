import 'package:flutter/material.dart';

/// Reusable info icon button that shows explanation in a bottom sheet
class InfoIconButton extends StatelessWidget {
  final String title;
  final String explanation;

  const InfoIconButton({
    super.key,
    required this.title,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.info_outline,
        size: 18,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () => _showExplanation(context),
    );
  }

  void _showExplanation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Explanation
            Text(
              explanation,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
            ),
            const SizedBox(height: 24),

            // Close button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Anladım'),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

/// Pre-defined explanations for financial metrics
class FinancialExplanations {
  static const netWorth =
      'Tüm yatırımlarını satıp borçlarını kapatırsan elinde kalacak toplam değerdir. Uzun vadeli finansal durumunu gösterir.';

  static const cashBalance =
      'Şu an harcayabileceğin banka veya cüzdan bakiyeni temsil eder. Eksi ise borç veya kredi kartı kullanımı vardır.';

  static const monthlyIncome =
      'Bu ay kazandığın toplam paradır. Maaş ve diğer gelirleri kapsar.';

  static const monthlyExpense =
      'Bu ay yaptığın harcamaların toplamıdır. Nakit akışını kontrol etmek için kullanılır.';

  static const totalAssets =
      'Altın, kripto ve hisse gibi yatırımlarının bugünkü toplam değeridir. Günlük harcamalar için kullanılmaz.';
}
