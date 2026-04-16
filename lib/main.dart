import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/order_tracking/presentation/pages/customer_landing_page.dart';
import 'features/laundry_management/presentation/pages/admin_dashboard_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/courier_task/presentation/pages/courier_dashboard_page.dart';
import 'features/laundry_management/presentation/pages/add_order_page.dart';
import 'features/laundry_management/presentation/pages/order_list_page.dart';
import 'features/laundry_management/presentation/pages/tracking_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; 

void main() async { // <--- Pastikan ada ASYNC di sini
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const LyraLaundryApp());
}
class AuthRemoteDataSource { // <--- Pastikan nama class ini sama persis
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      return null;
    }
  }
}

class LyraLaundryApp extends StatelessWidget {
  const LyraLaundryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lyra Laundry',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      
      // Definisikan rute halaman di sini
      routes: {
      '/': (context) => const CustomerLandingPage(),
      '/login': (context) => const LoginPage(), // Tambahkan ini
      '/admin-dashboard': (context) => const AdminDashboardPage(),
      '/add-order': (context) => const AddOrderPage(),
      '/courier-dashboard': (context) => const CourierDashboardPage(),
      '/order-list': (context) => const OrderListPage(),
      '/tracking': (context) => const TrackingPage(orderId: "LYR-999"), // Dummy ID
    },
    );
  }
}