// lib/customer/content/complaint_detail.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class ComplaintDetail extends StatefulWidget {
  final int pengaduanId;
  final String kodePengaduan;

  const ComplaintDetail({
    super.key,
    required this.pengaduanId,
    required this.kodePengaduan,
  });

  @override
  State<ComplaintDetail> createState() => _ComplaintDetailState();
}

class _ComplaintDetailState extends State<ComplaintDetail> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _detail;
  bool _isLoading = true;
  String? _errorMessage;

  final Color primaryBlue = const Color(0xFF1E2A5E);

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
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
        Uri.parse('${ApiConfig.customerPengaduan}/${widget.pengaduanId}'),
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        setState(() {
          _detail = responseData['data'];
        });
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'Gagal memuat detail';
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

  /// Ganti localhost / 127.0.0.1 ke baseHost agar bisa diakses dari device/emulator
  String _fixImageUrl(String url) {
    // Ambil host dari ApiConfig.baseUrl, misal "http://192.168.1.10:8000"
    final baseUri = Uri.parse(ApiConfig.baseUrl);
    final baseHost = '${baseUri.scheme}://${baseUri.host}:${baseUri.port}';

    return url
        .replaceFirst('http://localhost', baseHost)
        .replaceFirst('http://127.0.0.1', baseHost);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.kodePengaduan,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
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
                                onPressed: _fetchDetail,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue),
                                child: const Text('Coba Lagi',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        )
                      : _buildDetail(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail() {
    final d = _detail!;

    final String kode = d['kode_pengaduan'] ?? '-';
    final String status = d['status'] ?? 'menunggu';
    final String deskripsi = d['deskripsi'] ?? '-';
    final String tanggal = d['tanggal_pengaduan'] ?? d['created_at'] ?? '-';

    final rawKategori = d['kategori'];
    final String kategori = rawKategori is String
        ? rawKategori
        : rawKategori is Map
            ? (rawKategori['nama_kategori'] ?? rawKategori['nama'] ?? '-')
                .toString()
            : '-';

    // Fix URL foto bukti agar tidak localhost
    final rawFoto = d['foto_bukti'];
    final String? fotoBukti = (rawFoto != null && rawFoto.toString().isNotEmpty)
        ? _fixImageUrl(rawFoto.toString())
        : null;

    final String? responTeknisi = d['respon_teknisi'] ?? d['catatan'];

    final rawTeknisi = d['teknisi'];
    final String? namaTeknisi = rawTeknisi is Map
        ? (rawTeknisi['nama'] ?? rawTeknisi['nama_lengkap'])?.toString()
        : null;

    return RefreshIndicator(
      onRefresh: _fetchDetail,
      color: primaryBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryBlue, width: 2),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(kode,
                          style: TextStyle(
                            color: primaryBlue,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          )),
                      _buildStatusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tanggal,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Info Card
            _buildCard(
              children: [
                _buildRow('Kategori', kategori),
                const Divider(height: 24),
                _buildLabelValue('Deskripsi Pengaduan', deskripsi),
              ],
            ),

            // Foto Bukti
            if (fotoBukti != null) ...[
              const SizedBox(height: 12),
              _buildSectionLabel('Foto Bukti'),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  fotoBukti,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: primaryBlue,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, error, __) {
                    return Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.broken_image,
                                color: Colors.grey, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              'Gagal memuat foto',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Teknisi
            if (namaTeknisi != null) ...[
              const SizedBox(height: 12),
              _buildCard(
                children: [_buildRow('Ditangani oleh', namaTeknisi)],
              ),
            ],

            // Respon Teknisi
            if (responTeknisi != null && responTeknisi.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildCard(
                children: [
                  _buildLabelValue('Respon Teknisi', responTeknisi),
                ],
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryBlue, width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: primaryBlue,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                color: primaryBlue,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label,
        style: TextStyle(
          color: primaryBlue,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ));
  }

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
      child: Text(label,
          style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }
}