import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../../../../core/providers/auth_provider.dart';

class OrderRemoteDataSource {
  final String baseUrl = "https://lyra.biz.id/api";

  // Helper untuk Header (Biar nggak ngetik token berulang-ulang)
  Future<Map<String, String>> _getHeaders() async {
    String? token = await AuthStorage.getToken();
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. Ambil Order dengan Pagination (DIPERBARUI)
  // Menambahkan parameter page, defaultnya 1
  Future<List<OrderModel>> getOrders({int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders?page=$page'), // Tambahkan query parameter page
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      // Struktur bawaan Laravel paginate() biasanya memiliki array list di dalam key 'data'
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
      headers: await _getHeaders(), 
      body: {
        'status': newStatus,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengupdate status pesanan');
    }
  }

  // --- FUNGSI UPDATE BERAT CUCIAN ---
  Future<void> updateOrderWeight(int orderId, String weight) async {
    String? token = await AuthStorage.getToken();
    
    final url = Uri.parse('$baseUrl/orders/$orderId/weight'); 

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'weight': weight,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengupdate berat cucian: ${response.statusCode}');
    }
  }

  // 6. FUNGSI BARU: UPLOAD FOTO SUSULAN TIMBANGAN (FIXED)
  Future<void> uploadOrderImage(int orderId, File imageFile) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/orders/$orderId/image'));
    request.headers.addAll(await _getHeaders());
    
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

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

  // --- FUNGSI AMBIL DAFTAR KURIR ---
  Future<List<dynamic>> getAvailableCouriers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/couriers'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    } else {
      throw Exception('Gagal memuat daftar kurir');
    }
  }

  // --- FUNGSI ASSIGN KURIR KE ORDER ---
  Future<void> assignCourier(int orderId, int courierId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/assign-courier'),
      headers: await _getHeaders(),
      body: {
        'courier_id': courierId.toString(),
      },
    ).timeout(
      const Duration(seconds: 15), 
      onTimeout: () {
        throw Exception("Server terlalu lama merespons. Proses mungkin sudah berjalan, silakan refresh.");
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal menugaskan kurir');
    }
  }
}