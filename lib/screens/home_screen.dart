import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tcp_service.dart';
import 'ip_setup_page.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TcpService tcpService;
  List<bool> relee = [false, false, false, false];

  @override
  void initState() {
    super.initState();
    tcpService = Provider.of<TcpService>(context, listen: false);
    tcpService.conecteazaESP();

    // Verificare periodică
    Timer.periodic(Duration(seconds: 3), (timer) {
      if (!tcpService.conectat) {
        tcpService.conecteazaESP();
      }
    });
  }

  void toggleReleu(int index) async {
    if (!tcpService.conectat) {
      final ok = await tcpService.conecteazaESP();
      if (!ok) return;
    }

    setState(() => relee[index] = !relee[index]);
    String comanda = relee[index] ? "ON${index + 1}" : "OFF${index + 1}";
    tcpService.trimiteComanda(comanda);
  }

  @override
  void dispose() {
    tcpService.deconecteaza();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Control Relee"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IPSetupPage()),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Consumer<TcpService>(
              builder: (context, tcp, child) => Text(
                tcp.conectat ? "🟢 Conectat la ESP" : "🔴 Neconectat",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: tcp.conectat ? Colors.green : Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(4, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ElevatedButton(
                  onPressed: () => toggleReleu(index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: relee[index] ? Colors.green : Colors.red,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(
                    relee[index]
                        ? "Oprește releul ${index + 1}"
                        : "Pornește releul ${index + 1}",
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
 