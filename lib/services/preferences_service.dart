import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _ipKey = 'esp_ip';

  Future<void> saveIP(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ipKey, ip);
  }

  Future<String?> getIP() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ipKey);
  }
}
