// lib/customer/content/rating_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class RatingScreen extends StatefulWidget {
  final Map<String, dynamic> pengaduan;

  const RatingScreen({super.key, required this.pengaduan});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _saranController = TextEditingController();
  final Color primaryBlue = const Color(0xFF1E2A5E);

  int _selectedRating = 0;
  bool _isSubmitting = false;

  // Aspek penilaian hasil kerja teknisi
  final List<Map<String, dynamic>> _aspekOptions = [
    {'label': 'Pekerjaan rapi & bersih', 'icon': Icons.cleaning_services_outlined},
    {'label': 'Masalah terselesaikan', 'icon': Icons.check_circle_outline},
    {'label': 'Teknisi ramah & sopan', 'icon': Icons.sentiment_satisfied_outlined},
    {'label': 'Tiba tepat waktu', 'icon': Icons.schedule_outlined},
  ];
  final List<String> _selectedAspek = [];

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih bintang penilaian terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await _authService.getToken();
      if (token == null) return;

      // Gabungkan aspek yang dipilih + komentar tambahan
      final List<String> allSaran = [..._selectedAspek];
      if (_saranController.text.trim().isNotEmpty) {
        allSaran.add(_saranController.text.trim());
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/customer/rating'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'pengaduan_id': widget.pengaduan['id'],
          'rating': _selectedRating,
          'saran': allSaran.isNotEmpty ? allSaran.join(', ') : null,
        }),
      );

      debugPrint('Rating response ${response.statusCode}: ${response.body}');
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201 && responseData['status'] == 'success') {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Penilaian berhasil dikirim, terima kasih!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Gagal mengirim penilaian'),
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
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildStar(int index) {
    return GestureDetector(
      onTap: () => setState(() => _selectedRating = index),
      child: AnimatedScale(
        scale: _selectedRating >= index ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Icon(
          _selectedRating >= index ? Icons.star : Icons.star_border,
          color: _selectedRating >= index
              ? const Color(0xFFDDC000)
              : Colors.grey[400],
          size: 44,
        ),
      ),
    );
  }

  String _ratingLabel() {
    switch (_selectedRating) {
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
        return 'Ketuk bintang untuk menilai';
    }
  }

  Color _ratingColor() {
    switch (_selectedRating) {
      case 1:
      case 2:
        return const Color(0xFF721C24);
      case 3:
        return const Color(0xFF856404);
      case 4:
      case 5:
        return const Color(0xFF155724);
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _saranController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String kode = widget.pengaduan['kode_pengaduan'] ?? '-';

    final rawKategori = widget.pengaduan['kategori'];
    final String kategori = rawKategori is String
        ? rawKategori
        : rawKategori is Map
            ? (rawKategori['nama_kategori'] ?? rawKategori['nama'] ?? '-').toString()
            : '-';

    final rawTeknisi = widget.pengaduan['teknisi'];
    final String namaTeknisi = rawTeknisi is Map
        ? (rawTeknisi['nama'] ?? rawTeknisi['name'] ?? '-').toString()
        : (widget.pengaduan['nama_teknisi'] ?? '-');

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
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'BERI PENILAIAN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Bagaimana hasil kerja teknisi kami?',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  children: [
                    // ── Info pengaduan ──────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryBlue.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: primaryBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.receipt_long_outlined,
                                    color: primaryBlue, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                kode,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: primaryBlue,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _infoRow(Icons.category_outlined, 'Kategori', kategori),
                          const SizedBox(height: 6),
                          _infoRow(Icons.engineering_outlined, 'Teknisi', namaTeknisi),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Bintang rating ──────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Nilai Hasil Kerja',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: primaryBlue,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Seberapa puas kamu dengan hasil perbaikan?',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (i) => _buildStar(i + 1)),
                          ),
                          const SizedBox(height: 10),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                              color: _ratingColor(),
                            ),
                            child: Text(_ratingLabel()),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Aspek penilaian hasil kerja ─────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Apa yang kamu nilai baik? (opsional)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: primaryBlue,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pilih aspek hasil kerja yang memuaskan',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _aspekOptions.map((aspek) {
                              final String label = aspek['label'];
                              final IconData icon = aspek['icon'];
                              final bool isSelected = _selectedAspek.contains(label);

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedAspek.remove(label);
                                    } else {
                                      _selectedAspek.add(label);
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryBlue
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? primaryBlue
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        icon,
                                        size: 14,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 16),

                          // Komentar tambahan
                          Text(
                            'Komentar tambahan (opsional)',
                            style: TextStyle(
                              fontSize: 13,
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
                              controller: _saranController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText:
                                    'Ceritakan pengalaman kamu dengan hasil kerja teknisi...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                    color: Colors.grey, fontFamily: 'Inter'),
                              ),
                              style: const TextStyle(fontFamily: 'Inter'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Tombol kirim ────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isSubmitting ? null : _submitRating,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Kirim Penilaian',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontFamily: 'Inter',
          ),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }
}