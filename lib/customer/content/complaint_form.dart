// lib/screens/complaint_form.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/complaint_service.dart';

class ComplaintForm extends StatefulWidget {
  const ComplaintForm({super.key});

  @override
  State<ComplaintForm> createState() => _ComplaintFormState();
}

class _ComplaintFormState extends State<ComplaintForm> {
  // State
  int? selectedKategoriId;
  String? selectedKategoriName;
  Uint8List? _imageBytes;
  String? _fileName;
  bool _isLoading = false;
  bool _isLoadingKategori = false;
  List<Map<String, dynamic>> _kategoriList = [];

  final TextEditingController _descriptionController = TextEditingController();
  final ComplaintService _complaintService = ComplaintService();
  final ImagePicker _imagePicker = ImagePicker();

  // Colors
  final Color primaryBlue = const Color(0xFF1E2A5E);
  final Color submitBlue = const Color.fromARGB(255, 26, 87, 219);
  final Color backgroundColor = const Color(0xFFF5F5F5);
  final Color textGray = const Color(0xFF9CA3AF);

  @override
  void initState() {
    super.initState();
    _loadKategori();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // ─── Load Kategori dari API ────────────────────────────────────────────────

  Future<void> _loadKategori() async {
    setState(() => _isLoadingKategori = true);

    final result = await _complaintService.getKategori();

    if (result['success'] == true) {
      final List<dynamic> data = result['data'];
      setState(() {
        _kategoriList = data
            .map(
              (e) => {
                'id': e['id'],
                'nama': e['nama_kategori'] ?? e['nama'] ?? '',
              },
            )
            .toList();
      });
    } else {
      // Fallback: gunakan kategori statis jika API belum tersedia
      setState(() {
        _kategoriList = [
          {'id': 1, 'nama': 'Infrastruktur'},
          {'id': 2, 'nama': 'Pelayanan Publik'},
          {'id': 3, 'nama': 'Keamanan'},
          {'id': 4, 'nama': 'Kebersihan'},
          {'id': 5, 'nama': 'Lainnya'},
        ];
      });
    }

    setState(() => _isLoadingKategori = false);
  }

  // ─── Pilih Foto ────────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes(); // ✅ penting untuk Web

        setState(() {
          _imageBytes = bytes;
          _fileName = pickedFile.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih foto: ${e.toString()}')),
        );
      }
    }
  }

  // ─── Submit Pengaduan ──────────────────────────────────────────────────────

  Future<void> _submitComplaint() async {
    // Validasi input
    if (selectedKategoriId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kategori pengaduan')),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan isi deskripsi pengaduan')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _complaintService.createPengaduan(
      kategoriId: selectedKategoriId!,
      deskripsi: _descriptionController.text.trim(),
      fotoBukti: _imageBytes,
      fileName: _fileName,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'];
      _showSuccessDialog(
        kodePengaduan: data['kode_pengaduan'] ?? '',
        tanggal: data['tanggal_pengaduan'] ?? '',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal mengirim pengaduan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ─── Dialog Sukses ─────────────────────────────────────────────────────────

  void _showSuccessDialog({
    required String kodePengaduan,
    required String tanggal,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pengaduan Terkirim!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kode: $kodePengaduan',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Inter',
                ),
              ),
              if (tanggal.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Tanggal: $tanggal',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontFamily: 'Inter',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Pengaduan Anda telah berhasil dikirim. Kami akan segera menindaklanjuti.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Inter',
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E2A5E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // tutup dialog
                  Navigator.of(context).pop(); // kembali ke halaman sebelumnya
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Bottom Sheet Kategori ─────────────────────────────────────────────────

  void _showCategoryPicker() {
    if (_isLoadingKategori) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: const EdgeInsets.only(bottom: 20),
              ),
              const Text(
                'Pilih Kategori Pengaduan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 20),
              ..._kategoriList.map(
                (kategori) => ListTile(
                  title: Text(
                    kategori['nama'].toString(),
                    style: const TextStyle(fontSize: 16, fontFamily: 'Inter'),
                  ),
                  trailing: selectedKategoriId == kategori['id']
                      ? Icon(Icons.check, color: primaryBlue)
                      : null,
                  onTap: () {
                    setState(() {
                      selectedKategoriId = kategori['id'] as int;
                      selectedKategoriName = kategori['nama'].toString();
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Bottom Sheet Foto ─────────────────────────────────────────────────────

  void _showPhotoPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: const EdgeInsets.only(bottom: 20),
              ),
              const Text(
                'Pilih Foto Bukti',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.camera_alt, color: primaryBlue),
                title: const Text(
                  'Ambil Foto',
                  style: TextStyle(fontSize: 16, fontFamily: 'Inter'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: primaryBlue),
                title: const Text(
                  'Pilih dari Galeri',
                  style: TextStyle(fontSize: 16, fontFamily: 'Inter'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_imageBytes != null) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Hapus Foto',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Inter',
                      color: Colors.red,
                    ),
                  ),
                  onTap: () {
                    setState(() => _imageBytes = null);
                    Navigator.pop(context);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ─── Build UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(32),
                  bottomLeft: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(30, 30, 30, 30),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Buat Pengaduan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Kategori Pengaduan ──
                    _buildSectionLabel('Kategori Pengaduan'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _isLoadingKategori ? null : _showCategoryPicker,
                      child: Container(
                        decoration: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                _isLoadingKategori
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.people,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                const SizedBox(width: 12),
                                Text(
                                  selectedKategoriName ??
                                      'Pilih kategori pengaduan',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Deskripsi Pengaduan ──
                    _buildSectionLabel('Deskripsi Pengaduan'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.format_align_left,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _descriptionController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Inter',
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Jelaskan pengaduan Anda secara detail...',
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(
                                    alpha: 153,
                                  ), // 0.6 * 255
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              maxLines: 5,
                              minLines: 3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Foto Bukti ──
                    _buildSectionLabel('Foto Bukti'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showPhotoPicker,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(16),
                          // Tampilkan preview foto jika ada
                          image: _imageBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(_imageBytes!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _imageBytes == null
                            ? Center(
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: primaryBlue,
                                    size: 32,
                                  ),
                                ),
                              )
                            : Align(
                                alignment: Alignment.topRight,
                                child: Container(
                                  margin: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    if (_imageBytes != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Foto dipilih ✓',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // ── Submit Button ──
                    GestureDetector(
                      onTap: _isLoading ? null : _submitComplaint,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _isLoading
                              ? submitBlue.withValues(alpha: 0.7)
                              : submitBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Mengirim...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.send,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Kirim Pengaduan',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
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

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.5,
        fontFamily: 'Inter',
      ),
    );
  }
}
