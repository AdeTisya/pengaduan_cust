// lib/config/api_config.dart

class ApiConfig {
  // GANTI dengan IP komputer Anda
  // Untuk emulator: http://10.0.2.2:8000/api
  // Untuk real device: http://192.168.1.XXX:8000/api
  static const String baseUrl = 'http://localhost:8000/api';

  // Auth endpoints
  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';
  static const String me = '$baseUrl/auth/me';
  static const String refresh = '$baseUrl/auth/refresh';

  // Customer endpoints
  static const String customerDashboard = '$baseUrl/customer/dashboard';
  static const String customerPengaduan = '$baseUrl/customer/pengaduan';
  static const String customerProfile = '$baseUrl/customer/profile';

  // Teknisi endpoints
  static const String teknisiDashboard = '$baseUrl/teknisi/dashboard';
  static const String teknisiPengaduan = '$baseUrl/teknisi/pengaduan';
  // lib/config/api_config.dart
  static String get sendWhatsapp => '$baseUrl/teknisi/notifikasi/whatsapp';
  static const String teknisiProfile = '$baseUrl/teknisi/profile';

  // Headers untuk JSON
  static Map<String, String> headers({String? token}) {
    final Map<String, String> header = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      header['Authorization'] = 'Bearer $token';
    }

    return header;
  }

  // Headers untuk multipart (upload file)
  static Map<String, String> multipartHeaders({String? token}) {
    final Map<String, String> header = {'Accept': 'application/json'};

    if (token != null) {
      header['Authorization'] = 'Bearer $token';
    }

    return header;
  }
}
