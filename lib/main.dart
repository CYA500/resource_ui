import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(MaterialApp(
  theme: ThemeData.dark().copyWith(textTheme: GoogleFonts.orbitronTextTheme()),
  home: const HomePage(),
  debugShowCheckedModeBanner: false,
));

// --- شاشة البداية والربط ---
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _connect(String ip) {
    final channel = IOWebSocketChannel.connect(Uri.parse('ws://$ip:5050'));
    Navigator.push(context, MaterialPageRoute(builder: (c) => MonitorPage(channel: channel, ip: ip)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(onDetect: (cap) => _connect(cap.barcodes.first.rawValue ?? "")),
          Center(child: Container(width: 200, height: 200, decoration: BoxDecoration(border: Border.all(color: Colors.cyanAccent, width: 2), borderRadius: BorderRadius.circular(20)))),
          const Positioned(bottom: 50, left: 0, right: 0, child: Text("SCAN PC QR CODE", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 3)))
        ],
      ),
    );
  }
}

// --- شاشة المراقبة والتحكم (الجمالية) ---
class MonitorPage extends StatelessWidget {
  final WebSocketChannel channel;
  final String ip;
  const MonitorPage({super.key, required this.channel, required this.ip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF000428), Color(0xFF004e92)], begin: Alignment.topLeft),
        ),
        child: StreamBuilder(
          stream: channel.stream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            var data = jsonDecode(snapshot.data.toString());

            return Column(
              children: [
                const SizedBox(height: 50),
                Text("DASHBOARD: $ip", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildMetric("PROCESSOR", "${data['cpu']}%", Colors.cyanAccent, data['cpu'] / 100),
                      _buildMetric("MEMORY", "${data['ram']} MB", Colors.magentaAccent, 0.5),
                      _buildMetric("DISK LOAD", "${data['disk']}%", Colors.orangeAccent, data['disk'] / 100),
                      const SizedBox(height: 30),
                      const Text("ADVANCED COMMANDS", style: TextStyle(color: Colors.white38, fontSize: 10)),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _cmdBtn("RAM CLEAN", Icons.auto_fix_high, () => channel.sink.add("CLEAN_RAM")),
                          _cmdBtn("KILL APPS", Icons.apps_outage, () => channel.sink.add("CLOSE_WINDOWS")),
                          _cmdBtn("GAME MODE", Icons.bolt, () => channel.sink.add("GAME_MODE")),
                        ],
                      )
                    ],
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetric(String title, String val, Color color, double progress) {
    return GlassContainer.frostedGlass(
      height: 110, width: double.infinity, margin: const EdgeInsets.symmetric(vertical: 8),
      borderRadius: BorderRadius.circular(20), borderColor: color.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircularProgressIndicator(value: progress, color: color, strokeWidth: 8, backgroundColor: Colors.white10),
            const SizedBox(width: 25),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: color, fontSize: 12)),
              Text(val, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            ])
          ],
        ),
      ),
    );
  }

  Widget _cmdBtn(String label, IconData icon, VoidCallback tap) {
    return InkWell(
      onTap: tap,
      child: GlassContainer.frostedGlass(
        height: 100, width: 100, borderRadius: BorderRadius.circular(20),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: Colors.white), const SizedBox(height: 10), Text(label, style: const TextStyle(fontSize: 9))]),
      ),
    );
  }
}
