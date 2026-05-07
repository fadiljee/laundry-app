import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:laundry_app/core/theme/app_theme.dart'; 

class CheckoutPage extends StatefulWidget {
  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  
  // --- TEMPATKAN KODE FUNGSI DI SINI ---
  Future<void> bayarSekarang() async {
    final url = Uri.parse('https://lyra.biz.id/api/payment/token');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'total_harga': 50000, // Ambil dari variabel harga laundry kamu
          'nama': 'Fadil Customer',
          'email': 'fadil@example.com',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String snapToken = data['token'];
        
        // Link pembayaran Midtrans Sandbox
        final paymentUrl = Uri.parse('https://app.sandbox.midtrans.com/snap/v2/vtweb/$snapToken');
        
        if (await canLaunchUrl(paymentUrl)) {
          await launchUrl(paymentUrl, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memproses pembayaran: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pembayaran Laundry")),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          onPressed: () {
            // Panggil fungsi saat tombol diklik
            bayarSekarang();
          },
          child: Text("Bayar via QRIS / Transfer", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}