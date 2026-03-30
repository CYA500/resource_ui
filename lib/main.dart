import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:glass_kit/glass_kit.dart';
import 'dart:convert';

void main() => runApp(const MaterialApp(
  home: SetupScreen(),
  debugShowCheckedModeBanner: false,
));

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _ipController = TextEditingController();

  void _connect() {
    String ip = _ipController.text.trim();
    if (ip.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MonitorScreen(ip: ip),
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
            const Icon(Icons.monitor_heart, size: 80, color: Colors.cyanAccent),
            const SizedBox(height: 30),
            TextField(
              controller: _ipController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter PC IP (e.g. 192.168.1.106)",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.cyanAccent),
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _connect,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("Connect to Windows", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

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
    // استخدام IOWebSocketChannel لضمان أفضل توافق مع الأندرويد
    final String socketUrl = 'ws://${widget.ip}:5050';
    channel = IOWebSocketChannel.connect(Uri.parse(socketUrl));
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 50,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Center(
              child: StreamBuilder(
                stream: channel.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text("Connection Error\nCheck IP & Firewall", 
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.redAccent, fontSize: 18));
                  }
                  
                  if (!snapshot.hasData) {
                    return const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.cyanAccent),
                        SizedBox(height: 20),
                        Text("Waiting for Data...", style: TextStyle(color: Colors.white70)),
                      ],
                    );
                  }

                  try {
                    var data = jsonDecode(snapshot.data.toString());
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildGlassCard("CPU USAGE", "${data['cpu']}%", Colors.greenAccent),
                        const SizedBox(height: 25),
                        _buildGlassCard("AVAILABLE RAM", "${data['ram']} MB", Colors.blueAccent),
                      ],
                    );
                  } catch (e) {
                    return const Text("Data Format Error", style: TextStyle(color: Colors.orange));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard(String title, String value, Color color) {
    return GlassContainer.frostedGlass(
      height: 170,
      width: 320,
      borderRadius: BorderRadius.circular(30),
      borderWidth: 1.5,
      gradient: LinearGradient(
        colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, color: Colors.white60, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: color, shadows: [
            Shadow(color: color.withOpacity(0.5), blurRadius: 20)
          ])),
        ],
      ),
    );
  }
}
