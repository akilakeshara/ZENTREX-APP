import 'dart:convert';

class VpnParameters {
  String protocol;
  String remarks;
  String address;
  int port;
  String id;
  
  // Advanced
  String network; // tcp, ws, grpc, kcp
  String security; // tls, reality, none
  String encryption;
  String flow;
  
  // WS/GRPC/HTTP
  String path;
  String host;
  
  // TLS / Reality
  String sni;
  String alpn;
  String fingerprint; // fp
  String publicKey; // pbk
  String shortId; // sid
  String spiderX; // spx
  String insecure;
  String allowInsecure;
  String headerType;
  
  // VMess specifics
  String aid;
  String scy;

  VpnParameters({
    this.protocol = 'VLESS',
    this.remarks = '',
    this.address = '',
    this.port = 443,
    this.id = '',
    this.network = 'tcp',
    this.security = 'none',
    this.encryption = 'none',
    this.flow = '',
    this.path = '',
    this.host = '',
    this.sni = '',
    this.alpn = '',
    this.fingerprint = '',
    this.publicKey = '',
    this.shortId = '',
    this.spiderX = '',
    this.insecure = '',
    this.allowInsecure = '',
    this.headerType = '',
    this.aid = '0',
    this.scy = 'auto',
  });

  /// Parse a V2Ray URI (vless://, vmess://, trojan://)
  static VpnParameters parse(String url) {
    if (url.startsWith('vmess://')) {
      return _parseVmess(url);
    } else if (url.startsWith('vless://') || url.startsWith('trojan://')) {
      return _parseStandardUri(url);
    }
    throw FormatException('Unsupported or invalid VPN URI scheme');
  }

  /// Parses vless:// or trojan:// URLs
  static VpnParameters _parseStandardUri(String rawUrl) {
    final uri = Uri.parse(rawUrl);
    final protocol = uri.scheme.toUpperCase();
    
    // Auth info: "id@address:port"
    String id = '';
    if (uri.userInfo.isNotEmpty) {
      id = uri.userInfo;
    }

    final params = VpnParameters(
      protocol: protocol,
      id: id,
      address: uri.host,
      port: uri.hasPort ? uri.port : 443,
      remarks: Uri.decodeFull(uri.fragment.replaceAll('+', ' ')),
    );

    // Query parameters
    final q = uri.queryParameters;
    params.network = q['type'] ?? 'tcp';
    params.security = q['security'] ?? 'none';
    params.encryption = q['encryption'] ?? 'none';
    params.flow = q['flow'] ?? '';
    params.path = q['path'] ?? '';
    params.host = q['host'] ?? '';
    params.sni = q['sni'] ?? '';
    params.alpn = q['alpn'] ?? '';
    params.fingerprint = q['fp'] ?? '';
    params.publicKey = q['pbk'] ?? '';
    params.shortId = q['sid'] ?? '';
    params.spiderX = q['spx'] ?? '';
    params.insecure = q['insecure'] ?? '';
    params.allowInsecure = q['allowInsecure'] ?? '';
    params.headerType = q['headerType'] ?? '';

    return params;
  }

  /// Parses vmess:// base64 JSON
  static VpnParameters _parseVmess(String url) {
    final base64Str = url.substring('vmess://'.length);
    String decodedStr = '';
    
    // Add padding if necessary
    var normalizedStr = base64Str;
    while (normalizedStr.length % 4 != 0) {
      normalizedStr += '=';
    }

    try {
      decodedStr = utf8.decode(base64Decode(normalizedStr));
    } catch (e) {
      throw FormatException('Failed to decode vmess base64: $e');
    }

    final Map<String, dynamic> json = jsonDecode(decodedStr);

    return VpnParameters(
      protocol: 'VMESS',
      remarks: json['ps']?.toString() ?? '',
      address: json['add']?.toString() ?? '',
      port: int.tryParse(json['port']?.toString() ?? '443') ?? 443,
      id: json['id']?.toString() ?? '',
      aid: json['aid']?.toString() ?? '0',
      scy: json['scy']?.toString() ?? 'auto',
      network: json['net']?.toString() ?? 'tcp',
      security: json['tls']?.toString() ?? 'none',
      path: json['path']?.toString() ?? '',
      host: json['host']?.toString() ?? '',
      sni: json['sni']?.toString() ?? '',
      alpn: json['alpn']?.toString() ?? '',
    );
  }

  /// Rebuilds the VPN URI string
  String toUriString() {
    if (protocol == 'VMESS') {
      return _toVmessUri();
    } else {
      return _toStandardUri();
    }
  }

  String _toStandardUri() {
    final Map<String, String> q = {};
    if (network.isNotEmpty && network != 'tcp') q['type'] = network;
    if (security.isNotEmpty && security != 'none') q['security'] = security;
    if (encryption.isNotEmpty && encryption != 'none') q['encryption'] = encryption;
    if (flow.isNotEmpty) q['flow'] = flow;
    if (path.isNotEmpty) q['path'] = path;
    if (host.isNotEmpty) q['host'] = host;
    if (sni.isNotEmpty) q['sni'] = sni;
    if (alpn.isNotEmpty) q['alpn'] = alpn;
    if (fingerprint.isNotEmpty) q['fp'] = fingerprint;
    if (publicKey.isNotEmpty) q['pbk'] = publicKey;
    if (shortId.isNotEmpty) q['sid'] = shortId;
    if (spiderX.isNotEmpty) q['spx'] = spiderX;
    if (insecure.isNotEmpty) q['insecure'] = insecure;
    if (allowInsecure.isNotEmpty) q['allowInsecure'] = allowInsecure;
    if (headerType.isNotEmpty) q['headerType'] = headerType;

    final uri = Uri(
      scheme: protocol.toLowerCase(),
      userInfo: id,
      host: address,
      port: port,
      queryParameters: q.isEmpty ? null : q,
      fragment: Uri.encodeFull(remarks),
    );
    return uri.toString();
  }

  String _toVmessUri() {
    final Map<String, dynamic> json = {
      'v': '2',
      'ps': remarks,
      'add': address,
      'port': port,
      'id': id,
      'aid': aid,
      'scy': scy,
      'net': network,
      'type': 'none',
      'host': host,
      'path': path,
      'tls': security,
      'sni': sni,
      'alpn': alpn,
    };
    
    final str = jsonEncode(json);
    final encoded = base64Encode(utf8.encode(str));
    return 'vmess://$encoded';
  }

  /// Generates a strict Xray Core 1.8.0+ compliant JSON configuration string
  String toXrayJson(int socksPort) {
    Map<String, dynamic> config = {
      "log": {
        "access": "",
        "error": "",
        "loglevel": "error",
        "dnsLog": false
      },
      "dns": {
        "servers": [
          "1.1.1.1",
          "8.8.8.8"
        ]
      },
      "inbounds": [
        {
          "tag": "socks-in",
          "port": socksPort,
          "protocol": "socks",
          "listen": "127.0.0.1",
          "settings": {
            "auth": "noauth",
            "udp": true,
            "ip": "127.0.0.1"
          },
          "sniffing": {
            "enabled": true,
            "destOverride": ["http", "tls"]
          }
        }
      ],
      "outbounds": [],
      "routing": {
        "domainStrategy": "AsIs",
        "rules": [
          {
            "type": "field",
            "ip": ["geoip:private"],
            "outboundTag": "direct"
          }
        ]
      }
    };

    // Construct the primary outbound
    Map<String, dynamic> proxyOutbound = {
      "tag": "proxy",
      "protocol": protocol.toLowerCase(),
      "settings": <String, dynamic>{},
      "streamSettings": <String, dynamic>{
        "network": network,
        "security": security == 'none' ? "none" : security,
      }
    };

    // Protocol specifics
    if (protocol == 'VLESS') {
      var user = <String, dynamic>{
        "id": id,
        "encryption": encryption.isNotEmpty ? encryption : "none",
        "level": 0
      };
      if (flow.isNotEmpty) {
        user["flow"] = flow;
      }
      
      proxyOutbound['settings'] = {
        "vnext": [
          {
            "address": address,
            "port": port,
            "users": [user]
          }
        ]
      };
    } else if (protocol == 'VMESS') {
      proxyOutbound['settings'] = {
        "vnext": [
          {
            "address": address,
            "port": port,
            "users": [
              {
                "id": id,
                "alterId": int.tryParse(aid) ?? 0,
                "security": scy.isNotEmpty ? scy : "auto",
                "level": 0
              }
            ]
          }
        ]
      };
    } else if (protocol == 'TROJAN') {
      proxyOutbound['settings'] = {
        "servers": [
          {
            "address": address,
            "port": port,
            "password": id,
            "level": 0
          }
        ]
      };
    }

    // Transport specifics (network)
    Map<String, dynamic> streamSettings = proxyOutbound['streamSettings'];
    if (network == 'tcp') {
      streamSettings['tcpSettings'] = {
        "header": {
          "type": headerType.isNotEmpty ? headerType : "none"
        }
      };
      if (host.isNotEmpty && headerType == 'http') {
        streamSettings['tcpSettings']['header']['request'] = {
          "headers": {
            "Host": host.split(',')
          }
        };
      }
    } else if (network == 'ws') {
      streamSettings['wsSettings'] = {
        "path": path.isNotEmpty ? path : "/",
        "headers": host.isNotEmpty ? {"Host": host} : {}
      };
    } else if (network == 'grpc') {
      streamSettings['grpcSettings'] = {
        "serviceName": path,
        "multiMode": false
      };
    }

    // Security specifics
    if (security == 'tls') {
      streamSettings['tlsSettings'] = {
        "allowInsecure": allowInsecure == '1' || allowInsecure == 'true' || insecure == '1' || insecure == 'true',
        "serverName": sni.isNotEmpty ? sni : (host.isNotEmpty ? host : address),
      };
      if (alpn.isNotEmpty) {
        streamSettings['tlsSettings']['alpn'] = alpn.split(',');
      }
      if (fingerprint.isNotEmpty) {
        streamSettings['tlsSettings']['fingerprint'] = fingerprint;
      }
    } else if (security == 'reality') {
      streamSettings['realitySettings'] = {
        "show": false,
        "fingerprint": fingerprint.isNotEmpty ? fingerprint : "chrome",
        "serverName": sni.isNotEmpty ? sni : (host.isNotEmpty ? host : address),
        "publicKey": publicKey,
        "shortId": shortId,
        "spiderX": spiderX.isNotEmpty ? spiderX : "/"
      };
    }

    config['outbounds'].add(proxyOutbound);

    // Direct and Blackhole outbounds
    config['outbounds'].add({
      "tag": "direct",
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "UseIp"
      }
    });
    config['outbounds'].add({
      "tag": "block",
      "protocol": "blackhole",
      "settings": {}
    });

    return jsonEncode(config);
  }
}
