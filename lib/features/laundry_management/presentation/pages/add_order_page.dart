import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:qr_flutter/qr_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/order_remote_datasource.dart';
import '../../data/models/order_model.dart';

class _T {
  static const bg          = Color(0xFFF8FAFC); 
  static const surface     = Color(0xFFFFFFFF); 
  static const accent      = Color(0xFF2563EB); 
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
  
  // ---> (BARU) Variabel penampung kordinat asli
  double? _latitude;
  double? _longitude;
  
  // --- DAFTAR LAYANAN SESUAI HARGA ASLI ---
  final Map<String, String> _servicesData = {
    'Cuci Lipat': 'Cuci dan lipat pakaian sehari-hari.',
    'Setrika': 'Hanya jasa setrika agar pakaian rapi.',
    'Cuci Setrika': 'Paket lengkap cuci dan setrika wangi.',
    'Express 1 Hari': 'Layanan prioritas selesai dalam 24 jam.',
    'Cuci Basah': 'Hanya cuci saja (tanpa kering/lipat).',
    'Bed Cover Besar': 'Cuci bed cover ukuran besar/King.',
    'Bed Cover Kecil': 'Cuci bed cover ukuran kecil/Single.',
    'Sprei': 'Paket cuci sprei lengkap.',
    'Sprei Aja': 'Hanya cuci sprei per lembar.',
    'Sprei Single': 'Paket cuci sprei ukuran single.',
    'Karpet': 'Pembersihan karpet.',
    'Gorden': 'Pembersihan gorden.',
  };
  
  late String _selectedService;
  bool _isLoading = false;
  bool _isGettingLocation = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _selectedService = _servicesData.keys.first;
    _loadSavedCustomerData();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
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

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // ---> (BARU) Simpan kordinatnya ke variabel
      _latitude = position.latitude;
      _longitude = position.longitude;

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String address = "${place.street}, ${place.subLocality}, ${place.locality}";
          address += "\n(https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude})";
          _addressController.text = address;
        }
      } catch (e) {
        _addressController.text = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
      }
      _showSnackBar("Lokasi ditemukan!", isError: false);
    } catch (e) {
      _showSnackBar("Gagal lacak lokasi: $e", isError: true);
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
      // ---> (BARU) Sisipkan lat dan lng ke dalam payload yang dikirim ke Laravel
      final Map<String, String> orderData = {
        'customer_name': _nameController.text.trim(),
        'wa_number': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'weight': '0', 
        'service': _selectedService,
        'lat': _latitude?.toString() ?? '', // Kirim kordinat
        'lng': _longitude?.toString() ?? '', // Kirim kordinat
      };

      final OrderModel newOrder = await OrderRemoteDataSource().createOrder(orderData, null);

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
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: isError ? _T.danger : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
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
            style: GoogleFonts.poppins(
                color: _T.textMain, fontWeight: FontWeight.w700, fontSize: 20),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Simpan tiket ini untuk pelacakan.\nKurir kami akan segera meluncur!",
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
                  eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square, color: _T.textMain),
                  dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: _T.textMain),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text("Selesai",
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.surface,
        title: Text("Buat Pesanan Baru", style: GoogleFonts.poppins(color: _T.textMain, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Nama Pelanggan"),
            _buildTextField(controller: _nameController, hint: "Contoh: Budi Santoso", icon: Icons.person_rounded),
            const SizedBox(height: 20),
            
            _buildLabel("No. WhatsApp"),
            _buildTextField(controller: _phoneController, hint: "08xxxxxxxxxx", icon: Icons.phone_rounded, keyboardType: TextInputType.phone),
            const SizedBox(height: 20),

            _buildLabel("Alamat Penjemputan"),
            _buildLocationField(), 
            const SizedBox(height: 20),
            
            _buildLabel("Pilih Layanan"),
            DropdownButtonFormField<String>(
              value: _selectedService,
              isExpanded: true,
              items: _servicesData.keys.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => setState(() => _selectedService = val!),
              decoration: _inputDecoration(Icons.local_laundry_service_rounded),
            ),
            const SizedBox(height: 8),
            _buildServiceInfo(),

            const SizedBox(height: 48),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 14, color: _T.accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _servicesData[_selectedService]!,
              style: GoogleFonts.inter(color: _T.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSaveOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: _T.accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isLoading 
            ? const CircularProgressIndicator(color: Colors.white)
            : Text("Kirim Pesanan", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(text, style: GoogleFonts.inter(fontSize: 13, color: _T.textMain, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(icon).copyWith(hintText: hint),
    );
  }

  Widget _buildLocationField() {
    return TextField(
      controller: _addressController,
      maxLines: 2,
      decoration: _inputDecoration(Icons.location_on_rounded).copyWith(
        hintText: "Klik ikon lokasi untuk lacak otomatis...",
        suffixIcon: IconButton(
          icon: _isGettingLocation ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location_rounded, color: _T.accent),
          onPressed: _isGettingLocation ? null : _getCurrentLocation,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: _T.accent, size: 22),
      filled: true,
      fillColor: _T.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _T.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _T.border)),
    );
  }
}