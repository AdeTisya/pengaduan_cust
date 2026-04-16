// lib/customer/content/history_rating.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class HistoryRating extends StatefulWidget {
  const HistoryRating({super.key});

  @override
  State<HistoryRating> createState() => _HistoryRatingState();
}

class _HistoryRatingState extends State<HistoryRating> {
  final AuthService _authService = AuthService();
  final Color primaryBlue = const Color(0xFF1E2A5E);

  List<Map<String, dynamic>> _ratings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Sesi habis, silakan login kembali';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/customer/rating/history'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        final raw = responseData['data'];
        final List<dynamic> data = raw is List ? raw : [];
        setState(() {
          _ratings = data.map((e) => e as Map<String, dynamic>).toList();
        });
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'Gagal memuat data';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTanggal(String? tanggal) {
    if (tanggal == null || tanggal.isEmpty) return '-';
    try {
      final dt = DateTime.parse(tanggal).toLocal();
      const bulan = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      return '${dt.day} ${bulan[dt.month]} ${dt.year}';
    } catch (_) {
      return tanggal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Riwayat Penilaian',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Penilaian hasil kerja yang telah kamu berikan',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ──────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryBlue))
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.red[300], size: 48),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchHistory,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue),
                                child: const Text('Coba Lagi',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        )
                      : _ratings.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_border,
                                      color: Colors.grey[400], size: 64),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Belum ada penilaian',
                                    style: TextStyle(
                                        color: Colors.grey[500], fontSize: 16),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Penilaian muncul setelah pengaduan selesai',
                                    style: TextStyle(
                                        color: Colors.grey[400], fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchHistory,
                              color: primaryBlue,
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 24, 20, 40),
                                itemCount: _ratings.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) =>
                                    _buildRatingCard(_ratings[index]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> rating) {
    final String kode = rating['pengaduan_kode'] ?? '-';
    final String kategori = rating['kategori'] ?? '-';
    final String teknisi = rating['teknisi_nama'] ?? '-';
    final int bintang = rating['rating'] ?? 0;
    final String? komentar = rating['saran'];
    final String? balasan = rating['balasan_teknisi'];
    final String tanggal = _formatTanggal(rating['tanggal_rating']);

    return Container(
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Baris atas: kode & tanggal ──────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  kode,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tanggal,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            kategori,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontFamily: 'Inter',
            ),
          ),

          const SizedBox(height: 4),

          Row(
            children: [
              Icon(Icons.engineering_outlined,
                  size: 13, color: Colors.white.withValues(alpha: 0.65)),
              const SizedBox(width: 4),
              Text(
                teknisi,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Bintang & label ─────────────────────────────────
          Row(
            children: [
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < bintang ? Icons.star : Icons.star_border,
                    color: const Color(0xFFDDC000),
                    size: 20,
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text(
                '$bintang/5',
                style: const TextStyle(
                  color: Color(0xFFDDC000),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _labelBintang(bintang),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),

          // ── Komentar / aspek yang dinilai ───────────────────
          if (komentar != null && komentar.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.thumb_up_outlined,
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.65)),
                      const SizedBox(width: 6),
                      Text(
                        'Penilaian hasil kerja:',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Tampilkan aspek sebagai chip jika dipisah koma
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: komentar.split(', ').map((aspek) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          aspek.trim(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontFamily: 'Inter',
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

          // ── Balasan teknisi ─────────────────────────────────
          if (balasan != null && balasan.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.reply,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.65)),
                      const SizedBox(width: 4),
                      Text(
                        'Balasan dari teknisi:',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    balasan,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _labelBintang(int bintang) {
    switch (bintang) {
      case 1:
        return 'Sangat Buruk';
      case 2:
        return 'Buruk';
      case 3:
        return 'Cukup';
      case 4:
        return 'Baik';
      case 5:
        return 'Sangat Baik';
      default:
        return '-';
    }
  }
}