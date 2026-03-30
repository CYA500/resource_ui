import 'dart:io';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectionType { ip, qr, usb }

class ConnectionResult {
  final bool success;
  final String message;
  final WebSocketChannel? channel;

  ConnectionResult(this.success, this.message, {this.channel});
}

class ConnectionManager {
  static Future<ConnectionResult> connect(String address, ConnectionType type) async {
    try {
      String finalUrl = "";
      
      if (type == ConnectionType.usb) {
        // في وضع USB Tethering، غالباً ما يكون الآي بي هو 192.168.42.129 أو الـ Gateway
        finalUrl = "ws://$address:5050"; 
      } else {
        finalUrl = "ws://$address:5050";
      }

      final socket = await WebSocket.connect(finalUrl).timeout(const Duration(seconds: 5));
      return ConnectionResult(true, "Connected Successfully", channel: IOWebSocketChannel(socket));
      
    } on SocketException catch (e) {
      if (e.osError?.errorCode == 113) return ConnectionResult(false, "Host unreachable. Is the Firewall OFF?");
      if (e.osError?.errorCode == 111) return ConnectionResult(false, "Connection refused. Is the Server running?");
      return ConnectionResult(false, "Network error: ${e.message}");
    } on HttpException {
      return ConnectionResult(false, "Protocol error. Not a WebSocket server.");
    } catch (e) {
      return ConnectionResult(false, "Unknown Error: $e");
    }
  }
}
