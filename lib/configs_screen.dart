
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config_manager.dart';
import 'advanced_edit_screen.dart';
import 'vpn_service.dart';
import 'utils/ping_tester.dart';
import 'utils/vpn_uri_parser.dart';

class ConfigsScreen extends StatefulWidget {
  const ConfigsScreen({super.key});

  @override
  State<ConfigsScreen> createState() => _ConfigsScreenState();
}

class _ConfigsScreenState extends State<ConfigsScreen> {
  final ConfigManager _manager = ConfigManager.instance;
  
  Map<String, int> _pingResults = {};
  bool _isTestingPings = false;

  Future<void> _testAllPings() async {
    if (!_canModifyConfig()) return;
    if (_isTestingPings || _manager.configs.isEmpty) return;
    setState(() {
      _isTestingPings = true;
      _pingResults.clear();
    });

    final configs = _manager.configs;
    for (var i = 0; i < configs.length; i += 3) {
      final batch = configs.skip(i).take(3);
      await Future.wait(batch.map((config) async {
        try {
          final ping = await ZentrexVpnService.instance.getRealPing(config.url);
          if (mounted) {
            setState(() {
              _pingResults[config.id] = ping;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _pingResults[config.id] = -1;
            });
          }
        }
      }));
    }

    if (mounted) {
      await _manager.sortConfigsByPing(_pingResults);
      setState(() {
        _isTestingPings = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _manager.addListener(_refresh);
  }

  @override
  void dispose() {
    _manager.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool _canModifyConfig() {
    if (ZentrexVpnService.instance.currentStatus != "DISCONNECTED") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF131A2A),
          content: Text('Please disconnect the VPN first.',
              style: GoogleFonts.inter(color: Colors.redAccent)),
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _importFromClipboard() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    if (data == null || data.text == null || data.text!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard is empty')),
      );
      return;
    }

    final text = data.text!.trim();
    bool isJson = text.startsWith('{') && text.endsWith('}');

    if (!isJson &&
        !text.startsWith('vless://') &&
        !text.startsWith('vmess://') &&
        !text.startsWith('trojan://')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Invalid config URI or JSON in clipboard')),
      );
      return;
    }

    try {
      String protocol;
      String name;

      if (isJson) {
        // Basic JSON validation
        final map = jsonDecode(text);
        protocol = 'JSON';
        name = map['remarks'] ?? 'Imported JSON Config';
      } else {
        final uri = Uri.parse(text);
        protocol = uri.scheme.toUpperCase();
        name = Uri.decodeFull(uri.fragment.replaceAll('+', ' '));
        if (name.isEmpty) name = 'Imported $protocol Config';
      }

      final newConfig = VpnConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        url: text, // Store raw JSON string or the standard URL
        protocol: protocol,
        addedAt: DateTime.now(),
      );

      await _manager.addConfig(newConfig);
      _refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $name')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to parse config')),
      );
    }
  }

  void _deleteConfig(VpnConfig config) {
    if (!_canModifyConfig()) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Delete Config',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${config.name}"?',
            style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: const Color(0xFF00E5FF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _manager.removeConfig(config.id);
              _refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted ${config.name}')));
            },
            child: Text('Delete',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(VpnConfig config) async {
    if (!_canModifyConfig()) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdvancedEditScreen(config: config),
      ),
    );

    if (result == true) {
      _refresh();
    }
  }

  Widget _buildPingBadge(int ping) {
    Color color;
    String text;
    if (ping == -1) {
      color = Colors.redAccent;
      text = 'Timeout';
    } else if (ping < 150) {
      color = const Color(0xFF00E676);
      text = '${ping}ms';
    } else if (ping < 300) {
      color = Colors.orangeAccent;
      text = '${ping}ms';
    } else {
      color = Colors.redAccent;
      text = '${ping}ms';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flash_on_rounded, color: color, size: 12),
        const SizedBox(width: 2),
        Text(text, style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final configs = _manager.configs;
    final activeConfig = _manager.activeConfig;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72.0),
        child: FloatingActionButton.extended(
          onPressed: _testAllPings,
          backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.15),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
        ),
        icon: _isTestingPings
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF00E5FF)))
            : const Icon(Icons.speed_rounded,
                color: Color(0xFF00E5FF), size: 20),
        label: Text(
          _isTestingPings ? 'Testing...' : 'Test Pings',
          style: GoogleFonts.inter(
            color: const Color(0xFF00E5FF),
            fontWeight: FontWeight.w600,
          ),
        ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Configurations',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: _importFromClipboard,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.paste_rounded,
                                  color: Color(0xFF00E5FF), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Import',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF00E5FF),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: configs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_rounded,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          Text(
                            'No configs saved yet',
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                          left: 20, right: 20, bottom: 100),
                      itemCount: configs.length,
                      itemBuilder: (context, index) {
                        final config = configs[index];
                        final isActive = activeConfig?.id == config.id;

                        return Dismissible(
                          key: Key(config.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.centerRight,
                            child: const Icon(Icons.delete_outline,
                                color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            return _canModifyConfig();
                          },
                          onDismissed: (_) {
                            _manager.removeConfig(config.id);
                            _refresh();
                          },
                          child: GestureDetector(
                            onTap: () {
                              if (!_canModifyConfig()) return;
                              _manager.setActiveConfig(config.id);
                              _refresh();
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF131A2A),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isActive
                                      ? const Color(0xFF00E5FF)
                                      : Colors.white.withValues(alpha: 0.05),
                                  width: isActive ? 1.5 : 1.0,
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF00E5FF)
                                              .withValues(alpha: 0.15),
                                          blurRadius: 15,
                                          spreadRadius: 2,
                                        )
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.cyanAccent
                                              .withValues(alpha: 0.2)
                                          : Colors.white.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isActive
                                          ? Icons.check_circle_rounded
                                          : Icons.public_rounded,
                                      color: isActive
                                          ? const Color(0xFF00E5FF)
                                          : Colors.white38,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          config.name,
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                config.protocol,
                                                style: GoogleFonts.inter(
                                                  color: Colors.white70,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                            if (_pingResults.containsKey(config.id))
                                              _buildPingBadge(_pingResults[config.id]!),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert_rounded,
                                        color: Colors.white
                                            .withValues(alpha: 0.5)),
                                    color: const Color(0xFF1E293B),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditDialog(config);
                                      } else if (value == 'delete') {
                                        _deleteConfig(config);
                                      } else if (value == 'copy') {
                                        Clipboard.setData(ClipboardData(text: config.url));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: const Color(0xFF131A2A),
                                            content: Text('Copied to clipboard', style: GoogleFonts.inter(color: const Color(0xFF00E676))),
                                          ),
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.edit_rounded,
                                                color: Color(0xFF00E5FF),
                                                size: 18),
                                            const SizedBox(width: 12),
                                            Text('Edit',
                                                style: GoogleFonts.inter(
                                                    color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'copy',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.copy_rounded,
                                                color: Color(0xFF00E676),
                                                size: 18),
                                            const SizedBox(width: 12),
                                            Text('Copy',
                                                style: GoogleFonts.inter(
                                                    color: const Color(0xFF00E676))),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.delete_rounded,
                                                color: Colors.redAccent,
                                                size: 18),
                                            const SizedBox(width: 12),
                                            Text('Delete',
                                                style: GoogleFonts.inter(
                                                    color: Colors.redAccent)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
