import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart'; // Tambahan Google Fonts
import 'package:http/http.dart' as http;
import '../../../../core/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS (Modern Clean Light Theme)
// ─────────────────────────────────────────────────────────────
class _T {
  static const bg          = Color(0xFFF8FAFC); // Off-white/Slate-50
  static const surface     = Color(0xFFFFFFFF); // Pure White
  static const accent      = Color(0xFF2563EB); // Royal Blue
  static const accentDark  = Color(0xFF1D4ED8); // Darker Blue
  static const border      = Color(0xFFE2E8F0); // Light Slate
  
  static const textMain    = Color(0xFF0F172A); // Very Dark Slate
  static const textMuted   = Color(0xFF64748B); // Medium Slate
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isObscured = true;

  // Endpoint API
  final String loginUrl = "https://lyra.biz.id/api/login";

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showCustomSnackBar("Email dan Password wajib diisi!", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        body: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
        headers: {'Accept': 'application/json'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        await AuthStorage.saveToken(data['access_token']);
        String role = data['user']['role'];

        if (!mounted) return;
        _showCustomSnackBar("Selamat datang kembali, $role");

        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin-dashboard');
        } else if (role == 'courier') {
          Navigator.pushReplacementNamed(context, '/courier-dashboard');
        }
      } else {
        if (!mounted) return;
        _showCustomSnackBar(data['message'] ?? "Login Gagal", isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showCustomSnackBar("Koneksi bermasalah: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCustomSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.redAccent.withOpacity(0.9) : _T.accentDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, // Ikon status bar menjadi gelap
      child: Scaffold(
        backgroundColor: _T.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _T.textMain, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Text(
                  "Staff Access",
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: _T.textMain,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Silakan masuk untuk mengelola operasional\nLyra Laundry.",
                  style: GoogleFonts.inter(
                    color: _T.textMuted, 
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),

                // Form Section
                _buildLabel("EMAIL ADDRESS"),
                _buildTextField(
                  controller: _emailController,
                  hint: "staff@lyralaundry.com",
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                _buildLabel("PASSWORD"),
                _buildTextField(
                  controller: _passwordController,
                  hint: "••••••••",
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  obscureText: _isObscured,
                  onToggleObscure: () => setState(() => _isObscured = !_isObscured),
                ),
                const SizedBox(height: 48),

                // Login Button
                _buildLoginButton(),
                const SizedBox(height: 24),
                
                // Helper Footer
                Center(
                  child: Text(
                    "Masalah akses? Hubungi Admin Utama",
                    style: GoogleFonts.inter(
                      color: _T.textMuted.withOpacity(0.8), 
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: _T.accent,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.border),
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
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(color: _T.textMain),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: _T.textMuted.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: _T.accent.withOpacity(0.8), size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: _T.textMuted,
                    size: 20,
                  ),
                  onPressed: onToggleObscure,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleLogin,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: _isLoading 
                ? [Colors.grey.shade300, Colors.grey.shade300] 
                : [_T.accent, _T.accentDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: _isLoading ? [] : [
            BoxShadow(
              color: _T.accent.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  "SIGN IN TO DASHBOARD",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
        ),
      ),
    );
  }
}