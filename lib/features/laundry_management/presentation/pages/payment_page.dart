import 'package:flutter/material.dart';
import '../../data/datasources/order_remote_datasource.dart';

class PaymentPage extends StatefulWidget {
  final String orderId;
  final double weight;
  final String customerName;

  const PaymentPage({
    super.key,
    required this.orderId,
    required this.weight,
    required this.customerName,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final double _pricePerKg = 7000;
  String _selectedMethod = 'QRIS';

  @override
  Widget build(BuildContext context) {
    double total = widget.weight * _pricePerKg;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          "Detail Pembayaran",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildSummaryCard(total),
                  const SizedBox(height: 32),
                  const Text(
                    "Pilih Metode Pembayaran",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMethodOption("QRIS", Icons.qr_code_scanner_rounded, "Bayar instan pakai aplikasi bank/e-wallet"),
                  _buildMethodOption("Transfer Bank", Icons.account_balance_rounded, "Manual transfer via ATM/Mobile Banking"),
                  const SizedBox(height: 32),
                  _buildPaymentInstruction(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildBottomAction(total),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.orderId.substring(0, 8).toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.customerName,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            "Rp ${total.toStringAsFixed(0)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSmallInfo("Berat", "${widget.weight} Kg"),
                Container(width: 1, height: 20, color: Colors.white24),
                _buildSmallInfo("Harga/Kg", "Rp 7.000"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInfo(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMethodOption(String method, IconData icon, String subtitle) {
    bool isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: Color(0xFF6366F1), size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInstruction() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _selectedMethod == 'QRIS'
          ? Center(
              key: const ValueKey(1),
              child: Column(
                children: [
                  const Text("Scan QRIS untuk menyelesaikan pembayaran", style: TextStyle(color: Colors.white60, fontSize: 13)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
                    ),
                    child: Image.network(
                      'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=PAYMENT_${widget.orderId}',
                      height: 180,
                      width: 180,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              key: const ValueKey(2),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Rekening Tujuan", style: TextStyle(color: Colors.white60, fontSize: 13)),
                  const SizedBox(height: 16),
                  _buildBankDetail("Bank Mandiri", "123-000-456-789"),
                  const Divider(color: Colors.white10, height: 32),
                  const Text("Atas Nama", style: TextStyle(color: Colors.white60, fontSize: 13)),
                  const Text("LAUNDRY PINTAR POS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
    );
  }

  Widget _buildBankDetail(String bank, String acc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(bank, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(acc, style: const TextStyle(color: Color(0xFF818CF8), fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildBottomAction(double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 40,
            offset: const Offset(0, -10),
          )
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: const Color(0xFF6366F1).withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
              );

              try {
                await OrderRemoteDataSource().processPayment(
                  docId: widget.orderId,
                  totalAmount: total,
                  paymentMethod: _selectedMethod,
                );
                
                if (!mounted) return;
                Navigator.pop(context); // Tutup Loading
                Navigator.pop(context); // Kembali
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Pembayaran Berhasil Dikonfirmasi!", style: TextStyle(color: Colors.white)),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text(
              "KONFIRMASI LUNAS",
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w900, // Ganti dari black ke w900
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}