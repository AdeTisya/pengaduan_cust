// lib/services/auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Login method untuk JWT
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: ApiConfig.headers(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      debugPrint('LOGIN STATUS CODE: ${response.statusCode}');
      debugPrint('LOGIN RAW BODY: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        // Login berhasil
        final String token = responseData['data']['token'];
        final User user = User.fromJson(responseData['data']['user']);

        // Simpan token dan user data
        await saveToken(token);
        await saveUser(user);

        return {
          'success': true,
          'message': responseData['message'],
          'token': token,
          'user': user,
        };
      } else {
        // Login gagal — sertakan detail errors (jika ada) untuk debugging
        String message = responseData['message'] ?? 'Login gagal';

        if (responseData['errors'] != null) {
          final errors = responseData['errors'] as Map<String, dynamic>;
          final detailLines = errors.entries
              .map((e) => '${e.key}: ${(e.value as List).join(', ')}')
              .join('\n');
          message = '$message\n\n$detailLines';
        }

        return {'success': false, 'message': message};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Koneksi ke server gagal: ${e.toString()}',
      };
    }
  }

  // Logout method untuk JWT
  Future<bool> logout() async {
    try {
      final token = await getToken();

      if (token != null) {
        // Call logout API to blacklist token
        await http.post(
          Uri.parse(ApiConfig.logout),
          headers: ApiConfig.headers(token: token),
        );
      }

      // Clear local data
      await clearToken();
      await clearUser();

      return true;
    } catch (e) {
      // Even if API call fails, clear local data
      await clearToken();
      await clearUser();
      return true;
    }
  }

  // Get current user data
  Future<User?> getCurrentUser() async {
    try {
      final token = await getToken();

      if (token == null) return null;

      final response = await http.get(
        Uri.parse(ApiConfig.me),
        headers: ApiConfig.headers(token: token),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success') {
          final User user = User.fromJson(responseData['data']);

          // Update saved user data
          await saveUser(user);

          return user;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Refresh token (untuk JWT)
  Future<String?> refreshToken() async {
    try {
      final token = await getToken();

      if (token == null) return null;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/refresh'),
        headers: ApiConfig.headers(token: token),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success') {
          final String newToken = responseData['data']['token'];
          await saveToken(newToken);
          return newToken;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Save token to SharedPreferences
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Get token from SharedPreferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Clear token
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // Save user to SharedPreferences
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  // Get user from SharedPreferences
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString('user');

    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }

    return null;
  }

  // Clear user
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Check user role
  Future<String?> getUserRole() async {
    final user = await getUser();
    return user?.role.name;
  }

  // Handle token expiration (untuk auto refresh atau logout)
  Future<bool> handleTokenExpiration() async {
    // Try to refresh token
    final newToken = await refreshToken();

    if (newToken != null) {
      return true; // Token refreshed successfully
    } else {
      // Token cannot be refreshed, logout user
      await logout();
      return false;
    }
  }
}
