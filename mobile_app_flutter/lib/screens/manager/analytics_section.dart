// analytics_section.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/dummy_analytics_service.dart';

class AnalyticsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = DummyAnalyticsService.getWeeklyStockData();

    final isWide = MediaQuery.of(context).size.width > 600;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 16),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _SummaryCards(data: data)),
                  SizedBox(width: 24),
                  Expanded(child: _BarChartWidget(data: data)),
                ],
              )
            : Column(
                children: [
                  _SummaryCards(data: data),
                  SizedBox(height: 24),
                  _BarChartWidget(data: data),
                ],
              ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  _SummaryCards({required this.data});

  int _sumField(String key) => data.fold(0, (sum, item) => sum + (item[key] as int));

  @override
  Widget build(BuildContext context) {
    final stockInTotal = _sumField('stockIn');
    final stockOutTotal = _sumField('stockOut');
    final missedSalesTotal = _sumField('missedSales');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _InfoCard(label: 'Stock In', value: stockInTotal.toString()),
        _InfoCard(label: 'Stock Out', value: stockOutTotal.toString()),
        _InfoCard(label: 'Missed Sales', value: missedSalesTotal.toString()),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;

  _InfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[800])),
            SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _BarChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  _BarChartWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final weeks = data.map((e) => e['week'] as String).toList();

    final stockInSpots = <BarChartGroupData>[];
    final stockOutSpots = <BarChartGroupData>[];

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      stockInSpots.add(
        BarChartGroupData(x: i, barRods: [
          BarChartRodData(toY: (item['stockIn'] as int).toDouble(), color: Colors.green),
        ]),
      );
      stockOutSpots.add(
        BarChartGroupData(x: i, barRods: [
          BarChartRodData(toY: (item['stockOut'] as int).toDouble(), color: Colors.red),
        ]),
      );
    }

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          groupsSpace: 20,
          barGroups: [
            ...stockInSpots,
            ...stockOutSpots,
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, interval: 20),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= weeks.length) return Container();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(weeks[index], style: TextStyle(fontSize: 12)),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: true),
          alignment: BarChartAlignment.spaceAround,
          maxY: 160,
        ),
      ),
    );
  }
}
