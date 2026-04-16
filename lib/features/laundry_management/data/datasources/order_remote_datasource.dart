import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class OrderRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> createOrder({
    required String name,
    required String phone,
    required double weight,
    required String service,
    required File imageFile, // Foto timbangan
  }) async {
    try {
      // 1. Upload Foto ke Firebase Storage
      String fileName = 'timbangan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child('orders/$fileName');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      // 2. Simpan Data ke Firestore
      await _firestore.collection('orders').add({
        'customer_name': name,
        'wa_number': phone,
        'weight': weight,
        'service': service,
        'image_url': imageUrl, // Link foto yang baru diupload
        'status': 'Menunggu Pembayaran',
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Gagal simpan pesanan: $e");
    }
  }
}