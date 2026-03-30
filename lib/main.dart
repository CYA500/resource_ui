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

// --- الشاشة الرئيسية (واجهة الاتصال الثلاثية) ---
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
    try {
      final channel = IOWebSocketChannel.connect(Uri.parse('ws://${ip.trim()}:5050'));
      // الانتقال فوراً لشاشة العرض عند الاتصال
      Navigator.push(context, MaterialPageRoute(builder: (c) => MonitorDashboard(channel: channel, ip: ip)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connection Failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("PC MONITOR PRO", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner), text: "QR SCAN"),
            Tab(icon: Icon(Icons.lan), text: "MANUAL IP"),
            Tab(icon: Icon(Icons.usb), text: "USB MODE"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. واجهة الـ QR
          Stack(
            children: [
              MobileScanner(onDetect: (cap) {
                final String? code = cap.barcodes.first.rawValue;
                if (code != null) _connect(code);
              }),
              Center(child: Container(width: 220, height: 220, decoration: BoxDecoration(border: Border.all(color: Colors.cyanAccent, width: 2), borderRadius: BorderRadius.circular(25)))),
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
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "ENTER PC IP",
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 55)),
                  onPressed: () => _connect(_ipController.text),
                  child: const Text("CONNECT NOW", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          // 3. واجهة الـ USB
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.usb, size: 80, color: Colors.white24),
                SizedBox(height: 20),
                Text("1. Connect USB Cable\n2. Enable USB Tethering\n3. Use IP shown in PC Server", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- شاشة العرض والتحكم (Dashboard) ---
class MonitorDashboard extends StatelessWidget {
  final WebSocketChannel channel;
  final String ip;
  const MonitorDashboard({super.key, required this.channel, required this.ip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(title: Text("MONITORING: $ip"), backgroundColor: Colors.transparent, elevation: 0),
      body: StreamBuilder(
        stream: channel.stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("PC Disconnected", style: TextStyle(color: Colors.redAccent)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));

          var data = jsonDecode(snapshot.data.toString());

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // كروت العرض الزجاجية
              _buildMetricCard("CPU UTILIZATION", "${data['cpu']}%", Colors.cyanAccent, (data['cpu'] as int) / 100.0),
              _buildMetricCard("MEMORY AVAILABLE", "${data['ram']} MB", Colors.pinkAccent, 0.6),
              _buildMetricCard("DISK USAGE", "${data['disk']}%", Colors.orangeAccent, (data['disk'] as int) / 100.0),
              
              const SizedBox(height: 30),
              const Text("REMOTE ACTIONS", style: TextStyle(color: Colors.white38, letterSpacing: 2, fontSize: 12)),
              const SizedBox(height: 15),
              
              // أزرار الأوامر
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _actionButton("CLEAN", Icons.auto_fix_high, () => channel.sink.add("CLEAN_RAM")),
                  _actionButton("KILL", Icons.power_settings_new, () => channel.sink.add("CLOSE_WINDOWS")),
                  _actionButton("GAME", Icons.bolt, () => channel.sink.add("GAME_MODE")),
                ],
              ),
              const SizedBox(height: 50),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, double percent) {
    return GlassContainer.frostedGlass(
      height: 130, width: double.infinity, margin: const EdgeInsets.symmetric(vertical: 10),
      borderRadius: BorderRadius.circular(30), borderColor: color.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(value: percent.clamp(0.0, 1.0), color: color, strokeWidth: 8, backgroundColor: Colors.white10),
                Icon(Icons.speed, color: color.withOpacity(0.5), size: 15),
              ],
            ),
            const SizedBox(width: 25),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer.frostedGlass(
        height: 100, width: 100, borderRadius: BorderRadius.circular(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
