import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'vpn_service.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final ZentrexVpnService _vpnService = ZentrexVpnService.instance;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<String> _logs = [];
  List<String> _filteredLogs = [];
  bool _isLoading = true;
  String _searchQuery = "";
  Timer? _refreshTimer;
  StreamSubscription? _vpnStatusSub;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
    
    // Poll fast for live feeling
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _fetchLogs());

    // Instant update on state change
    _vpnStatusSub = _vpnService.v2rayStatusStream.listen((status) {
      if (mounted) _fetchLogs();
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _applyFilter();
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _vpnStatusSub?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    final logs = await _vpnService.getLogs();
    if (mounted) {
      setState(() {
        _logs = logs;
        _applyFilter();
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _applyFilter() {
    List<String> tempLogs = [];
    bool hideTraffic = false;

    for (String log in _logs) {
      final lowerLog = log.toLowerCase();
      
      // Ignore harmless native package logs that confuse the user
      if (lowerLog.contains('stopcore failed') || lowerLog.contains('stopcore success')) {
        continue;
      }

      bool isSuccess = lowerLog.contains('success') || lowerLog.contains('connected');
      bool isStopLog = lowerLog.contains('stop') || lowerLog.contains('disconnect') || lowerLog.contains('close');

      if (!hideTraffic) {
        tempLogs.add(log);
        if (isSuccess) {
          hideTraffic = true;
        }
      } else {
        // If traffic is hidden, only show stop/disconnect messages
        if (isStopLog) {
          tempLogs.add(log);
        }
      }
    }

    if (_searchQuery.isEmpty) {
      _filteredLogs = tempLogs;
    } else {
      _filteredLogs = tempLogs
          .where((log) => log.toLowerCase().contains(_searchQuery))
          .toList();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _clearLogs() async {
    await _vpnService.clearLogs();
    setState(() {
      _logs.clear();
      _filteredLogs.clear();
    });
  }

  void _copyLogs() {
    final allLogs = _filteredLogs.join('\n');
    Clipboard.setData(ClipboardData(text: allLogs));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF131A2A),
        content: Text('Logs copied to clipboard',
            style: GoogleFonts.inter(color: const Color(0xFF00E5FF))),
      ),
    );
  }

  Color _getLogColor(String log) {
    final lowerLog = log.toLowerCase();
    if (lowerLog.contains('error') ||
        lowerLog.contains('exception') ||
        lowerLog.contains('failed')) {
      return Colors.redAccent;
    } else if (lowerLog.contains('warn')) {
      return Colors.orangeAccent;
    } else if (lowerLog.contains('success') || lowerLog.contains('connected')) {
      return const Color(0xFF00E676);
    } else if (lowerLog.contains('app:') || lowerLog.contains('core:')) {
      return const Color(0xFF00E5FF);
    }
    return Colors.white70;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17), // Deep Space Black
      body: SafeArea(
        child: Column(
          children: [
            // Header with title and quick actions
            Padding(
              padding: const EdgeInsets.only(
                  left: 24.0, right: 24.0, top: 16.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'System Logs',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_rounded,
                            color: Colors.white54),
                        tooltip: 'Clear Logs',
                        onPressed: _clearLogs,
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_all_rounded,
                            color: Color(0xFF00E5FF)),
                        tooltip: 'Copy Logs',
                        onPressed: _copyLogs,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search logs (e.g. error, tcp)...',
                  hintStyle: GoogleFonts.inter(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Colors.white54, size: 20),
                  filled: true,
                  fillColor: const Color(0xFF131A2A),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
                  ),
                ),
              ),
            ),

            // Log Viewer
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A2A),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: _isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFF00E5FF)),
                      )
                    : _filteredLogs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.terminal_rounded,
                                    size: 48,
                                    color: Colors.white.withValues(alpha: 0.2)),
                                const SizedBox(height: 12),
                                Text(
                                  'No logs found',
                                  style: GoogleFonts.inter(
                                      color: Colors.white38, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredLogs.length,
                            itemBuilder: (context, index) {
                              final log = _filteredLogs[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Text(
                                  log,
                                  style: GoogleFonts.robotoMono(
                                    fontSize: 11,
                                    color: _getLogColor(log),
                                    height: 1.3,
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
