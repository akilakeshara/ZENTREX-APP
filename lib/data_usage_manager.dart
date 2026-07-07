import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'vpn_service.dart';

class DataUsageManager extends ChangeNotifier {
  static const String _todayDateKey = 'data_usage_today_date';
  static const String _todayBytesKey = 'data_usage_today_bytes';
  static const String _monthDateKey = 'data_usage_month_date';
  static const String _monthBytesKey = 'data_usage_month_bytes';
  static const String _dailyHistoryKey = 'data_usage_history_daily';
  static const String _monthlyHistoryKey = 'data_usage_history_monthly';

  DataUsageManager._privateConstructor();
  static final DataUsageManager instance = DataUsageManager._privateConstructor();

  String _todayDate = '';
  String _monthDate = '';
  int _todayBytes = 0;
  int _monthBytes = 0;

  Map<String, int> _dailyHistory = {};
  Map<String, int> _monthlyHistory = {};

  int get todayBytes => _todayBytes;
  int get monthBytes => _monthBytes;
  Map<String, int> get dailyHistory => _dailyHistory;
  Map<String, int> get monthlyHistory => _monthlyHistory;

  int _lastSessionDl = 0;
  int _lastSessionUl = 0;
  StreamSubscription? _vpnStatusSub;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    _todayDate = prefs.getString(_todayDateKey) ?? '';
    _todayBytes = prefs.getInt(_todayBytesKey) ?? 0;
    _monthDate = prefs.getString(_monthDateKey) ?? '';
    _monthBytes = prefs.getInt(_monthBytesKey) ?? 0;

    final dailyStr = prefs.getString(_dailyHistoryKey);
    if (dailyStr != null) {
      try {
        final map = jsonDecode(dailyStr) as Map<String, dynamic>;
        _dailyHistory = map.map((k, v) => MapEntry(k, v as int));
      } catch (_) {}
    }
    
    final monthlyStr = prefs.getString(_monthlyHistoryKey);
    if (monthlyStr != null) {
      try {
        final map = jsonDecode(monthlyStr) as Map<String, dynamic>;
        _monthlyHistory = map.map((k, v) => MapEntry(k, v as int));
      } catch (_) {}
    }

    _checkAndResetDates(prefs);
    
    _startTracking();
    
    notifyListeners();
  }

  void _startTracking() {
    _vpnStatusSub = ZentrexVpnService.instance.v2rayStatusStream.listen((status) {
      if (status.state == "DISCONNECTED") {
        _lastSessionDl = 0;
        _lastSessionUl = 0;
        return;
      }
      
      int dlDelta = status.download - _lastSessionDl;
      int ulDelta = status.upload - _lastSessionUl;
      
      if (dlDelta < 0) dlDelta = status.download;
      if (ulDelta < 0) ulDelta = status.upload;
      
      if (dlDelta > 0 || ulDelta > 0) {
        addUsage(dlDelta, ulDelta);
        _lastSessionDl = status.download;
        _lastSessionUl = status.upload;
      }
    });
  }

  @override
  void dispose() {
    _vpnStatusSub?.cancel();
    super.dispose();
  }

  String _getCurrentDateStr() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  String _getCurrentMonthStr() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}";
  }

  void _checkAndResetDates(SharedPreferences prefs) {
    final currentDate = _getCurrentDateStr();
    final currentMonth = _getCurrentMonthStr();

    bool changed = false;

    if (_todayDate != currentDate) {
      _todayDate = currentDate;
      _todayBytes = 0;
      prefs.setString(_todayDateKey, currentDate);
      prefs.setInt(_todayBytesKey, 0);
      changed = true;
    }

    if (_monthDate != currentMonth) {
      _monthDate = currentMonth;
      _monthBytes = 0;
      prefs.setString(_monthDateKey, currentMonth);
      prefs.setInt(_monthBytesKey, 0);
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  Future<void> addUsage(int dlDelta, int ulDelta) async {
    if (dlDelta <= 0 && ulDelta <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    
    _checkAndResetDates(prefs);

    int totalDelta = dlDelta + ulDelta;
    
    _todayBytes += totalDelta;
    _monthBytes += totalDelta;

    _dailyHistory[_todayDate] = _todayBytes;
    _monthlyHistory[_monthDate] = _monthBytes;

    if (_dailyHistory.length > 30) {
      final keys = _dailyHistory.keys.toList()..sort();
      _dailyHistory.remove(keys.first);
    }
    if (_monthlyHistory.length > 12) {
      final keys = _monthlyHistory.keys.toList()..sort();
      _monthlyHistory.remove(keys.first);
    }

    await prefs.setInt(_todayBytesKey, _todayBytes);
    await prefs.setInt(_monthBytesKey, _monthBytes);
    await prefs.setString(_dailyHistoryKey, jsonEncode(_dailyHistory));
    await prefs.setString(_monthlyHistoryKey, jsonEncode(_monthlyHistory));

    notifyListeners();
  }
}
