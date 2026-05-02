import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:qr_flutter/qr_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- IMPORT INI
import '../../data/datasources/order_remote_datasource.dart';
import '../../data/models/order_model.dart';


class _T {
  static const bg          = Color(0xFFF8FAFC); 
  static const surface     = Color(0xFFFFFFFF); 
  static const accent      = Color(0xFF2563EB); 
  static const accentDark  = Color(0xFF1D4ED8); 
  static const accentFaint = Color(0x1A2563EB);
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
  
  // Daftar Layanan dan Deskripsinya
  final Map<String, String> _servicesData = {
    'Cuci Lipat (Wash & Fold)': 'Layanan dasar cuci dan lipat pakaian sehari-hari.',
    'Cuci Setrika (Wash & Iron)': 'Layanan komprehensif agar pakaian rapi dan wangi.',
    'Dry Cleaning': 'Pencucian khusus bahan sensitif tanpa air.',
    'Laundry Ekspres/Same Day': 'Layanan cepat selesai dalam hitungan jam.',
    'Laundry Antar-Jemput': 'Kemudahan mengambil dan mengantar cucian ke lokasi konsumen.',
    'Laundry Satuan': 'Khusus untuk pakaian berbahan khusus seperti jas, kebaya, atau gaun.'
  };
  
  late String _selectedService;
  
  bool _isLoading = false;
  bool _isGettingLocation = false; // State untuk loading lokasi

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _selectedService = _servicesData.keys.first;
    
    // Panggil fungsi untuk mengambil data pelanggan tersimpan
    _loadSavedCustomerData();

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
    super.dispose();
  }

  // --- FUNGSI LOAD DATA PELANGGAN LAMA ---
  Future<void> _loadSavedCustomerData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('last_customer_name');
    final savedPhone = prefs.getString('last_customer_wa');

    if (savedName != null && savedPhone != null) {
      if (mounted) {
        setState(() {
          _nameController.text = savedName;
          _phoneController.text = savedPhone;
        });
      }
    }
  }

  // --- FUNGSI AMBIL LOKASI OTOMATIS ---
  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'GPS kamu tidak aktif. Mohon nyalakan GPS terlebih dahulu.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Izin lokasi ditolak.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Izin lokasi ditolak permanen. Buka pengaturan HP untuk mengizinkan.';
      }

      // Ambil Koordinat
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // Ubah Koordinat jadi Alamat (Geocoding)
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          // Format alamat yang rapi
          String address = "";
          if (place.street != null && place.street!.isNotEmpty) address += "${place.street}, ";
          if (place.subLocality != null && place.subLocality!.isNotEmpty) address += "${place.subLocality}, ";
          if (place.locality != null && place.locality!.isNotEmpty) address += "${place.locality}";
          
          // Tambahkan link Gmaps di akhir alamat agar kurir mudah klik
          address += "\n(https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude})";
          
          _addressController.text = address;
        } else {
          _addressController.text = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
        }
      } catch (e) {
        // Fallback jika geocoding gagal, berikan link google maps saja
        _addressController.text = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
      }

      _showSnackBar("Lokasi berhasil ditemukan!", isError: false);
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _handleSaveOrder() async {
    if (_nameController.text.isEmpty || _addressController.text.isEmpty) {
      _showSnackBar("Nama & Alamat wajib diisi!", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Map<String, String> orderData = {
        'customer_name': _nameController.text.trim(),
        'wa_number': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'weight': '0', 
        'service': _selectedService,
      };

      final OrderModel newOrder = await OrderRemoteDataSource().createOrder(orderData, null);

      // --- SIMPAN DATA PELANGGAN KE MEMORI LOKAL SETELAH SUKSES ---
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_customer_name', orderData['customer_name']!);
      await prefs.setString('last_customer_wa', orderData['wa_number']!);

      if (!mounted) return;
      _showSuccessDialog(newOrder.orderCode);

    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Gagal Membuat Pesanan: $e", isError: true);
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
        backgroundColor: isError ? _T.danger : const Color(0xFF10B981), 
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
              "Ini adalah tiket pesanan Anda.\nKurir kami akan segera meluncur!",
              textAlign: TextAlign.center,
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
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: _T.textMain),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: _T.textMain),
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
                child: Text("Selesai", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
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
            "Buat Pesanan Baru", 
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
                  _buildTextField(
                    controller: _nameController, 
                    hint: "Contoh: Budi Santoso", 
                    icon: Icons.person_rounded
                  ),
                  const SizedBox(height: 20),
                  
                  _buildLabel("No. WhatsApp (Aktif)"),
                  _buildTextField(
                    controller: _phoneController, 
                    hint: "08xxxxxxxxxx", 
                    icon: Icons.phone_rounded, 
                    keyboardType: TextInputType.phone
                  ),
                  const SizedBox(height: 20),

                  _buildLabel("Alamat Penjemputan"),
                  _buildLocationField(), 
                  const SizedBox(height: 20),
                  
                  _buildLabel("Pilih Layanan"),
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedService,
                      dropdownColor: _T.surface,
                      isExpanded: true,
                      icon: const Icon(Icons.expand_more_rounded, color: _T.textMuted),
                      style: GoogleFonts.inter(color: _T.textMain, fontWeight: FontWeight.w600, fontSize: 14),
                      items: _servicesData.keys.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => _selectedService = val!),
                      decoration: _inputDecoration(Icons.local_laundry_service_rounded),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: _T.textMuted.withOpacity(0.8)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _servicesData[_selectedService]!,
                            style: GoogleFonts.inter(color: _T.textMuted, fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
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
                              "Kirim Pesanan", 
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

  Widget _buildTextField({
    required TextEditingController controller, 
    required String hint, 
    required IconData icon, 
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(color: _T.textMain, fontWeight: FontWeight.w500),
        decoration: _inputDecoration(icon).copyWith(hintText: hint),
      ),
    );
  }

  Widget _buildLocationField() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: _addressController,
        maxLines: 3, 
        minLines: 1,
        style: GoogleFonts.inter(color: _T.textMain, fontWeight: FontWeight.w500),
        decoration: _inputDecoration(Icons.location_on_rounded).copyWith(
          hintText: "Ketik alamat atau tekan ikon lokasi...",
          suffixIcon: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Material(
              color: _T.accentFaint,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: InkWell(
                onTap: _isGettingLocation ? null : _getCurrentLocation,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: _isGettingLocation 
                    ? const SizedBox(
                        width: 18, height: 18, 
                        child: CircularProgressIndicator(strokeWidth: 2.5)
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.my_location_rounded, color: _T.accent, size: 18),
                          const SizedBox(width: 6),
                          Text("Lacak", style: GoogleFonts.inter(color: _T.accent, fontWeight: FontWeight.w600, fontSize: 12)),
                        ],
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Padding(
        padding: const EdgeInsets.only(bottom: 2.0),
        child: Icon(icon, color: _T.accent.withOpacity(0.8), size: 22),
      ),
      filled: true,
      fillColor: _T.surface,
      hintStyle: GoogleFonts.inter(color: _T.textMuted.withOpacity(0.6), fontWeight: FontWeight.w400, fontSize: 13),
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