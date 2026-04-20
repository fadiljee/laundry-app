import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Import Pages
import 'core/theme/app_theme.dart';
import 'features/order_tracking/presentation/pages/customer_landing_page.dart';
import 'features/laundry_management/presentation/pages/admin_dashboard_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/courier_task/presentation/pages/courier_dashboard_page.dart';
import 'features/laundry_management/presentation/pages/add_order_page.dart';
import 'features/laundry_management/presentation/pages/order_list_page.dart';
import 'features/laundry_management/presentation/pages/tracking_page.dart';
import 'features/order_tracking/presentation/pages/qr_scanner_page.dart';

void main() async { 
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      initialRoute: '/',
      routes: {
        '/': (context) => const CustomerLandingPage(),
        '/login': (context) => const LoginPage(), 
        '/admin-dashboard': (context) => const AdminDashboardPage(),
        '/add-order': (context) => const AddOrderPage(),
        '/order-list': (context) => const OrderListPage(),
        '/tracking': (context) => const TrackingPage(orderIdFromScanner: null),
        '/scanner': (context) => const QrScannerPage(),
        '/courier-dashboard': (context) => CourierDashboardPage(), // Tanpa const
      },
    );
  }
}