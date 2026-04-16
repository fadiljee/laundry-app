import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/datasources/order_remote_datasource.dart';

class AddOrderPage extends StatefulWidget {
  const AddOrderPage({super.key});

  @override
  State<AddOrderPage> createState() => _AddOrderPageState();
}

class _AddOrderPageState extends State<AddOrderPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _weightController = TextEditingController();
  
  String _selectedService = 'Cuci Kering';
  final List<String> _services = ['Cuci Kering', 'Cuci Setrika', 'Setrika Saja', 'Bedcover'];
  
  File? _selectedImage; // Menyimpan file foto sementara
  bool _isLoading = false; // Status loading saat simpan ke Firebase

  // Fungsi untuk mengambil foto dari kamera
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50, // Kompres agar upload lebih cepat
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal membuka kamera: $e")),
      );
    }
  }

  // Fungsi utama untuk simpan data ke Firebase
  Future<void> _handleSaveOrder() async {
    // Validasi input
    if (_nameController.text.isEmpty || 
        _phoneController.text.isEmpty || 
        _weightController.text.isEmpty || 
        _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua data dan Foto wajib diisi!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Tampilkan Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Memanggil fungsi di RemoteDataSource yang kita buat tadi
      await OrderRemoteDataSource().createOrder(
        name: _nameController.text,
        phone: _phoneController.text,
        weight: double.parse(_weightController.text),
        service: _selectedService,
        imageFile: _selectedImage!,
      );

      if (!mounted) return;
      Navigator.pop(context); // Tutup loading dialog
      
      // Tampilkan Modal Sukses & QR
      _showSuccessAndQR(context);

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Tutup loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Input Pesanan Baru"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Data Pelanggan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Nama Pelanggan",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Nomor WhatsApp (Contoh: 62812...)",
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 25),

              const Text("Rincian Cucian", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildDropdownService(),
              const SizedBox(height: 15),
              TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Berat Cucian",
                  suffixText: "Kg",
                  prefixIcon: const Icon(Icons.scale),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // Bagian Bukti Foto Penimbangan (Tuntutan No. 6)
              const Text("Bukti Foto Penimbangan", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildImagePickerArea(),
              
              const SizedBox(height: 30),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSaveOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SIMPAN & KIRIM NOTIFIKASI WA", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownService() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedService,
          items: _services.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (val) => setState(() => _selectedService = val!),
        ),
      ),
    );
  }

  Widget _buildImagePickerArea() {
    return InkWell(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.5)),
        ),
        child: _selectedImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_rounded, size: 50, color: Colors.blue[300]),
                  const Text("Klik untuk Ambil Foto Timbangan", style: TextStyle(color: Colors.blue)),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_selectedImage!, fit: BoxFit.cover),
              ),
      ),
    );
  }

  void _showSuccessAndQR(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 70),
            const SizedBox(height: 15),
            const Text("Pesanan Berhasil Disimpan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Icon(Icons.qr_code_2_rounded, size: 150), // Simulasi QR
            const SizedBox(height: 20),
            const Text("WhatsApp otomatis telah dikirim ke pelanggan.", textAlign: TextAlign.center),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Tutup BottomSheet
                Navigator.pop(context); // Kembali ke Dashboard
              }, 
              child: const Text("Kembali ke Dashboard")
            )
          ],
        ),
      ),
    );
  }
}