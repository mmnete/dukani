import 'package:flutter/material.dart';
// Import your modular widgets
import 'inventory_analytics_widget.dart'; // Adjust import path
import 'stock_summary_widget.dart'; // Adjust import path
import '../../services/dummy_analytics_service.dart'; // Adjust import path
import '../../l10n/app_localizations.dart'; // Import for localization
import '../invite_workers_screen.dart';
import '../worker/stock_entry_screen.dart';
import 'worker_management_section.dart';

class ManagerDashboardScreen extends StatelessWidget {
  final String managerName;

  const ManagerDashboardScreen({Key? key, required this.managerName})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AppLocalizations localizations = AppLocalizations.of(
      context,
    )!; // Get localizations
    final weeklyData = DummyAnalyticsService.getWeeklyStockData();

    // Calculate total stock in, stock out, and missed sales from dummy data
    int totalStockIn = weeklyData.fold(
      0,
      (sum, item) => sum + (item['stockIn'] as int),
    );
    int totalStockOut = weeklyData.fold(
      0,
      (sum, item) => sum + (item['stockOut'] as int),
    );
    int totalMissedSales = weeklyData.fold(
      0,
      (sum, item) => sum + (item['missedSales'] as int),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.welcomeMessage(managerName),
        ), // Localized welcome message
        centerTitle: false, // Align title to the left
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: theme.primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    localizations.managerMenu, // Localized
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    managerName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded),
              title: Text(localizations.dashboardOverview), // Localized
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Already on dashboard, do nothing or refresh
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_rounded),
              title: Text(localizations.manageProducts), // Localized
              onTap: () {
                Navigator.pop(context); // Close the drawer
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${localizations.navigatingTo(localizations.manageProducts)} ${localizations.notImplementedYet}',
                    ),
                  ),
                );
                // TODO: Navigate to Inventory Management Screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_alt_rounded),
              title: Text(localizations.manageWorkers),
              onTap: () {
                Navigator.pop(context);
                // Navigate to the new WorkerInvitationScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WorkerInvitationScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: Text(localizations.profileSettings), // Localized
              onTap: () {
                Navigator.pop(context); // Close the drawer
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${localizations.navigatingTo(localizations.profileSettings)} ${localizations.notImplementedYet}',
                    ),
                  ),
                );
                // TODO: Navigate to Profile Settings Screen
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: Text(localizations.logout), // Localized
              onTap: () {
                Navigator.pop(context); // Close the drawer
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${localizations.navigatingTo(localizations.logout)} ${localizations.notImplementedYet}',
                    ),
                  ),
                );
                // TODO: Implement logout logic
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // This makes the entire dashboard scrollable
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.dashboardOverview, // Localized
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 24),

              // Stock Summary Section
              StockSummaryWidget(
                stockIn: totalStockIn,
                stockOut: totalStockOut,
                missedSales: totalMissedSales,
              ),
              const SizedBox(height: 16),

              // Inventory Analytics Chart Section
              const InventoryAnalyticsWidget(),
              const SizedBox(height: 24),

              // Quick Actions Section
              Text(
                localizations.quickActions, // Localized
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                // Use Wrap for responsive button layout
                spacing: 16.0, // horizontal space between buttons
                runSpacing: 16.0, // vertical space between lines of buttons
                children: [
                  // Prioritized Quick Actions for a Tanzanian small business owner
                  _buildActionButton(
                    context,
                    label: localizations.recordSales, // Localized: Rekodi Mauzo
                    icon: Icons
                        .point_of_sale_rounded, // More fitting icon for sales
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${localizations.recordSales} ${localizations.notImplementedYet}',
                          ),
                        ),
                      );
                      // TODO: Navigate to Record Sales Screen
                    },
                  ),
                  _buildActionButton(
                    context,
                    label:
                        localizations.recordStockIn, // Localized: Ingiza Bidhaa
                    icon: Icons.add_box_rounded, // Icon for adding stock
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StockEntryScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionButton(
                    context,
                    label: localizations
                        .viewInventory, // Localized: Angalia Bidhaa
                    icon: Icons.inventory_rounded, // Icon for viewing inventory
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${localizations.viewInventory} ${localizations.notImplementedYet}',
                          ),
                        ),
                      );
                      // TODO: Navigate to View Inventory Screen
                    },
                  ),
                  _buildActionButton(
                    context,
                    label:
                        localizations.salesReport, // Localized: Ripoti ya Mauzo
                    icon: Icons.receipt_long_rounded, // Icon for sales report
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${localizations.salesReport} ${localizations.notImplementedYet}',
                          ),
                        ),
                      );
                      // TODO: Navigate to Sales Report Screen
                    },
                  ),
                  _buildActionButton(
                    context,
                    label: localizations
                        .manageProducts, // Localized: Dhibiti Bidhaa
                    icon: Icons.category_rounded, // Icon for managing products
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${localizations.manageProducts} ${localizations.notImplementedYet}',
                          ),
                        ),
                      );
                      // TODO: Navigate to Manage Products CRUD Screen
                    },
                  ),
                  _buildActionButton(
                    context,
                    label: localizations
                        .manageWorkers, // Localized: Dhibiti Wafanyakazi
                    icon: Icons.people_alt_rounded, // Icon for managing workers
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkerManagementSection(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24), // Extra space at the bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 160, // Fixed width for action buttons for better alignment in Wrap
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(label, textAlign: TextAlign.center),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.white, // White background for actions
          foregroundColor: Colors.blueGrey, // Darker text/icon color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.blueGrey.withOpacity(0.2), width: 1),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
