// lib/customer/content/change_password_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isLoading = false;

  final Color primaryBlue = const Color(0xFF1E2A5E);

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await _authService.getToken();
      if (token == null) {
        _showSnackbar('Sesi habis, silakan login kembali', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'password_lama': _oldPassCtrl.text,
          'password_baru': _newPassCtrl.text,
          'password_baru_confirmation': _confirmPassCtrl.text,
        }),
      );

      debugPrint('🔐 Change Password - Status: ${response.statusCode}');
      debugPrint('🔐 Response: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        _showSnackbar(
          data['message'] ?? 'Password berhasil diubah',
          isError: false,
        );
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) Navigator.of(context).pop();
      } else {
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          final firstMsg = (errors.values.first as List).first.toString();
          _showSnackbar(firstMsg, isError: true);
        } else {
          _showSnackbar(
            data['message'] ?? 'Gagal mengubah password',
            isError: true,
          );
        }
      }
    } catch (e) {
      _showSnackbar('Terjadi kesalahan: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFD32F2F)
            : const Color(0xFF1D9E75),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Container(
              width: double.infinity,
              color: primaryBlue,
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'Kembali',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Text(
                    'UBAH PASSWORD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 90),
                ],
              ),
            ),

            // ── Content ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // ── Info Banner ──────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryBlue.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: primaryBlue.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primaryBlue.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock_reset_rounded,
                                color: primaryBlue,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Keamanan Akun',
                                    style: TextStyle(
                                      color: primaryBlue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Gunakan password yang kuat dengan kombinasi huruf besar, huruf kecil, angka, dan simbol.',
                                    style: TextStyle(
                                      color: primaryBlue.withValues(
                                        alpha: 0.75,
                                      ),
                                      fontSize: 12,
                                      fontFamily: 'Inter',
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Form Card ────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Password Saat Ini'),
                            const SizedBox(height: 8),
                            _buildPasswordField(
                              controller: _oldPassCtrl,
                              hint: 'Masukkan password saat ini',
                              show: _showOld,
                              onToggle: () =>
                                  setState(() => _showOld = !_showOld),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Password saat ini tidak boleh kosong';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            _buildLabel('Password Baru'),
                            const SizedBox(height: 8),
                            _buildPasswordField(
                              controller: _newPassCtrl,
                              hint: 'Masukkan password baru',
                              show: _showNew,
                              onToggle: () =>
                                  setState(() => _showNew = !_showNew),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Password baru tidak boleh kosong';
                                }
                                if (v.length < 8) {
                                  return 'Password minimal 8 karakter';
                                }
                                if (v == _oldPassCtrl.text) {
                                  return 'Password baru tidak boleh sama dengan password lama';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 8),
                            _PasswordStrengthBar(password: _newPassCtrl.text),

                            const SizedBox(height: 20),

                            _buildLabel('Konfirmasi Password Baru'),
                            const SizedBox(height: 8),
                            _buildPasswordField(
                              controller: _confirmPassCtrl,
                              hint: 'Ulangi password baru',
                              show: _showConfirm,
                              onToggle: () =>
                                  setState(() => _showConfirm = !_showConfirm),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Konfirmasi password tidak boleh kosong';
                                }
                                if (v != _newPassCtrl.text) {
                                  return 'Konfirmasi password tidak cocok';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Submit Button ────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            disabledBackgroundColor: primaryBlue.withValues(
                              alpha: 0.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.lock_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Simpan Password Baru',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Cancel Button ────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Batal',
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: primaryBlue,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool show,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      validator: validator,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 14, fontFamily: 'Inter'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 13,
          fontFamily: 'Inter',
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            show ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: Colors.grey[500],
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

// ── Password Strength Bar ─────────────────────────────────────────────────

class _PasswordStrengthBar extends StatelessWidget {
  final String password;
  const _PasswordStrengthBar({required this.password});

  int get _strength {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$&*~%^()_\-+=]').hasMatch(password)) score++;
    return score;
  }

  String get _label {
    switch (_strength) {
      case 1:
        return 'Lemah';
      case 2:
        return 'Cukup';
      case 3:
        return 'Kuat';
      case 4:
        return 'Sangat Kuat';
      default:
        return '';
    }
  }

  Color get _color {
    switch (_strength) {
      case 1:
        return const Color(0xFFD32F2F);
      case 2:
        return const Color(0xFFF57C00);
      case 3:
        return const Color(0xFF1976D2);
      case 4:
        return const Color(0xFF1D9E75);
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: i < _strength ? _color : Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          _label,
          style: TextStyle(
            fontSize: 11,
            color: _color,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
