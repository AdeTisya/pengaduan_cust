// lib/services/whatsapp_debug.dart
// Debug service to test WhatsApp endpoints

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class WhatsAppDebug {
  static final AuthService _authService = AuthService();

  /// Test the WhatsApp endpoint and get detailed response
  static Future<Map<String, dynamic>> testWhatsAppEndpoint({
    required String target,
    required String message,
  }) async {
    try {
      debugPrint('🔍 [WhatsApp Debug] Starting test...');
      debugPrint('📱 Target: $target');
      debugPrint('📝 Message: $message');

      final token = await _authService.getToken();
      if (token == null) {
        debugPrint('❌ [WhatsApp Debug] No token available');
        return {'success': false, 'error': 'No token'};
      }

      debugPrint('🔐 Token retrieved: ${token.substring(0, 20)}...');

      final requestBody = {'target': target, 'message': message};

      debugPrint('📤 Sending to: ${ApiConfig.sendWhatsapp}');
      debugPrint('📦 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(ApiConfig.sendWhatsapp),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('📨 Response status: ${response.statusCode}');
      debugPrint('📨 Response body: ${response.body}');

      try {
        final data = jsonDecode(response.body);
        debugPrint('✅ [WhatsApp Debug] Parsed response: $data');
        return {
          'success': response.statusCode == 200 && data['status'] == 'success',
          'statusCode': response.statusCode,
          'data': data,
        };
      } catch (e) {
        debugPrint('❌ [WhatsApp Debug] Failed to parse response: $e');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'error': 'Failed to parse response: $e',
          'rawBody': response.body,
        };
      }
    } catch (e) {
      debugPrint('❌ [WhatsApp Debug] Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
