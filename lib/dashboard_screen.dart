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

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final ZentrexVpnService _vpnService = ZentrexVpnService.instance;

  bool _isConnected = false;
  bool _isConnecting = false;
  bool _hasMeasuredInitialPing = false;

  // High-frequency updating stats
  final ValueNotifier<int> _ping = ValueNotifier<int>(0);
  final ValueNotifier<bool> _isPinging = ValueNotifier<bool>(false);
  final ValueNotifier<int> _uploadBytes = ValueNotifier<int>(0);
  final ValueNotifier<int> _downloadBytes = ValueNotifier<int>(0);
  final ValueNotifier<String> _sessionDuration =
      ValueNotifier<String>('00:00:00');
  final ValueNotifier<int> _appMemBytes = ValueNotifier<int>(0);

  Timer? _memTimer;
  StreamSubscription? _vpnStatusSub;
  static const _memoryChannel = MethodChannel('com.zentrex/memory');

  // Animation for the connect button pulsing
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initVpn();
    _fetchMemory();
    _memTimer =
        Timer.periodic(const Duration(seconds: 3), (_) => _fetchMemory());
  }

  Future<void> _fetchMemory() async {
    try {
      final Map<Object?, Object?> result =
          await _memoryChannel.invokeMethod('getMemoryInfo');
      if (mounted) {
        _appMemBytes.value = (result['appTotalMem'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _memTimer?.cancel();
    _vpnStatusSub?.cancel();
    _pulseController.dispose();

    _ping.dispose();
    _isPinging.dispose();
    _uploadBytes.dispose();
    _downloadBytes.dispose();
    _sessionDuration.dispose();
    _appMemBytes.dispose();
    super.dispose();
  }

  Future<void> _initVpn() async {
    await _vpnService.initialize();
    _vpnStatusSub = _vpnService.v2rayStatusStream.listen((status) {
      if (!mounted) return;

      bool newIsConnected = status.state == "CONNECTED";
      bool newIsConnecting =
          status.state == "DISCONNECTED" ? false : _isConnecting;

      // Handle button pulsing
      if (newIsConnected || newIsConnecting) {
        if (!_pulseController.isAnimating)
          _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.value = 1.0;
      }

      if (_isConnected != newIsConnected || _isConnecting != newIsConnecting) {
        setState(() {
          _isConnected = newIsConnected;
          _isConnecting = newIsConnecting;
        });
      }

      _uploadBytes.value = status.upload;
      _downloadBytes.value = status.download;
      _sessionDuration.value = status.duration;

      if (newIsConnected && !_hasMeasuredInitialPing) {
        _hasMeasuredInitialPing = true;
        _measurePing();
      } else if (!newIsConnected) {
        _ping.value = 0;
        _hasMeasuredInitialPing = false;
      }
    });
  }

  Future<void> _toggleConnection() async {
    final activeConfig = ConfigManager.instance.activeConfig;

    if (_isConnected) {
      await _vpnService.disconnect();
    } else {
      if (activeConfig == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF131A2A),
            content: Text('Please select a config from the Configs page!',
                style: GoogleFonts.inter(color: const Color(0xFF00E5FF))),
          ),
        );
        return;
      }
      setState(() {
        _isConnecting = true;
      });
      bool success =
          await _vpnService.connect(activeConfig.url, activeConfig.name);
      if (!success) {
        if (mounted) {
          setState(() {
            _isConnecting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF131A2A),
              content: Text('Failed to connect. Check configuration.',
                  style: GoogleFonts.inter(color: Colors.redAccent)),
            ),
          );
        }
      }
    }
  }

  Future<void> _measurePing() async {
    if (!_isConnected || _isPinging.value) return;
    _isPinging.value = true;
    int ping = await _vpnService.getPing();
    if (mounted) {
      _ping.value = ping;
      _isPinging.value = false;
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

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17), // Deep Space Black
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
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
                  const SizedBox(height: 4),
                  Text(
                    'Advanced Network',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF00E5FF),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListenableBuilder(
                  listenable: ConfigManager.instance,
                  builder: (context, _) {
                    final activeConfig = ConfigManager.instance.activeConfig;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Connect Button with RepaintBoundary and ScaleTransition
                          RepaintBoundary(
                            child: GestureDetector(
                              onTap: _toggleConnection,
                              child: ScaleTransition(
                                scale: _pulseAnimation,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: _isConnected
                                          ? [
                                              const Color(0xFF00E676),
                                              const Color(0xFF1DE9B6)
                                            ] // Emerald glow
                                          : [
                                              const Color(0xFF00E5FF),
                                              const Color(0xFF7000FF)
                                            ], // Cyberpunk Cyan/Purple
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isConnected
                                                ? const Color(0xFF00E676)
                                                : const Color(0xFF00E5FF))
                                            .withValues(
                                                alpha:
                                                    _isConnecting ? 0.6 : 0.4),
                                        blurRadius: _isConnecting ? 40 : 30,
                                        spreadRadius: 5,
                                      )
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _isConnected
                                          ? Icons.power_settings_new
                                          : Icons.rocket_launch_rounded,
                                      size: 56,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Status Text
                          Text(
                            _isConnected
                                ? 'CONNECTED'
                                : (_isConnecting
                                    ? 'CONNECTING...'
                                    : 'DISCONNECTED'),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 2.0,
                              color: _isConnected
                                  ? const Color(0xFF00E676)
                                  : Colors.white54,
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

                          // Reserve fixed height space for session duration to prevent layout jumping
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 20,
                            child: _isConnected
                                ? ValueListenableBuilder<String>(
                                    valueListenable: _sessionDuration,
                                    builder: (context, duration, _) {
                                      return Text(
                                        'Session Duration: $duration',
                                        style: GoogleFonts.inter(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      );
                                    },
                                  )
                                : const SizedBox.shrink(),
                          ),

                          const SizedBox(height: 36),

                          // Metrics Grid
                          Row(
                            children: [
                              Expanded(
                                child: _buildGridCard(
                                    Icons.public_rounded,
                                    'Address',
                                    _extractHost(activeConfig?.url ?? ''),
                                    Colors.blueAccent),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildGridCard(
                                    Icons.security_rounded,
                                    'Protocol',
                                    activeConfig?.protocol ?? 'Unknown',
                                    Colors.pinkAccent),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ValueListenableBuilder<int>(
                                    valueListenable: _downloadBytes,
                                    builder: (context, dl, _) {
                                      return _buildGridCard(
                                          Icons.arrow_downward_rounded,
                                          'Download',
                                          _formatBytes(dl),
                                          const Color(0xFF00E5FF));
                                    }),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ValueListenableBuilder<int>(
                                    valueListenable: _uploadBytes,
                                    builder: (context, ul, _) {
                                      return _buildGridCard(
                                          Icons.arrow_upward_rounded,
                                          'Upload',
                                          _formatBytes(ul),
                                          const Color(0xFF7000FF));
                                    }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _measurePing,
                                  borderRadius: BorderRadius.circular(20),
                                  child: ValueListenableBuilder<bool>(
                                      valueListenable: _isPinging,
                                      builder: (context, isPinging, _) {
                                        return ValueListenableBuilder<int>(
                                            valueListenable: _ping,
                                            builder: (context, pingValue, _) {
                                              return _buildGridCard(
                                                Icons.network_ping_rounded,
                                                'Ping',
                                                !_isConnected
                                                    ? 'Offline'
                                                    : (isPinging
                                                        ? 'Wait..'
                                                        : (pingValue > 0
                                                            ? '${pingValue}ms'
                                                            : 'Tap')),
                                                _isConnected && pingValue > 0
                                                    ? const Color(0xFF00E676)
                                                    : Colors.white54,
                                              );
                                            });
                                      }),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ValueListenableBuilder<int>(
                                    valueListenable: _appMemBytes,
                                    builder: (context, memValue, _) {
                                      return _buildGridCard(
                                          Icons.memory_rounded,
                                          'App RAM',
                                          _formatBytes(memValue),
                                          Colors.orangeAccent);
                                    }),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(
      IconData icon, String label, String value, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2A), // Elevated dark blue
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
