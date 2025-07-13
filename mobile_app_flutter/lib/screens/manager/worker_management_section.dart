import 'package:flutter/material.dart';
import '../../services/dummy_analytics_service.dart';
import '../../l10n/app_localizations.dart';
import '../invite_workers_screen.dart';

class WorkerManagementSection extends StatefulWidget {
  @override
  _WorkerManagementSectionState createState() => _WorkerManagementSectionState();
}

class _WorkerManagementSectionState extends State<WorkerManagementSection> {
  late List<Map<String, dynamic>> _allWorkers;
  List<Map<String, dynamic>> _filteredWorkers = [];
  List<String> _activityLog = []; // New list for aggregated activity log
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _allWorkers = DummyAnalyticsService.getWorkersData();
    _filteredWorkers = List.from(_allWorkers); // Initialize with all workers
    _searchController.addListener(_filterWorkers);
    _generateActivityLog(); // Generate initial activity log
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterWorkers);
    _searchController.dispose();
    super.dispose();
  }

  void _filterWorkers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredWorkers = _allWorkers.where((worker) {
        final nameLower = worker['name']?.toLowerCase() ?? '';
        final roleLower = worker['role']?.toLowerCase() ?? '';
        return nameLower.contains(query) || roleLower.contains(query);
      }).toList();
    });
  }

  // New method to aggregate worker activities into a single log
  void _generateActivityLog() {
    _activityLog.clear();
    for (var worker in _allWorkers) {
      final String workerName = worker['name'] ?? 'Unknown Worker';
      final List<String> actions = (worker['actionsToday'] as List?)?.map((e) => e.toString()).toList() ?? [];
      if (actions.isNotEmpty) {
        for (var action in actions) {
          _activityLog.add('$workerName: $action');
        }
      }
    }
  }

  void _removeWorker(int index) {
    setState(() {
      final workerToRemove = _filteredWorkers[index];
      _filteredWorkers.removeAt(index);
      _allWorkers.removeWhere((worker) => worker['id'] == workerToRemove['id']); // Remove from all workers list too
      _generateActivityLog(); // Regenerate log after worker removal
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.workerRemoved)));
  }

  void _inviteWorker() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WorkerInvitationScreen()),
    );
  }

  // Placeholder for worker profile view
  void _viewWorkerProfile(Map<String, dynamic> worker) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final localizations = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(localizations.workerProfile),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('${localizations.managerName}: ${worker['name']}'),
                Text('${localizations.managerPhone}: ${worker['phone']}'),
                Text('${localizations.lastActivity}: ${worker['lastActivity']}'),
                const SizedBox(height: 16),
                Text(localizations.actionsToday, style: const TextStyle(fontWeight: FontWeight.bold)),
                if ((worker['actionsToday'] as List).isEmpty)
                  Text(localizations.noActivityRecorded)
                else
                  ... (worker['actionsToday'] as List).map((action) => Text('- $action')).toList(),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.workerManagementCenter),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Block: Worker Management (Search, Invite, List Existing Workers)
            Expanded(
              flex: 3, // Adjust flex to control vertical space distribution
              child: Card(
                margin: const EdgeInsets.all(16.0),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.manageWorkers, // Changed title to be more specific
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: localizations.searchWorkers,
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _inviteWorker,
                        icon: const Icon(Icons.person_add_rounded),
                        label: Text(localizations.inviteWorker),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50), // Make button full width
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _filteredWorkers.isEmpty
                            ? Center(child: Text(localizations.noWorkersFound))
                            : ListView.builder(
                                itemCount: _filteredWorkers.length,
                                itemBuilder: (context, index) {
                                  final worker = _filteredWorkers[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    child: ListTile(
                                      leading: CircleAvatar(child: Text(worker['name']![0])),
                                      title: Text(worker['name']!),
                                      subtitle: Text(worker['role']!),
                                      onTap: () => _viewWorkerProfile(worker), // View profile on tap
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_rounded, color: Colors.red),
                                        onPressed: () => _removeWorker(index),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom Block: Worker Activity Log
            Expanded(
              flex: 2, // Adjust flex to control vertical space distribution
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.workerActivityLog,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _activityLog.isEmpty
                            ? Center(child: Text(localizations.noActivityRecorded))
                            : ListView.builder(
                                itemCount: _activityLog.length,
                                itemBuilder: (context, index) {
                                  final activity = _activityLog[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Text(
                                      activity,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
