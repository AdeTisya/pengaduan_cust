// lib/teknisi/content/complaint_list_teknisi.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class ComplaintListTeknisi extends StatefulWidget {
  const ComplaintListTeknisi({super.key});

  @override
  State<ComplaintListTeknisi> createState() => _ComplaintListTeknisiState();
}

class _ComplaintListTeknisiState extends State<ComplaintListTeknisi> {
  String selectedFilter = 'Semua status';
  List<Map<String, dynamic>> _pengaduanList = [];
  bool _isLoading = false;
  String? _errorMessage;

  final AuthService _authService = AuthService();
  final Color primaryBlue = const Color(0xFF1B2B5C);

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

  // ─── Fetch Pengaduan ───────────────────────────────────────────────────────

  Future<void> _fetchPengaduan() async {
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

      final statusFilter = _filterMap[selectedFilter];
      final uri = Uri.parse(ApiConfig.teknisiPengaduan).replace(
        queryParameters: statusFilter != null ? {'status': statusFilter} : null,
      );

      final response = await http.get(
        uri,
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        final raw = responseData['data'];
        List<dynamic> data;
        if (raw is List) {
          data = raw;
        } else if (raw is Map && raw['data'] is List) {
          data = raw['data'] as List<dynamic>;
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
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ─── Ubah Status Pengaduan ─────────────────────────────────────────────────

  Future<void> _updateStatus({
    required int pengaduanId,
    required String status,
    String? catatan,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return;

      final response = await http.put(
        Uri.parse('${ApiConfig.teknisiPengaduan}/$pengaduanId'),
        headers: ApiConfig.headers(token: token),
        body: jsonEncode({
          'status': status,
          if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Status berhasil diubah'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchPengaduan(); // refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Gagal mengubah status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ─── Bottom Sheet Ubah Status ──────────────────────────────────────────────

  void _showUbahStatusSheet(Map<String, dynamic> item) {
    final int id = item['id'] as int;
    final String statusSaat = item['status'] ?? 'menunggu';
    final TextEditingController catatanController = TextEditingController();
    String? statusDipilih;

    // Opsi status yang bisa dipilih teknisi
    final List<Map<String, dynamic>> statusOptions = [
      {'value': 'diproses', 'label': 'Diproses', 'icon': Icons.build_circle_outlined, 'color': const Color(0xFF004085)},
      {'value': 'selesai', 'label': 'Selesai', 'icon': Icons.check_circle_outline, 'color': const Color(0xFF155724)},
      {'value': 'ditolak', 'label': 'Ditolak', 'icon': Icons.cancel_outlined, 'color': const Color(0xFF721C24)},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Ubah Status Pengaduan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primaryBlue,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Status saat ini: ${_labelStatus(statusSaat)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pilihan status
                    ...statusOptions.map((opt) {
                      final isSelected = statusDipilih == opt['value'];
                      return GestureDetector(
                        onTap: () => setSheetState(
                            () => statusDipilih = opt['value'] as String),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryBlue
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? null
                                : Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                opt['icon'] as IconData,
                                color: isSelected
                                    ? Colors.white
                                    : opt['color'] as Color,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                opt['label'] as String,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : primaryBlue,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              if (isSelected) ...[
                                const Spacer(),
                                const Icon(Icons.check,
                                    color: Colors.white, size: 18),
                              ]
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 8),

                    // Catatan
                    Text(
                      'Catatan (opsional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryBlue,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: TextField(
                        controller: catatanController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Tulis catatan atau keterangan...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                              color: Colors.grey, fontFamily: 'Inter'),
                        ),
                        style: const TextStyle(fontFamily: 'Inter'),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Tombol simpan
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: statusDipilih != null
                              ? primaryBlue
                              : Colors.grey[300],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: statusDipilih == null
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                _updateStatus(
                                  pengaduanId: id,
                                  status: statusDipilih!,
                                  catatan: catatanController.text.trim(),
                                );
                              },
                        child: Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            color: statusDipilih != null
                                ? Colors.white
                                : Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 32),
            child: const Center(
              child: Text(
                'DAFTAR PENGADUAN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.02,
                  fontFamily: 'Inter',
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
                  return GestureDetector(
                    onTap: () {
                      if (selectedFilter == label) return;
                      setState(() => selectedFilter = label);
                      _fetchPengaduan();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryBlue : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: isSelected
                            ? null
                            : Border.all(color: primaryBlue, width: 1.5),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : primaryBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // List Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: primaryBlue),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red[300], size: 48),
                            const SizedBox(height: 12),
                            Text(_errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchPengaduan,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue),
                              child: const Text('Coba Lagi',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : _pengaduanList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inbox_outlined,
                                    color: Colors.grey[400], size: 64),
                                const SizedBox(height: 12),
                                Text(
                                  'Tidak ada pengaduan',
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchPengaduan,
                            color: primaryBlue,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                              itemCount: _pengaduanList.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) =>
                                  _buildComplaintCard(_pengaduanList[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // ─── Card ──────────────────────────────────────────────────────────────────

  Widget _buildComplaintCard(Map<String, dynamic> item) {
    final String kode = item['kode_pengaduan'] ?? '-';
    final String deskripsi = item['deskripsi'] ?? '-';
    final String status = item['status'] ?? 'menunggu';

    final rawKategori = item['kategori'];
    final String kategori = rawKategori is String
        ? rawKategori
        : rawKategori is Map
            ? (rawKategori['nama_kategori'] ?? rawKategori['nama'] ?? '-')
                .toString()
            : '-';

    // Nama customer / pelapor
    final rawCustomer = item['customer'] ?? item['user'] ?? item['pelapor'];
    final String namaCustomer = rawCustomer is Map
        ? (rawCustomer['nama'] ?? rawCustomer['name'] ?? '-').toString()
        : '-';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue, width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kode + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kode,
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),

          const SizedBox(height: 8),

          // Nama pelapor
          if (namaCustomer != '-')
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  namaCustomer,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),

          const SizedBox(height: 8),

          // Deskripsi
          Text(
            deskripsi,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 12,
              fontFamily: 'Inter',
            ),
          ),

          const SizedBox(height: 12),

          // Kategori + Tombol Ubah
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                kategori,
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
              GestureDetector(
                onTap: () => _showUbahStatusSheet(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    'Ubah',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
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

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _labelStatus(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu': return 'Menunggu';
      case 'diproses': return 'Diproses';
      case 'selesai': return 'Selesai';
      case 'ditolak': return 'Ditolak';
      default: return status;
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'menunggu':
        bgColor = const Color(0xFFFFF3CD);
        textColor = const Color(0xFF856404);
        break;
      case 'diproses':
        bgColor = const Color(0xFFCCE5FF);
        textColor = const Color(0xFF004085);
        break;
      case 'selesai':
        bgColor = const Color(0xFFD4EDDA);
        textColor = const Color(0xFF155724);
        break;
      case 'ditolak':
        bgColor = const Color(0xFFF8D7DA);
        textColor = const Color(0xFF721C24);
        break;
      default:
        bgColor = const Color(0xFFF0F0F0);
        textColor = const Color(0xFF666666);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _labelStatus(status),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}