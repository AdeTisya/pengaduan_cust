import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class FonnteService {
  static final AuthService _authService = AuthService();

  static Future<bool> sendMessage({
    required String target,
    required String message,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse(ApiConfig.sendWhatsapp),
        headers: ApiConfig.headers(token: token),
        body: jsonEncode({'target': target, 'message': message}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['status'] == 'success';
    } catch (e) {
      debugPrint('WA error: $e');
      return false;
    }
  }
}
