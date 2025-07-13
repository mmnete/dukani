// inventory_analytics_widget.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class InventoryAnalyticsWidget extends StatelessWidget {
  const InventoryAnalyticsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inventory Analytics 📊',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Container(
          height: 220,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _InventoryLineChart(),
        ),
      ],
    );
  }
}

class _InventoryLineChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, horizontalInterval: 20),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              getTitlesWidget: (value, _) {
                return Text(value.toInt().toString());
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, _) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return Text(days[value.toInt()]);
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minY: 0,
        maxY: 120,
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 30),
              FlSpot(1, 50),
              FlSpot(2, 40),
              FlSpot(3, 70),
              FlSpot(4, 90),
              FlSpot(5, 100),
              FlSpot(6, 110),
            ],
            isCurved: true,
            barWidth: 3,
            color: Colors.green,
            dotData: FlDotData(show: true),
          ),
          LineChartBarData(
            spots: const [
              FlSpot(0, 20),
              FlSpot(1, 40),
              FlSpot(2, 30),
              FlSpot(3, 60),
              FlSpot(4, 80),
              FlSpot(5, 85),
              FlSpot(6, 90),
            ],
            isCurved: true,
            barWidth: 3,
            color: Colors.red,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}
