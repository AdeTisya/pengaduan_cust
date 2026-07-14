import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../content/chatbot_page.dart';
import '../../config/api_config.dart';
import '../contentbuttom/navigation_button.dart';

class DashboardCust extends StatefulWidget {
  const DashboardCust({super.key});

  @override
  State<DashboardCust> createState() => _DashboardCustState();
}

class _DashboardCustState extends State<DashboardCust> {
  int totalPengaduan = 0;
  int menunggu = 0;
  int diterima = 0;
  int diproses = 0;
  int selesai = 0;
  int ditolak = 0;
  List<Map<String, dynamic>> grafikBulanan = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse(ApiConfig.customerDashboard),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'];
        final statistik = data['statistik'];
        final grafik = data['grafik_pengaduan'] as List;

        setState(() {
          totalPengaduan = statistik['total_pengaduan'] ?? 0;
          menunggu = statistik['menunggu'] ?? 0;
          diterima = statistik['diterima'] ?? 0;
          diproses = statistik['diproses'] ?? 0;
          selesai = statistik['selesai'] ?? 0;
          ditolak = statistik['ditolak'] ?? 0;
          grafikBulanan = grafik
              .map(
                (e) => {
                  'bulan': (e['bulan'] ?? '').toString(),
                  'total': int.tryParse(e['total'].toString()) ?? 0,
                },
              )
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      // ✅ floatingActionButton dipindah ke sini (level Scaffold)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatbotPage()),
          );
        },
        // 💡 Tambahkan properti color di sini untuk mengubah warna ikon
        icon: const Icon(
          Icons.support_agent,
          color: Colors.white, // Silakan ganti dengan warna yang Anda inginkan
        ),
        label: const Text(
          'Asisten',
          style: TextStyle(
            color: Colors.white,
          ), // Opsional: jika ingin warna teksnya senada
        ),
        backgroundColor: const Color.fromARGB(255, 56, 70, 130),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header biru dengan logo & logout
              Container(
                width: double.infinity,
                color: const Color(0xFF1E2A5E),
                padding: const EdgeInsets.fromLTRB(47, 50, 47, 27),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Transform.translate(
                          offset: const Offset(160, -70),
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(
                                    255,
                                    55,
                                    66,
                                    111,
                                  ).withValues(alpha: 0.3),
                                  offset: const Offset(0, 4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo_kominfo.png',
                              width: 84,
                              height: 84,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Container(
                          width: 84,
                          height: 250,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E2A5E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout, color: Colors.white, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Transform.translate(
                offset: const Offset(0, -40),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(27, 0, 27, 0),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: const Offset(0, 8),
                            blurRadius: 20,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            offset: const Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
                            child: Column(
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.description,
                                      size: 30,
                                      color: Colors.black,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Total Pengaduan',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 13),
                                Text(
                                  isLoading ? '-' : '$totalPengaduan',
                                  style: const TextStyle(
                                    color: Color(0xFF0059FF),
                                    fontSize: 32,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Pengaduan Terdaftar',
                                  style: TextStyle(
                                    color: Color(0xFF464646),
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 35),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildStatusColumn(
                                      count: isLoading ? '-' : '$menunggu',
                                      label: 'Menunggu',
                                      color: const Color(0xFFDDC000),
                                    ),
                                    _buildStatusColumn(
                                      count: isLoading ? '-' : '$diterima',
                                      label: 'Diterima',
                                      color: const Color(0xFF7C3AED),
                                    ),
                                    _buildStatusColumn(
                                      count: isLoading ? '-' : '$diproses',
                                      label: 'Diproses',
                                      color: const Color(0xFF0059FF),
                                    ),
                                    _buildStatusColumn(
                                      count: isLoading ? '-' : '$selesai',
                                      label: 'Selesai',
                                      color: const Color(0xFF328E6E),
                                    ),
                                    _buildStatusColumn(
                                      count: isLoading ? '-' : '$ditolak',
                                      label: 'Ditolak',
                                      color: const Color(0xFFFF0000),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),

                          // Bottom nav card
                          Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E2A5E),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const MainScaffold(initialIndex: 1),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.history,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'History pengaduan',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 2,
                                  height: 30,
                                  color: Colors.white,
                                ),
                                InkWell(
                                  onTap: () {
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pushNamed('/history_rating');
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'History Rating',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Graph section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      offset: const Offset(-4, -4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bar_chart, size: 24, color: Colors.black),
                        SizedBox(width: 8),
                        Text(
                          'Graph Pengaduan Internet',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : grafikBulanan.isEmpty
                          ? Center(
                              child: Text(
                                'Belum ada data grafik',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : _buildGrafik(),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 100,
              ), // ✅ padding bawah agar FAB tidak nutup konten
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrafik() {
    final maxTotal = grafikBulanan
        .map((e) => e['total'] as int)
        .fold(0, (a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: grafikBulanan.map((item) {
          final total = (item['total'] as int?) ?? 0;
          final ratio = maxTotal == 0 ? 0.0 : total / maxTotal;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$total',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0059FF),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 28,
                height: 120 * ratio + 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2A5E),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item['bulan'],
                style: const TextStyle(fontSize: 12, color: Color(0xFF464646)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusColumn({
    required String count,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF464646), fontSize: 15),
        ),
      ],
    );
  }
}
