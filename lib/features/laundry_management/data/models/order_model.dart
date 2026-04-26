class OrderModel {
  final int id;
  final String orderCode;
  final String customerName;
  final double weight;
  final int totalHarga;
  final String status;
  final String statusPembayaran;
  final String address;
  final String service;
  
  // --- TAMBAHAN BARU ---
  final String? imageUrl;
  final double? courierLat;
  final double? courierLng;
  final List<OrderLogModel> logs;

  OrderModel({
    required this.id,
    required this.orderCode,
    required this.customerName,
    required this.weight,
    required this.totalHarga,
    required this.status,
    required this.statusPembayaran,
    required this.address,
    required this.service,
    this.imageUrl,
    this.courierLat,
    this.courierLng,
    required this.logs,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? 0,
      orderCode: json['order_code']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? 'Pelanggan',
      
      weight: json['weight'] is String 
          ? (double.tryParse(json['weight']) ?? 0.0) 
          : (json['weight'] ?? 0).toDouble(),
          
      totalHarga: (json['total_harga'] ?? 0).toInt(),
      status: json['status']?.toString() ?? 'pending',
      statusPembayaran: json['status_pembayaran']?.toString() ?? 'belum_bayar',
      address: json['address']?.toString() ?? 'Tanpa Alamat',
      service: json['service']?.toString() ?? 'Reguler',
      
      // --- PENANGKAP DATA BARU ---
      imageUrl: json['image_url']?.toString(), 
      courierLat: json['courier_lat'] != null ? double.tryParse(json['courier_lat'].toString()) : null,
      courierLng: json['courier_lng'] != null ? double.tryParse(json['courier_lng'].toString()) : null,
      
      logs: (json['logs'] as List? ?? [])
          .map((log) => OrderLogModel.fromJson(log))
          .toList(),
    );
  }
}

class OrderLogModel {
  final String status;
  final String message;
  final DateTime createdAt;

  OrderLogModel({
    required this.status,
    required this.message,
    required this.createdAt,
  });

  factory OrderLogModel.fromJson(Map<String, dynamic> json) {
    return OrderLogModel(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}