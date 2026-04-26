import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
import 'features/laundry_management/presentation/pages/manage_couriers_page.dart';
import 'features/laundry_management/presentation/pages/financial_report_page.dart';

void main() { 
  WidgetsFlutterBinding.ensureInitialized();
  
  // Membuat Status Bar transparan untuk kesan modern UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const LyraLaundryApp());
}

class LyraLaundryApp extends StatelessWidget {
  const LyraLaundryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lyra Laundry',
      debugShowCheckedModeBanner: false, // Menghilangkan banner debug
      theme: AppTheme.lightTheme, // Tema profesional yang kita set di bawah
      initialRoute: '/',
      // Menghilangkan efek glow saat scroll mentok (biar bersih spt iOS)
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
          child: child!,
        );
      },
      onGenerateRoute: (settings) {
        // Logika khusus tidak diubah sama sekali
        if (settings.name == '/tracking') {
          final args = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (context) => TrackingPage(orderIdFromScanner: args),
          );
        }
        return null;
      },
      routes: {
        '/': (context) => const CustomerLandingPage(),
        '/login': (context) => const LoginPage(), 
        '/admin-dashboard': (context) => const AdminDashboardPage(),
        '/add-order': (context) => AddOrderPage(),
        '/order-list': (context) => const OrderListPage(),
        '/scanner': (context) => const QrScannerPage(),
        '/courier-dashboard': (context) => const CourierDashboardPage(),
        '/manage-couriers': (context) => const ManageCouriersPage(),
        '/financial-report': (context) => const FinancialReportPage(),
      },
    );
  }
}