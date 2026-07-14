import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../../services/fonnte_service.dart';
import '../../utils/notification_template.dart';

class ComplainDetail extends StatefulWidget {
  final Map<String, dynamic> item;

  const ComplainDetail({super.key, required this.item});

  @override
  State<ComplainDetail> createState() => _ComplainDetailState();
}

class _ComplainDetailState extends State<ComplainDetail>
    with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final Color primaryBlue = const Color(0xFF1B2B5C);

  bool _isUpdating = false;
  late Map<String, dynamic> _item;

  bool _waitingForSettingsReturn = false;
  String? _pendingAlamatAfterSettings;

  @override
  void initState() {
    super.initState();
    _item = Map<String, dynamic>.from(widget.item);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed &&
        _waitingForSettingsReturn &&
        _pendingAlamatAfterSettings != null) {
      _waitingForSettingsReturn = false;
      final alamat = _pendingAlamatAfterSettings!;
      _pendingAlamatAfterSettings = null;
      _recheckPermissionAfterSettings(alamat);
    }
  }

  Future<void> _recheckPermissionAfterSettings(String alamatTujuan) async {
    if (!mounted) return;
    _openGoogleMapsDirections(alamatTujuan);
  }

  String _getAlamatTujuan() {
    final alamatPengaduan =
        _item['alamat'] ??
        _item['alamat_pengaduan'] ??
        _item['lokasi'] ??
        '';

    if (alamatPengaduan.toString().trim().isNotEmpty &&
        alamatPengaduan.toString() != '-') {
      return alamatPengaduan.toString();
    }

    return '';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GOOGLE MAPS — minta izin lokasi sistem, lalu buka Maps tanpa origin
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _openGoogleMapsDirections(String alamatTujuan) async {
    // 1. Cek apakah layanan lokasi aktif di perangkat
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      _showLocationRequiredDialog(
        icon: Icons.location_disabled_rounded,
        iconColor: const Color(0xFF856404),
        bgColor: const Color(0xFFFFF3CD),
        borderColor: const Color(0xFFFFD700),
        title: 'Layanan Lokasi Mati',
        message:
            'GPS perangkat Anda sedang tidak aktif.\n\n'
            'Aktifkan lokasi di Pengaturan agar aplikasi dapat menampilkan '
            'rute navigasi dari posisi Anda saat ini.',
        primaryLabel: 'Buka Pengaturan Lokasi',
        onPrimary: () async {
          Navigator.pop(context);
          _waitingForSettingsReturn = true;
          _pendingAlamatAfterSettings = alamatTujuan;
          await Geolocator.openLocationSettings();
        },
      );
      return;
    }

    // 2. Cek status permission
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Tampilkan dialog izin sistem (Allow / Deny) dari OS
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (!mounted) return;
      _showLocationRequiredDialog(
        icon: Icons.location_off_rounded,
        iconColor: const Color(0xFF856404),
        bgColor: const Color(0xFFFFF3CD),
        borderColor: const Color(0xFFFFD700),
        title: 'Izin Lokasi Diperlukan',
        message:
            'Aplikasi membutuhkan izin lokasi untuk menampilkan rute '
            'navigasi dari posisi Anda saat ini.\n\n'
            'Izin lokasi wajib diberikan untuk menggunakan fitur navigasi.',
        primaryLabel: 'Izinkan Lokasi',
        onPrimary: () async {
          Navigator.pop(context);
          final perm = await Geolocator.requestPermission();
          if (!mounted) return;
          if (perm == LocationPermission.always ||
              perm == LocationPermission.whileInUse) {
            await _launchMapsWithPosition(alamatTujuan);
          } else {
            _openGoogleMapsDirections(alamatTujuan);
          }
        },
      );
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      _showLocationRequiredDialog(
        icon: Icons.lock_outline_rounded,
        iconColor: const Color(0xFF721C24),
        bgColor: const Color(0xFFF8D7DA),
        borderColor: const Color(0xFFF5C6CB),
        title: 'Izin Lokasi Diblokir',
        message:
            'Izin lokasi telah diblokir secara permanen.\n\n'
            'Untuk mengaktifkannya:\n'
            'Buka Pengaturan → Aplikasi → ${_appName()} → Izin → Lokasi → pilih "Izinkan".\n\n'
            'Izin lokasi wajib diberikan untuk menggunakan fitur navigasi.',
        primaryLabel: 'Buka Pengaturan Aplikasi',
        onPrimary: () async {
          Navigator.pop(context);
          _waitingForSettingsReturn = true;
          _pendingAlamatAfterSettings = alamatTujuan;
          await Geolocator.openAppSettings();
        },
      );
      return;
    }

    // 3. Permission granted — langsung buka Maps (tanpa getCurrentPosition)
    //    Google Maps akan otomatis pakai "Your location" dari GPS device
    if (!mounted) return;
    await _launchMapsWithPosition(alamatTujuan);
  }

  /// Buka Google Maps tanpa origin → Maps otomatis pakai "Your location"
  Future<void> _launchMapsWithPosition(String alamatTujuan) async {
    final encodedTujuan = Uri.encodeComponent(alamatTujuan);

    // Coba buka Google Maps app native (langsung navigasi dari current location)
    final uriNative = Uri.parse(
      'google.navigation:q=$encodedTujuan&mode=d',
    );

    // Fallback: web URL tanpa origin → Maps pakai "Your location" otomatis
    final uriWeb = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$encodedTujuan'
      '&travelmode=driving',
    );

    if (await canLaunchUrl(uriNative)) {
      await launchUrl(uriNative, mode: LaunchMode.externalApplication);
    } else {
      await _launchUri(uriWeb);
    }
  }

  Future<void> _launchUri(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka Google Maps'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _appName() => 'Kominfo Pengaduan';

  void _showLocationRequiredDialog({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String title,
    required String message,
    required String primaryLabel,
    required VoidCallback onPrimary,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Icon(icon, color: iconColor, size: 34),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: primaryBlue,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF555555),
                  fontFamily: 'Inter',
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: primaryBlue.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: primaryBlue, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Izin lokasi wajib untuk fitur navigasi.',
                        style: TextStyle(
                          fontSize: 11,
                          color: primaryBlue,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Batal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: onPrimary,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      primaryLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UPDATE STATUS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _updateStatus({
    required int pengaduanId,
    required String status,
    String? catatan,
    Uint8List? fotoBuktiBytes,
    String? fotoBuktiFileName,
  }) async {
    setState(() => _isUpdating = true);

    try {
      final token = await _authService.getToken();
      if (token == null) return;

      final uri = Uri.parse(
        '${ApiConfig.teknisiPengaduan}/$pengaduanId/update-status',
      );

      http.Response response;

      if (fotoBuktiBytes != null) {
        final request = http.MultipartRequest('POST', uri)
          ..headers.addAll({
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          })
          ..fields['status'] = status
          ..fields['_method'] = 'PUT';

        if (catatan != null && catatan.isNotEmpty) {
          request.fields['catatan'] = catatan;
        }

        request.files.add(
          http.MultipartFile.fromBytes(
            'foto_penyelesaian',
            fotoBuktiBytes,
            filename: fotoBuktiFileName ?? 'foto_penyelesaian.jpg',
          ),
        );

        final streamed = await request.send();
        response = await http.Response.fromStream(streamed);
      } else {
        response = await http.put(
          uri,
          headers: ApiConfig.headers(token: token),
          body: jsonEncode({
            'status': status,
            if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
          }),
        );
      }

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        final data = responseData['data'];
        setState(() {
          _item['status'] = status;
          if (catatan != null && catatan.isNotEmpty) {
            _item['catatan'] = catatan;
          }
          if (data != null && data['foto_penyelesaian'] != null) {
            _item['foto_penyelesaian'] = data['foto_penyelesaian'];
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Status berhasil diubah'),
            backgroundColor: Colors.green,
          ),
        );

        await _kirimNotifikasiWA(
          status: status,
          catatan: catatan,
          fotoPenyelesaianUrl: _item['foto_penyelesaian']?.toString(),
        );
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
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // KIRIM NOTIFIKASI WA
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _kirimNotifikasiWA({
    required String status,
    String? catatan,
    String? fotoPenyelesaianUrl,
  }) async {
    final rawCustomer = _item['customer'] ?? _item['user'] ?? _item['pelapor'];

    final String nomorHP = rawCustomer is Map
        ? (rawCustomer['telepon'] ??
                rawCustomer['phone'] ??
                rawCustomer['no_hp'] ??
                '')
            .toString()
        : '';

    if (nomorHP.isEmpty || nomorHP == '-') return;

    String nomorBersih = nomorHP.replaceAll(RegExp(r'\D'), '');
    if (nomorBersih.startsWith('0')) {
      nomorBersih = '62${nomorBersih.substring(1)}';
    }
    if (nomorBersih.isEmpty) return;

    final String namaCustomer = rawCustomer is Map
        ? (rawCustomer['nama'] ?? rawCustomer['name'] ?? 'Pelanggan').toString()
        : 'Pelanggan';

    final String kode = _item['kode_pengaduan'] ?? '-';

    final String pesan = NotificationTemplate.ubahStatus(
      kodePengaduan: kode,
      namaCustomer: namaCustomer,
      status: status,
      catatan: catatan,
      fotoPenyelesaianUrl: fotoPenyelesaianUrl,
    );

    final bool berhasil = await FonnteService.sendMessage(
      target: nomorBersih,
      message: pesan,
    );

    if (!mounted) return;

    if (!berhasil) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Status diubah, namun notifikasi WA gagal terkirim'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BOTTOM SHEET UBAH STATUS
  // ══════════════════════════════════════════════════════════════════════════

  void _showUbahStatusSheet() {
    final int id = _item['id'] as int;
    final String statusSaat = _item['status'] ?? 'menunggu';
    final TextEditingController catatanController = TextEditingController();
    String? statusDipilih;
    Uint8List? fotoBuktiBytes;
    String? fotoBuktiFileName;

    final List<Map<String, dynamic>> statusOptions = [
      {
        'value': 'diproses',
        'label': 'Diproses',
        'icon': Icons.build_circle_outlined,
        'color': const Color(0xFF004085),
      },
      {
        'value': 'selesai',
        'label': 'Selesai',
        'icon': Icons.check_circle_outline,
        'color': const Color(0xFF155724),
      },
      {
        'value': 'ditolak',
        'label': 'Ditolak',
        'icon': Icons.cancel_outlined,
        'color': const Color(0xFF721C24),
      },
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
            final bool isSelesai = statusDipilih == 'selesai';

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      ...statusOptions.map((opt) {
                        final isSelected = statusDipilih == opt['value'];
                        return GestureDetector(
                          onTap: () => setSheetState(
                            () => statusDipilih = opt['value'] as String,
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
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
                                  const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                      if (isSelesai) ...[
                        const SizedBox(height: 4),
                        _buildFotoBuktiPicker(
                          fotoBytes: fotoBuktiBytes,
                          onFotoPicked: (bytes, fileName) => setSheetState(() {
                            fotoBuktiBytes = bytes;
                            fotoBuktiFileName = fileName;
                          }),
                          onFotoRemoved: () => setSheetState(() {
                            fotoBuktiBytes = null;
                            fotoBuktiFileName = null;
                          }),
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 4),
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
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: TextField(
                          controller: catatanController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Tulis catatan atau keterangan...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontFamily: 'Inter',
                            ),
                          ),
                          style: const TextStyle(fontFamily: 'Inter'),
                        ),
                      ),
                      if (isSelesai && fotoBuktiBytes == null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFFFD700),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xFF856404),
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Foto bukti penyelesaian wajib dilampirkan.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF856404),
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _canSubmit(statusDipilih, fotoBuktiBytes)
                                    ? primaryBlue
                                    : Colors.grey[300],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed:
                              !_canSubmit(statusDipilih, fotoBuktiBytes)
                                  ? null
                                  : () {
                                      Navigator.pop(ctx);
                                      _updateStatus(
                                        pengaduanId: id,
                                        status: statusDipilih!,
                                        catatan: catatanController.text.trim(),
                                        fotoBuktiBytes: fotoBuktiBytes,
                                        fotoBuktiFileName: fotoBuktiFileName,
                                      );
                                    },
                          child: Text(
                            'Simpan Perubahan',
                            style: TextStyle(
                              color:
                                  _canSubmit(statusDipilih, fotoBuktiBytes)
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
              ),
            );
          },
        );
      },
    );
  }

  bool _canSubmit(String? statusDipilih, Uint8List? bytes) {
    if (statusDipilih == null) return false;
    if (statusDipilih == 'selesai' && bytes == null) return false;
    return true;
  }

  Widget _buildFotoBuktiPicker({
    required Uint8List? fotoBytes,
    required void Function(Uint8List bytes, String fileName) onFotoPicked,
    required VoidCallback onFotoRemoved,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto Bukti Penyelesaian *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: primaryBlue,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        if (fotoBytes != null) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  fotoBytes,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onFotoRemoved,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _pickImageSheet(onFotoPicked),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Ganti',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          GestureDetector(
            onTap: () => _pickImageSheet(onFotoPicked),
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryBlue.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: primaryBlue, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Tambah Foto Bukti',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primaryBlue,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kamera atau Galeri',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500], fontFamily: 'Inter'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _pickImageSheet(void Function(Uint8List bytes, String fileName) onPicked) {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih Sumber Foto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: primaryBlue,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: primaryBlue),
                title: const Text('Kamera', style: TextStyle(fontFamily: 'Inter')),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? file = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                  if (file != null) {
                    final bytes = await file.readAsBytes();
                    onPicked(bytes, file.name);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: primaryBlue),
                title: const Text('Galeri', style: TextStyle(fontFamily: 'Inter')),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if (file != null) {
                    final bytes = await file.readAsBytes();
                    onPicked(bytes, file.name);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String kode = _item['kode_pengaduan'] ?? '-';
    final String deskripsi = _item['deskripsi'] ?? '-';
    final String status = _item['status'] ?? 'menunggu';
    final String? catatan = _item['catatan'];
    final String? tanggal =
        _item['created_at'] ?? _item['tanggal_pengaduan'] ?? _item['tanggal'];
    final String alamat = _item['alamat'] ?? '-';

    final rawKategori = _item['kategori'];
    final String kategori = rawKategori is String
        ? rawKategori
        : rawKategori is Map
            ? (rawKategori['nama_kategori'] ?? rawKategori['nama'] ?? '-').toString()
            : '-';

    final rawCustomer = _item['customer'] ?? _item['user'] ?? _item['pelapor'];
    final String namaCustomer = rawCustomer is Map
        ? (rawCustomer['nama'] ?? rawCustomer['name'] ?? '-').toString()
        : '-';
    final String emailCustomer = rawCustomer is Map
        ? (rawCustomer['email'] ?? '-').toString()
        : '-';
    final String teleponCustomer = rawCustomer is Map
        ? (rawCustomer['telepon'] ?? rawCustomer['phone'] ?? rawCustomer['no_hp'] ?? '-').toString()
        : '-';

    final rawTeknisi = _item['teknisi'];
    final String namaTeknisi = rawTeknisi is Map
        ? (rawTeknisi['nama'] ?? rawTeknisi['name'] ?? '-').toString()
        : '-';

    final String? fotoUrl = _item['foto'] ?? _item['foto_pengaduan'] ?? _item['foto_bukti'];
    final String? fotoPenyelesaianUrl = _item['foto_penyelesaian']?.toString();
    final String alamatTujuan = _getAlamatTujuan();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                backgroundColor: primaryBlue,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: const Text(
                    'DETAIL PENGADUAN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.02,
                      fontFamily: 'Inter',
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                  ),
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Kode Pengaduan', style: TextStyle(fontSize: 11, color: Colors.grey[500], fontFamily: 'Inter')),
                                  const SizedBox(height: 4),
                                  Text(
                                    kode,
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: primaryBlue, fontFamily: 'Inter', letterSpacing: 0.5),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _buildStatusBadge(status),
                          ],
                        ),
                      ),

                      if (fotoUrl != null && fotoUrl.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle('Foto Pengaduan', Icons.photo_outlined),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  fotoUrl,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 200,
                                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                                    child: Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 48)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (fotoPenyelesaianUrl != null && fotoPenyelesaianUrl.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle('Foto Bukti Penyelesaian', Icons.task_alt_rounded),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  fotoPenyelesaianUrl,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 200,
                                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                                    child: Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 48)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      _sectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle('Informasi Pengaduan', Icons.info_outline),
                            const SizedBox(height: 16),
                            _infoRow(label: 'Kategori', value: kategori, icon: Icons.category_outlined),
                            _divider(),
                            _infoRow(label: 'Tanggal', value: _formatTanggal(tanggal), icon: Icons.calendar_today_outlined),
                            _divider(),
                            _infoRow(label: 'Deskripsi', value: deskripsi, icon: Icons.description_outlined, multiLine: true),
                            if (catatan != null && catatan.isNotEmpty) ...[
                              _divider(),
                              _infoRow(label: 'Catatan Teknisi', value: catatan, icon: Icons.sticky_note_2_outlined, multiLine: true),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      _sectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle('Data Pelapor', Icons.person_outline),
                            const SizedBox(height: 16),
                            _infoRow(label: 'Nama', value: namaCustomer, icon: Icons.badge_outlined),
                            if (emailCustomer != '-') ...[
                              _divider(),
                              _infoRow(label: 'Email', value: emailCustomer, icon: Icons.email_outlined),
                            ],
                            if (teleponCustomer != '-') ...[
                              _divider(),
                              _infoRow(label: 'Telepon', value: teleponCustomer, icon: Icons.phone_outlined),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      _sectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle('Lokasi Pengaduan', Icons.location_on_outlined),
                            const SizedBox(height: 16),
                            _infoRow(label: 'Alamat', value: alamat, icon: Icons.map_outlined, multiLine: true),
                            if (alamatTujuan.isNotEmpty) ...[
                              _divider(),
                              GestureDetector(
                                onTap: () => _openGoogleMapsDirections(alamatTujuan),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: primaryBlue.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: primaryBlue.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.navigation_outlined, size: 18, color: primaryBlue),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Navigasi ke Lokasi',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primaryBlue, fontFamily: 'Inter'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      if (namaTeknisi != '-') ...[
                        const SizedBox(height: 16),
                        _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle('Teknisi Penanganan', Icons.build_outlined),
                              const SizedBox(height: 16),
                              _infoRow(label: 'Nama Teknisi', value: namaTeknisi, icon: Icons.engineering_outlined),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4)),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _isUpdating ? null : () => _showUbahStatusSheet(),
                  icon: _isUpdating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                  label: Text(
                    _isUpdating ? 'Menyimpan...' : 'Ubah Status Pengaduan',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: primaryBlue, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primaryBlue, fontFamily: 'Inter'),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _infoRow({required String label, required String value, required IconData icon, bool multiLine = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontFamily: 'Inter')),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF333333), fontFamily: 'Inter', height: 1.4),
                  maxLines: multiLine ? null : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 20, color: Colors.grey[200], thickness: 1);

  String _labelStatus(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu': return 'Menunggu';
      case 'diproses': return 'Diproses';
      case 'selesai': return 'Selesai';
      case 'ditolak': return 'Ditolak';
      default: return status;
    }
  }

  String _formatTanggal(String? tanggal) {
    if (tanggal == null || tanggal.isEmpty) return '-';
    try {
      final dt = DateTime.parse(tanggal).toLocal();
      const bulan = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${dt.day} ${bulan[dt.month]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return tanggal;
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    switch (status.toLowerCase()) {
      case 'menunggu': bgColor = const Color(0xFFFFF3CD); textColor = const Color(0xFF856404); break;
      case 'diproses': bgColor = const Color(0xFFCCE5FF); textColor = const Color(0xFF004085); break;
      case 'selesai':  bgColor = const Color(0xFFD4EDDA); textColor = const Color(0xFF155724); break;
      case 'ditolak':  bgColor = const Color(0xFFF8D7DA); textColor = const Color(0xFF721C24); break;
      default:         bgColor = const Color(0xFFF0F0F0); textColor = const Color(0xFF666666);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(_labelStatus(status), style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
    );
  }
}