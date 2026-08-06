import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config_manager.dart';

class MetricsGrid extends StatelessWidget {
  final VpnConfig? activeConfig;
  final ValueListenable<int> downloadBytesListenable;
  final ValueListenable<int> uploadBytesListenable;
  final ValueListenable<int> pingListenable;
  final ValueListenable<bool> isPingingListenable;
  final ValueListenable<int> appMemBytesListenable;
  final bool isConnected;
  final VoidCallback onPingTap;

  const MetricsGrid({
    super.key,
    required this.activeConfig,
    required this.downloadBytesListenable,
    required this.uploadBytesListenable,
    required this.pingListenable,
    required this.isPingingListenable,
    required this.appMemBytesListenable,
    required this.isConnected,
    required this.onPingTap,
  });

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
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Widget _buildGridCard(IconData icon, String label, String value, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2A),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                  valueListenable: downloadBytesListenable,
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
                  valueListenable: uploadBytesListenable,
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
                onTap: onPingTap,
                borderRadius: BorderRadius.circular(20),
                child: ValueListenableBuilder<bool>(
                    valueListenable: isPingingListenable,
                    builder: (context, isPinging, _) {
                      return ValueListenableBuilder<int>(
                          valueListenable: pingListenable,
                          builder: (context, pingValue, _) {
                            return _buildGridCard(
                              Icons.network_ping_rounded,
                              'Ping',
                              !isConnected
                                  ? 'Offline'
                                  : (isPinging
                                      ? 'Wait..'
                                      : (pingValue > 0
                                          ? '${pingValue}ms'
                                          : 'Tap')),
                              isConnected && pingValue > 0
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
                  valueListenable: appMemBytesListenable,
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
    );
  }
}
