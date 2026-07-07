import 'package:zentrex/utils/vpn_uri_parser.dart';


void main() {
  String url = 'vless://d72b06d4-edae-4cd6-bd1b-447a97e06861@free.sahanwickramasinghevip.shop:443?security=tls&encryption=none&insecure=1&headerType=none&fp=chrome&type=tcp&allowInsecure=1&sni=aka.ms#Dialog%20Zoom-%20Sahan%20Wickaramasinghe';
  final params = VpnParameters.parse(url);
  String jsonStr = params.toXrayJson(10808);
  // ignore: avoid_print
  print(jsonStr);
}
