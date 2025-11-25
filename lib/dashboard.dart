import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<dynamic> _barangList = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final String apiUrl = "http://127.0.0.1:8000/api/barang";

  @override
  void initState() {
    super.initState();
    _fetchBarang();
  }

  // Fungsi untuk mengambil data dari API
  Future<void> _fetchBarang() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      developer.log('🚀 Mencoba fetch data dari: $apiUrl', name: 'API');
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      developer.log('📡 Response status: ${response.statusCode}', name: 'API');
      developer.log('📦 Response body: ${response.body}', name: 'API');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          final data = responseData['data'];
          developer.log('✅ Data diterima: ${data.length} items', name: 'API');
          
          setState(() {
            _barangList = List<dynamic>.from(data);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Gagal memuat data';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error ${response.statusCode}: ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('❌ Error: $e', name: 'API');
      setState(() {
        _errorMessage = 'Koneksi gagal: $e';
        _isLoading = false;
      });
    }
  }

  // Fungsi untuk menambah barang dengan debugging lengkap
  Future<void> _tambahBarang() async {
    final namaController = TextEditingController();
    final stokController = TextEditingController(text: '0');

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool isSubmitting = false;
          
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text("Tambah Barang Baru"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: namaController,
                  decoration: const InputDecoration(
                    labelText: "Nama Barang *",
                    border: OutlineInputBorder(),
                    hintText: "Masukkan nama barang",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: stokController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Jumlah Barang *",
                    border: OutlineInputBorder(),
                    hintText: "Masukkan jumlah",
                  ),
                ),
                if (isSubmitting) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 5),
                  const Text(
                    "Menyimpan...",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  // Validasi input
                  if (namaController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nama barang harus diisi')),
                    );
                    return;
                  }

                  final stok = int.tryParse(stokController.text);
                  if (stok == null || stok < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Jumlah barang harus angka positif')),
                    );
                    return;
                  }

                  setDialogState(() => isSubmitting = true);

                  try {
                    developer.log('📤 Mengirim data ke API...', name: 'API');
                    
                    final Map<String, dynamic> requestData = {
                      'nama': namaController.text,
                      'barang': stok,
                    };

                    developer.log('📝 Data yang dikirim: $requestData', name: 'API');

                    final response = await http.post(
                      Uri.parse(apiUrl),
                      headers: {
                        'Accept': 'application/json',
                        'Content-Type': 'application/json',
                      },
                      body: json.encode(requestData),
                    ).timeout(const Duration(seconds: 10));

                    developer.log('📡 POST Response status: ${response.statusCode}', name: 'API');
                    developer.log('📦 POST Response body: ${response.body}', name: 'API');

                    final responseData = json.decode(response.body);

                    if (response.statusCode == 201 && responseData['success'] == true) {
                      developer.log('✅ Barang berhasil ditambahkan', name: 'API');
                      
                      // Refresh data
                      _fetchBarang();
                      
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(responseData['message'] ?? 'Barang berhasil ditambahkan'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      final errorMsg = responseData['message'] ?? 
                                     responseData['errors']?.toString() ?? 
                                     'Gagal menambah barang';
                      developer.log('❌ Gagal: $errorMsg', name: 'API');
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal: $errorMsg'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      setDialogState(() => isSubmitting = false);
                    }
                  } catch (e) {
                    developer.log('❌ Exception: $e', name: 'API');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    setDialogState(() => isSubmitting = false);
                  }
                },
                child: const Text("Simpan"),
              ),
            ],
          );
        },
      ),
    );
  }

  // [Fungsi _hapusBarang dan _editBarang tetap sama seperti sebelumnya]
  Future<void> _hapusBarang(int index) async {
    final barang = _barangList[index];
    final barangId = barang['id'];

    bool confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Barang"),
        content: Text("Yakin hapus ${barang['nama']}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.delete(
          Uri.parse('$apiUrl/$barangId'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          _fetchBarang();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Barang berhasil dihapus')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus: ${response.statusCode}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _editBarang(int index) async {
    final barang = _barangList[index];
    final barangId = barang['id'];
    
    final namaController = TextEditingController(text: barang['nama'] ?? '');
    final stokController = TextEditingController(text: (barang['barang'] ?? 0).toString());

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Edit Barang"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(
                labelText: "Nama Barang",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: stokController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Jumlah Barang",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (namaController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama barang harus diisi')),
                );
                return;
              }

              try {
                final response = await http.put(
                  Uri.parse('$apiUrl/$barangId'),
                  headers: {
                    'Accept': 'application/json',
                    'Content-Type': 'application/json',
                  },
                  body: json.encode({
                    'nama': namaController.text,
                    'barang': int.tryParse(stokController.text) ?? 0,
                  }),
                ).timeout(const Duration(seconds: 10));

                if (response.statusCode == 200) {
                  _fetchBarang();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Barang berhasil diupdate')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal update: ${response.statusCode}')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          Positioned(
            top: -50,
            left: -40,
            child: _buildCircle(150, Colors.white.withOpacity(0.1)),
          ),
          Positioned(
            bottom: -70,
            right: -60,
            child: _buildCircle(220, Colors.white.withOpacity(0.1)),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 15),
                const Text(
                  "📦 Dashboard Barang - Roky 5E",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // Debug Info
                if (_barangList.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Data ditemukan: ${_barangList.length} barang",
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),

                // Tombol Refresh dan Tambah
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _fetchBarang,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Refresh"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _tambahBarang,
                        icon: const Icon(Icons.add),
                        label: const Text("Tambah Barang"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Content Area
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Memuat data...",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        )
                      : _errorMessage.isNotEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.white,
                                      size: 50,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _errorMessage,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed: _fetchBarang,
                                      child: const Text('Coba Lagi'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _barangList.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.inventory_2_outlined,
                                        color: Colors.white,
                                        size: 60,
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        "Tidak ada data barang",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      const Text(
                                        "Klik tombol 'Tambah Barang' untuk menambah data",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton(
                                        onPressed: _tambahBarang,
                                        child: const Text('Tambah Barang Pertama'),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: _barangList.length,
                                  itemBuilder: (context, index) {
                                    final barang = _barangList[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 15),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(color: Colors.white24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.inventory_2_outlined,
                                          color: Colors.white,
                                        ),
                                        title: Text(
                                          barang['nama'] ?? 'No Name',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        ),
                                        subtitle: Text(
                                          "Jumlah: ${barang['barang'] ?? 0}",
                                          style: const TextStyle(color: Colors.white70),
                                        ),
                                        trailing: Wrap(
                                          spacing: 10,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Colors.yellowAccent,
                                              ),
                                              onPressed: () => _editBarang(index),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.redAccent,
                                              ),
                                              onPressed: () => _hapusBarang(index),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}