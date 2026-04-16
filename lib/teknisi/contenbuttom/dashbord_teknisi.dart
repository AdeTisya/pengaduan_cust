import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../models/user.dart';
import '../../../config/api_config.dart';
import '../content/rating_history_teknisi.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardTeknisi extends StatefulWidget {
  const DashboardTeknisi({super.key});

  @override
  State<DashboardTeknisi> createState() => _DashboardTeknisiState();
}

class _DashboardTeknisiState extends State<DashboardTeknisi> {
  final AuthService _authService = AuthService();

  User? _user;
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load user dari local storage dulu
    final localUser = await _authService.getUser();
    if (mounted) {
      setState(() {
        _user = localUser;
      });
    }

    // Load dashboard data dari API
    await _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse(ApiConfig.teknisiDashboard),
        headers: ApiConfig.headers(token: token),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['status'] == 'success' && mounted) {
          setState(() {
            _dashboardData = body['data'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    // Tampilkan dialog konfirmasi
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Konfirmasi Logout',
          style: TextStyle(
            fontFamily: 'Germania One',
            color: Color(0xFF1E2A5E),
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar?',
          style: TextStyle(fontFamily: 'GFS Neohellenic'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E2A5E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        // Kembali ke halaman login dan hapus semua route
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  // Helper ambil nilai statistik
  int _getStat(String key) {
    return _dashboardData?['statistik']?[key] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF1E2A5E),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E2A5E),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(50),
                      bottomRight: Radius.circular(50),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 50),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: app icon kiri, logout kanan
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // App icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.language,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          // Logout button
                          GestureDetector(
                            onTap: _handleLogout,
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.logout,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Logout',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontFamily: 'GFS Neohellenic',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Grid icon 4 kotak
                      Center(
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 5,
                            mainAxisSpacing: 5,
                            physics: const NeverScrollableScrollPhysics(),
                            children: List.generate(
                              4,
                              (index) => Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // SELAMAT DATANG
                      const Text(
                        'SELAMAT DATANG',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Gidugu',
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Nama teknisi dari API
                      Text(
                        'Di Aplikasi Pengaduan\n${_user?.nama ?? 'Teknisi'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'GFS Neohellenic',
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Statistics card ──────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        offset: Offset(-4, -4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  child: _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              color: Color(0xFF1E2A5E),
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header kartu
                            const Row(
                              children: [
                                Icon(
                                  Icons.list_alt,
                                  size: 28,
                                  color: Color(0xFF1E2A5E),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Total Pengaduan',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'Germania One',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 30),

                            // Total ditugaskan
                            Center(
                              child: Text(
                                '${_getStat('total_ditugaskan')}',
                                style: const TextStyle(
                                  color: Color(0xFF0059FF),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'Germania One',
                                ),
                              ),
                            ),
                            const Center(
                              child: Text(
                                'Pengaduan Terdaftar',
                                style: TextStyle(
                                  color: Color(0xFF464646),
                                  fontSize: 15,
                                  fontFamily: 'GFS Neohellenic',
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatItem(
                                  '${_getStat('menunggu')}',
                                  'Menunggu',
                                  const Color(0xFFDDC000),
                                ),
                                _buildStatItem(
                                  '${_getStat('diterima')}',
                                  'Diterima',
                                  const Color(0xFF7C3AED),
                                ),
                                _buildStatItem(
                                  '${_getStat('diproses')}',
                                  'Diproses',
                                  const Color(0xFF0059FF),
                                ),
                                _buildStatItem(
                                  '${_getStat('selesai')}',
                                  'Selesai',
                                  const Color(0xFF328E6E),
                                ),
                                _buildStatItem(
                                  '${_dashboardData?['total_penilaian'] ?? 0}',
                                  'Penilaian',
                                  const Color(0xFFFF6B00),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Rata-rata rating
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Color(0xFFDDC000),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Rata-rata Rating: ${_dashboardData?['rata_rating'] ?? 0}',
                                    style: const TextStyle(
                                      color: Color(0xFF464646),
                                      fontSize: 15,
                                      fontFamily: 'GFS Neohellenic',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),

                // ── Action buttons ───────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2A5E),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 28,
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.history,
                                color: Colors.white,
                                size: 26,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'History pengaduan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontFamily: 'Inclusive Sans',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RatingHistoryTeknisi(),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2A5E),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 28,
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.star, color: Colors.white, size: 26),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'History Rating',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontFamily: 'Inclusive Sans',
                                    ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.w400,
            fontFamily: 'Germania One',
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF464646),
            fontSize: 15,
            fontFamily: 'GFS Neohellenic',
          ),
        ),
      ],
    );
  }
}
