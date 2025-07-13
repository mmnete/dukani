import 'package:flutter/material.dart';
import 'stock_entry_screen.dart';
import 'sale_entry_screen.dart';
import 'missed_sale_entry_screen.dart';

class WorkerHomeScreen extends StatelessWidget {
  const WorkerHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Worker Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.inventory),
              label: const Text('Record New Stock'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StockEntryScreen()),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.sell),
              label: const Text('Record Sale'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SaleEntryScreen()),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.report_problem),
              label: const Text('Record Missing Item'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MissedSaleEntryScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
