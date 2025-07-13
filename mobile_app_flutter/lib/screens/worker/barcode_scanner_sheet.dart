import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class BarcodeScannerSheet extends StatefulWidget {
  final Function(String barcode) onScanned;

  const BarcodeScannerSheet({Key? key, required this.onScanned})
    : super(key: key);

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet> {
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status == PermissionStatus.granted;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return const Center(child: Text('Camera permission denied.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Product')),
      body: MobileScanner(
        controller: MobileScannerController(),
        onDetect: (barcodeCapture) {
          final barcode = barcodeCapture.barcodes.first.rawValue;
          if (barcode != null) {
            widget.onScanned(barcode); // Let _launchScanner handle the pop
          }
        },
      ),
    );
  }
}
