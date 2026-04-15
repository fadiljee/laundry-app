import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Staff")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person, size: 80, color: Colors.blue),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email/Username",
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
  String email = _emailController.text.trim();
  String password = _passwordController.text.trim();

  if (email == "admin" && password == "admin123") {
    // Jika login sebagai Admin
    Navigator.pushReplacementNamed(context, '/admin-dashboard');
  } else if (email == "kurir" && password == "kurir123") {
    // Jika login sebagai Kurir (nanti kita buat rutenya)
    Navigator.pushReplacementNamed(context, '/courier-dashboard');
  } else {
    // Jika salah
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Email atau Password salah! (Coba: admin/admin123)"),
        backgroundColor: Colors.red,
      ),
    );
  }
},
                child: const Text("MASUK"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}