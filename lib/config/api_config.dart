// lib/config/api_config.dart

class ApiConfig {
   static const String baseUrl = 'http://sigapnetgk.web.id/api';

  // Auth endpoints
  static const String login = '$baseUrl/auth/mobile/login';
  static const String logout = '$baseUrl/auth/logout';
  static const String me = '$baseUrl/auth/me';
  static const String refresh = '$baseUrl/auth/refresh';

  // Customer endpoints
  static const String customerDashboard = '$baseUrl/customer/dashboard';
  static const String customerPengaduan = '$baseUrl/customer/pengaduan';
  static const String customerProfile = '$baseUrl/customer/profile';
  static const String customerChatbot = '$baseUrl/customer/chatbot';

  // Teknisi endpoints
  static const String teknisiDashboard = '$baseUrl/teknisi/dashboard';
  static const String teknisiPengaduan = '$baseUrl/teknisi/pengaduan';
  static const String sendWhatsapp = '$baseUrl/teknisi/notifikasi/whatsapp';
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
