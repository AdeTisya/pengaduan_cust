import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/auth_service.dart';
import '../../../models/user.dart';
import '../content/change_pw.dart';

class ProfileTeknisi extends StatefulWidget {
  const ProfileTeknisi({super.key});

  @override
  State<ProfileTeknisi> createState() => _ProfileTeknisiState();
}

class _ProfileTeknisiState extends State<ProfileTeknisi>
    with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = true;

  LocationPermission _locationPermission = LocationPermission.denied;
  bool _locationServiceEnabled = false;
  bool _isCheckingLocation = false;
  bool _waitingForSettingsReturn = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkLocationStatus();
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
    if (state == AppLifecycleState.resumed && _waitingForSettingsReturn) {
      _waitingForSettingsReturn = false;
      _checkLocationStatus();
    }
  }

  Future<void> _loadUserData() async {
    final localUser = await _authService.getUser();
    if (mounted) {
      setState(() {
        _user = localUser;
        _isLoading = false;
      });
    }
    final freshUser = await _authService.getCurrentUser();
    if (mounted && freshUser != null) {
      setState(() => _user = freshUser);
    }
  }

  Future<void> _checkLocationStatus() async {
    if (!mounted) return;
    setState(() => _isCheckingLocation = true);

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();

    if (mounted) {
      setState(() {
        _locationServiceEnabled = serviceEnabled;
        _locationPermission = permission;
        _isCheckingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                child: Column(
                  children: [
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
                      child: ClipOval(child: _buildAvatar()),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isLoading ? 'Memuat...' : (_user?.nama ?? 'Nama Pengguna'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'Inclusive Sans',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isLoading ? '' : (_user?.email ?? 'Email pengguna'),
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

              _buildInfoCard(
                title: 'Informasi personal',
                children: [
                  _buildInfoRow(Icons.person_outline, 'Nama', _user?.nama ?? '-'),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.phone_outlined, 'Telepon', _user?.telepon ?? '-'),
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
                    valueColor: (_user?.status == 'aktif')
                        ? const Color(0xFF328E6E)
                        : Colors.red,
                  ),
                  const SizedBox(height: 10),
                ],
              ),

              const SizedBox(height: 20),

              _buildInfoCard(
                title: 'Informasi Akun',
                children: [
                  _buildInfoRow(Icons.email_outlined, 'Email', _user?.email ?? '-'),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.badge_outlined, 'Role', _user?.role.name ?? '-'),
                  const SizedBox(height: 10),
                ],
              ),

              const SizedBox(height: 24),

              GestureDetector(
                onTap: _showSettingsMenu,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2A5E),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(Icons.settings, size: 44, color: Colors.white),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true, // ← PENTING: biar bisa scroll jika overflow
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _SettingsBottomSheet(
        onEditProfile: () {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Edit profil - segera hadir'),
              backgroundColor: Colors.blue,
            ),
          );
        },
        onChangePassword: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
          );
        },
        onLocationPermission: () {
          Navigator.pop(ctx);
          _showLocationPermissionScreen();
        },
        locationPermission: _locationPermission,
        locationServiceEnabled: _locationServiceEnabled,
        isCheckingLocation: _isCheckingLocation,
      ),
    );
  }

  void _showLocationPermissionScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _LocationPermissionScreen(
          locationPermission: _locationPermission,
          locationServiceEnabled: _locationServiceEnabled,
          onPermissionChanged: () {
            _checkLocationStatus();
          },
          onOpenAppSettings: () async {
            _waitingForSettingsReturn = true;
            await Geolocator.openAppSettings();
          },
          onOpenLocationSettings: () async {
            _waitingForSettingsReturn = true;
            await Geolocator.openLocationSettings();
          },
          onRequestPermission: () async {
            final perm = await Geolocator.requestPermission();
            if (mounted) {
              setState(() => _locationPermission = perm);
            }
            await _checkLocationStatus();
            return perm;
          },
        ),
      ),
    ).then((_) {
      _checkLocationStatus();
    });
  }

  Widget _buildAvatar() {
    if (_isLoading) {
      return const CircularProgressIndicator(color: Color(0xFF1E2A5E));
    }
    final foto = _user?.fotoProfil;
    if (foto != null && foto.isNotEmpty) {
      return Image.network(
        foto,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.person, size: 60, color: Color(0xFF1E2A5E)),
      );
    }
    return const Icon(Icons.person, size: 60, color: Color(0xFF1E2A5E));
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontFamily: 'Germania One',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
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
          style: TextStyle(fontSize: 14, color: Color(0xFF464646)),
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

// ════════════════════════════════════════════════════════════════════════════
// SETTINGS BOTTOM SHEET WIDGET
// ════════════════════════════════════════════════════════════════════════════

class _SettingsBottomSheet extends StatelessWidget {
  final VoidCallback onEditProfile;
  final VoidCallback onChangePassword;
  final VoidCallback onLocationPermission;
  final LocationPermission locationPermission;
  final bool locationServiceEnabled;
  final bool isCheckingLocation;

  const _SettingsBottomSheet({
    required this.onEditProfile,
    required this.onChangePassword,
    required this.onLocationPermission,
    required this.locationPermission,
    required this.locationServiceEnabled,
    required this.isCheckingLocation,
  });

  _LocationBadge get _badge {
    if (isCheckingLocation) {
      return _LocationBadge(
        label: 'Memeriksa...',
        color: Colors.grey,
        bgColor: Colors.grey.shade100,
        icon: Icons.hourglass_empty_rounded,
      );
    }
    if (!locationServiceEnabled) {
      return _LocationBadge(
        label: 'GPS Mati',
        color: const Color(0xFF856404),
        bgColor: const Color(0xFFFFF3CD),
        icon: Icons.location_disabled_rounded,
      );
    }
    switch (locationPermission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return _LocationBadge(
          label: 'Diizinkan',
          color: const Color(0xFF155724),
          bgColor: const Color(0xFFD4EDDA),
          icon: Icons.check_circle_outline_rounded,
        );
      case LocationPermission.deniedForever:
        return _LocationBadge(
          label: 'Diblokir',
          color: const Color(0xFF721C24),
          bgColor: const Color(0xFFF8D7DA),
          icon: Icons.block_rounded,
        );
      case LocationPermission.denied:
      default:
        return _LocationBadge(
          label: 'Ditolak',
          color: const Color(0xFF856404),
          bgColor: const Color(0xFFFFF3CD),
          icon: Icons.location_off_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;

    // ✅ FIX OVERFLOW: wrap dengan DraggableScrollableSheet / SingleChildScrollView
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

            const Text(
              'Pengaturan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E2A5E),
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 24),

            // Edit Profile
            _SettingsOption(
              icon: Icons.manage_accounts_outlined,
              title: 'Ubah Informasi Profil',
              subtitle: 'Perbarui data pribadi Anda',
              onTap: onEditProfile,
            ),

            const SizedBox(height: 12),

            // Change Password
            _SettingsOption(
              icon: Icons.lock_outline,
              title: 'Ganti Password',
              subtitle: 'Ubah kata sandi akun Anda',
              onTap: onChangePassword,
            ),

            const SizedBox(height: 12),

            // Izin Lokasi
            GestureDetector(
              onTap: onLocationPermission,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFF1E2A5E),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Izin Lokasi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E2A5E),
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Kelola izin akses lokasi aplikasi',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badge.bgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badge.icon, color: badge.color, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            badge.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: badge.color,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Tutup',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// LOCATION PERMISSION SCREEN
// ════════════════════════════════════════════════════════════════════════════

class _LocationPermissionScreen extends StatefulWidget {
  final LocationPermission locationPermission;
  final bool locationServiceEnabled;
  final VoidCallback onPermissionChanged;
  final Future<void> Function() onOpenAppSettings;
  final Future<void> Function() onOpenLocationSettings;
  final Future<LocationPermission> Function() onRequestPermission;

  const _LocationPermissionScreen({
    required this.locationPermission,
    required this.locationServiceEnabled,
    required this.onPermissionChanged,
    required this.onOpenAppSettings,
    required this.onOpenLocationSettings,
    required this.onRequestPermission,
  });

  @override
  State<_LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<_LocationPermissionScreen>
    with WidgetsBindingObserver {
  final Color primaryBlue = const Color(0xFF1E2A5E);

  late LocationPermission _permission;
  late bool _serviceEnabled;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _permission = widget.locationPermission;
    _serviceEnabled = widget.locationServiceEnabled;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();

    if (mounted) {
      setState(() {
        _serviceEnabled = serviceEnabled;
        _permission = permission;
        _isLoading = false;
      });
      widget.onPermissionChanged();
    }
  }

  _PermissionState get _permissionState {
    if (!_serviceEnabled) return _PermissionState.serviceOff;
    switch (_permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return _PermissionState.granted;
      case LocationPermission.deniedForever:
        return _PermissionState.blockedPermanent;
      case LocationPermission.denied:
      default:
        return _PermissionState.denied;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Izin Lokasi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E2A5E)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildStatusCard(),
                  const SizedBox(height: 24),
                  _buildActionSection(),
                  const SizedBox(height: 24),
                  _buildUsageInfoCard(),
                  const SizedBox(height: 24),
                  if (_permissionState == _PermissionState.blockedPermanent)
                    _buildManualStepsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final config = _getStatusConfig();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: config.bgColor,
              shape: BoxShape.circle,
              border: Border.all(color: config.borderColor, width: 1.5),
            ),
            child: Icon(config.icon, color: config.color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Izin Lokasi',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  config.statusLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: config.color,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  config.statusDesc,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Inter',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    final state = _permissionState;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                child: Icon(Icons.tune_rounded, color: primaryBlue, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Kelola Izin',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: primaryBlue,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (state == _PermissionState.granted) ...[
            _buildSuccessInfo(),
            const SizedBox(height: 16),
            _buildActionButton(
              label: 'Kelola di Pengaturan Aplikasi',
              icon: Icons.settings_outlined,
              color: primaryBlue,
              onTap: () async => await widget.onOpenAppSettings(),
              isOutlined: true,
            ),
          ] else if (state == _PermissionState.serviceOff) ...[
            _buildInfoText(
              'GPS perangkat Anda sedang tidak aktif. Aktifkan layanan lokasi '
              'di pengaturan perangkat agar navigasi dapat bekerja.',
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              label: 'Aktifkan Layanan Lokasi',
              icon: Icons.gps_fixed_rounded,
              color: primaryBlue,
              onTap: () async => await widget.onOpenLocationSettings(),
            ),
          ] else if (state == _PermissionState.denied) ...[
            _buildInfoText(
              'Aplikasi belum mendapatkan izin akses lokasi. '
              'Izin lokasi diperlukan untuk fitur navigasi ke lokasi pengaduan.',
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              label: 'Izinkan Akses Lokasi',
              icon: Icons.location_on_outlined,
              color: primaryBlue,
              onTap: () async {
                setState(() => _isLoading = true);
                final perm = await widget.onRequestPermission();
                if (mounted) {
                  setState(() {
                    _permission = perm;
                    _isLoading = false;
                  });
                }
              },
            ),
          ] else if (state == _PermissionState.blockedPermanent) ...[
            _buildInfoText(
              'Izin lokasi telah diblokir secara permanen. '
              'Anda perlu mengaktifkannya secara manual melalui pengaturan aplikasi.',
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              label: 'Buka Pengaturan Aplikasi',
              icon: Icons.app_settings_alt_outlined,
              color: const Color(0xFF721C24),
              onTap: () async => await widget.onOpenAppSettings(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD4EDDA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF28A745).withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF155724), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Izin lokasi sudah aktif. Fitur navigasi siap digunakan.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF155724),
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey[600],
        fontFamily: 'Inter',
        height: 1.6,
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: isOutlined
          ? OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: color.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onTap,
              icon: Icon(icon, color: color, size: 18),
              label: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontFamily: 'Inter',
                ),
              ),
            )
          : ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: onTap,
              icon: Icon(icon, color: Colors.white, size: 18),
              label: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'Inter',
                ),
              ),
            ),
    );
  }

  Widget _buildUsageInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                child: Icon(Icons.info_outline, color: primaryBlue, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Mengapa Lokasi Diperlukan?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: primaryBlue,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildUsageItem(
            Icons.navigation_outlined,
            'Navigasi ke Lokasi Pengaduan',
            'Menampilkan rute dari posisi Anda ke lokasi pengaduan secara real-time.',
          ),
          const SizedBox(height: 12),
          _buildUsageItem(
            Icons.location_searching_rounded,
            'Akurasi Rute',
            'Memberikan arah yang tepat dan efisien saat menuju lokasi perbaikan.',
          ),
          const SizedBox(height: 12),
          _buildUsageItem(
            Icons.privacy_tip_outlined,
            'Privasi Terjaga',
            'Lokasi hanya digunakan saat fitur navigasi aktif, tidak disimpan di server.',
          ),
        ],
      ),
    );
  }

  Widget _buildUsageItem(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryBlue, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primaryBlue,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'Inter',
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManualStepsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8D7DA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF721C24).withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.help_outline_rounded, color: Color(0xFF721C24), size: 18),
              SizedBox(width: 8),
              Text(
                'Cara Mengaktifkan Secara Manual',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF721C24),
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildStep('1', 'Buka Pengaturan perangkat Anda'),
          _buildStep('2', 'Pilih menu Aplikasi atau Manajer Aplikasi'),
          _buildStep('3', 'Cari dan pilih "Kominfo Pengaduan"'),
          _buildStep('4', 'Pilih menu Izin'),
          _buildStep('5', 'Pilih Lokasi → Izinkan'),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF721C24),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4A0E14),
                  fontFamily: 'Inter',
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig() {
    switch (_permissionState) {
      case _PermissionState.granted:
        return _StatusConfig(
          icon: Icons.location_on_rounded,
          color: const Color(0xFF155724),
          bgColor: const Color(0xFFD4EDDA),
          borderColor: const Color(0xFF28A745),
          statusLabel: 'Diizinkan',
          statusDesc: 'Akses lokasi aktif dan siap digunakan.',
        );
      case _PermissionState.serviceOff:
        return _StatusConfig(
          icon: Icons.location_disabled_rounded,
          color: const Color(0xFF856404),
          bgColor: const Color(0xFFFFF3CD),
          borderColor: const Color(0xFFFFD700),
          statusLabel: 'GPS Mati',
          statusDesc: 'Layanan lokasi perangkat tidak aktif.',
        );
      case _PermissionState.denied:
        return _StatusConfig(
          icon: Icons.location_off_rounded,
          color: const Color(0xFF856404),
          bgColor: const Color(0xFFFFF3CD),
          borderColor: const Color(0xFFFFD700),
          statusLabel: 'Belum Diizinkan',
          statusDesc: 'Aplikasi belum mendapatkan izin akses lokasi.',
        );
      case _PermissionState.blockedPermanent:
        return _StatusConfig(
          icon: Icons.block_rounded,
          color: const Color(0xFF721C24),
          bgColor: const Color(0xFFF8D7DA),
          borderColor: const Color(0xFFF5C6CB),
          statusLabel: 'Diblokir',
          statusDesc: 'Izin lokasi diblokir secara permanen.',
        );
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SHARED SMALL WIDGETS & DATA CLASSES
// ════════════════════════════════════════════════════════════════════════════

class _SettingsOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1E2A5E), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E2A5E),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}

enum _PermissionState { granted, serviceOff, denied, blockedPermanent }

class _StatusConfig {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final String statusLabel;
  final String statusDesc;

  const _StatusConfig({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.statusLabel,
    required this.statusDesc,
  });
}

class _LocationBadge {
  final String label;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _LocationBadge({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.icon,
  });
}