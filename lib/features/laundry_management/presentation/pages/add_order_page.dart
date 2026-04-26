import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart'; 
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
  static const accentDark  = Color(0xFF1D4ED8); 
  static const border      = Color(0xFFE2E8F0); 
  static const textMain    = Color(0xFF0F172A); 
  static const textMuted   = Color(0xFF64748B); 
  static const danger      = Color(0xFFEF4444); 
}

class AddOrderPage extends StatefulWidget {
  const AddOrderPage({super.key});

  @override
  State<AddOrderPage> createState() => _AddOrderPageState();
}

class _AddOrderPageState extends State<AddOrderPage>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _weightController = TextEditingController();
  
  String _selectedService = 'Cuci Kering';
  final List<String> _services = ['Cuci Kering', 'Cuci Setrika', 'Setrika Saja', 'Bedcover'];
  
  bool _isLoading = false;

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
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveOrder() async {
    // Validasi Input (Hapus pengecekan gambar)
    if (_nameController.text.isEmpty || 
        _addressController.text.isEmpty || 
        _weightController.text.isEmpty) {
      _showSnackBar("Nama, Alamat & Berat wajib diisi!", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Siapkan Map Data untuk Laravel
      final Map<String, String> orderData = {
        'customer_name': _nameController.text.trim(),
        'wa_number': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'weight': _weightController.text.trim(),
        'service': _selectedService,
      };

      // 2. Tembak API Laravel via OrderRemoteDataSource
      // (Pastikan fungsi createOrder di datasource kamu juga tidak lagi memaksa _selectedImage)
      final OrderModel newOrder = await OrderRemoteDataSource().createOrder(
        orderData, 
        null, // Kirim null untuk gambar
      );

      if (!mounted) return;
      
      // 3. Tampilkan Dialog Sukses dengan QR Code dari Order Code Laravel
      _showSuccessDialog(newOrder.orderCode);

    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Gagal Simpan: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? _T.danger : _T.accentDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _T.surface,
        surfaceTintColor: Colors.transparent, 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: _T.border, width: 1),
        ),
        title: Center(
          child: Text(
            "Pesanan Berhasil!",
            style: GoogleFonts.poppins(color: _T.textMain, fontWeight: FontWeight.w700, fontSize: 20),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Scan QR untuk Tracking",
              style: GoogleFonts.inter(color: _T.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _T.bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _T.border),
              ),
              child: SizedBox(
                width: 180,
                height: 180,
                child: QrImageView(
                  data: code,
                  version: QrVersions.auto,
                  size: 180.0,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: _T.textMain,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: _T.textMain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              code,
              style: GoogleFonts.poppins(
                color: _T.accent,
                fontWeight: FontWeight.w700,
                fontSize: 22,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); 
                  Navigator.pop(context); 
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.accent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  "Selesai", 
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
            "Input Pesanan Baru", 
            style: GoogleFonts.poppins(color: _T.textMain, fontWeight: FontWeight.w700, fontSize: 18)
          ),
          centerTitle: true,
        ),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Nama Pelanggan"),
                  _buildTextField(controller: _nameController, hint: "Masukkan nama", icon: Icons.person_rounded),
                  const SizedBox(height: 20),
                  
                  _buildLabel("No. WhatsApp"),
                  _buildTextField(controller: _phoneController, hint: "08xxxxxxxx", icon: Icons.phone_rounded, keyboardType: TextInputType.phone),
                  const SizedBox(height: 20),

                  _buildLabel("Alamat Lengkap"),
                  _buildTextField(controller: _addressController, hint: "Jl. Contoh No. 123", icon: Icons.location_on_rounded),
                  const SizedBox(height: 20),
                  
                  _buildLabel("Layanan"),
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedService,
                      dropdownColor: _T.surface,
                      icon: const Icon(Icons.expand_more_rounded, color: _T.textMuted),
                      style: GoogleFonts.inter(color: _T.textMain, fontWeight: FontWeight.w500),
                      items: _services.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => _selectedService = val!),
                      decoration: _inputDecoration(Icons.local_laundry_service_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildLabel("Berat Cucian (Kg)"),
                  _buildTextField(controller: _weightController, hint: "0.0", icon: Icons.scale_rounded, keyboardType: TextInputType.number),
                  
                  // FOTO TIMBANGAN TELAH DIHAPUS DARI SINI
                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSaveOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _T.accent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        shadowColor: _T.accent.withOpacity(0.4),
                      ),
                      child: _isLoading 
                          ? const SizedBox(
                              height: 24, width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              "Simpan Pesanan", 
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5)
                            ),
                    ),
                  ),
                  const SizedBox(height: 20), 
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text, 
        style: GoogleFonts.inter(fontSize: 13, color: _T.textMain, fontWeight: FontWeight.w600)
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(color: _T.textMain, fontWeight: FontWeight.w500),
        decoration: _inputDecoration(icon).copyWith(hintText: hint),
      ),
    );
  }

  InputDecoration _inputDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: _T.accent.withOpacity(0.8), size: 22),
      filled: true,
      fillColor: _T.surface,
      hintStyle: GoogleFonts.inter(color: _T.textMuted.withOpacity(0.6), fontWeight: FontWeight.w400),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14), 
        borderSide: const BorderSide(color: _T.border)
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14), 
        borderSide: const BorderSide(color: _T.border)
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14), 
        borderSide: const BorderSide(color: _T.accent, width: 1.5)
      ),
    );
  }
}