import 'dart:io';

class PingTester {
  /// Measures TCP socket connection time to the host and port.
  /// Returns the latency in milliseconds, or -1 if it times out/fails.
  static Future<int> tcpPing(String host, int port, {int timeoutMs = 3000}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(host, port, timeout: Duration(milliseconds: timeoutMs));
      socket.destroy();
      return stopwatch.elapsedMilliseconds;
    } catch (e) {
      return -1;
    }
  }
}
