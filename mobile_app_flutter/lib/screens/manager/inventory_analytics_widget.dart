// lib/widgets/inventory_analytics_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/dummy_analytics_service.dart'; // Adjust import path
import '../../l10n/app_localizations.dart'; // Import for localization

class InventoryAnalyticsWidget extends StatelessWidget {
  const InventoryAnalyticsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final data = DummyAnalyticsService.getWeeklyStockData();

    // Extracting data for the chart
    final List<FlSpot> stockInSpots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), (entry.value['stockIn'] as int).toDouble());
    }).toList();

    final List<FlSpot> stockOutSpots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), (entry.value['stockOut'] as int).toDouble());
    }).toList();

    // Determine max Y value for the chart to set appropriate maxY
    double maxYValue = 0;
    for (var item in data) {
      if (item['stockIn'] > maxYValue) maxYValue = item['stockIn'].toDouble();
      if (item['stockOut'] > maxYValue) maxYValue = item['stockOut'].toDouble();
    }
    // Add some buffer to maxY for better visual spacing
    maxYValue = (maxYValue + 10).ceilToDouble(); // Round up and add 10

    // Get localized day names
    final List<String> localizedDays = [
      localizations.monday,
      localizations.tuesday,
      localizations.wednesday,
      localizations.thursday,
      localizations.friday,
      localizations.saturday,
      localizations.sunday,
    ];

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.weeklyStockMovementAnalytics,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250, // Fixed height for the chart area
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxYValue / 5, // Dynamic interval based on maxY
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: maxYValue / 5, // Use the same dynamic interval
                        getTitlesWidget: (value, meta) {
                          // Format y-axis labels as integers
                          return Text(
                            value.toInt().toString(),
                            style: theme.textTheme.bodySmall,
                          );
                        },
                        reservedSize: 30, // Reserve space for labels to prevent overlap with chart
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1, // Show label for each day
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < localizedDays.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                localizedDays[index],
                                style: theme.textTheme.bodySmall,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      left: BorderSide(color: Colors.black54),
                      bottom: BorderSide(color: Colors.black54),
                    ),
                  ),
                  minY: 0,
                  maxY: maxYValue, // Set dynamic max Y
                  lineBarsData: [
                    // Stock In Line: Neutral Blue
                    LineChartBarData(
                      spots: stockInSpots,
                      isCurved: true,
                      color: Colors.blueGrey, // Changed to neutral blue
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blueGrey.withOpacity(0.2),
                      ),
                    ),
                    // Stock Out (Sales) Line: Green
                    LineChartBarData(
                      spots: stockOutSpots,
                      isCurved: true,
                      color: Colors.green, // Changed to green
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
