import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        textTheme: GoogleFonts.orbitronTextTheme(ThemeData.dark().textTheme),
      ),
      home: const MainNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}

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

  void _onConnect(String ip) {
    if (ip.isEmpty) return;
    final channel = IOWebSocketChannel.connect(Uri.parse('ws://${ip.trim()}:5050'));
    Navigator.push(
      context,
      MaterialPageRoute(builder: (c) => MonitorDashboard(channel: channel, ip: ip)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("PC LINK PRO", style: TextStyle(letterSpacing: 3)),
        backgroundColor: const Color(0xFF1E293B),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: "QR"), Tab(text: "IP"), Tab(text: "USB")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MobileScanner(onDetect: (cap) => _onConnect(cap.barcodes.first.rawValue ?? "")),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(controller: _ipController, decoration: const InputDecoration(labelText: "PC IP Address", border: OutlineInputBorder())),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: () => _onConnect(_ipController.text), child: const Text("CONNECT")),
              ],
            ),
          ),
          const Center(child: Text("USB Tethering Mode Active")),
        ],
      ),
    );
  }
}

class MonitorDashboard extends StatelessWidget {
  final WebSocketChannel channel;
  final String ip;
  const MonitorDashboard({super.key, required this.channel, required this.ip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(title: Text("LIVE: $ip"), backgroundColor: Colors.transparent, elevation: 0),
      body: StreamBuilder(
        stream: channel.stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
          
          final data = jsonDecode(snapshot.data.toString());
          
          return Container(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                _statCard("CPU STATUS", "${data['cpu']}%", Colors.cyanAccent, (data['cpu'] as int) / 100.0),
                _statCard("RAM FREE", "${data['ram']} MB", Colors.pinkAccent, 0.5),
                _statCard("DISK LOAD", "${data['disk']}%", Colors.orangeAccent, (data['disk'] as int) / 100.0),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _cmdBtn("CLEAN", Icons.auto_fix_high, () => channel.sink.add("CLEAN_RAM")),
                    _cmdBtn("KILL", Icons.close, () => channel.sink.add("CLOSE_WINDOWS")),
                    _cmdBtn("GAME", Icons.bolt, () => channel.sink.add("GAME_MODE")),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(String t, String v, Color c, double p) {
    return GlassContainer.frostedGlass(
      height: 120, width: double.infinity, margin: const EdgeInsets.symmetric(vertical: 10),
      borderRadius: BorderRadius.circular(20), borderColor: c.withOpacity(0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          CircularProgressIndicator(value: p.clamp(0.0, 1.0), color: c, strokeWidth: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(t, style: TextStyle(color: c, fontSize: 12)),
              Text(v, style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _cmdBtn(String l, IconData i, VoidCallback t) {
    return InkWell(
      onTap: t,
      child: GlassContainer.frostedGlass(
        height: 90, width: 90, borderRadius: BorderRadius.circular(15),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i), Text(l, style: const TextStyle(fontSize: 10))]),
      ),
    );
  }
}
