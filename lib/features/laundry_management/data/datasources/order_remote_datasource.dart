import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // PASTIKAN INI Future<String>, BUKAN Future<void>
  Future<String> createOrder({
    required String name,
    required String phone,
    required double weight,
    required String service,
    required File imageFile,
  }) async {
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Gunakan DocumentReference untuk menangkap data yang baru disimpan
      DocumentReference docRef = await _firestore.collection('orders').add({
        'customer_name': name,
        'wa_number': phone,
        'weight': weight,
        'service': service,
        'image_base64': base64Image,
        'status': 'Menunggu Pembayaran',
        'created_at': FieldValue.serverTimestamp(),
      });
      
      // Kembalikan ID dokumennya ke UI
      return docRef.id; 
    } catch (e) {
      print("Error di DataSource: $e");
      throw Exception("Gagal simpan: $e");
    }
  }

  // Tambahkan di dalam class OrderRemoteDataSource
Future<void> processPayment({
  required String docId,
  required double totalAmount,
  required String paymentMethod,
}) async {
  try {
    await _firestore.collection('orders').doc(docId).update({
      'status': 'Sudah Dibayar',
      'total_price': totalAmount,
      'payment_method': paymentMethod,
      'payment_at': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    throw Exception("Gagal memproses pembayaran: $e");
  }
}
}