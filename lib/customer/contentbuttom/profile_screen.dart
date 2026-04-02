import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/auth_service.dart';
import '../../../models/user.dart';
import '../../../config/api_config.dart';
import '../content/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Helper: pastikan foto_profil selalu jadi full URL
  String? _getFotoProfilUrl(String? fotoProfil) {
    if (fotoProfil == null || fotoProfil.isEmpty) return null;

    // Jika sudah full URL (http/https), langsung pakai
    if (fotoProfil.startsWith('http://') ||
        fotoProfil.startsWith('https://')) {
      return fotoProfil;
    }

    // Jika hanya path relatif, tambahkan base storage URL
    final baseStorage = ApiConfig.baseUrl
        .replaceFirst('/api', '/storage');
    return '$baseStorage/$fotoProfil';
  }

  Future<void> _loadProfile() async {
    if (mounted) setState(() => _isLoading = true);

    // Load dari local dulu
    final localUser = await _authService.getUser();
    if (mounted) {
      setState(() {
        _user = localUser;
      });
    }

    // Refresh dari API
    try {
      final token = await _authService.getToken();
      if (token == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.customerProfile),
        headers: ApiConfig.headers(token: token),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success' && mounted) {
          final freshUser = User.fromJson(body['data']);
          await _authService.saveUser(freshUser);
          setState(() {
            _user = freshUser;
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

  @override
  Widget build(BuildContext context) {
    final fotoUrl = _getFotoProfilUrl(_user?.fotoProfil);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        color: const Color(0xFF1E2A5E),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E2A5E),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: const Text(
                  'PROFIL USER',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),

              // ── Content ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  children: [
                    // Profile Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2A5E),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.only(bottom: 16, top: 24),
                      child: Column(
                        children: [
                          // Avatar
                          Container(
                            width: 120,
                            height: 120,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ClipOval(
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Color(0xFF1E2A5E),
                                    )
                                  : fotoUrl != null
                                      ? Image.network(
                                          fotoUrl,
                                          fit: BoxFit.cover,
                                          width: 120,
                                          height: 120,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Center(
                                              child:
                                                  CircularProgressIndicator(
                                                color:
                                                    const Color(0xFF1E2A5E),
                                                value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                          errorBuilder: (_, error, __) {
                                            debugPrint(
                                                'Gagal load foto: $fotoUrl — $error');
                                            return const Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Color(0xFF1E2A5E),
                                            );
                                          },
                                        )
                                      : const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Color(0xFF1E2A5E),
                                        ),
                            ),
                          ),

                          // Nama
                          Text(
                            _user?.nama ?? 'Nama Pengguna',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Email
                          Text(
                            _user?.email ?? 'Email pengguna',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.43,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Informasi Personal ─────────────────────────
                    _buildInfoCard(
                      title: 'Informasi personal',
                      rows: [
                        _InfoRow(Icons.person_outline, 'Nama',
                            _user?.nama ?? '-'),
                        _InfoRow(Icons.phone_outlined, 'Telepon',
                            _user?.telepon ?? '-'),
                      ],
                    ),

                    // ── Informasi Instansi ─────────────────────────
                    _buildInfoCard(
                      title: 'Informasi Instansi',
                      rows: [
                        _InfoRow(
                          Icons.business_outlined,
                          'Instansi',
                          _user?.instansi?.namaInstansi ?? '-',
                        ),
                      ],
                    ),

                    // ── Informasi Akun ─────────────────────────────
                    _buildInfoCard(
                      title: 'Informasi Akun',
                      rows: [
                        _InfoRow(Icons.email_outlined, 'Email',
                            _user?.email ?? '-'),
                        _InfoRow(
                          Icons.badge_outlined,
                          'Role',
                          _user?.role.name ?? '-',
                        ),
                        _InfoRow(
                          Icons.circle,
                          'Status',
                          _user?.status ?? '-',
                          valueColor: _user?.status == 'aktif'
                              ? const Color(0xFF328E6E)
                              : Colors.red,
                        ),
                      ],
                    ),

                    // ── Settings icon ──────────────────────────────
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2A5E),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<_InfoRow> rows,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12),
            ...rows.map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(row.icon,
                          size: 18, color: const Color(0xFF1E2A5E)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 72,
                        child: Text(
                          row.label,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ),
                      const Text(
                        ': ',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF888888)),
                      ),
                      Expanded(
                        child: Text(
                          row.value,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: row.valueColor ?? Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

// Helper class untuk baris info
class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow(this.icon, this.label, this.value, {this.valueColor});
}