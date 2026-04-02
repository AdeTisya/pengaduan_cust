// lib/services/complaint_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../services/auth_service.dart';

class ComplaintService {
  static final ComplaintService _instance = ComplaintService._internal();
  factory ComplaintService() => _instance;
  ComplaintService._internal();

  final AuthService _authService = AuthService();

  /// Membuat pengaduan baru dengan multipart/form-data
  /// Menggunakan Uint8List agar kompatibel di Android, iOS, maupun Web
  Future<Map<String, dynamic>> createPengaduan({
    required int kategoriId,
    required String deskripsi,
    Uint8List? fotoBukti,   // bytes dari gambar
    String? fileName,       // nama file, misal: "foto.jpg"
  }) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Sesi habis, silakan login kembali',
        };
      }

      // Buat multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.customerPengaduan),
      );

      // Tambahkan headers Authorization
      request.headers.addAll(ApiConfig.multipartHeaders(token: token));

      // Tambahkan field form-data
      request.fields['kategori_id'] = kategoriId.toString();
      request.fields['deskripsi'] = deskripsi;

      // Tambahkan foto jika ada — pakai fromBytes agar work di semua platform
      if (fotoBukti != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'foto_bukti',
            fotoBukti,
            filename: fileName ?? 'foto_bukti.jpg',
          ),
        );
      }

      // Kirim request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      // Konversi response
      final response = await http.Response.fromStream(streamedResponse);
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['status'] == 'success') {
        return {
          'success': true,
          'message': responseData['message'],
          'data': responseData['data'],
        };
      } else {
        // Handle validation errors (422)
        if (response.statusCode == 422 && responseData['errors'] != null) {
          final errors = responseData['errors'] as Map<String, dynamic>;
          final firstError = errors.values.first;
          final errorMessage = firstError is List
              ? firstError.first.toString()
              : firstError.toString();
          return {
            'success': false,
            'message': errorMessage,
          };
        }

        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal membuat pengaduan',
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'Tidak ada koneksi internet',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Ambil daftar kategori pengaduan dari API
  Future<Map<String, dynamic>> getKategori() async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Sesi habis, silakan login kembali',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/kategori'),
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal memuat kategori',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }
}