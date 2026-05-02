import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────
class _T {
  static const bg          = Color(0xFFF8FAFC); 
  static const surface     = Color(0xFFFFFFFF); 
  static const accent      = Color(0xFF2563EB); 
  static const border      = Color(0xFFE2E8F0); 
  static const textMain    = Color(0xFF0F172A); 
  static const textMuted   = Color(0xFF64748B); 
  static const success     = Color(0xFF10B981); 
  static const danger      = Color(0xFFEF4444); 
}

// --- MODEL ---
class CourierModel {
  final int id;
  final String name;
  final String email;
  final String? photoUrl;

  CourierModel({required this.id, required this.name, required this.email, this.photoUrl});

  factory CourierModel.fromJson(Map<String, dynamic> json) {
    String? rawUrl = json['photo_url'];
    
    // Perbaikan: Paksa refresh dengan Timestamp agar Flutter tidak pakai cache lama
    String? finalUrl;
    if (rawUrl != null && rawUrl.isNotEmpty) {
      finalUrl = rawUrl.contains('?') 
          ? "$rawUrl&t=${DateTime.now().millisecondsSinceEpoch}"
          : "$rawUrl?t=${DateTime.now().millisecondsSinceEpoch}";
    }

    return CourierModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      photoUrl: finalUrl, 
    );
  }
}

// --- API DATASOURCE ---
class CourierApi {
  // PASTIKAN IP INI SESUAI DENGAN IP LAPTOP KAMU SAAT INI
  static const String baseUrl = "http://192.168.1.9:8000/api";

  static Future<Map<String, String>> _getHeaders() async {
    String? token = await AuthStorage.getToken();
    return {'Authorization': 'Bearer $token', 'Accept': 'application/json'};
  }

  static Future<List<CourierModel>> getCouriers() async {
    final response = await http.get(Uri.parse('$baseUrl/couriers'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      List data = json.decode(response.body)['data'];
      return data.map((e) => CourierModel.fromJson(e)).toList();
    }
    throw Exception("Gagal memuat data kurir");
  }

  static Future<void> saveCourier({
    int? id,
    required String name,
    required String email,
    required String password,
    File? imageFile,
  }) async {
    final isEdit = id != null;
    final url = isEdit ? '$baseUrl/couriers/$id' : '$baseUrl/couriers';
    
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll(await _getHeaders());

    if (isEdit) {
      request.fields['_method'] = 'PUT'; 
    }
    
    request.fields['name'] = name;
    request.fields['email'] = email;
    
    if (password.isNotEmpty) {
      request.fields['password'] = password;
    }

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', imageFile.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(json.decode(response.body)['message'] ?? "Gagal menyimpan data");
    }
  }

  static Future<void> deleteCourier(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/couriers/$id'), headers: await _getHeaders());
    if (response.statusCode != 200) throw Exception("Gagal menghapus kurir");
  }
}

class ManageCouriersPage extends StatefulWidget {
  const ManageCouriersPage({super.key});

  @override
  State<ManageCouriersPage> createState() => _ManageCouriersPageState();
}

class _ManageCouriersPageState extends State<ManageCouriersPage> {
  late Future<List<CourierModel>> _couriersFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    final future = CourierApi.getCouriers();
    setState(() {
      _couriersFuture = future; 
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
        backgroundColor: isError ? _T.danger : _T.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showCourierDialog({CourierModel? courier}) {
    final isEdit = courier != null;
    final nameCtrl = TextEditingController(text: isEdit ? courier.name : '');
    final emailCtrl = TextEditingController(text: isEdit ? courier.email : '');
    final passCtrl = TextEditingController();
    File? selectedImage;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: _T.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(isEdit ? "Edit Kurir" : "Tambah Kurir", 
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                      if (picked != null) {
                        setDialogState(() => selectedImage = File(picked.path));
                      }
                    },
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: _T.bg,
                          backgroundImage: selectedImage != null 
                              ? FileImage(selectedImage!) 
                              : (isEdit && courier.photoUrl != null 
                                  ? NetworkImage(courier.photoUrl!) 
                                  : null) as ImageProvider?,
                          child: (selectedImage == null && (!isEdit || courier.photoUrl == null))
                              ? const Icon(Icons.camera_alt_rounded, size: 30, color: _T.textMuted)
                              : null,
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: _T.accent, shape: BoxShape.circle),
                            child: const Icon(Icons.edit, size: 14, color: Colors.white),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(nameCtrl, "Nama Lengkap", Icons.badge_rounded),
                  const SizedBox(height: 12),
                  _buildTextField(emailCtrl, "Email", Icons.email_rounded),
                  const SizedBox(height: 12),
                  _buildTextField(
                    passCtrl, 
                    isEdit ? "Password (Kosongkan jika tetap)" : "Password", 
                    Icons.lock_rounded, 
                    obscure: true
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context), 
                child: const Text("Batal", style: TextStyle(color: _T.textMuted))
              ),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || (!isEdit && passCtrl.text.isEmpty)) {
                    _showSnackBar("Nama, Email, dan Password wajib diisi!", isError: true);
                    return;
                  }
                  setDialogState(() => isLoading = true);
                  try {
                    await CourierApi.saveCourier(
                      id: courier?.id,
                      name: nameCtrl.text,
                      email: emailCtrl.text,
                      password: passCtrl.text,
                      imageFile: selectedImage,
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                    _refreshData();
                    _showSnackBar("Data berhasil disimpan");
                  } catch (e) {
                    setDialogState(() => isLoading = false);
                    _showSnackBar(e.toString(), isError: true);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _T.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Simpan", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: _T.accent),
        filled: true, fillColor: _T.bg,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.surface, elevation: 0,
        title: Text("Kelola Kurir", style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: _T.textMain, fontSize: 18)),
        centerTitle: true,
      ),
      body: FutureBuilder<List<CourierModel>>(
        future: _couriersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Belum ada kurir"));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final courier = snapshot.data![index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _T.surface, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _T.border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: _buildAvatar(courier.photoUrl),
                  title: Text(courier.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text(courier.email, style: const TextStyle(fontSize: 13)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit_note_rounded, color: _T.accent), onPressed: () => _showCourierDialog(courier: courier)),
                      IconButton(icon: const Icon(Icons.delete_outline_rounded, color: _T.danger), onPressed: () => _confirmDelete(courier)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCourierDialog(),
        backgroundColor: _T.accent,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text("Tambah Kurir", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // WIDGET AVATAR DENGAN LOADING & ERROR HANDLING
 Widget _buildAvatar(String? url) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _T.accent.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: url != null
            ? Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                },
                errorBuilder: (context, error, stackTrace) {
                  // LOG ERROR KE CONSOLE UNTUK LIHAT KENAPA HILANG
                  print("Gagal muat gambar: $url");
                  print("Error detail: $error");
                  return const Icon(Icons.broken_image_rounded, color: _T.danger);
                },
              )
            : const Icon(Icons.person, color: _T.accent),
      ),
    );
  }

  void _confirmDelete(CourierModel courier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Kurir?"),
        content: Text("Yakin ingin menghapus ${courier.name}? Data ini tidak bisa dikembalikan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              try {
                await CourierApi.deleteCourier(courier.id);
                if (!mounted) return;
                Navigator.pop(context);
                _refreshData();
                _showSnackBar("Kurir berhasil dihapus");
              } catch (e) {
                Navigator.pop(context);
                _showSnackBar(e.toString(), isError: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _T.danger),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}