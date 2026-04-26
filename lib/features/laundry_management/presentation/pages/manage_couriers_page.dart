import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart'; // Pastikan sudah ter-import
import 'package:http/http.dart' as http;
import '../../../../core/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS (Modern Clean Light Theme)
// ─────────────────────────────────────────────────────────────
class _T {
  static const bg          = Color(0xFFF8FAFC); // Off-white/Slate-50
  static const surface     = Color(0xFFFFFFFF); // Pure White
  static const accent      = Color(0xFF2563EB); // Royal Blue
  static const border      = Color(0xFFE2E8F0); // Light Slate
  static const textMain    = Color(0xFF0F172A); // Very Dark Slate
  static const textMuted   = Color(0xFF64748B); // Medium Slate
  static const success     = Color(0xFF10B981); // Emerald Green
  static const danger      = Color(0xFFEF4444); // Red
}

// --- MODEL ---
class CourierModel {
  final int id;
  final String name;
  final String email;

  CourierModel({required this.id, required this.name, required this.email});

  factory CourierModel.fromJson(Map<String, dynamic> json) {
    return CourierModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }
}

// --- API DATASOURCE ---
class CourierApi {
  static const String baseUrl = "https://prize-pancake-spore.ngrok-free.dev/api";

  static Future<Map<String, String>> _getHeaders() async {
    String? token = await AuthStorage.getToken();
    return {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
  }

  static Future<List<CourierModel>> getCouriers() async {
    final response = await http.get(Uri.parse('$baseUrl/couriers'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      List data = json.decode(response.body)['data'];
      return data.map((e) => CourierModel.fromJson(e)).toList();
    }
    throw Exception("Gagal memuat data kurir");
  }

  static Future<void> addCourier(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/couriers'),
      headers: await _getHeaders(),
      body: {'name': name, 'email': email, 'password': password},
    );
    if (response.statusCode != 201) throw Exception("Email sudah dipakai atau data tidak valid");
  }

  static Future<void> editCourier(int id, String name, String email, String password) async {
    final Map<String, dynamic> body = {'name': name, 'email': email};
    if (password.isNotEmpty) {
      body['password'] = password;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/couriers/$id'),
      headers: await _getHeaders(),
      body: body,
    );
    if (response.statusCode != 200) throw Exception("Gagal mengupdate data kurir");
  }

  static Future<void> deleteCourier(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/couriers/$id'), headers: await _getHeaders());
    if (response.statusCode != 200) throw Exception("Gagal menghapus kurir");
  }
}

// --- HALAMAN UI ---
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
    setState(() {
      _couriersFuture = CourierApi.getCouriers();
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? _T.danger : _T.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // --- DIALOG TAMBAH & EDIT ---
  void _showCourierDialog({CourierModel? courier}) {
    final isEdit = courier != null;
    final nameCtrl = TextEditingController(text: isEdit ? courier.name : '');
    final emailCtrl = TextEditingController(text: isEdit ? courier.email : '');
    final passCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: _T.surface,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: _T.border),
            ),
            title: Text(
              isEdit ? "Edit Data Kurir" : "Tambah Kurir Baru", 
              style: GoogleFonts.poppins(color: _T.textMain, fontSize: 18, fontWeight: FontWeight.w700)
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(nameCtrl, "Nama Lengkap", Icons.badge_rounded),
                const SizedBox(height: 16),
                _buildTextField(emailCtrl, "Alamat Email", Icons.email_rounded),
                const SizedBox(height: 16),
                _buildTextField(
                  passCtrl, 
                  isEdit ? "Password Baru (Opsional)" : "Password", 
                  Icons.lock_rounded, 
                  obscure: true
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: _T.textMuted,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text("Batal", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || (!isEdit && passCtrl.text.isEmpty)) {
                          _showSnackBar("Nama & Email wajib diisi!", isError: true);
                          return;
                        }
                        setDialogState(() => isLoading = true);
                        try {
                          if (isEdit) {
                            await CourierApi.editCourier(courier.id, nameCtrl.text, emailCtrl.text, passCtrl.text);
                          } else {
                            await CourierApi.addCourier(nameCtrl.text, emailCtrl.text, passCtrl.text);
                          }
                          
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          _showSnackBar(isEdit ? "Data berhasil diubah!" : "Kurir berhasil ditambahkan!");
                          _refreshData();
                        } catch (e) {
                          setDialogState(() => isLoading = false);
                          _showSnackBar(e.toString(), isError: true);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.accent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text("Simpan", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(CourierModel courier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _T.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: _T.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: _T.danger),
            const SizedBox(width: 10),
            Text("Hapus Kurir?", style: GoogleFonts.poppins(color: _T.textMain, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          "Yakin ingin menghapus ${courier.name}? Akun ini tidak bisa dipulihkan setelah dihapus.",
          style: GoogleFonts.inter(color: _T.textMuted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            style: TextButton.styleFrom(foregroundColor: _T.textMuted),
            child: Text("Batal", style: GoogleFonts.inter(fontWeight: FontWeight.w600))
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await CourierApi.deleteCourier(courier.id);
                _refreshData();
                if (!context.mounted) return;
                _showSnackBar("Kurir berhasil dihapus");
              } catch (e) {
                if (!context.mounted) return;
                _showSnackBar("Gagal menghapus kurir", isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.danger,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Hapus Akun", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.inter(color: _T.textMain, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: _T.textMuted.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: _T.accent.withOpacity(0.7), size: 20),
        filled: true,
        fillColor: _T.bg,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
            "Kelola Data Kurir", 
            style: GoogleFonts.poppins(color: _T.textMain, fontSize: 18, fontWeight: FontWeight.w700)
          ),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: () async => _refreshData(),
          color: _T.accent,
          backgroundColor: _T.surface,
          child: FutureBuilder<List<CourierModel>>(
            future: _couriersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: _T.accent));
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text("Error: ${snapshot.error}", style: GoogleFonts.inter(color: _T.danger))
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.group_off_rounded, size: 64, color: _T.border),
                      const SizedBox(height: 16),
                      Text("Belum ada data kurir.", style: GoogleFonts.inter(color: _T.textMuted)),
                    ],
                  )
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final courier = snapshot.data![index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: _T.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _T.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _T.accent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.two_wheeler_rounded, color: _T.accent, size: 24),
                      ),
                      title: Text(
                        courier.name, 
                        style: GoogleFonts.poppins(color: _T.textMain, fontWeight: FontWeight.w600, fontSize: 15)
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          courier.email, 
                          style: GoogleFonts.inter(color: _T.textMuted, fontSize: 13)
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_note_rounded, color: _T.accent, size: 26),
                            tooltip: "Edit Kurir",
                            onPressed: () => _showCourierDialog(courier: courier),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_sweep_rounded, color: _T.danger, size: 24),
                            tooltip: "Hapus Kurir",
                            onPressed: () => _confirmDelete(courier),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
       floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCourierDialog(), 
          backgroundColor: _T.accent,
          elevation: 4, // elevation ini sudah cukup untuk memberi efek shadow bawaan
          icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
          label: Text(
            "Tambah Kurir", 
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.5)
          ),
        ),
      ),
    );
  }
}