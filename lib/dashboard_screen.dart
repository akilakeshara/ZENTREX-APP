import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'vpn_service.dart';
import 'config_manager.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ZentrexVpnService _vpnService = ZentrexVpnService.instance;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isPinging = false;
  bool _hasMeasuredInitialPing = false;
  int _ping = 0;
  
  // Traffic & Memory Stats
  int _uploadBytes = 0;
  int _downloadBytes = 0;
  String _sessionDuration = '00:00:00';
  int _appMemBytes = 0;
  int _deviceTotalMemBytes = 0;
  int _deviceAvailMemBytes = 0;
  
  Timer? _memTimer;
  static const _memoryChannel = MethodChannel('com.zentrex/memory');

  @override
  void initState() {
    super.initState();
    _initVpn();
    _fetchMemory();
    _memTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchMemory());
  }

  Future<void> _fetchMemory() async {
    try {
      final Map<Object?, Object?> result = await _memoryChannel.invokeMethod('getMemoryInfo');
      if (mounted) {
        setState(() {
          _deviceTotalMemBytes = (result['deviceTotalMem'] as num?)?.toInt() ?? 0;
          _deviceAvailMemBytes = (result['deviceAvailMem'] as num?)?.toInt() ?? 0;
          _appMemBytes = (result['appTotalMem'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _memTimer?.cancel();
    super.dispose();
  }

  Future<void> _initVpn() async {
    await _vpnService.initialize();
    _vpnService.v2rayStatusStream.listen((status) {
      if (!mounted) return;
      setState(() {
        _isConnected = status.state == "CONNECTED";
        if (status.state == "DISCONNECTED") {
          _isConnecting = false;
        }

        _uploadBytes = status.upload;
        _downloadBytes = status.download;
        _sessionDuration = status.duration;

        if (_isConnected) {
          _isConnecting = false;
          // Measure ping once on connect, user can tap to refresh manually
          if (!_hasMeasuredInitialPing) {
            _hasMeasuredInitialPing = true;
            _measurePing();
          }
        } else {
          _ping = 0;
          _hasMeasuredInitialPing = false;
        }
      });
    });
  }

  Future<void> _toggleConnection() async {
    final activeConfig = ConfigManager.instance.activeConfig;
    
    if (_isConnected) {
      await _vpnService.disconnect();
    } else {
      if (activeConfig == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a config from the Configs page!')),
        );
        return;
      }
      setState(() {
        _isConnecting = true;
      });
      bool success = await _vpnService.connect(activeConfig.url, activeConfig.name);
      if (!success) {
        setState(() {
          _isConnecting = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to connect. Check configuration.')),
          );
        }
      }
    }
  }

  Future<void> _measurePing() async {
    if (!_isConnected || _isPinging) return;
    if (mounted) {
      setState(() {
        _isPinging = true;
      });
    }
    int ping = await _vpnService.getPing();
    if (mounted) {
      setState(() {
        _ping = ping;
        _isPinging = false;
      });
    }
  }

  String _extractHost(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (_) {
      return "Unknown";
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeConfig = ConfigManager.instance.activeConfig;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ZENTREX',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                  Text(
                    'Advanced Network',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Connect Button
                    GestureDetector(
                      onTap: _toggleConnection,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _isConnected
                                ? [Colors.redAccent, Colors.deepOrange]
                                : [Colors.cyanAccent, Colors.blueAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isConnected ? Colors.redAccent : Colors.cyanAccent)
                                  .withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _isConnected ? Icons.power_settings_new : Icons.rocket_launch_rounded,
                            size: 56,
                            color: _isConnected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Status Text
                    Text(
                      _isConnected
                          ? 'CONNECTED'
                          : (_isConnecting ? 'CONNECTING...' : 'DISCONNECTED'),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 2.0,
                        color: _isConnected ? Colors.greenAccent : Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activeConfig?.name ?? 'No Config Selected',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_isConnected) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Session Duration: $_sessionDuration',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Unified Metrics Hub
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        children: [
                          _buildMetricRow(
                            Icons.public, 'Address', _extractHost(activeConfig?.url ?? ''), Colors.blueAccent,
                            Icons.security, 'Protocol', activeConfig?.protocol ?? 'Unknown', Colors.pinkAccent,
                          ),
                          Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                          _buildMetricRow(
                            Icons.arrow_downward_rounded, 'Download', _formatBytes(_downloadBytes), Colors.cyanAccent,
                            Icons.arrow_upward_rounded, 'Upload', _formatBytes(_uploadBytes), Colors.purpleAccent,
                          ),
                          Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                          InkWell(
                            onTap: _measurePing,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                            child: _buildMetricRow(
                              Icons.network_ping, 'Ping', 
                              !_isConnected ? 'Offline' : (_isPinging ? 'Wait..' : (_ping > 0 ? '${_ping}ms' : 'Tap')),
                              _isConnected && _ping > 0 ? Colors.greenAccent : Colors.white70,
                              Icons.memory, 'App RAM', _formatBytes(_appMemBytes), Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Widget _buildMetricRow(IconData icon1, String label1, String val1, Color color1,
                         IconData icon2, String label2, String val2, Color color2) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(child: _buildMetricItem(icon1, label1, val1, color1)),
          Container(
            height: 40,
            width: 1,
            color: Colors.white.withValues(alpha: 0.05),
          ),
          const SizedBox(width: 20),
          Expanded(child: _buildMetricItem(icon2, label2, val2, color2)),
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
