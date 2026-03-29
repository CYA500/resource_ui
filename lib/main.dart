import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:glass_kit/glass_kit.dart';
import 'dart:convert';

void main() => runApp(const MaterialApp(
  home: SetupScreen(),
  debugShowCheckedModeBanner: false,
));

// شاشة إدخال الـ IP
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _ipController = TextEditingController();

  void _connect() {
    if (_ipController.text.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MonitorScreen(ip: _ipController.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.monitor_heart, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 20),
            TextField(
              controller: _ipController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter PC IP (e.g. 192.168.1.5)",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _connect,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Connect to Windows"),
            ),
          ],
        ),
      ),
    );
  }
}

// شاشة العرض الشفافة (Glassmorphism)
class MonitorScreen extends StatefulWidget {
  final String ip;
  const MonitorScreen({super.key, required this.ip});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  late WebSocketChannel channel;

  @override
  void initState() {
    super.initState();
    channel = WebSocketChannel.connect(Uri.parse('ws://${widget.ip}:5050'));
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: 50, left: 20, child: BackButton(color: Colors.white)),
            Center(
              child: StreamBuilder(
                stream: channel.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Text("Connection Error", style: TextStyle(color: Colors.red));
                  if (!snapshot.hasData) return const CircularProgressIndicator();

                  var data = jsonDecode(snapshot.data);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _glassCard("CPU", "${data['cpu']}%", Colors.greenAccent),
                      const SizedBox(height: 25),
                      _glassCard("Available RAM", "${data['ram']} MB", Colors.cyanAccent),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassCard(String title, String val, Color col) {
    return GlassContainer.frostedGlass(
      height: 160, width: 320,
      borderRadius: BorderRadius.circular(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 18)),
          Text(val, style: TextStyle(color: col, fontSize: 45, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
