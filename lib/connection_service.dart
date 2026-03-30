import 'dart:io';
import 'package:web_socket_channel/io.dart';

class ConnectionService {
  static Future<dynamic> tryConnect(String ip) async {
    final String url = 'ws://$ip:5050';
    try {
      // محاولة فتح اتصال خام للفحص
      final socket = await WebSocket.connect(url).timeout(const Duration(seconds: 5));
      return IOWebSocketChannel(socket);
    } on SocketException catch (e) {
      if (e.message.contains("113")) return "Firewall is blocking the connection.";
      if (e.message.contains("111")) return "Server is not running on PC.";
      return "Network Unreachable. Check WiFi/USB.";
    } on HandshakeException {
      return "Security handshake failed.";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }
}
