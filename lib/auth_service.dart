import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String BASE_URL = "http://91.107.184.128:8080";

  Future<Map<String, dynamic>> sendOTP(String email) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send OTP: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> verifyOTP(String userId, String otp) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'otp': otp,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to verify OTP: ${response.statusCode}');
    }
  }
}