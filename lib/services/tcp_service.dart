import 'dart:io';
import 'package:flutter/foundation.dart';
import 'preferences_service.dart';

class TcpService extends ChangeNotifier {
  Socket? socket;
  bool conectat = false;
  bool _connecting = false; // 🔒 Adăugat pentru a preveni reconectări paralele

  final int port = 6789;
  Function(String)? onDataReceived;
  final PreferencesService _prefsService = PreferencesService();

  Future<void> setIP(String ip) async {
    await _prefsService.setIP(ip);
    print("✅ IP salvat: $ip");
  }

  Future<bool> conecteazaESP() async {
    if (_connecting || conectat) return conectat;

    _connecting = true;
    final ip = await _prefsService.getIP();

    if (ip == null) {
      print("⚠️ IP-ul nu este setat.");
      _connecting = false;
      return false;
    }

    try {
      socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 10));
      conectat = true;
      notifyListeners();

      socket!.listen(
        (data) {
          final mesaj = String.fromCharCodes(data);
          print("📥 $mesaj");
          onDataReceived?.call(mesaj);
        },
        onError: (err) {
          print("❌ Eroare în socket: $err");
          _handleDisconnect();
        },
        onDone: () {
          print("🔌 Conexiune închisă de ESP.");
          _handleDisconnect();
        },
        cancelOnError: true,
      );

      _connecting = false;
      return true;
    } catch (e) {
      print("❌ Conectare eșuată: $e");
      conectat = false;
      _connecting = false;
      notifyListeners();
      return false;
    }
  }

  void _handleDisconnect() {
    socket?.destroy();
    socket = null;
    conectat = false;
    _connecting = false;
    notifyListeners();
  }

  void trimiteComanda(String comanda) {
    if (socket != null && conectat) {
      socket!.write('$comanda\n');
      print("➡️ Trimis: $comanda");
    } else {
      print("⚠️ Nu ești conectat la Controler.");
    }
  }

  void deconecteaza() {
    socket?.close();
    socket = null;
    conectat = false;
    _connecting = false;
    notifyListeners();
  }
}
