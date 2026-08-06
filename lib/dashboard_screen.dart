import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'vpn_service.dart';
import 'config_manager.dart';

import 'widgets/dashboard/dashboard_header.dart';
import 'widgets/dashboard/connection_button.dart';
import 'widgets/dashboard/metrics_grid.dart';

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

      if (newIsConnected || newIsConnecting) {
        if (!_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17), // Deep Space Black
      body: SafeArea(
        child: Column(
          children: [
            const DashboardHeader(),
            Expanded(
              child: ListenableBuilder(
                  listenable: ConfigManager.instance,
                  builder: (context, _) {
                    final activeConfig = ConfigManager.instance.activeConfig;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ConnectionButton(
                                    isConnected: _isConnected,
                                    isConnecting: _isConnecting,
                                    onTap: _toggleConnection,
                                    pulseAnimation: _pulseAnimation,
                                  ),
                                  const SizedBox(height: 24),
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
                                  MetricsGrid(
                                    activeConfig: activeConfig,
                                    downloadBytesListenable: _downloadBytes,
                                    uploadBytesListenable: _uploadBytes,
                                    pingListenable: _ping,
                                    isPingingListenable: _isPinging,
                                    appMemBytesListenable: _appMemBytes,
                                    isConnected: _isConnected,
                                    onPingTap: _measurePing,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
