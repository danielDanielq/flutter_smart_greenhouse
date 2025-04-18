import 'dart:io';
import 'package:flutter/foundation.dart'; // 👈 importă asta
import 'preferences_service.dart';

class TcpService extends ChangeNotifier {
  Socket? socket;
  bool conectat = false;
  final int port = 6789;

  Future<bool> conecteazaESP() async {
    final prefs = PreferencesService();
    final ip = await prefs.getIP();

    if (ip == null) {
      print("⚠️ IP-ul nu este setat.");
      return false;
    }

    try {
      socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
      conectat = true;
      notifyListeners(); // 👈 Notifică UI-ul

      socket!.listen(
        (data) {
          print("📥 ${String.fromCharCodes(data)}");
        },
        onError: (err) {
          print("❌ Eroare: $err");
          _handleDisconnect();
        },
        onDone: () {
          print("🔌 Conexiune închisă.");
          _handleDisconnect();
        },
      );
      return true;
    } catch (e) {
      print("❌ Conectare eșuată: $e");
      conectat = false;
      notifyListeners(); // 👈 actualizare
      return false;
    }
  }

  void _handleDisconnect() {
    socket?.destroy();
    conectat = false;
    notifyListeners(); // 👈 actualizare UI când pică
  }

  void trimiteComanda(String comanda) {
    if (socket != null && conectat) {
      socket!.write('$comanda\n');
      print("➡️ Trimis: $comanda");
    } else {
      print("⚠️ Nu ești conectat la ESP.");
    }
  }

  void deconecteaza() {
    socket?.close();
    conectat = false;
    notifyListeners(); // 👈
  }
}
