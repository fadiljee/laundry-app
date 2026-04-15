// Snippet logika widget-nya:
Column(
  children: [
    TextField(
      decoration: InputDecoration(
        labelText: 'Berat Cucian (Kg)',
        border: OutlineInputBorder(),
        suffixText: 'Kg',
      ),
      keyboardType: TextInputType.number,
    ),
    const SizedBox(height: 16),
    InkWell(
      onTap: () { /* Fungsi ambil foto pake image_picker */ },
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 40),
            Text("Ambil Foto Timbangan"),
          ],
        ),
      ),
    ),
  ],
)