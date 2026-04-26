import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/datasources/order_remote_datasource.dart';
import '../../data/models/order_model.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS (Modern Clean Light Theme)
// ─────────────────────────────────────────────────────────────
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

class _OrderListPageState extends State<OrderListPage>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // --- FUNGSI REFRESH ---
  Future<void> _onRefresh() async {
    setState(() {});
  }

  // --- FUNGSI UPLOAD FOTO ---
  Future<void> _uploadNewPhoto(int orderId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera, 
      imageQuality: 60,
      maxWidth: 1024,  
      maxHeight: 1024,
    );
    
    if (pickedFile != null) {
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: _T.accent)),
      );

      try {
        await OrderRemoteDataSource().uploadOrderImage(orderId, File(pickedFile.path));
        
        if (!mounted) return;
        Navigator.pop(context); // Tutup loading
        Navigator.pop(context); // Tutup dialog foto
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text("Foto timbangan berhasil diupload!"), backgroundColor: _T.success),
        );
        _onRefresh(); 
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Tutup loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal upload: $e"), backgroundColor: _T.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, 
      child: Scaffold(
        backgroundColor: _T.bg,
        appBar: AppBar(
          backgroundColor: _T.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: _T.textMain),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _T.border, height: 1),
          ),
          title: Text(
            "Daftar Pesanan",
            style: GoogleFonts.poppins(color: _T.textMain, fontWeight: FontWeight.w700, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: _T.accent,
              backgroundColor: _T.surface,
              child: FutureBuilder<List<OrderModel>>(
                future: OrderRemoteDataSource().getAllOrders(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}", style: GoogleFonts.inter(color: _T.danger)));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: _T.accent));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final orders = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(orders[index]);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(color: _T.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tag_rounded, size: 16, color: _T.accent),
                    const SizedBox(width: 4),
                    Text(order.orderCode, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: _T.textMain, letterSpacing: 1.0, fontSize: 14)),
                  ],
                ),
                _buildStatusBadge(order.status),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.person_rounded, "Pelanggan", order.customerName),
                _buildInfoRow(Icons.local_laundry_service_rounded, "Layanan", order.service),
                _buildInfoRow(Icons.scale_rounded, "Berat", "${order.weight} Kg"),
                const SizedBox(height: 20),
                
                // --- ACTION BUTTONS (SISA QR & FOTO SAJA) ---
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showQrDialog(order.orderCode),
                        icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                        label: Text("QR Code", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _T.textMain,
                          side: const BorderSide(color: _T.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showPhotoDialog(order),
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: Text("Timbangan", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _T.accent,
                          side: const BorderSide(color: _T.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: _T.surface, shape: BoxShape.circle),
            child: const Icon(Icons.inbox_rounded, size: 64, color: _T.border),
          ),
          const SizedBox(height: 24),
          Text("Belum ada pesanan", style: GoogleFonts.poppins(color: _T.textMain, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text("Daftar pesanan pelanggan akan muncul di sini.", style: GoogleFonts.inter(color: _T.textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _T.textMuted.withOpacity(0.7)),
          const SizedBox(width: 12),
          Text("$label: ", style: GoogleFonts.inter(color: _T.textMuted, fontSize: 13)),
          Expanded(child: Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _T.textMain, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor = status.toLowerCase().contains('bayar') ? _T.warning : _T.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.2)),
      ),
      child: Text(status, style: GoogleFonts.inter(color: badgeColor, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  // --- DIALOG TAMPILKAN QR CODE ---
  void _showQrDialog(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _T.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: _T.border)),
        title: Center(child: Text("QR Pelanggan", style: GoogleFonts.poppins(color: _T.textMain, fontWeight: FontWeight.w700))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _T.bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: _T.border)),
              child: SizedBox(
                width: 180,
                height: 180,
                child: QrImageView(
                  data: code,
                  version: QrVersions.auto,
                  size: 180.0,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: _T.textMain),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: _T.textMain),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(code, style: GoogleFonts.poppins(color: _T.accent, fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: 1.5)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text("Tutup", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _T.textMuted)),
          )
        ],
      ),
    );
  }

  // --- DIALOG FOTO TIMBANGAN ---
  void _showPhotoDialog(OrderModel order) {
    final String? imageUrl = order.imageUrl; 

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _T.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: _T.border)),
        title: Text("Bukti Timbangan", style: GoogleFonts.poppins(color: _T.textMain, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.7, 
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200, color: _T.bg,
                          child: const Center(child: Icon(Icons.broken_image_rounded, size: 50, color: _T.border)),
                        ),
                      ),
                    )
                  : Container(
                      height: 150, width: double.infinity,
                      decoration: BoxDecoration(color: _T.bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _T.border)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image_not_supported_rounded, size: 40, color: _T.textMuted),
                          const SizedBox(height: 8),
                          Text("Belum ada foto", style: GoogleFonts.inter(color: _T.textMuted)),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _uploadNewPhoto(order.id), 
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: Text(imageUrl == null ? "Upload Foto" : "Ganti Foto", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text("Tutup", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _T.textMuted)),
          )
        ],
      ),
    );
  }
}