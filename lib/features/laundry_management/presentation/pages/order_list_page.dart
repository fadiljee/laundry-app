import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/datasources/order_remote_datasource.dart';
import '../../data/models/order_model.dart';

class _T {
  static const bg          = Color(0xFFF8FAFC); 
  static const surface     = Color(0xFFFFFFFF); 
  static const accent      = Color(0xFF2563EB); 
  static const border      = Color(0xFFE2E8F0); 
  static const textMain    = Color(0xFF0F172A); 
  static const textMuted   = Color(0xFF64748B); 
  static const success     = Color(0xFF10B981); 
  static const warning     = Color(0xFFF59E0B); 
  static const danger      = Color(0xFFEF4444); 
}

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<String> _adminStatusOptions = [
    'Menunggu Pembayaran',
    'Lunas - Siap Jemput',
    'Proses Cuci',
    'Proses Antar',
    'Selesai'
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async { setState(() {}); }

  // --- LOGIC: UPLOAD FOTO ---
  Future<void> _uploadNewPhoto(int orderId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 60);
    if (pickedFile != null) {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      try {
        await OrderRemoteDataSource().uploadOrderImage(orderId, File(pickedFile.path));
        if (!mounted) return;
        Navigator.pop(context); // Tutup loading
        Navigator.pop(context); // Tutup dialog foto
        _onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Foto berhasil diupload!"), backgroundColor: _T.success));
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: _T.danger));
      }
    }
  }

  // --- LOGIC: UPDATE STATUS ---
  Future<void> _updateStatus(int id, String status) async {
    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      await OrderRemoteDataSource().updateOrderStatus(id, status);
      Navigator.pop(context);
      _onRefresh();
    } catch (e) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.surface, elevation: 0,
        title: Text("Daftar Pesanan Admin", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: _T.textMain)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: FutureBuilder<List<OrderModel>>(
          future: OrderRemoteDataSource().getAllOrders(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Belum ada pesanan"));
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) => _buildOrderCard(snapshot.data![index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    bool isUnweighed = order.weight == 0 || order.weight == 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: _T.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: _T.border)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: _T.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.orderCode, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                _buildStatusBadge(order.status),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(Icons.person, "Pelanggan", order.customerName),
                _buildInfoRow(Icons.local_laundry_service, "Layanan", order.service),
                _buildInfoRow(Icons.scale, "Berat", isUnweighed ? "Belum diinput" : "${order.weight} Kg", 
                  trailing: _buildEditBtn(isUnweighed, () => _showUpdateWeightDialog(order))),
                const Divider(height: 32),
                
                // Dropdown Status
                Row(
                  children: [
                    const Icon(Icons.published_with_changes_rounded, size: 20, color: _T.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: _T.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _T.border)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _adminStatusOptions.contains(order.status) ? order.status : _adminStatusOptions[0],
                            isExpanded: true,
                            items: _adminStatusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (val) => _updateStatus(order.id, val!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- TOMBOL AKSI (QR & TIMBANGAN) KEMBALI LAGI ---
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showQrDialog(order.orderCode),
                        icon: const Icon(Icons.qr_code_scanner, size: 18),
                        label: const Text("QR Code"),
                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showPhotoDialog(order),
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text("Timbangan"),
                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- REVISI DIALOG FOTO ---
  void _showPhotoDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Bukti Timbangan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            order.imageUrl != null 
              ? Image.network(order.imageUrl!, height: 200, fit: BoxFit.cover)
              : const Text("Belum ada foto"),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _uploadNewPhoto(order.id),
              icon: const Icon(Icons.camera),
              label: const Text("Ambil Foto"),
              style: ElevatedButton.styleFrom(backgroundColor: _T.accent, foregroundColor: Colors.white),
            )
          ],
        ),
      ),
    );
  }

  void _showQrDialog(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 200, height: 200, child: QrImageView(data: code, version: QrVersions.auto)),
          const SizedBox(height: 10),
          Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
      ),
    );
  }

  // --- DIALOG INPUT BERAT ---
  void _showUpdateWeightDialog(OrderModel order) {
    final TextEditingController weightCtrl = TextEditingController(text: isUnweighed(order) ? '' : order.weight.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Input Berat"),
        content: TextField(controller: weightCtrl, keyboardType: TextInputType.number),
        actions: [
          ElevatedButton(onPressed: () async {
            await OrderRemoteDataSource().updateOrderWeight(order.id, weightCtrl.text);
            Navigator.pop(ctx);
            _onRefresh();
          }, child: const Text("Simpan"))
        ],
      ),
    );
  }

  bool isUnweighed(OrderModel o) => o.weight == 0 || o.weight == 0.0;
  Widget _buildEditBtn(bool isNew, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: isNew ? _T.warning.withOpacity(0.1) : _T.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(isNew ? "Input" : "Edit", style: TextStyle(color: isNew ? _T.warning : _T.accent, fontSize: 11, fontWeight: FontWeight.bold))));
  Widget _buildInfoRow(IconData icon, String label, String value, {Widget? trailing}) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Icon(icon, size: 18, color: _T.textMuted), const SizedBox(width: 12), Text("$label: ", style: const TextStyle(color: _T.textMuted, fontSize: 13)), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))), if (trailing != null) trailing]));
  Widget _buildStatusBadge(String status) { Color color = status.contains('Lunas') || status.contains('Selesai') ? _T.success : _T.warning; return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))); }
}