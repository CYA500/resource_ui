import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:io';

void main() => runApp(const MaterialApp(
  home: HomePage(),
  debugShowCheckedModeBanner: false,
));

// --- منطق الاتصال ---
class ConnectionService {
  static Future<dynamic> tryConnect(String ip) async {
    final String url = 'ws://${ip.trim()}:5050';
    try {
      final socket = await WebSocket.connect(url).timeout(const Duration(seconds: 5));
      return IOWebSocketChannel(socket);
    } on SocketException catch (e) {
      if (e.message.contains("113")) return "Firewall is blocking the connection.";
      if (e.message.contains("111")) return "Server is not running on PC.";
      return "Network error: ${e.message}";
    } catch (e) {
      return "Connection Failed: $e";
    }
  }
}

// --- الواجهة الرئيسية ---
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  void _startConnection(String ip) async {
    if (ip.isEmpty) return;
    
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
    );
    
    var result = await ConnectionService.tryConnect(ip);
    Navigator.pop(context); // إغلاق التحميل

    if (result is String) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: Colors.redAccent)
      );
    } else {
      Navigator.push(
        context, 
        MaterialPageRoute(builder: (c) => MonitorPage(channel: result, ip: ip))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text("PC Monitor PRO"),
        backgroundColor: const Color(0xFF16213E),
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(icon: Icon(Icons.qr_code_scanner), text: "QR"),
          Tab(icon: Icon(Icons.lan), text: "IP"),
          Tab(icon: Icon(Icons.usb), text: "USB"),
        ]),
      ),
      body: TabBarView(controller: _tabController, children: [
        // تبويب الـ QR
        MobileScanner(onDetect: (cap) {
          final String? code = cap.barcodes.first.rawValue;
          if (code != null) _startConnection(code);
        }),
        // تبويب الـ IP
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            TextField(
              controller: _ipController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Enter PC IP Address",
                labelStyle: TextStyle(color: Colors.cyanAccent),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _startConnection(_ipController.text),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
              child: const Text("Connect via WiFi"),
            ),
          ]),
        ),
        // تبويب الـ USB
        const Center(
          child: Text(
            "1. Connect USB Cable\n2. Enable USB Tethering\n3. Type PC IP from Server screen",
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ]),
    );
  }
}

// --- شاشة عرض البيانات ---
class MonitorPage extends StatelessWidget {
  final WebSocketChannel channel;
  final String ip;
  const MonitorPage({super.key, required this.channel, required this.ip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: Text("Monitoring: $ip"), backgroundColor: Colors.transparent),
      body: StreamBuilder(
        stream: channel.stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Connection Lost", style: TextStyle(color: Colors.red)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          var data = jsonDecode(snapshot.data.toString());
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _infoCard("CPU USAGE", "${data['cpu']}%", Colors.greenAccent),
              const SizedBox(height: 20),
              _infoCard("RAM AVAILABLE", "${data['ram']} MB", Colors.blueAccent),
            ],
          );
        },
      ),
    );
  }

  Widget _infoCard(String label, String value, Color color) {
    return Center(
      child: Container(
        width: 300, padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(color: color, fontSize: 45, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}
