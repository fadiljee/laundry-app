import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../../../../core/providers/auth_provider.dart';

class OrderRemoteDataSource {
  final String baseUrl = "https://prize-pancake-spore.ngrok-free.dev/api";

  // Helper untuk Header (Biar nggak ngetik token berulang-ulang)
  Future<Map<String, String>> _getHeaders() async {
    String? token = await AuthStorage.getToken();
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. Ambil Semua Order
  Future<List<OrderModel>> getAllOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body)['data'];
      return data.map((item) => OrderModel.fromJson(item)).toList();
    } else {
      throw Exception("Gagal mengambil daftar pesanan");
    }
  }

  // 2. Create Order (PERBAIKAN: imageFile sekarang boleh null)
  Future<OrderModel> createOrder(Map<String, String> data, File? imageFile) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/orders'));
    request.headers.addAll(await _getHeaders());
    request.fields.addAll(data);

    // Cek: Kalau gambarnya ada, baru dimasukin ke request
    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return OrderModel.fromJson(json.decode(response.body)['data']);
    } else {
      print("Error Laravel: ${response.body}");
      throw Exception("Gagal simpan pesanan ke server");
    }
  }

  // 3. Ambil Detail Order (UNTUK TRACKING)
  Future<OrderModel> getOrderDetail(String code) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/$code'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return OrderModel.fromJson(json.decode(response.body)['data']);
    } else {
      throw Exception("Pesanan dengan kode $code tidak ditemukan");
    }
  }

  // 4. Konfirmasi Pembayaran
  Future<void> confirmPayment(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$id/pay'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception("Gagal konfirmasi pembayaran");
    }
  }

  // 5. Update Status Kurir/Admin
  Future<void> updateOrderStatus(int orderId, String newStatus) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/status'),
      headers: await _getHeaders(), // Langsung pakai helper header
      body: {
        'status': newStatus,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengupdate status pesanan');
    }
  }

  // 6. FUNGSI BARU: UPLOAD FOTO SUSULAN TIMBANGAN (FIXED)
  Future<void> uploadOrderImage(int orderId, File imageFile) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/orders/$orderId/image'));
    request.headers.addAll(await _getHeaders());
    
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    // PERBAIKAN: Tambahkan timeout maksimal 20 detik. 
    // Kalau server/ngrok tidak merespons, dia akan otomatis membatalkan dan menampilkan error.
    var streamedResponse = await request.send().timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        throw Exception("Koneksi lambat atau terputus. Silakan coba lagi.");
      },
    );
    
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Gagal mengupload foto timbangan: ${response.body}');
    }
  }
}