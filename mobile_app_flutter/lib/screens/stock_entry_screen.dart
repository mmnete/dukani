// dukani/mobile_app_flutter/lib/screens/stock_entry_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_app_flutter/main.dart'; // Import main.dart to access WorkerProvider
import 'package:mobile_app_flutter/services/api_service.dart'; // NEW IMPORT for ApiService

// This screen will handle recording new stock entries.
class StockEntryScreen extends StatefulWidget {
  const StockEntryScreen({Key? key}) : super(key: key);

  @override
  State<StockEntryScreen> createState() => _StockEntryScreenState();
}

class _StockEntryScreenState extends State<StockEntryScreen> {
  // Controllers for text input fields
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController(); // For display only, not sent to StockEntry model
  final TextEditingController _notesController = TextEditingController();

  // State for barcode scan result, image path, and selected product ID
  String? _scannedBarcode;
  String? _imagePath; // Placeholder for image capture path
  // IMPORTANT: REPLACE THIS WITH AN ACTUAL PRODUCT UUID FROM YOUR DJANGO ADMIN
  String? _selectedProductId; // This will be set by scanBarcode or manual lookup

  bool _isSaving = false; // To manage loading state for save button

  // Instantiate ApiService
  final ApiService _apiService = ApiService(); // NEW: Create an instance of ApiService

  @override
  void dispose() {
    // Clean up controllers when the widget is removed from the tree
    _productNameController.dispose();
    _barcodeController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Placeholder for barcode scanning logic
  Future<void> _scanBarcode() async {
    // In a real app, this would use a barcode scanner package (e.g., flutter_barcode_scanner)
    // For now, we'll simulate a scan and also a product lookup.
    _showMessage('Scanning barcode...');
    await Future.delayed(const Duration(seconds: 1)); // Simulate scanning delay

    // Simulate successful scan and product lookup
    setState(() {
      _scannedBarcode = '1234567890123'; // Example scanned barcode
      _barcodeController.text = _scannedBarcode!; // Populate barcode field
      _productNameController.text = 'Simulated Oil Filter X'; // Simulate autofill
      _priceController.text = '15000.00'; // Simulate autofill for display
      // Replace 'YOUR_ACTUAL_PRODUCT_UUID_HERE' with a real Product UUID from your Django Admin
      _selectedProductId = '38c25c93-5264-43c7-a1c0-d75c4d0b52a5'; // <-- IMPORTANT: Replace this!
    });
    _showMessage('Barcode scanned: $_scannedBarcode. Product details autofilled.');
    print('Product Name after scan: ${_productNameController.text}'); // Debug print
    print('Simulated Product ID: $_selectedProductId'); // Debug print
  }

  // Placeholder for image capture logic
  Future<void> _captureImage() async {
    // In a real app, this would use an image picker package (e.g., image_picker)
    // For now, we'll simulate an image capture.
    _showMessage('Capturing image...');
    await Future.delayed(const Duration(seconds: 1)); // Simulate capture delay
    setState(() {
      _imagePath = 'https://placehold.co/600x400/000000/FFFFFF?text=Product+Image'; // Example placeholder image URL
    });
    _showMessage('Image captured!');
  }

  // Function to handle saving the stock entry
  Future<void> _saveStockEntry() async {
    setState(() {
      _isSaving = true; // Set saving state to true
    });

    final workerNotifier = WorkerProvider.of(context);
    final currentWorker = workerNotifier.currentWorker;

    if (currentWorker == null) {
      _showMessage('Error: Worker data not available. Cannot save stock.', isError: true);
      setState(() { _isSaving = false; });
      return;
    }

    print('Attempting to save stock entry...'); // Debug print
    print('Product Name before validation: ${_productNameController.text}'); // Debug print

    // --- Detailed Validation ---
    if (_productNameController.text.trim().isEmpty) {
      _showMessage('Product Name is required.', isError: true);
      setState(() { _isSaving = false; });
      return;
    }

    final int? quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      _showMessage('Please enter a valid Quantity (must be a number greater than 0).', isError: true);
      setState(() { _isSaving = false; });
      return;
    }

    final double? price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      _showMessage('Please enter a valid Unit Price (must be a number greater than 0).', isError: true);
      setState(() { _isSaving = false; });
      return;
    }
    // --- End Detailed Validation ---

    // Ensure a product ID is available if product name is provided
    // In a real app, product lookup would happen after barcode scan or manual name entry
    // For now, if product name is filled, we assume _selectedProductId is set by scan
    if (_selectedProductId == null) {
      _showMessage('Product ID is missing. Please scan a barcode or ensure product is selected.', isError: true);
      setState(() { _isSaving = false; });
      return;
    }

    // Collect all data for the backend API
    final Map<String, dynamic> stockEntryData = {
      'shop': currentWorker.shopId, // Django expects 'shop' ID
      'worker': currentWorker.id,   // Django expects 'worker' ID
      'product': _selectedProductId, // Django expects 'product' ID
      'quantity': quantity,
      'image_url': _imagePath, // Optional
      'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(), // Optional
      // 'recorded_at' is auto-generated by Django
    };

    print('Sending Stock Entry to API: $stockEntryData'); // Debug print

    // Use the ApiService to post the data
    final bool success = await _apiService.postStockEntry(stockEntryData);

    if (success) {
      _showMessage('Stock Entry Saved Successfully!');
      // Clear form fields after successful save
      _productNameController.clear();
      _barcodeController.clear();
      _quantityController.clear();
      _priceController.clear();
      _notesController.clear();
      setState(() {
        _scannedBarcode = null;
        _imagePath = null;
        _selectedProductId = null; // Clear selected product ID
      });
    } else {
      // Error message is already handled by ApiService, but we can add more specific UI feedback here if needed
      _showMessage('Failed to save stock entry. Check terminal for details.', isError: true);
    }

    setState(() {
      _isSaving = false; // Reset saving state
    });
  }

  // Helper function to show a SnackBar message
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating, // Make it float above content
        margin: const EdgeInsets.all(10), // Add some margin
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Entry'),
      ),
      body: SingleChildScrollView( // Allows scrolling if content overflows
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Record Incoming Stock',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Barcode Scan Section
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _scanBarcode, // Disable when saving
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Barcode'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade700, // Improved color
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            if (_scannedBarcode != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Scanned: $_scannedBarcode',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // Manual Entry Form
            TextFormField(
              controller: _productNameController,
              decoration: InputDecoration(
                labelText: 'Product Name',
                hintText: 'e.g., Oil Filter, Spark Plug',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.auto_fix_high),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _barcodeController,
              decoration: InputDecoration(
                labelText: 'Barcode (Optional)',
                hintText: 'Enter barcode manually or scan',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.qr_code),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity Received',
                hintText: 'e.g., 10, 50',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.format_list_numbered),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Unit Price (TZS)',
                hintText: 'e.g., 15000.00',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Any additional details',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.note),
              ),
              maxLines: 3,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 20),

            // Image Capture Section
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _captureImage, // Disable when saving
              icon: const Icon(Icons.camera_alt),
              label: Text(_imagePath != null ? 'Image Captured!' : 'Capture Product Image (Optional)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _imagePath != null ? Colors.grey.shade600 : Colors.deepOrange.shade700, // Improved colors
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            if (_imagePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Image: $_imagePath',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: 30),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveStockEntry, // Disable when saving
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700, // Improved color
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white) // Show spinner when saving
                  : const Text(
                      'Save Stock Entry',
                      style: TextStyle(fontSize: 20),
                    ),
            ),
            const SizedBox(height: 15),

            // Back to Home Button
            OutlinedButton(
              onPressed: _isSaving ? null : () { // Disable when saving
                Navigator.pop(context); // Go back to previous screen
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                side: BorderSide(color: Colors.teal.shade700),
                foregroundColor: Colors.teal.shade700,
              ),
              child: const Text('Back to Home'),
            ),
            const SizedBox(height: 80), // Added generous padding for navigation bar
          ],
        ),
      ),
    );
  }
}
