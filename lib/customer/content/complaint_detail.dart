// lib/customer/content/complaint_detail.dart
//
// PERUBAHAN: Menampilkan "Foto Bukti Penyelesaian" dari teknisi
// ketika status = selesai dan ada field foto_penyelesaian di API.

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import 'rating_screen.dart';

// ══════════════════════════════════════════════════════════════════════════════
// STATUS STEPPER WIDGET  (tidak berubah dari versi sebelumnya)
// ══════════════════════════════════════════════════════════════════════════════

class StatusStepper extends StatefulWidget {
  final String status;
  const StatusStepper({super.key, required this.status});

  @override
  State<StatusStepper> createState() => _StatusStepperState();
}

class _StatusStepperState extends State<StatusStepper>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _spinController;
  late AnimationController _checkController;
  late AnimationController _connectorController;

  late Animation<double> _pulseAnim;
  late Animation<double> _spinAnim;
  late Animation<double> _checkAnim;
  late Animation<double> _connectorAnim;

  static const _steps = [
    _StepData(
      key: 'menunggu',
      label: 'Menunggu',
      icon: Icons.hourglass_top_rounded,
      tooltip: 'Menunggu admin menerima pengaduan Anda',
    ),
    _StepData(
      key: 'diterima',
      label: 'Diterima',
      icon: Icons.verified_outlined,
      tooltip:
          'Pengaduan sudah diterima, teknisi akan segera melakukan perbaikan, mohon ditunggu',
    ),
    _StepData(
      key: 'diproses',
      label: 'Diproses',
      icon: Icons.engineering_outlined,
      tooltip: 'Teknisi sudah dalam perjalanan menuju lokasi Anda',
    ),
    _StepData(
      key: 'selesai',
      label: 'Selesai',
      icon: Icons.task_alt_rounded,
      tooltip: 'Pengaduan sudah berhasil diselesaikan',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _connectorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
    _spinAnim = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_spinController);
    _checkAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _checkController, curve: Curves.easeOut));
    _connectorAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _connectorController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant StatusStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _checkController.forward(from: 0);
      _connectorController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _spinController.dispose();
    _checkController.dispose();
    _connectorController.dispose();
    super.dispose();
  }

  int get _activeIndex {
    final s = widget.status.toLowerCase();
    if (s == 'ditolak') return -1;
    for (int i = 0; i < _steps.length; i++) {
      if (_steps[i].key == s) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final activeIdx = _activeIndex;
    final isDitolak = widget.status.toLowerCase() == 'ditolak';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(_steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                final stepIdx = i ~/ 2;
                final isDone = !isDitolak && stepIdx < activeIdx;
                return Expanded(
                  child: AnimatedBuilder(
                    animation: _connectorAnim,
                    builder: (_, __) => _ConnectorLine(
                      filled: isDone,
                      fillProgress: isDone ? _connectorAnim.value : 0.0,
                    ),
                  ),
                );
              }
              final stepIdx = i ~/ 2;
              final step = _steps[stepIdx];
              final bool isActive = !isDitolak && stepIdx == activeIdx;
              final bool isDone = !isDitolak && stepIdx < activeIdx;
              final bool isPending = isDitolak || stepIdx > activeIdx;

              return _buildStep(
                step: step,
                isActive: isActive,
                isDone: isDone,
                isPending: isPending,
              );
            }),
          ),
          if (!isDitolak && activeIdx >= 0) ...[
            const SizedBox(height: 12),
            _buildInfoBanner(_steps[activeIdx]),
          ],
        ],
      ),
    );
  }

  Widget _buildStep({
    required _StepData step,
    required bool isActive,
    required bool isDone,
    required bool isPending,
  }) {
    const double circleSize = 52;
    const Color primaryBlue = Color(0xFF1E2A5E);
    const Color doneGreen = Color(0xFF1D9E75);
    const Color pendingGray = Color(0xFFCCCCCC);
    const Color activeAmber = Color(0xFFF0C040);

    Color circleBg;
    Color iconColor;
    Color labelColor;

    if (isDone) {
      circleBg = doneGreen;
      iconColor = Colors.white;
      labelColor = doneGreen;
    } else if (isActive) {
      switch (step.key) {
        case 'menunggu':
          circleBg = activeAmber;
          iconColor = const Color(0xFF856404);
          labelColor = const Color(0xFF856404);
          break;
        case 'diterima':
          circleBg = const Color(0xFF378ADD);
          iconColor = Colors.white;
          labelColor = const Color(0xFF185FA5);
          break;
        case 'diproses':
          circleBg = primaryBlue;
          iconColor = Colors.white;
          labelColor = primaryBlue;
          break;
        case 'selesai':
          circleBg = doneGreen;
          iconColor = Colors.white;
          labelColor = doneGreen;
          break;
        default:
          circleBg = primaryBlue;
          iconColor = Colors.white;
          labelColor = primaryBlue;
      }
    } else {
      circleBg = pendingGray;
      iconColor = Colors.white;
      labelColor = Colors.grey;
    }

    return Tooltip(
      message: step.tooltip,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A5E).withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontFamily: 'Inter',
        height: 1.4,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      preferBelow: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: circleSize + 16,
            height: circleSize + 16,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isActive)
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Transform.scale(
                      scale: _pulseAnim.value,
                      child: Container(
                        width: circleSize,
                        height: circleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: circleBg.withValues(
                              alpha: 1.5 - _pulseAnim.value,
                            ),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    color: circleBg,
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: circleBg.withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: _buildStepIcon(
                    step: step,
                    isActive: isActive,
                    isDone: isDone,
                    iconColor: iconColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            step.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              color: labelColor,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(_StepData step) {
    Color bgColor;
    Color iconColor;
    Color textColor;
    IconData bannerIcon;

    switch (step.key) {
      case 'menunggu':
        bgColor = const Color(0xFFFFF8E1);
        iconColor = const Color(0xFF856404);
        textColor = const Color(0xFF6D4C00);
        bannerIcon = Icons.access_time_rounded;
        break;
      case 'diterima':
        bgColor = const Color(0xFFE3F2FD);
        iconColor = const Color(0xFF185FA5);
        textColor = const Color(0xFF0D47A1);
        bannerIcon = Icons.check_circle_outline_rounded;
        break;
      case 'diproses':
        bgColor = const Color(0xFFEEF0FA);
        iconColor = const Color(0xFF1E2A5E);
        textColor = const Color(0xFF1E2A5E);
        bannerIcon = Icons.engineering_outlined;
        break;
      case 'selesai':
        bgColor = const Color(0xFFE8F5E9);
        iconColor = const Color(0xFF1D9E75);
        textColor = const Color(0xFF0F6E56);
        bannerIcon = Icons.task_alt_rounded;
        break;
      default:
        bgColor = const Color(0xFFF5F5F5);
        iconColor = Colors.grey;
        textColor = Colors.grey;
        bannerIcon = Icons.info_outline;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: iconColor.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(bannerIcon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              step.tooltip,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontFamily: 'Inter',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIcon({
    required _StepData step,
    required bool isActive,
    required bool isDone,
    required Color iconColor,
  }) {
    if (isDone) {
      return AnimatedBuilder(
        animation: _checkAnim,
        builder: (_, __) => CustomPaint(
          size: const Size(28, 28),
          painter: _CheckPainter(
            progress: 1.0,
            color: iconColor,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (isActive) {
      switch (step.key) {
        case 'menunggu':
          return _BouncingDots(color: iconColor);
        case 'diproses':
          return AnimatedBuilder(
            animation: _spinAnim,
            builder: (_, __) => Transform.rotate(
              angle: _spinAnim.value,
              child: Icon(Icons.sync_rounded, color: iconColor, size: 26),
            ),
          );
        case 'diterima':
        case 'selesai':
          return AnimatedBuilder(
            animation: _checkAnim,
            builder: (_, __) => CustomPaint(
              size: const Size(28, 28),
              painter: _CheckPainter(
                progress: _checkAnim.value,
                color: iconColor,
                strokeWidth: step.key == 'selesai' ? 2.8 : 2.5,
              ),
            ),
          );
      }
    }

    return Icon(step.icon, color: iconColor, size: 24);
  }
}

class _StepData {
  final String key;
  final String label;
  final IconData icon;
  final String tooltip;
  const _StepData({
    required this.key,
    required this.label,
    required this.icon,
    required this.tooltip,
  });
}

class _ConnectorLine extends StatelessWidget {
  final bool filled;
  final double fillProgress;
  const _ConnectorLine({required this.filled, required this.fillProgress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(2),
      ),
      child: filled
          ? FractionallySizedBox(
              widthFactor: fillProgress,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1D9E75),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )
          : null,
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  const _CheckPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final startPoint = Offset(cx - 8, cy);
    final midPoint = Offset(cx - 2, cy + 6);
    final endPoint = Offset(cx + 9, cy - 7);

    final totalLen = _dist(startPoint, midPoint) + _dist(midPoint, endPoint);
    final seg1Len = _dist(startPoint, midPoint);
    final drawnLen = progress * totalLen;

    final path = Path();
    if (drawnLen <= seg1Len) {
      final t = drawnLen / seg1Len;
      path.moveTo(startPoint.dx, startPoint.dy);
      path.lineTo(
        startPoint.dx + (midPoint.dx - startPoint.dx) * t,
        startPoint.dy + (midPoint.dy - startPoint.dy) * t,
      );
    } else {
      final t = (drawnLen - seg1Len) / _dist(midPoint, endPoint);
      path.moveTo(startPoint.dx, startPoint.dy);
      path.lineTo(midPoint.dx, midPoint.dy);
      path.lineTo(
        midPoint.dx + (endPoint.dx - midPoint.dx) * t,
        midPoint.dy + (endPoint.dy - midPoint.dy) * t,
      );
    }
    canvas.drawPath(path, paint);
  }

  double _dist(Offset a, Offset b) =>
      math.sqrt(math.pow(b.dx - a.dx, 2) + math.pow(b.dy - a.dy, 2));

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.progress != progress || old.color != color;
}

class _BouncingDots extends StatefulWidget {
  final Color color;
  const _BouncingDots({required this.color});

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _anims = _controllers
        .map(
          (c) => Tween<double>(
            begin: 0,
            end: -8,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
        )
        .toList();
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (i) => AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _anims[i].value),
            child: Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// COMPLAINT DETAIL SCREEN  ← YANG DIMODIFIKASI
// ══════════════════════════════════════════════════════════════════════════════

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
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        setState(() => _detail = responseData['data']);
      } else {
        setState(
          () =>
              _errorMessage = responseData['message'] ?? 'Gagal memuat detail',
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _fixImageUrl(String url) {
    final baseUri = Uri.parse(ApiConfig.baseUrl);
    final baseHost = '${baseUri.scheme}://${baseUri.host}';

    return url
        .replaceFirst('http://localhost', baseHost)
        .replaceFirst('http://127.0.0.1', baseHost)
        .replaceFirst('http://10.0.2.2', baseHost);
  }

  String _formatTanggal(String? tanggal) {
    if (tanggal == null || tanggal.isEmpty) return '-';
    try {
      final dt = DateTime.parse(tanggal).toLocal();
      const bulan = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${dt.day} ${bulan[dt.month]} ${dt.year}, '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return tanggal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
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
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.kodePengaduan,
                      overflow: TextOverflow.ellipsis,
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
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryBlue))
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
                            onPressed: _fetchDetail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                            ),
                            child: const Text(
                              'Coba Lagi',
                              style: TextStyle(color: Colors.white),
                            ),
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
    final String tanggal = _formatTanggal(
      d['tanggal_pengaduan'] ?? d['created_at'],
    );

    final rawKategori = d['kategori'];
    final String kategori = rawKategori is String
        ? rawKategori
        : rawKategori is Map
        ? (rawKategori['nama_kategori'] ?? rawKategori['nama'] ?? '-')
              .toString()
        : '-';

    // Foto bukti laporan (dari customer saat membuat pengaduan)
    final rawFoto = d['foto_bukti'];
    final String? fotoBukti = (rawFoto != null && rawFoto.toString().isNotEmpty)
        ? _fixImageUrl(rawFoto.toString())
        : null;

    // ── BARU: Foto bukti penyelesaian dari teknisi ────────────────────────
    final rawFotoPenyelesaian = d['foto_penyelesaian'];
    final String? fotoPenyelesaian =
        (rawFotoPenyelesaian != null &&
            rawFotoPenyelesaian.toString().isNotEmpty)
        ? _fixImageUrl(rawFotoPenyelesaian.toString())
        : null;
    // ─────────────────────────────────────────────────────────────────────

    final String? responTeknisi = d['respon_teknisi'] ?? d['catatan'];

    final rawTeknisi = d['teknisi'];
    final String? namaTeknisi = rawTeknisi is Map
        ? (rawTeknisi['nama'] ?? rawTeknisi['nama_lengkap'])?.toString()
        : null;

    final bool sudahRating = d['rating'] != null;
    final bool bisaRating = status.toLowerCase() == 'selesai' && !sudahRating;

    final rawRating = d['rating'];
    final int? nilaiRating = rawRating is Map
        ? rawRating['rating'] as int?
        : null;
    final String? saranRating = rawRating is Map
        ? rawRating['saran']?.toString()
        : null;
    final String? balasanTeknisi = rawRating is Map
        ? rawRating['balasan_teknisi']?.toString()
        : null;

    return RefreshIndicator(
      onRefresh: _fetchDetail,
      color: primaryBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status Card ───────────────────────────────────
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kode,
                            style: TextStyle(
                              color: primaryBlue,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tanggal,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      _buildStatusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 16),
                  if (status.toLowerCase() != 'ditolak')
                    StatusStepper(status: status)
                  else
                    _buildDitolakBanner(),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Info Pengaduan ────────────────────────────────
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Informasi Pengaduan', Icons.info_outline),
                  const SizedBox(height: 12),
                  _buildRow('Kategori', kategori),
                  const Divider(height: 20, color: Color(0xFFEEEEEE)),
                  _buildLabelValue('Deskripsi Pengaduan', deskripsi),
                ],
              ),
            ),

            // ── Foto Bukti Laporan (dari customer) ───────────
            if (fotoBukti != null) ...[
              const SizedBox(height: 12),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Foto Bukti', Icons.photo_outlined),
                    const SizedBox(height: 12),
                    _buildNetworkImage(fotoBukti),
                  ],
                ),
              ),
            ],

            // ── BARU: Foto Bukti Penyelesaian (dari teknisi) ─
            if (fotoPenyelesaian != null) ...[
              const SizedBox(height: 12),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                      'Foto Bukti Penyelesaian',
                      Icons.task_alt_rounded,
                    ),
                    const SizedBox(height: 4),
                    // Keterangan singkat
                    Text(
                      'Foto ini dikirim oleh teknisi sebagai bukti pengaduan telah diselesaikan.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Inter',
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Badge "Terverifikasi"
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF1D9E75).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            size: 13,
                            color: Color(0xFF1D9E75),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Dikirim oleh Teknisi',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF0F6E56),
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildNetworkImage(fotoPenyelesaian),
                  ],
                ),
              ),
            ],

            // ── Teknisi ───────────────────────────────────────
            if (namaTeknisi != null) ...[
              const SizedBox(height: 12),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                      'Teknisi Penanganan',
                      Icons.engineering_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildRow('Ditangani oleh', namaTeknisi),
                  ],
                ),
              ),
            ],

            // ── Respon Teknisi ────────────────────────────────
            if (responTeknisi != null && responTeknisi.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                      'Respon Teknisi',
                      Icons.sticky_note_2_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildLabelValue('Catatan', responTeknisi),
                  ],
                ),
              ),
            ],

            // ── Rating sudah ada ──────────────────────────────
            if (sudahRating && nilaiRating != null) ...[
              const SizedBox(height: 12),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Penilaian Kamu', Icons.star_outline),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < nilaiRating ? Icons.star : Icons.star_border,
                          color: const Color(0xFFDDC000),
                          size: 24,
                        ),
                      ),
                    ),
                    if (saranRating != null && saranRating.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        saranRating,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF555555),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                    if (balasanTeknisi != null &&
                        balasanTeknisi.isNotEmpty) ...[
                      const Divider(height: 20, color: Color(0xFFEEEEEE)),
                      Row(
                        children: [
                          Icon(Icons.reply, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 6),
                          Text(
                            'Balasan Teknisi:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        balasanTeknisi,
                        style: TextStyle(
                          fontSize: 13,
                          color: primaryBlue,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // ── Tombol Beri Rating ────────────────────────────
            if (bisaRating) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDDC000),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RatingScreen(pengaduan: _detail!),
                      ),
                    );
                    if (result == true && mounted) _fetchDetail();
                  },
                  icon: const Icon(
                    Icons.star,
                    color: Color(0xFF1E2A5E),
                    size: 22,
                  ),
                  label: const Text(
                    'Beri Penilaian',
                    style: TextStyle(
                      color: Color(0xFF1E2A5E),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Shared image widget ──────────────────────────────────────────────────

  Widget _buildNetworkImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 180,
            color: Colors.grey[100],
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
        errorBuilder: (_, __, ___) => Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image, color: Colors.grey[400], size: 40),
                const SizedBox(height: 8),
                Text(
                  'Gagal memuat foto',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDitolakBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8D7DA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.cancel_outlined, color: Color(0xFF721C24), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pengaduan ini telah ditolak. Silakan hubungi layanan kami untuk informasi lebih lanjut.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF721C24),
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
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
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryBlue, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: primaryBlue,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: primaryBlue,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
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
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: primaryBlue,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
            height: 1.4,
          ),
        ),
      ],
    );
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
      case 'diterima':
        bgColor = const Color(0xFFE2D9F3);
        textColor = const Color(0xFF4A235A);
        label = 'Diterima';
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
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}
