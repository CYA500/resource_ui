import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';

void main() => runApp(MaterialApp(
      theme: ThemeData.dark(),
      home: const MainNavigation(),
      debugShowCheckedModeBanner: false,
    ));

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  void _connect(String ip) {
    if (ip.isEmpty) return;
    final channel = IOWebSocketChannel.connect(Uri.parse('ws://${ip.trim()}:5050'));
    Navigator.push(context, MaterialPageRoute(builder: (c) => MonitorPage(channel: channel, ip: ip)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("PC MONITOR PRO", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner), text: "QR"),
            Tab(icon: Icon(Icons.lan), text: "IP"),
            Tab(icon: Icon(Icons.usb), text: "USB"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. واجهة الـ QR
          Stack(
            children: [
              MobileScanner(onDetect: (cap) => _connect(cap.barcodes.first.rawValue ?? "")),
              Center(child: Container(width: 200, height: 200, decoration: BoxDecoration(border: Border.all(color: Colors.cyanAccent, width: 2), borderRadius: BorderRadius.circular(20)))),
            ],
          ),
          // 2. واجهة الـ IP
          Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _ipController,
                  decoration: InputDecoration(
                    labelText: "PC IP ADDRESS",
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 50)),
                  onPressed: () => _connect(_ipController.text),
                  child: const Text("CONNECT VIA WIFI"),
                ),
              ],
            ),
          ),
          // 3. واجهة الـ USB
          const Center(
            child: Text(
              "1. Connect USB Cable\n2. Enable USB Tethering\n3. Use IP shown on PC",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class MonitorPage extends StatelessWidget {
  final WebSocketChannel channel;
  final String ip;
  const MonitorPage({super.key, required this.channel, required this.ip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF020617), Color(0xFF1E1B4B)], begin: Alignment.topCenter),
        ),
        child: StreamBuilder(
          stream: channel.stream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
            var data = jsonDecode(snapshot.data.toString());

            return Column(
              children: [
                const SizedBox(height: 60),
                Text("LIVE DATA: $ip", style: const TextStyle(color: Colors.cyanAccent, letterSpacing: 2)),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _glassMetric("CPU LOAD", "${data['cpu']}%", Colors.cyanAccent, data['cpu'] / 100.0),
                      _glassMetric("RAM FREE", "${data['ram']} MB", Colors.pinkAccent, 0.7),
                      _glassMetric("DISK LOAD", "${data['disk']}%", Colors.orangeAccent, data['disk'] / 100.0),
                      const SizedBox(height: 30),
                      const Text("CORE COMMANDS", style: TextStyle(color: Colors.white38)),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _controlBtn("CLEAN", Icons.brush, () => channel.sink.add("CLEAN_RAM")),
                          _controlBtn("KILL", Icons.close, () => channel.sink.add("CLOSE_WINDOWS")),
                          _controlBtn("GAME", Icons.bolt, () => channel.sink.add("GAME_MODE")),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _glassMetric(String title, String val, Color color, double prog) {
    return GlassContainer.frostedGlass(
      height: 110, width: double.infinity, margin: const EdgeInsets.symmetric(vertical: 10),
      borderRadius: BorderRadius.circular(25),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            CircularProgressIndicator(value: prog.clamp(0.0, 1.0), color: color, strokeWidth: 5),
            const SizedBox(width: 25),
            Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: color, fontSize: 12)),
              Text(val, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            ])
          ],
        ),
      ),
    );
  }

  Widget _controlBtn(String label, IconData icon, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: GlassContainer.frostedGlass(
        height: 90, width: 90, borderRadius: BorderRadius.circular(20),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: Colors.white), Text(label, style: const TextStyle(fontSize: 10))]),
      ),
    );
  }
}
