import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS (Modern Clean Theme)
// ─────────────────────────────────────────────────────────────
class _T {
  static const bg          = Color(0xFFF1F5F9); 
  static const surface     = Color(0xFFFFFFFF); 
  static const accent      = Color(0xFF2563EB); 
  static const accentLight = Color(0xFFDBEAFE); 
  static const border      = Color(0xFFE2E8F0); 
  static const textMain    = Color(0xFF0F172A); 
  static const textMuted   = Color(0xFF64748B); 
  static const success     = Color(0xFF10B981); 
  static const danger      = Color(0xFFEF4444); 
  static const dangerLight = Color(0xFFFEE2E2); 

  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}

// --- MODEL ---
class CourierModel {
  final int id;
  final String name;
  final String email;
  final String? phone; 
  final String? photoUrl;

  CourierModel({required this.id, required this.name, required this.email, this.phone, this.photoUrl});

  factory CourierModel.fromJson(Map<String, dynamic> json) {
    String? rawUrl = json['photo_url'];
    
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
      phone: json['phone'], 
      photoUrl: finalUrl, 
    );
  }
}

// --- API DATASOURCE ---
class CourierApi {
  static const String baseUrl = "https://lyra.biz.id/api";

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
    required String phone, 
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
    request.fields['phone'] = phone; 
    
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
    setState(() {
      _couriersFuture = CourierApi.getCouriers(); 
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.white)),
        backgroundColor: isError ? _T.danger : _T.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showCourierDialog({CourierModel? courier}) {
    final isEdit = courier != null;
    final nameCtrl = TextEditingController(text: isEdit ? courier.name : '');
    final emailCtrl = TextEditingController(text: isEdit ? courier.email : '');
    final phoneCtrl = TextEditingController(text: isEdit ? courier.phone : ''); 
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
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? "Edit Kurir" : "Tambah Kurir Baru", 
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 20, color: _T.textMain)),
                const SizedBox(height: 4),
                Text(isEdit ? "Perbarui informasi kurir di bawah ini" : "Lengkapi form untuk menambah kurir", 
                    style: GoogleFonts.inter(fontSize: 13, color: _T.textMuted)),
              ],
            ),
            content: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  // Foto Profil Picker
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                        if (picked != null) {
                          setDialogState(() => selectedImage = File(picked.path));
                        }
                      },
                      child: Stack(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: _T.bg,
                              shape: BoxShape.circle,
                              border: Border.all(color: _T.border, width: 2),
                              image: selectedImage != null 
                                  ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover)
                                  : (isEdit && courier.photoUrl != null 
                                      ? DecorationImage(image: NetworkImage(courier.photoUrl!), fit: BoxFit.cover) 
                                      : null),
                            ),
                            child: (selectedImage == null && (!isEdit || courier.photoUrl == null))
                                ? const Icon(Icons.add_a_photo_rounded, size: 28, color: _T.textMuted)
                                : null,
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _T.accent, 
                                shape: BoxShape.circle,
                                border: Border.all(color: _T.surface, width: 2),
                              ),
                              child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(nameCtrl, "Nama Lengkap", Icons.badge_rounded),
                  const SizedBox(height: 16),
                  _buildTextField(emailCtrl, "Email", Icons.email_rounded, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildTextField(
                    phoneCtrl, 
                    "Nomor WA (Cth: 0812...)", 
                    Icons.phone_android_rounded,
                    keyboardType: TextInputType.phone
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    passCtrl, 
                    isEdit ? "Password (Kosongkan jika tetap)" : "Password", 
                    Icons.lock_rounded, 
                    obscure: true
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: _T.border, width: 1.5),
                      ),
                      child: Text("Batal", style: GoogleFonts.inter(color: _T.textMuted, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
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
                            phone: phoneCtrl.text, 
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _T.accent, 
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text("Simpan", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool obscure = false, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 14, color: _T.textMain),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: _T.textMuted.withOpacity(0.7), fontSize: 13),
        prefixIcon: Icon(icon, size: 20, color: _T.textMuted),
        filled: true, 
        fillColor: _T.bg,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), 
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _T.accent, width: 1.5),
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _T.border, height: 1),
          ),
          title: Text(
            "Kelola Kurir", 
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: _T.textMain, fontSize: 18)
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
                return Center(child: Text("Error: ${snapshot.error}", style: GoogleFonts.inter(color: _T.danger)));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: _T.surface, shape: BoxShape.circle, boxShadow: _T.shadowSm),
                        child: const Icon(Icons.group_off_rounded, size: 48, color: _T.textMuted),
                      ),
                      const SizedBox(height: 16),
                      Text("Belum ada data kurir", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _T.textMain)),
                      Text("Tekan tombol tambah untuk membuat akun kurir", style: GoogleFonts.inter(fontSize: 13, color: _T.textMuted)),
                    ],
                  ),
                );
              }

              // Implementasi Animasi Staggered List
              return AnimationLimiter(
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.all(20),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final courier = snapshot.data![index];
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 500),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildCourierCard(courier),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCourierDialog(),
          backgroundColor: _T.accent,
          elevation: 4,
          icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
          label: Text("Tambah Kurir", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ),
    );
  }

  // --- KARTU KURIR YANG LEBIH MODERN ---
  Widget _buildCourierCard(CourierModel courier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.surface, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.border, width: 0.8),
        boxShadow: _T.shadowSm,
      ),
      child: Row(
        children: [
          _buildAvatar(courier.photoUrl),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courier.name, 
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, color: _T.textMain),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.email_rounded, size: 14, color: _T.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        courier.email, 
                        style: GoogleFonts.inter(fontSize: 12, color: _T.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone_rounded, size: 14, color: _T.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      courier.phone ?? 'Belum ada nomor', 
                      style: GoogleFonts.inter(fontSize: 12, color: _T.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Action Buttons
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: _T.accent, size: 20), 
                onPressed: () => _showCourierDialog(courier: courier),
                style: IconButton.styleFrom(backgroundColor: _T.accentLight, padding: const EdgeInsets.all(8)),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: _T.danger, size: 20), 
                onPressed: () => _confirmDelete(courier),
                style: IconButton.styleFrom(backgroundColor: _T.dangerLight, padding: const EdgeInsets.all(8)),
                constraints: const BoxConstraints(),
              ),
            ],
          )
        ],
      ),
    );
  }

 Widget _buildAvatar(String? url) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: _T.accentLight,
        shape: BoxShape.circle,
        border: Border.all(color: _T.surface, width: 2),
        boxShadow: [
          BoxShadow(
            color: _T.accent.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipOval(
        child: url != null
            ? Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _T.accent));
                },
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person_rounded, color: _T.accent, size: 28),
              )
            : const Icon(Icons.person_rounded, color: _T.accent, size: 28),
      ),
    );
  }

  void _confirmDelete(CourierModel courier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _T.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: _T.dangerLight, shape: BoxShape.circle),
              child: const Icon(Icons.warning_rounded, color: _T.danger, size: 24),
            ),
            const SizedBox(width: 12),
            Text("Hapus Kurir?", style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: Text("Yakin ingin menghapus akun ${courier.name}? Data ini tidak bisa dikembalikan.", 
            style: GoogleFonts.inter(color: _T.textMuted, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text("Batal", style: GoogleFonts.inter(color: _T.textMuted, fontWeight: FontWeight.w600))
          ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.danger,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Hapus", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}