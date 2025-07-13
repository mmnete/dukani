import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart'; // Import for localization

class StockSummaryWidget extends StatelessWidget {
  final int stockIn;
  final int stockOut;
  final int missedSales;

  const StockSummaryWidget({
    Key? key,
    required this.stockIn,
    required this.stockOut,
    required this.missedSales,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                localizations.quickStockOverview,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryItem(context, localizations.stockIn, stockIn, Colors.blueGrey),
                const VerticalDivider(thickness: 1.5, width: 20, color: Colors.grey),
                _buildSummaryItem(context, localizations.stockOut, stockOut, Colors.green),
                const VerticalDivider(thickness: 1.5, width: 20, color: Colors.grey),
                _buildSummaryItem(context, localizations.missedSales, missedSales, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, int value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}


