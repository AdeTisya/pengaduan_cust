import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class ChatbotService {
  Future<String> sendMessage(String message, List<ChatMessage> history) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final historyJson = history
        .map((h) => {'role': h.role, 'text': h.text})
        .toList();

    final response = await http.post(
      Uri.parse(ApiConfig.customerChatbot),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: jsonEncode({'message': message, 'history': historyJson}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['reply'];
    } else if (response.statusCode == 429) {
      throw Exception('Terlalu banyak permintaan, coba beberapa saat lagi.');
    } else {
      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');
      throw Exception('Gagal menghubungi asisten. Silakan coba lagi.');
    }
  }
}
