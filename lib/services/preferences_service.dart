import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _ipKey = 'esp_ip';
  static const String _flowKey = 'flow_rate';
  static const String _autoModeKey = 'auto_mode';
  static const String _tempLateralKey = 'temp_lateral';
  static const String _tempVentKey = 'temp_vent';
  static const String _autoKey = 'mod_automat';
  static const String _releeKey = 'relee_states';
  
  Future<void> saveReleeStates(List<bool> states) async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = states.map((e) => e ? '1' : '0').toList();
    await prefs.setStringList(_releeKey, stringList);
  }

  Future<List<bool>> getReleeStates() async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = prefs.getStringList(_releeKey);
    if (stringList == null) return [false, false, false, false];
    return stringList.map((e) => e == '1').toList();
  }

  Future<void> setAutoMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoKey, value);
  }

  
  Future<void> saveIP(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ipKey, ip);
  }

  Future<String?> getIP() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ipKey);
  }

  Future<void> saveFlowRate(double flowRate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_flowKey, flowRate);
  }

  Future<double> getFlowRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_flowKey) ?? 5.0; // valoare implicită
  }

  Future<void> saveAutoMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoModeKey, enabled);
  }

  Future<bool> getAutoMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoModeKey) ?? false;
  }

  Future<void> saveTempLateral(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_tempLateralKey, value);
  }

  Future<double> getTempLateral() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_tempLateralKey) ?? 24.0;
  }

  Future<void> saveTempVent(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_tempVentKey, value);
  }

  Future<double> getTempVent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_tempVentKey) ?? 34.0;
  }

  Future<void> setIP(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ipKey, ip);
  }
}
