import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(MaterialApp(
  theme: ThemeData.dark().copyWith(
    textTheme: GoogleFonts.orbitronTextTheme(ThemeData.dark().textTheme),
  ),
  home: const HomePage(),
  debugShowCheckedModeBanner: false,
));

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isConnecting = false;

  void _connect(String ip) {
    if (isConnecting) return;
    setState() => isConnecting = true;
    
    try {
      final channel = IOWebSocketChannel.connect(Uri.parse('ws://$ip:5050'));
      Navigator.push(context, MaterialPageRoute(builder: (c) => MonitorPage(channel: channel, ip: ip)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState() => isConnecting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (cap) {
              final String? code = cap.barcodes.first.rawValue;
              if (code != null) _connect(code);
            },
          ),
          Center(
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyanAccent, width: 2),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          const Positioned(
            bottom: 80, left: 0, right: 0,
            child: Text("POINT AT PC QR CODE", 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 4, fontWeight: FontWeight.bold)
            ),
          )
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
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000428), Color(0xFF004e92)], 
            begin: Alignment.topLeft, end: Alignment.bottomRight
          ),
        ),
        child: StreamBuilder(
          stream: channel.stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text("Disconnected"));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
            
            var data = jsonDecode(snapshot.data.toString());

            return Column(
              children: [
                const SizedBox(height: 60),
                Text("SYSTEM STATUS: $ip", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, letterSpacing: 2)),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildMetric("PROCESSOR", "${data['cpu']}%", Colors.cyanAccent, (data['cpu'] as int) / 100.0),
                      _buildMetric("RAM USAGE", "${data['ram']} MB", Colors.pinkAccent, 0.6), // تم تصحيح اللون هنا
                      _buildMetric("DISK LOAD", "${data['disk']}%", Colors.orangeAccent, (data['disk'] as int) / 100.0),
                      const SizedBox(height: 30),
                      const Text("CONTROL UNIT", style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2)),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _cmdBtn("FLUSH RAM", Icons.cleaning_services, () => channel.sink.add("CLEAN_RAM")),
                          _cmdBtn("KILL APPS", Icons.terminal, () => channel.sink.add("CLOSE_WINDOWS")),
                          _cmdBtn("ULTRA MODE", Icons.bolt, () => channel.sink.add("GAME_MODE")),
                        ],
                      ),
                      const SizedBox(height: 30),
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
      height: 120, width: double.infinity, margin: const EdgeInsets.symmetric(vertical: 10),
      borderRadius: BorderRadius.circular(25), borderColor: color.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              height: 60, width: 60,
              child: CircularProgressIndicator(value: progress.clamp(0.0, 1.0), color: color, strokeWidth: 8, backgroundColor: Colors.white10),
            ),
            const SizedBox(width: 25),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(val, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ]
            )
          ],
        ),
      ),
    );
  }

  Widget _cmdBtn(String label, IconData icon, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: GlassContainer.frostedGlass(
        height: 100, width: 100, borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Icon(icon, color: Colors.white, size: 30), 
            const SizedBox(height: 10), 
            Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold))
          ]
        ),
      ),
    );
  }
}
