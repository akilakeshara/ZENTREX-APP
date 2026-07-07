import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';

void main() {
  test('parse vless url', () {
    String url = 'vless://d72b06d4-edae-4cd6-bd1b-447a97e06861@free.sahanwickramasinghevip.shop:443?security=tls&encryption=none&insecure=1&headerType=none&fp=chrome&type=tcp&allowInsecure=1&sni=aka.ms#Dialog%20Zoom-%20Sahan%20Wickaramasinghe';
    final parsedConfig = V2ray.parseFromURL(url);
    String rawJson = parsedConfig.getFullConfiguration();
    // ignore: avoid_print
    print(rawJson);
  });
}
