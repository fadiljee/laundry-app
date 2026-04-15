import 'package:flutter/material.dart';

class AddOrderPage extends StatefulWidget {
  const AddOrderPage({super.key});

  @override
  State<AddOrderPage> createState() => _AddOrderPageState();
}

class _AddOrderPageState extends State<AddOrderPage> {
  // Controller untuk menangkap input teks
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _weightController = TextEditingController();
  
  // Variabel dummy untuk pilihan layanan
  String _selectedService = 'Cuci Kering';
  final List<String> _services = ['Cuci Kering', 'Cuci Setrika', 'Setrika Saja', 'Bedcover'];

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
              const Text(
                "Data Pelanggan",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              
              // Input Nama
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Nama Pelanggan",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),
              
              // Input WhatsApp (Penting untuk Notif WA)
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

              const Text(
                "Rincian Cucian",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              // Dropdown Layanan
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedService,
                    items: _services.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedService = newValue!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Input Berat (Tuntutan No. 6)
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Berat Cucian",
                  suffixText: "Kg",
                  prefixIcon: const Icon(Icons.scale),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // Tombol Upload Foto Timbangan (Tuntutan No. 6)
              const Text(
                "Bukti Foto Penimbangan",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Membuka Kamera (Simulasi)")),
                  );
                },
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.5), style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_rounded, size: 40, color: Colors.blue[300]),
                      const SizedBox(height: 8),
                      const Text("Ambil Foto Timbangan", style: TextStyle(color: Colors.blue)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Tombol Simpan & Kirim WA
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => _handleSaveOrder(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "SIMPAN & KIRIM NOTIFIKASI WA",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSaveOrder() {
    // Validasi sederhana
    if (_nameController.text.isEmpty || _weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap isi semua data!")),
      );
      return;
    }

    // Tampilkan Modal Berhasil & Simulasi WA
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Pesanan Berhasil Disimpan!", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("WhatsApp sedang dikirim ke ${_nameController.text}..."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup Dialog
              Navigator.pop(context); // Kembali ke Dashboard
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}