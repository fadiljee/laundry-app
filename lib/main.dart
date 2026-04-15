import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/order_tracking/presentation/pages/customer_landing_page.dart';
import 'features/laundry_management/presentation/pages/admin_dashboard_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/courier_task/presentation/pages/courier_dashboard_page.dart';
import 'features/laundry_management/presentation/pages/add_order_page.dart';
import 'features/laundry_management/presentation/pages/order_list_page.dart';
import 'features/laundry_management/presentation/pages/tracking_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LyraLaundryApp());
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