import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerPage extends StatelessWidget {
  const QrScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Nota Laundry')),
      body: MobileScanner(
        // Fungsi ini jalan pas scanner nemu QR code
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            debugPrint('Barcode found! ${barcode.rawValue}');
            
            // Nanti di sini kita arahkan ke halaman Tracking
            // Navigator.push(context, MaterialPageRoute(builder: (...) => TrackingPage(id: barcode.rawValue)));
            
            // Untuk sekarang, kita back dulu sambil bawa data
            Navigator.pop(context, barcode.rawValue);
          }
        },
      ),
    );
  }
}