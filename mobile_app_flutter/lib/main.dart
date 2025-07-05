// dukani/mobile_app_flutter/lib/main.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For local persistence (like AsyncStorage)
import 'dart:convert'; // For JSON encoding/decoding

// Import the new StockEntryScreen from its dedicated file
import 'package:mobile_app_flutter/screens/stock_entry_screen.dart';

// No need for http import or API_BASE_URL here anymore, it's in api_service.dart

// --- Worker Model ---
// This defines the structure for our 'fake' worker
class Worker {
  final String id;
  final String name;
  final String phoneNumber;
  final String shopId;
  final String shopName;

  Worker({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.shopId,
    required this.shopName,
  });

  // Factory constructor to create a Worker from a JSON map
  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      shopId: json['shopId'],
      shopName: json['shopName'],
    );
  }

  // Convert a Worker object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'shopId': shopId,
      'shopName': shopName,
    };
  }
}

// --- Worker Provider (similar to WorkerContext in React) ---
// This InheritedNotifier will provide the current worker to the widget tree
class WorkerNotifier extends ChangeNotifier {
  Worker? _currentWorker;
  bool _isLoading = true;

  Worker? get currentWorker => _currentWorker;
  bool get isLoading => _isLoading;

  WorkerNotifier() {
    print('WorkerNotifier initialized. Starting _loadWorker()...'); // Debug print
    _loadWorker();
  }

  // Define a default fake worker for MVP testing
  // IMPORTANT: REPLACE THESE WITH ACTUAL UUIDS FROM YOUR DJANGO ADMIN
  static final Worker _fakeWorker = Worker(
    id: 'da5bc8d5-63ef-4a06-bf1e-bf221a04cab8', // <-- Replace with actual Worker UUID (e.g., da5bc8d5-63ef-4a06-bf1e-bf221a04cab8)
    name: 'Test Worker (Offline)',
    phoneNumber: '5104248843', // Ensure this matches a Worker in your DB
    shopId: 'd2422927-0956-4044-a2b2-9bc311b3bd83', // <-- IMPORTANT: Replace with actual Shop UUID (e.g., d2422927-0956-4044-a2b2-9bc311b3bd83)
    shopName: 'Main Auto Spares', // Update if your shop name is different
  );

  Future<void> _loadWorker() async {
    print('_loadWorker() started.'); // Debug print
    try {
      final prefs = await SharedPreferences.getInstance();
      print('SharedPreferences instance obtained.'); // Debug print
      final String? workerJson = prefs.getString('currentWorker');
      print('Worker JSON from prefs: $workerJson'); // Debug print

      if (workerJson != null) {
        _currentWorker = Worker.fromJson(jsonDecode(workerJson));
        print('Existing worker loaded: ${_currentWorker?.name}'); // Debug print
      } else {
        _currentWorker = _fakeWorker;
        await prefs.setString('currentWorker', jsonEncode(_fakeWorker.toJson()));
        print('Fake worker set and saved: ${_fakeWorker.name}'); // Debug print
      }
    } catch (e) {
      print('Error in _loadWorker(): $e'); // Debug print for errors
      // Fallback to fake worker if any error occurs during loading
      _currentWorker = _fakeWorker;
      // Attempt to save fake worker, but don't let it block if prefs is truly broken
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('currentWorker', jsonEncode(_fakeWorker.toJson()));
        print('Fake worker set after error fallback.');
      } catch (e2) {
        print('Further error trying to save fake worker after initial load error: $e2');
      }
    } finally {
      _isLoading = false;
      print('_isLoading set to false. Calling notifyListeners()...'); // Debug print
      notifyListeners(); // Notify listeners that loading is complete and worker is set
      print('notifyListeners() called.'); // Debug print
    }
  }

  Future<void> setCurrentWorker(Worker? worker) async {
    _currentWorker = worker;
    final prefs = await SharedPreferences.getInstance();
    if (worker != null) {
      await prefs.setString('currentWorker', jsonEncode(worker.toJson()));
      print('Worker set to: ${worker.name}'); // Debug print
    } else {
      await prefs.remove('currentWorker');
      print('Worker removed from preferences.'); // Debug print
    }
    notifyListeners(); // Notify listeners of the change
  }
}

// Helper to access WorkerNotifier from context
class WorkerProvider extends InheritedNotifier<WorkerNotifier> {
  const WorkerProvider({
    Key? key,
    required WorkerNotifier notifier,
    required Widget child,
  }) : super(key: key, notifier: notifier, child: child);

  static WorkerNotifier of(BuildContext context) {
    final WorkerNotifier? result = context.dependOnInheritedWidgetOfExactType<WorkerProvider>()?.notifier;
    assert(result != null, 'No WorkerProvider found in widget tree');
    return result!;
  }
}

// --- Main Application Widget ---
void main() {
  runApp(
    WorkerProvider(
      notifier: WorkerNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final workerNotifier = WorkerProvider.of(context);

    // Show loading indicator until worker data is loaded
    if (workerNotifier.isLoading) {
      print('MyApp: isLoading is true, showing CircularProgressIndicator.'); // Debug print
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading worker data...'),
              ],
            ),
          ),
        ),
      );
    }
    print('MyApp: isLoading is false, showing HomeScreen.'); // Debug print
    return MaterialApp(
      title: 'Dukani Worker App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      ),
      home: const HomeScreen(),
      routes: {
        '/stock_entry': (context) => const StockEntryScreen(),
        '/sale_entry': (context) => const SaleEntryScreen(),
        '/missed_sale_entry': (context) => const MissedSaleEntryScreen(),
      },
    );
  }
}

// --- Home Screen ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final workerNotifier = WorkerProvider.of(context);
    final worker = workerNotifier.currentWorker;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dukani Worker App'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Dukani Worker App',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (worker != null)
                Text(
                  'Welcome, ${worker.name} (${worker.shopName})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/stock_entry');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
                  child: const Text('Record Stock Entry'),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/sale_entry');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600),
                  child: const Text('Record Sale'),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/missed_sale_entry');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade600),
                  child: const Text('Report Missed Sale'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Placeholder Screens (will be moved to separate files later) ---
// SaleEntryScreen and MissedSaleEntryScreen are still here for now.
class SaleEntryScreen extends StatelessWidget {
  const SaleEntryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Entry'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Record Sale',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'This screen will allow workers to record sold items.\nFeatures: Select product, Enter quantity/price.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class MissedSaleEntryScreen extends StatelessWidget {
  const MissedSaleEntryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missed Sale'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Report Missed Sale',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'This screen will allow workers to report items customers couldn\'t find.\nFeatures: Enter product name, quantity, reason.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
