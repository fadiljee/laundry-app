import 'package:flutter/material.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  // Data Dummy untuk List Pesanan
  final List<Map<String, dynamic>> _dummyOrders = [
    {
      "id": "LYR-001",
      "customer": "Fadil",
      "status": "Menunggu Pembayaran",
      "total": "Rp 35.000",
      "service": "Cuci Kering",
      "isVerified": false,
    },
    {
      "id": "LYR-002",
      "customer": "Budi",
      "status": "Sedang Dicuci",
      "total": "Rp 50.000",
      "service": "Cuci Setrika",
      "isVerified": true,
    },
    {
      "id": "LYR-003",
      "customer": "Siska",
      "status": "Selesai",
      "total": "Rp 25.000",
      "service": "Setrika Saja",
      "isVerified": true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Pesanan"),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list_rounded))
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: _dummyOrders.length,
        itemBuilder: (context, index) {
          final order = _dummyOrders[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order['id'],
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      _buildStatusBadge(order['status']),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.person, size: 20)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order['customer'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(order['service'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const Spacer(),
                      Text(order['total'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  // Tombol Verifikasi (Hanya muncul jika belum verified - Sesuai Flowchart)
                  if (!order['isVerified'])
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showVerifyDialog(index),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text("VERIFIKASI PEMBAYARAN"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    )
                  else
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.verified, color: Colors.blue, size: 16),
                        SizedBox(width: 5),
                        Text("Pembayaran Valid", style: TextStyle(color: Colors.blue, fontSize: 12)),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == "Menunggu Pembayaran") color = Colors.orange;
    if (status == "Sedang Dicuci") color = Colors.blue;
    if (status == "Selesai") color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showVerifyDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Verifikasi Pembayaran?"),
        content: Text("Pastikan uang transfer dari ${_dummyOrders[index]['customer']} sudah masuk ke rekening."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _dummyOrders[index]['isVerified'] = true;
                _dummyOrders[index]['status'] = "Sedang Dicuci";
              });
              Navigator.pop(context);
            },
            child: const Text("Ya, Valid"),
          ),
        ],
      ),
    );
  }
}