import 'dart:async'; // Make sure this is imported at the top
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // for barcode scanning
import '../../services/api_service_selector.dart'; // Your API interface
import '../../services/api_provider.dart'; // Adjust path as needed
import 'barcode_scanner_sheet.dart';

class StockEntryScreen extends StatefulWidget {
  const StockEntryScreen({super.key});

  @override
  State<StockEntryScreen> createState() => _StockEntryScreenState();
}

class _StockEntryScreenState extends State<StockEntryScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();

  bool _isScanning = false;
  bool _isSubmitting = false;
  final ApiProvider apiService = ApiServiceSelector().switchTo(ApiMode.dummy);

  void _onBarcodeScanned(String barcode) {
    setState(() {
      _barcodeController.text = barcode;
      _isScanning = false;
    });

    // Optionally call API to auto-fill name/unit if barcode is known
    // You could do something like: apiService.lookupBarcode(barcode)
  }

  Future<void> _submit() async {
    final barcode = _barcodeController.text.trim();
    final name = _nameController.text.trim();
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
    final unit = _unitController.text.trim().isEmpty
        ? "unit"
        : _unitController.text.trim();

    if (name.isEmpty || quantity <= 0) {
      _showSnackBar("Please enter valid item name and quantity.");
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await apiService.recordStockItem({
      'barcode': barcode,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'timestamp': DateTime.now().toIso8601String(),
    });

    setState(() => _isSubmitting = false);

    if (success) {
      _clearForm();
      _showSnackBar("Item recorded ✅");
    } else {
      _showSnackBar("Failed to record item ❌");
    }
  }

  void _clearForm() {
    _barcodeController.clear();
    _nameController.clear();
    _quantityController.clear();
    _unitController.clear();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _launchScanner() async {
    final completer = Completer<String>();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BarcodeScannerSheet(
          onScanned: (String barcode) {
            completer.complete(barcode);
            Navigator.pop(context); // Close the scanner screen
          },
        ),
      ),
    );

    final result = await completer.future;

    if (result.isNotEmpty) {
      setState(() {
        _barcodeController.text = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Record Stock")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _isScanning
              ? _buildScanner()
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barcode field
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _barcodeController,
                              decoration: const InputDecoration(
                                labelText: 'Barcode (optional)',
                                prefixIcon: Icon(Icons.qr_code),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.camera_alt),
                            tooltip: "Scan",
                            onPressed: _launchScanner,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Name
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                          prefixIcon: Icon(Icons.inventory),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Quantity
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                                prefixIcon: Icon(Icons.confirmation_num),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _unitController,
                              decoration: const InputDecoration(
                                labelText: 'Unit (e.g. pcs, L, box)',
                                prefixIcon: Icon(Icons.straighten),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: _isSubmitting
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text("Record Item"),
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          onDetect: (barcodeCapture) {
            final code = barcodeCapture.barcodes.first.rawValue;
            if (code != null && code.isNotEmpty) {
              _onBarcodeScanned(code);
            }
          },
        ),
        Positioned(
          top: 16,
          right: 16,
          child: ElevatedButton(
            onPressed: () => setState(() => _isScanning = false),
            child: const Icon(Icons.close),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }
}
