import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsManager extends ChangeNotifier {
  // Keys
  static const String _primaryDnsKey = 'settings_primary_dns';
  static const String _secondaryDnsKey = 'settings_secondary_dns';
  static const String _enableSniffingKey = 'settings_enable_sniffing';
  static const String _enableMuxKey = 'settings_enable_mux';
  static const String _muxConcurrencyKey = 'settings_mux_concurrency';
  static const String _allowInsecureKey = 'settings_allow_insecure';
  static const String _bypassLanKey = 'settings_bypass_lan';

  // Singleton
  SettingsManager._privateConstructor();
  static final SettingsManager instance = SettingsManager._privateConstructor();

  // State
  String _primaryDns = '1.1.1.1';
  String _secondaryDns = '8.8.8.8';
  bool _enableSniffing = true;
  bool _enableMux = false;
  int _muxConcurrency = 8;
  bool _allowInsecure = false;
  bool _bypassLan = true;

  // Getters
  String get primaryDns => _primaryDns;
  String get secondaryDns => _secondaryDns;
  bool get enableSniffing => _enableSniffing;
  bool get enableMux => _enableMux;
  int get muxConcurrency => _muxConcurrency;
  bool get allowInsecure => _allowInsecure;
  bool get bypassLan => _bypassLan;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    _primaryDns = prefs.getString(_primaryDnsKey) ?? '1.1.1.1';
    _secondaryDns = prefs.getString(_secondaryDnsKey) ?? '8.8.8.8';
    _enableSniffing = prefs.getBool(_enableSniffingKey) ?? true;
    _enableMux = prefs.getBool(_enableMuxKey) ?? false;
    _muxConcurrency = prefs.getInt(_muxConcurrencyKey) ?? 8;
    _allowInsecure = prefs.getBool(_allowInsecureKey) ?? false;
    _bypassLan = prefs.getBool(_bypassLanKey) ?? true;
    
    notifyListeners();
  }

  Future<void> setPrimaryDns(String value) async {
    _primaryDns = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_primaryDnsKey, value);
    notifyListeners();
  }

  Future<void> setSecondaryDns(String value) async {
    _secondaryDns = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_secondaryDnsKey, value);
    notifyListeners();
  }

  Future<void> setEnableSniffing(bool value) async {
    _enableSniffing = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enableSniffingKey, value);
    notifyListeners();
  }

  Future<void> setEnableMux(bool value) async {
    _enableMux = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enableMuxKey, value);
    notifyListeners();
  }

  Future<void> setMuxConcurrency(int value) async {
    _muxConcurrency = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_muxConcurrencyKey, value);
    notifyListeners();
  }

  Future<void> setAllowInsecure(bool value) async {
    _allowInsecure = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_allowInsecureKey, value);
    notifyListeners();
  }

  Future<void> setBypassLan(bool value) async {
    _bypassLan = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bypassLanKey, value);
    notifyListeners();
  }
}
