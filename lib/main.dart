// تحتاج لإضافة: mobile_scanner: ^5.1.1 في pubspec.yaml
import 'package:flutter/material.dart';
import 'services/connection_manager.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() => runApp(const MaterialApp(home: HomeScreen(), debugShowCheckedModeBanner: false));

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  void _handleConnection(String address, ConnectionType type) async {
    showDialog(context: context, builder: (c) => const Center(child: CircularProgressIndicator()));
    
    var result = await ConnectionManager.connect(address, type);
    Navigator.pop(context); // إغلاق الـ Loading

    if (result.success) {
      // الانتقال لشاشة المراقبة مع تمرير الـ channel
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.redAccent)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PC Monitor PRO"),
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(icon: Icon(Icons.qr_code_scanner), text: "QR Scan"),
          Tab(icon: Icon(Icons.lan), text: "Manual IP"),
          Tab(icon: Icon(Icons.usb), text: "USB Mode"),
        ]),
      ),
      body: TabBarView(controller: _tabController, children: [
        // QR Tab
        MobileScanner(onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) _handleConnection(barcodes.first.rawValue!, ConnectionType.qr);
        }),
        // IP Tab
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            TextField(controller: _ipController, decoration: const InputDecoration(labelText: "Enter PC IP")),
            ElevatedButton(onPressed: () => _handleConnection(_ipController.text, ConnectionType.ip), child: const Text("Connect"))
          ]),
        ),
        // USB Tab
        const Center(child: Text("1. Enable USB Tethering\n2. Enter PC Gateway IP above", textAlign: TextAlign.center)),
      ]),
    );
  }
}
