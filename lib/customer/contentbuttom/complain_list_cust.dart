// lib/screens/complaint_list.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../content/complaint_form.dart';
import '../content/complaint_detail.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class ComplaintList extends StatefulWidget {
  const ComplaintList({super.key});

  @override
  State<ComplaintList> createState() => _ComplaintListState();
}

class _ComplaintListState extends State<ComplaintList> {
  String selectedFilter = 'Semua status';
  List<Map<String, dynamic>> _pengaduanList = [];
  bool _isLoading = false;
  String? _errorMessage;

  final AuthService _authService = AuthService();

  // Map filter label ke nilai status API
  final Map<String, String?> _filterMap = {
    'Semua status': null,
    'Menunggu': 'menunggu',
    'Diproses': 'diproses',
    'Selesai': 'selesai',
    'Ditolak': 'ditolak',
  };

  @override
  void initState() {
    super.initState();
    _fetchPengaduan();
  }

  // ─── Fetch dari API ────────────────────────────────────────────────────────
  Future<void> _fetchPengaduan() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _authService.getToken();

      if (!mounted) return;

      if (token == null) {
        setState(() {
          _errorMessage = 'Sesi habis, silakan login kembali';
          _isLoading = false;
        });
        return;
      }

      final statusFilter = _filterMap[selectedFilter];
      final uri = Uri.parse(ApiConfig.customerPengaduan).replace(
        queryParameters: statusFilter != null ? {'status': statusFilter} : null,
      );

      final response = await http.get(
        uri,
        headers: ApiConfig.headers(token: token),
      );

      if (!mounted) return;

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        final raw = responseData['data'];

        List<dynamic> data;
        if (raw is List) {
          data = raw;
        } else if (raw is Map && raw['data'] is List) {
          data = raw['data'];
        } else {
          data = [];
        }

        setState(() {
          _pengaduanList = data.map((e) => e as Map<String, dynamic>).toList();
        });
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'Gagal memuat data';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1E2A5E),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
                child: const Center(
                  child: Text(
                    'DAFTAR PENGADUAN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // Filter Tabs
              Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterMap.keys.map((label) {
                      final isSelected = selectedFilter == label;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterTab(label, isSelected),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // List Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1E2A5E),
                        ),
                      )
                    : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red[300],
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchPengaduan,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E2A5E),
                              ),
                              child: const Text(
                                'Coba Lagi',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _pengaduanList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              color: Colors.grey[400],
                              size: 64,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada pengaduan',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchPengaduan,
                        color: const Color(0xFF1E2A5E),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                          itemCount: _pengaduanList.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildComplaintCard(_pengaduanList[index]);
                          },
                        ),
                      ),
              ),
            ],
          ),

          // FAB Tambah Pengaduan
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ComplaintForm()),
                );
                // Refresh list setelah kembali dari form
                _fetchPengaduan();
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2A5E),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filter Tab ────────────────────────────────────────────────────────────

  Widget _buildFilterTab(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (selectedFilter == text) return;
        setState(() => selectedFilter = text);
        _fetchPengaduan();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E2A5E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? null
              : Border.all(color: const Color(0xFF1E2A5E), width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1E2A5E),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ─── Complaint Card ────────────────────────────────────────────────────────

  Widget _buildComplaintCard(Map<String, dynamic> item) {
    final String kode = item['kode_pengaduan'] ?? '-';
    final String deskripsi = item['deskripsi'] ?? '-';
    // kategori bisa berupa Map, String, atau null tergantung response API
    String kategori = '-';
    final dynamic rawKategori = item['kategori'];
    if (rawKategori is Map) {
      kategori =
          rawKategori['nama_kategori']?.toString() ??
          rawKategori['nama']?.toString() ??
          '-';
    } else if (rawKategori is String) {
      kategori = rawKategori;
    }
    final String status = item['status'] ?? 'menunggu';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2A5E), width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kode,
                style: const TextStyle(
                  color: Color(0xFF1E2A5E),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              deskripsi,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                kategori,
                style: const TextStyle(
                  color: Color(0xFF1E2A5E),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ComplaintDetail(
                        pengaduanId: item['id'] as int,
                        kodePengaduan: kode,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2A5E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Detail',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Status Badge ──────────────────────────────────────────────────────────

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'menunggu':
        bgColor = const Color(0xFFFFF3CD);
        textColor = const Color(0xFF856404);
        label = 'Menunggu';
        break;
      case 'diproses':
        bgColor = const Color(0xFFCCE5FF);
        textColor = const Color(0xFF004085);
        label = 'Diproses';
        break;
      case 'selesai':
        bgColor = const Color(0xFFD4EDDA);
        textColor = const Color(0xFF155724);
        label = 'Selesai';
        break;
      case 'ditolak':
        bgColor = const Color(0xFFF8D7DA);
        textColor = const Color(0xFF721C24);
        label = 'Ditolak';
        break;
      default:
        bgColor = const Color(0xFFF0F0F0);
        textColor = const Color(0xFF666666);
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
