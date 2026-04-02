import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../models/user.dart';

class ProfileTeknisi extends StatefulWidget {
  const ProfileTeknisi({super.key});

  @override
  State<ProfileTeknisi> createState() => _ProfileTeknisiState();
}

class _ProfileTeknisiState extends State<ProfileTeknisi> {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Coba ambil dari local storage dulu (cepat)
    final localUser = await _authService.getUser();
    if (mounted) {
      setState(() {
        _user = localUser;
        _isLoading = false;
      });
    }

    // Lalu refresh dari API
    final freshUser = await _authService.getCurrentUser();
    if (mounted && freshUser != null) {
      setState(() {
        _user = freshUser;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E2A5E),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(50),
                          bottomRight: Radius.circular(50),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: const Center(
                        child: Text(
                          'PROFIL USER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontFamily: 'Gidugu',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // User profile card
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2A5E),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 28,
                        horizontal: 24,
                      ),
                      child: Column(
                        children: [
                          // Avatar - foto profil dari API
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  offset: const Offset(0, 4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Color(0xFF1E2A5E),
                                    )
                                  : (_user?.fotoProfil != null &&
                                          _user!.fotoProfil!.isNotEmpty)
                                      ? Image.network(
                                          _user!.fotoProfil!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Color(0xFF1E2A5E),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Color(0xFF1E2A5E),
                                        ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Nama dari API
                          Text(
                            _isLoading
                                ? 'Memuat...'
                                : (_user?.nama ?? 'Nama Pengguna'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontFamily: 'Inclusive Sans',
                              fontWeight: FontWeight.w400,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Email dari API
                          Text(
                            _isLoading
                                ? ''
                                : (_user?.email ?? 'Email pengguna'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: 'Inclusive Sans',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Personal information card
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi personal',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontFamily: 'Germania One',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(Icons.person_outline, 'Nama',
                              _user?.nama ?? '-'),
                          const SizedBox(height: 10),
                          _buildInfoRow(Icons.phone_outlined, 'Telepon',
                              _user?.telepon ?? '-'),
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            Icons.business_outlined,
                            'Instansi',
                            _user?.instansi?.namaInstansi ?? '-',
                          ),
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            Icons.circle,
                            'Status',
                            _user?.status ?? '-',
                            valueColor: _user?.status == 'aktif'
                                ? const Color(0xFF328E6E)
                                : Colors.red,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Account information card
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Akun',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontFamily: 'Germania One',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                              Icons.email_outlined, 'Email', _user?.email ?? '-'),
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            Icons.badge_outlined,
                            'Role',
                            _user?.role.name ?? '-',
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Settings icon
                    const Icon(
                      Icons.settings,
                      size: 44,
                      color: Colors.black87,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1E2A5E)),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF464646),
              fontFamily: 'GFS Neohellenic',
            ),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF464646),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black,
              fontFamily: 'GFS Neohellenic',
            ),
          ),
        ),
      ],
    );
  }
}