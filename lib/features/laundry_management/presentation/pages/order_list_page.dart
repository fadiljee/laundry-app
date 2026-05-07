import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

// Ganti dengan path import project Anda yang sebenarnya
import '../../data/datasources/order_remote_datasource.dart';
import '../../data/models/order_model.dart';

// --- DESIGN TOKENS ---
class _T {
  static const bg = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const accent = Color(0xFF2563EB);
  static const accentLight = Color(0xFFEEF2FF);
  static const border = Color(0xFFE2E8F0);
  static const borderLight = Color(0xFFF1F5F9);
  static const textMain = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFD1FAE5);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const danger = Color(0xFFEF4444);
  static const dangerLight = Color(0xFFFEE2E2);
  static const purple = Color(0xFF9333EA);
  static const purpleLight = Color(0xFFF3E8FF);
}

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage>
    with SingleTickerProviderStateMixin {
  
  // --- STATE UNTUK PAGINATION ---
  final ScrollController _scrollController = ScrollController();
  List<OrderModel> _orders = [];
  int _currentPage = 1;
  bool _isFirstLoad = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  final List<String> _adminStatusOptions = [
    'Menunggu Pembayaran',
    'Lunas - Siap Jemput',
    'Proses Cuci',
    'Proses Antar',
    'Selesai'
  ];

  @override
  void initState() {
    super.initState();
    _fetchInitialOrders();

    // Listener untuk mendeteksi scroll mentok ke bawah
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        _fetchMoreOrders();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // --- LOGIC PAGINATION ---
  
  Future<void> _fetchInitialOrders() async {
    setState(() {
      _isFirstLoad = true;
      _currentPage = 1;
      _hasMoreData = true;
      _orders.clear();
    });

    try {
      // NOTE: Sesuaikan pemanggilan ini dengan Data Source Anda.
      // Pastikan method getOrders bisa menerima parameter page.
      // Jika Anda masih pakai getAllOrders(), ubahlah untuk mendukung pagination.
      final List<OrderModel> newOrders = 
          await OrderRemoteDataSource().getOrders(page: _currentPage);
      
      setState(() {
        _orders = newOrders;
        _isFirstLoad = false;
        // Asumsi: jika data kurang dari 10 (atau limit Anda), maka sudah habis.
        if (newOrders.isEmpty || newOrders.length < 10) {
          _hasMoreData = false;
        }
      });
    } catch (e) {
      setState(() => _isFirstLoad = false);
      _showErrorSnackBar("Gagal memuat pesanan: $e");
    }
  }

  Future<void> _fetchMoreOrders() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);
    
    try {
      _currentPage++;
      final List<OrderModel> additionalOrders = 
          await OrderRemoteDataSource().getOrders(page: _currentPage);
      
      setState(() {
        _isLoadingMore = false;
        if (additionalOrders.isEmpty) {
          _hasMoreData = false;
        } else {
          _orders.addAll(additionalOrders);
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _currentPage--; // Kembalikan page jika gagal
      });
      _showErrorSnackBar("Gagal memuat lebih banyak pesanan");
    }
  }

  Future<void> _onRefresh() async {
    await _fetchInitialOrders();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _T.danger,
        behavior: SnackBarBehavior.floating,
      )
    );
  }

  // ----------------------------------------

  String _getUnit(String serviceName) {
    if (serviceName.contains('Bed Cover') ||
        serviceName.contains('Sprei Aja')) {
      return 'Pcs';
    } else if (serviceName == 'Sprei' || serviceName == 'Sprei Single') {
      return 'Set';
    }
    return 'Kg';
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: _T.accent)),
    );
  }

  Future<void> _updateStatus(int id, String status) async {
    _showLoadingDialog();
    try {
      await OrderRemoteDataSource().updateOrderStatus(id, status);
      if (!mounted) return;
      Navigator.pop(context);
      // Cukup refresh background tanpa reset pagination penuh jika memungkinkan, 
      // tapi refresh list penuh lebih aman untuk sinkronisasi.
      _onRefresh();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorSnackBar("Gagal: $e");
    }
  }

  void _showAssignCourierSheet(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: _T.surface,
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, scrollController) {
              return FutureBuilder<List<dynamic>>(
                future: OrderRemoteDataSource().getAvailableCouriers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: _T.accent));
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text("Data kurir tidak tersedia"));
                  }

                  final couriers = snapshot.data!;
                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                              color: _T.border,
                              borderRadius: BorderRadius.circular(10))),
                      const SizedBox(height: 16),
                      Text("Tugaskan Kurir",
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: couriers.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: _T.border),
                          itemBuilder: (context, index) {
                            final courier = couriers[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _T.accentLight,
                                child: const Icon(Icons.motorcycle_rounded,
                                    color: _T.accent),
                              ),
                              title: Text(courier['name'],
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600)),
                              subtitle:
                                  Text(courier['phone'] ?? courier['email']),
                              onTap: () async {
                                final selectedCourierId = courier['id'];
                                final selectedCourierName = courier['name'];

                                Navigator.pop(sheetContext);
                                _showLoadingDialog();

                                try {
                                  await OrderRemoteDataSource()
                                      .assignCourier(order.id, selectedCourierId);

                                  if (!mounted) return;
                                  Navigator.pop(this.context);
                                  _onRefresh();

                                  ScaffoldMessenger.of(this.context)
                                      .showSnackBar(SnackBar(
                                    content:
                                        Text("$selectedCourierName ditugaskan!"),
                                    backgroundColor: _T.success,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                } catch (e) {
                                  if (!mounted) return;
                                  Navigator.pop(this.context);
                                  _showErrorSnackBar("Gagal: $e");
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            });
      },
    );
  }

  void _showUpdateWeightDialog(OrderModel order) {
    final String unit = _getUnit(order.service);
    final TextEditingController weightCtrl = TextEditingController(
        text: order.weight == 0 ? '' : order.weight.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Input Jumlah ($unit)"),
        content: TextField(
          controller: weightCtrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
          ],
          decoration: InputDecoration(
            hintText: "Contoh: 2.5",
            suffixText: unit,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (weightCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              _showLoadingDialog();
              try {
                await OrderRemoteDataSource()
                    .updateOrderWeight(order.id, weightCtrl.text);
                if (!mounted) return;
                Navigator.pop(context);
                _onRefresh();
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                _showErrorSnackBar("Gagal: $e");
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _T.accent, foregroundColor: Colors.white),
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: _T.accent,
          child: CustomScrollView(
            controller: _scrollController, // PENTING: Attach Controller di sini
            physics: const BouncingScrollPhysics(), 
            slivers: [
              // --- Header ---
              SliverToBoxAdapter(
                child: AnimationConfiguration.synchronized(
                  duration: const Duration(milliseconds: 800),
                  child: FadeInAnimation(
                    child: SlideAnimation(
                      verticalOffset: -30.0,
                      child: _buildHeader(),
                    ),
                  ),
                ),
              ),

              // --- List Body ---
              if (_isFirstLoad) 
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: _T.accent)
                  ),
                )
              else if (_orders.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text("Belum ada pesanan")),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 600),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildOrderCard(_orders[index]),
                            ),
                          ),
                        );
                      },
                      childCount: _orders.length,
                    ),
                  ),
                ),

              // --- Pagination Loading Indicator ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: _isLoadingMore 
                      ? const CircularProgressIndicator(color: _T.accent) 
                      : (_hasMoreData 
                          ? const SizedBox.shrink() 
                          : Text("Semua pesanan telah dimuat", 
                              style: GoogleFonts.inter(color: _T.textMuted, fontSize: 12))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.surface,
        border: Border(bottom: BorderSide(color: _T.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Daftar Pesanan",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _T.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Admin Panel",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: _T.textMain,
                    ),
                  ),
                ],
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_T.accentLight, Color(0xFFE0E7FF)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _T.accent.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.local_laundry_service_rounded,
                    color: _T.accent, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildStatCard("Menunggu", "12", Icons.access_time_rounded, _T.warning, _T.warningLight)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard("Proses", "8", Icons.autorenew_rounded, _T.accent, _T.accentLight)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard("Selesai", "5", Icons.check_circle_outline_rounded, _T.success, _T.successLight)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.border, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _T.textMain,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: _T.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    bool isNew = order.weight == 0;
    String unit = _getUnit(order.service);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {},
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: _T.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _T.border.withOpacity(0.5), width: 1),
              boxShadow: [
                BoxShadow(
                  color: _T.accent.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_T.bg, _T.borderLight],
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(bottom: BorderSide(color: _T.border, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _T.accent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: _T.accent.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.shopping_basket_rounded,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.orderCode,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                letterSpacing: 0.3,
                                color: _T.textMain,
                              ),
                            ),
                            Text(
                              "Tarik info waktu dari API jika ada",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: _T.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildStatusBadge(order.status, key: ValueKey(order.status)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _T.bg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [_T.accentLight, Color(0xFFE0E7FF)],
                                ),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(order.customerName),
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _T.accent,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.customerName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _T.textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_rounded,
                                          size: 14, color: _T.textMuted),
                                      const SizedBox(width: 6),
                                      Text(
                                        "+62 ... (Data API)",
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: _T.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        Icons.checkroom_rounded,
                        "Layanan",
                        order.service,
                        _T.accentLight,
                        _T.accent,
                      ),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        Icons.scale_rounded,
                        "Berat",
                        isNew ? "Belum diinput" : "${order.weight} $unit",
                        _T.purpleLight,
                        _T.purple,
                        trailing: _buildActionButton(
                          isNew ? "Input" : "Edit",
                          isNew ? _T.warning : _T.accent,
                          isNew ? _T.warningLight : _T.accentLight,
                          () => _showUpdateWeightDialog(order),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        Icons.motorcycle_rounded,
                        "Kurir",
                        order.courierName ?? "Belum ada kurir",
                        _T.dangerLight,
                        _T.danger,
                        trailing: _buildActionButton(
                          order.courierName == null ? "Tugaskan" : "Ganti",
                          _T.warning,
                          _T.warningLight,
                          () => _showAssignCourierSheet(order),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(height: 0.5, color: _T.border),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ubah Status",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: _T.textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: _T.bg,
                              border: Border.all(color: _T.border, width: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.swap_horiz_rounded,
                                    size: 18, color: _T.accent),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _adminStatusOptions.contains(order.status)
                                          ? order.status
                                          : _adminStatusOptions[0],
                                      isExpanded: true,
                                      items: _adminStatusOptions
                                          .map((s) => DropdownMenuItem(
                                                value: s,
                                                child: Text(
                                                  s,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: _T.textMain,
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                      onChanged: (val) => _updateStatus(order.id, val!),
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                          color: _T.textMuted),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _showQrDialog(order.orderCode),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: _T.accent, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.qr_code_scanner_rounded,
                                      size: 18, color: _T.accent),
                                  const SizedBox(width: 8),
                                  Text(
                                    "QR Code",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _T.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _showPhotoDialog(order),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: _T.accent,
                                elevation: 0,
                                shadowColor: _T.accent.withOpacity(0.25),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.camera_alt_rounded,
                                      size: 18, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Foto Bukti",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon, String label, String value, Color bgColor, Color iconColor, {Widget? trailing}
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, color: _T.textMuted)),
              const SizedBox(height: 4),
              Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _T.textMain)),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildActionButton(
      String label, Color textColor, Color bgColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
        child: Text(
          label,
          style: GoogleFonts.poppins(color: textColor, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, {Key? key}) {
    Color color = status.contains('Lunas') || status.contains('Selesai')
        ? _T.success
        : status.contains('Proses') ? _T.accent : _T.warning;
    Color bgColor = status.contains('Lunas') || status.contains('Selesai')
        ? _T.successLight
        : status.contains('Proses') ? _T.accentLight : _T.warningLight;

    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
      child: Text(
        status,
        style: GoogleFonts.poppins(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _getInitials(String name) {
    List<String> names = name.split(' ');
    if (names.length >= 2) return '${names[0][0]}${names[1][0]}'.toUpperCase();
    return name.substring(0, 2).toUpperCase();
  }

  void _showQrDialog(String code) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 200, height: 200, child: QrImageView(data: code, version: QrVersions.auto)),
            const SizedBox(height: 10),
            Text(code, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  void _showPhotoDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Bukti Timbangan", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            order.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      order.imageUrl!,
                      height: 200, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
                    ),
                  )
                : const Text("Belum ada foto"),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _uploadNewPhoto(order.id),
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text("Ambil Foto"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.accent, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _uploadNewPhoto(int orderId) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 60);
    if (pickedFile != null) {
      if (!mounted) return;
      Navigator.pop(context);
      _showLoadingDialog();
      try {
        await OrderRemoteDataSource().uploadOrderImage(orderId, File(pickedFile.path));
        if (!mounted) return;
        Navigator.pop(context);
        _onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto berhasil diupload!"), backgroundColor: _T.success),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        _showErrorSnackBar("Gagal: $e");
      }
    }
  }
}