import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer';

class VpnConfig {
  final String id;
  final String name;
  final String url;
  final String protocol;
  final DateTime addedAt;

  VpnConfig({
    required this.id,
    required this.name,
    required this.url,
    required this.protocol,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'protocol': protocol,
        'addedAt': addedAt.toIso8601String(),
      };

  factory VpnConfig.fromJson(Map<String, dynamic> json) {
    return VpnConfig(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      protocol: json['protocol'],
      addedAt: DateTime.parse(json['addedAt']),
    );
  }
}

class ConfigManager extends ChangeNotifier {
  static const String _configsKey = 'zentrex_saved_configs';
  static const String _activeConfigKey = 'zentrex_active_config_id';

  // Singleton
  ConfigManager._privateConstructor();
  static final ConfigManager instance = ConfigManager._privateConstructor();

  List<VpnConfig> _configs = [];
  String? _activeConfigId;

  List<VpnConfig> get configs => List.unmodifiable(_configs);

  VpnConfig? get activeConfig {
    if (_activeConfigId == null) return null;
    try {
      return _configs.firstWhere((c) => c.id == _activeConfigId);
    } catch (_) {
      return null;
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Load configs
    final String? configsJson = prefs.getString(_configsKey);
    if (configsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(configsJson);
        _configs = decoded.map((e) => VpnConfig.fromJson(e)).toList();
      } catch (e) {
        log("Error parsing saved configs: \$e");
        _configs = [];
      }
    }

    // Load active config ID
    _activeConfigId = prefs.getString(_activeConfigKey);
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_configs.map((c) => c.toJson()).toList());
    await prefs.setString(_configsKey, encoded);
  }

  Future<void> addConfig(VpnConfig config) async {
    _configs.add(config);
    await _saveToStorage();

    // Auto-select if it's the only one
    if (_configs.length == 1) {
      await setActiveConfig(config.id);
    }
    notifyListeners();
  }

  Future<void> removeConfig(String id) async {
    _configs.removeWhere((c) => c.id == id);
    if (_activeConfigId == id) {
      await setActiveConfig(null);
    }
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> updateConfig(VpnConfig updatedConfig) async {
    final index = _configs.indexWhere((c) => c.id == updatedConfig.id);
    if (index != -1) {
      _configs[index] = updatedConfig;
      await _saveToStorage();
      notifyListeners();
    }
  }

  Future<void> setActiveConfig(String? id) async {
    _activeConfigId = id;
    final prefs = await SharedPreferences.getInstance();
    if (id != null) {
      await prefs.setString(_activeConfigKey, id);
    } else {
      await prefs.remove(_activeConfigKey);
    }
    notifyListeners();
  }

  Future<void> sortConfigsByPing(Map<String, int> pings) async {
    _configs.sort((a, b) {
      final pingA = pings[a.id] ?? 999999;
      final pingB = pings[b.id] ?? 999999;
      
      final actualA = pingA == -1 ? 999999 : pingA;
      final actualB = pingB == -1 ? 999999 : pingB;

      return actualA.compareTo(actualB);
    });
    await _saveToStorage();
    notifyListeners();
  }
}
