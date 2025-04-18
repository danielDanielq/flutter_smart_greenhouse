import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class IPSetupPage extends StatefulWidget {
  const IPSetupPage({super.key});

  @override
  State<IPSetupPage> createState() => _IPSetupPageState();
}

class _IPSetupPageState extends State<IPSetupPage> {
  final TextEditingController _ipController = TextEditingController();
  final PreferencesService _prefs = PreferencesService();

  @override
  void initState() {
    super.initState();
    _loadSavedIP();
  }

  Future<void> _loadSavedIP() async {
    final savedIP = await _prefs.getIP();
    if (savedIP != null) {
      _ipController.text = savedIP;
    }
  }

  Future<void> _saveIP() async {
    await _prefs.saveIP(_ipController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('IP salvat: ${_ipController.text}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurare IP ESP')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _ipController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Introdu IP-ul ESP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveIP,
              child: const Text("💾 Salvează IP"),
            )
          ],
        ),
      ),
    );
  }
}
