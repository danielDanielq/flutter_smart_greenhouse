import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../services/tcp_service.dart';

class IPSetupPage extends StatefulWidget {
  const IPSetupPage({super.key});

  @override
  State<IPSetupPage> createState() => _IPSetupPageState();
}

class _IPSetupPageState extends State<IPSetupPage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _flowController = TextEditingController();
  final TextEditingController _tempLateralController = TextEditingController();
  final TextEditingController _tempVentController = TextEditingController();
  final PreferencesService _prefs = PreferencesService();

  bool _autoMode = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _ipController.text = await _prefs.getIP() ?? '';
    _flowController.text = (await _prefs.getFlowRate()).toStringAsFixed(1);
    _tempLateralController.text = (await _prefs.getTempLateral()).toStringAsFixed(1);
    _tempVentController.text = (await _prefs.getTempVent()).toStringAsFixed(1);
    _autoMode = await _prefs.getAutoMode();

    setState(() {});
  }

  Future<void> _savePreferences() async {
    // Salvează preferințele
    await _prefs.saveIP(_ipController.text);
    await _prefs.saveFlowRate(double.tryParse(_flowController.text) ?? 5.0);
    await _prefs.saveTempLateral(double.tryParse(_tempLateralController.text) ?? 24.0);
    await _prefs.saveTempVent(double.tryParse(_tempVentController.text) ?? 34.0);
    await _prefs.saveAutoMode(_autoMode);

    final tcp = Provider.of<TcpService>(context, listen: false);
    if (tcp.conectat) {
      // Trimite setările către ESP și loghează în consolă
      String autoModeCommand = "AUTO:${_autoMode ? 1 : 0}";
      print('Trimite comanda: $autoModeCommand');
      tcp.trimiteComanda(autoModeCommand);

      if (_autoMode) {
        String tempLateralCommand = "TEMP_LATERALE:${_tempLateralController.text}";
        String tempVentCommand = "TEMP_VENTIL:${_tempVentController.text}";
        
        //print('➡️ Trimis: $tempLateralCommand'); // Log mesajul trimis pentru temperatura laterale
        //print('➡️ Trimis: $tempVentCommand'); // Log mesajul trimis pentru temperatura ventilatoare

        
        tcp.trimiteComanda(tempLateralCommand);
        tcp.trimiteComanda(tempVentCommand);
       }else {
        // Dacă nu există conexiune
        print('❌ Conexiune nereușită! Nu s-au putut trimite setările.');
      }
    }else {
      // Dacă nu există conexiune
      print('❌ Conexiune nereușită! Nu s-au putut trimite setările.');
    }

    // Confirmare în UI
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✔️ Setări salvate')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Setări",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _ipController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '🌐 Introdu IP-ul ESP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _tempLateralController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '🌡️ Temp. deschidere laterale (°C)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _tempVentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '🌬️ Temp. pornire ventilatoare (°C)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text("🤖 Mod Automat"),
              value: _autoMode,
              onChanged: (value) {
                setState(() {
                  _autoMode = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _savePreferences,
              child: const Text("💾 Salvează Setările"),
            ),
          ],
        ),
      ),
    );
  }
}
