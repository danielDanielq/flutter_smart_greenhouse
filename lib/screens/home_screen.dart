import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tcp_service.dart';
import '../services/preferences_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TcpService tcpService;
  List<bool> relee = [false, false, false, false];
  Timer? _reconnectTimer;
  Timer? _dataRequestTimer;
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _tempLateralController = TextEditingController();
  final TextEditingController _tempVentController = TextEditingController();
  final TextEditingController _debitController = TextEditingController();
  bool _autoMode = false;
  bool modAutomatActiv = false;

  double temp1 = 0, temp2 = 0, shtTemp = 0, humidity = 0, soilMoisture = 0, flowRate = 0;

  final List<String> denumiri = [
    "Irigare",
    "Lateral Stânga",
    "Lateral Dreapta",
    "Ventilatoare"
  ];

  final List<IconData> iconite = [
    Icons.water_drop,
    Icons.open_in_full,
    Icons.open_in_full,
    Icons.air
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      tcpService = Provider.of<TcpService>(context, listen: false);

      // Ascultăm modificările TcpService
      tcpService.addListener(() {
        if (!tcpService.conectat) {
          // Dacă s-a deconectat, resetăm starea releelor
          if (mounted) {
            setState(() {
              for (int i = 0; i < relee.length; i++) {
                relee[i] = false;
              }
            });
          }
        }
      });

      final prefs = PreferencesService();
      _ipController.text = await prefs.getIP() ?? '';
      _tempLateralController.text = (await prefs.getTempLateral()).toStringAsFixed(1);
      _tempVentController.text = (await prefs.getTempVent()).toStringAsFixed(1);
      _autoMode = await prefs.getAutoMode();

      tcpService.onDataReceived = _proceseazaDate;

      final conectat = await tcpService.conecteazaESP();
      if (!conectat) return;

      _dataRequestTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (tcpService.conectat) {
          tcpService.trimiteComanda("SEND DATA");
        }
      });

      _reconnectTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
        if (!tcpService.conectat) {
          final ok = await tcpService.conecteazaESP();
          if (ok) {
            print("✅ Reconectare reușită");
          }
        }
      });

      _loadModAutomat();
    });
  }



  Future<void> _salveazaSetariAuto() async {
    final prefs = PreferencesService();
    await prefs.saveTempLateral(double.tryParse(_tempLateralController.text) ?? 24.0);
    await prefs.saveTempVent(double.tryParse(_tempVentController.text) ?? 34.0);
    await prefs.saveAutoMode(_autoMode);

    if (!tcpService.conectat) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Nu ești conectat la ESP")),
      );
      return;
    }

    tcpService.trimiteComanda("AUTO:${_autoMode ? 1 : 0}");
    if (_autoMode) {
      tcpService.trimiteComanda("TEMP_LATERALE:${_tempLateralController.text}");
      tcpService.trimiteComanda("TEMP_VENTIL:${_tempVentController.text}");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✔️ Setări trimise și salvate")),
    );
  }

  Future<void> _loadModAutomat() async {
    final prefs = PreferencesService();
    final val = await prefs.getAutoMode();
    setState(() {
      modAutomatActiv = val;
    });
  }

  void _proceseazaDate(String mesaj) {
    print("📬 Procesare mesaj în HomeScreen: $mesaj");
    final linii = mesaj.trim().split('\n');

    for (final linie in linii) {
      final values = linie.trim().split(',');

      if (values.length != 6) continue;

      final t1 = double.tryParse(values[0]);
      final t2 = double.tryParse(values[1]);
      final t3 = double.tryParse(values[2]);
      final hum = double.tryParse(values[3]);
      final flow = double.tryParse(values[4]);
      final soil = double.tryParse(values[5]);

      if ([t1, t2, t3, hum, flow, soil].contains(null)) {
        print("❌ Parsare eșuată: $values");
        continue;
      }

      setState(() {
        temp1 = t1!;
        temp2 = t2!;
        shtTemp = t3!;
        humidity = hum!;
        flowRate = flow!;
        soilMoisture = soil!;
      });

      print("✅ Valori actualizate: $t1, $t2, $t3, $hum, $flow, $soil");
      return;
    }
  }

  void toggleReleu(int index) async {
    if (!tcpService.conectat) {
      final ok = await tcpService.conecteazaESP();
      if (!ok) return;
    }

    if (index == 0 && !relee[0]) {
      final text = _debitController.text.trim();
      if (text.isEmpty || double.tryParse(text) == null || double.parse(text) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Introdu un debit valid pentru irigare!")),
        );
        return;
      }
    }

    setState(() => relee[index] = !relee[index]);
    final comanda = (index == 0 && relee[0])
        ? "ON1:${_debitController.text.trim()}"
        : relee[index] ? "ON${index + 1}" : "OFF${index + 1}";

    tcpService.trimiteComanda(comanda);
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _dataRequestTimer?.cancel();
    _debitController.dispose();
    _ipController.dispose();
    _tempLateralController.dispose();
    _tempVentController.dispose();
    tcpService.deconecteaza();
    super.dispose();
  }

  Widget buildSensorCard(String label, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(label),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔌 Conexiune
            Consumer<TcpService>(
              builder: (context, tcp, child) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(tcp.conectat ? Icons.check_circle : Icons.error,
                      color: tcp.conectat ? Colors.green : Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    tcp.conectat ? "Conectat la Controler" : "Neconectat",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: tcp.conectat ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🌐 IP ESP
            TextField(
              controller: _ipController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '🌐 Introdu IP-ul ESP',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: () async {
                final ip = _ipController.text.trim();
                if (ip.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("⚠️ Introdu un IP valid!")),
                  );
                  return;
                }

                final prefs = PreferencesService();
                await prefs.saveIP(ip);
                tcpService.setIP(ip);
                final conectat = await tcpService.conecteazaESP();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(conectat ? "✔️ IP salvat și conectat!" : "❌ Nu s-a putut conecta."),
                  ),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text("Salvează și Conectează"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 20),

            // 🔁 Mod automat
            const Text("Mod Automat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SwitchListTile(
              title: const Text("Activează controlul automat"),
              value: _autoMode,
              onChanged: (val) {
                setState(() {
                  _autoMode = val;
                });
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _tempLateralController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Temperatură deschidere laterale (°C)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _tempVentController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Temperatură pornire ventilatoare (°C)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _salveazaSetariAuto,
              icon: const Icon(Icons.save),
              label: const Text("Trimite și salvează setările"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 30),

            // 🔧 Control relee
            const Text("Control Relee", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: TextField(
                controller: _debitController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Debit pentru irigare (L)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            ...List.generate(4, (index) {
              final activ = relee[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ElevatedButton.icon(
                  onPressed: () => toggleReleu(index),
                  icon: Icon(iconite[index]),
                  label: Text(
                    activ ? "Oprește ${denumiri[index]}" : "Pornește ${denumiri[index]}",
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activ ? Colors.green : Colors.grey[800],
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              );
            }),

            const SizedBox(height: 30),

            const Text("Date Senzori", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            buildSensorCard("Temperatura DS18B20 - Față", "${temp1.toStringAsFixed(1)}°C", Icons.thermostat, Colors.orange),
            buildSensorCard("Temperatura DS18B20 - Spate", "${temp2.toStringAsFixed(1)}°C", Icons.thermostat, Colors.orange),
            buildSensorCard("Temperatura SHT31 - Mijloc", "${shtTemp.toStringAsFixed(1)}°C", Icons.device_thermostat, Colors.redAccent),
            buildSensorCard("Umiditate Aer", "${humidity.toStringAsFixed(1)}%", Icons.water_drop_outlined, Colors.blue),
            buildSensorCard("Umiditate Sol", "${soilMoisture.toStringAsFixed(0)}%", Icons.grass, Colors.brown),
            buildSensorCard("Debit Irigare", "${flowRate.toStringAsFixed(1)} L/min", Icons.water, Colors.cyan),
          ],
        ),
      ),
    );
  }
}
