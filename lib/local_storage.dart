import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveUserLogin(String userId, String email) async {
    await _prefs.setString('user_id', userId);
    await _prefs.setString('user_email', email);
    await _prefs.setBool('is_logged_in', true);
  }

  static Future<bool> isUserLoggedIn() async {
    return _prefs.getBool('is_logged_in') ?? false;
  }

  static String getUserId() {
    return _prefs.getString('user_id') ?? '';
  }

  static String getUserEmail() {
    return _prefs.getString('user_email') ?? '';
  }

  static Future<void> logout() async {
    await _prefs.remove('user_id');
    await _prefs.remove('user_email');
    await _prefs.setBool('is_logged_in', false);
  }
}