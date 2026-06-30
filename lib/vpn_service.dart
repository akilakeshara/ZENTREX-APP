import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import 'package:zentrex/utils/vpn_uri_parser.dart';

class ZentrexVpnService {
  late final V2ray v2ray;
  bool _isInitialized = false;
  String? _lastConfigJson;
  final StreamController<V2RayStatus> _statusController =
      StreamController<V2RayStatus>.broadcast();

  // Singleton pattern
  ZentrexVpnService._privateConstructor() {
    v2ray = V2ray(
      onStatusChanged: (V2RayStatus status) {
        _statusController.add(status);
      },
    );
  }
  static final ZentrexVpnService instance =
      ZentrexVpnService._privateConstructor();

  Future<void> initialize() async {
    if (_isInitialized) return;
    await v2ray.initialize(
      notificationIconResourceType: "drawable",
      notificationIconResourceName: "ic_notification",
    );
    _isInitialized = true;
  }

  Future<bool> connect(String configUri, String profileName) async {
    if (!_isInitialized) await initialize();
    
    try {
      // Forcefully stop any hanging core process first
      try {
        await v2ray.stopV2Ray();
      } catch (_) {}

      Map<String, dynamic> configMap;
      
      bool isJson = configUri.trim().startsWith('{') && configUri.trim().endsWith('}');

      int randomSocksPort = 10000 + DateTime.now().millisecondsSinceEpoch % 40000;

      if (isJson) {
        configMap = jsonDecode(configUri);
        
        // If the user imports a raw JSON, we must manually ensure DNS loop break
        // and scrub invalid fields since it doesn't pass through our generator.
        if (!configMap.containsKey('routing')) {
          configMap['routing'] = {"domainStrategy": "UseIp", "rules": []};
        }
        if (configMap['routing']['rules'] == null) {
          configMap['routing']['rules'] = [];
        }
        
        List<dynamic> rules = configMap['routing']['rules'];
        rules.removeWhere((rule) => 
          (rule['ip'] != null && rule['ip'].toString().contains('geoip')) ||
          (rule['domain'] != null && rule['domain'].toString().contains('geosite'))
        );

        // Remove direct port 53 routing if we want DNS to go through the proxy!
        // We actually DO want DNS to go through the proxy once connected.
        configMap['routing']['rules'] = rules;
        configMap.remove('dns'); // Prevents hijacking DNS to blocked IPs
      } else {
        // Parse the raw VPN URL using our robust custom parser
        final params = VpnParameters.parse(configUri);
        
        // PRE-RESOLVE THE DOMAIN TO AN IP ADDRESS BEFORE STARTING THE VPN!
        // This completely bypasses the DNS deadlock on SNI bug hosts (where generic DNS is blocked).
        // Since the VPN hasn't started yet, this uses the working ISP DNS.
        try {
          // Check if it's not already an IP
          bool isIPv4 = RegExp(r'^([0-9]{1,3}\.){3}[0-9]{1,3}$').hasMatch(params.address);
          bool isIPv6 = params.address.contains(':');
          if (!isIPv4 && !isIPv6) {
            print("Pre-resolving proxy domain: ${params.address}");
            final addresses = await InternetAddress.lookup(params.address).timeout(const Duration(seconds: 5));
            if (addresses.isNotEmpty) {
              params.address = addresses.first.address;
              print("Pre-resolved to IP: ${params.address}");
            }
          }
        } catch (e) {
          print("Failed to pre-resolve domain: $e");
        }

        String rawJson = params.toXrayJson(randomSocksPort);
        configMap = jsonDecode(rawJson);
      }

      String finalJsonConfig = jsonEncode(configMap);
      _lastConfigJson = finalJsonConfig;

      print("========= FINAL V2RAY CONFIG =========");
      print(finalJsonConfig);
      print("======================================");

      if (await v2ray.requestPermission()) {
        await v2ray.startV2Ray(
          remark: profileName,
          config: finalJsonConfig,
          proxyOnly: false,
          blockedApps: null,
          // bypassSubnets causes VpnService builder to crash/ANR if formatted wrong
          // We will rely on geoip:private in the routing rules instead.
          bypassSubnets: null, 
        );
        return true;
      }
      return false;
    } catch (e) {
      print("VPN Connection Error: $e");
      return false; 
    }
  }

  Future<void> disconnect() async {
    await v2ray.stopV2Ray();
  }

  Future<int> getPing() async {
    try {
      return await v2ray.getConnectedServerDelay();
    } catch (_) {
      return -1;
    }
  }

  Stream<V2RayStatus> get v2rayStatusStream => _statusController.stream;
}
