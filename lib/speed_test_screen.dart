import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'utils/speed_tester.dart';
import 'dart:async';

class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> with TickerProviderStateMixin {
  final SpeedTester _speedTester = SpeedTester();
  StreamSubscription<SpeedTestState>? _subscription;

  SpeedTestState _currentState = SpeedTestState(stage: SpeedTestStage.idle);
  final List<FlSpot> _downloadSpots = [];
  final List<FlSpot> _uploadSpots = [];
  double _timeCounter = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _speedTester.cancelTest();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTest() {
    setState(() {
      _downloadSpots.clear();
      _uploadSpots.clear();
      _timeCounter = 0;
      _currentState = SpeedTestState(stage: SpeedTestStage.pinging);
    });
    
    _pulseController.repeat(reverse: true);

    _subscription = _speedTester.startTest().listen((state) {
      if (!mounted) return;
      setState(() {
        _currentState = state;
        _timeCounter += 0.1;
        
        if (state.stage == SpeedTestStage.downloading) {
          _downloadSpots.add(FlSpot(_timeCounter, state.downloadMbps));
        } else if (state.stage == SpeedTestStage.uploading) {
          // Continue X axis from where download left off
          _uploadSpots.add(FlSpot(_timeCounter, state.uploadMbps));
        } else if (state.stage == SpeedTestStage.finished || state.stage == SpeedTestStage.error) {
          _pulseController.stop();
          _pulseController.value = 1.0;
        }
      });
    });
  }

  void _stopTest() {
    _speedTester.cancelTest();
    _subscription?.cancel();
    _pulseController.stop();
    _pulseController.value = 1.0;
    setState(() {
      _currentState = _currentState.copyWith(stage: SpeedTestStage.idle);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'SPEED TEST',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2.0,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Graph Section
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131A2A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: _buildGraph(),
                ),
              ),
              const SizedBox(height: 32),
              
              // Metrics Section
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Ping',
                      _currentState.pingMs > 0 ? '${_currentState.pingMs.toStringAsFixed(0)} ms' : '--',
                      Icons.network_ping_rounded,
                      const Color(0xFF00E676),
                      _currentState.stage == SpeedTestStage.pinging,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Download',
                      _currentState.downloadMbps > 0 ? '${_currentState.downloadMbps.toStringAsFixed(1)} Mbps' : '--',
                      Icons.arrow_downward_rounded,
                      const Color(0xFF00E5FF),
                      _currentState.stage == SpeedTestStage.downloading,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Upload',
                      _currentState.uploadMbps > 0 ? '${_currentState.uploadMbps.toStringAsFixed(1)} Mbps' : '--',
                      Icons.arrow_upward_rounded,
                      const Color(0xFF7000FF),
                      _currentState.stage == SpeedTestStage.uploading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              
              // Action Button Section
              Expanded(
                flex: 1,
                child: Center(
                  child: _buildActionButton(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGraph() {
    if (_downloadSpots.isEmpty && _uploadSpots.isEmpty) {
      return Center(
        child: Text(
          'Start test to see network graph',
          style: GoogleFonts.inter(color: Colors.white38),
        ),
      );
    }

    double maxY = 10.0;
    for (var spot in _downloadSpots) {
      if (spot.y > maxY) maxY = spot.y;
    }
    for (var spot in _uploadSpots) {
      if (spot.y > maxY) maxY = spot.y;
    }
    maxY = maxY * 1.2; // Add 20% headroom

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        minX: 0,
        maxX: _timeCounter > 10 ? _timeCounter : 10,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5 > 0 ? maxY / 5 : 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          if (_downloadSpots.isNotEmpty)
            LineChartBarData(
              spots: _downloadSpots,
              isCurved: true,
              color: const Color(0xFF00E5FF),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
              ),
            ),
          if (_uploadSpots.isNotEmpty)
            LineChartBarData(
              spots: _uploadSpots,
              isCurved: true,
              color: const Color(0xFF7000FF),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF7000FF).withValues(alpha: 0.2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, bool isAnimated) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAnimated ? color : Colors.white.withValues(alpha: 0.05),
          width: isAnimated ? 1.5 : 1.0,
        ),
        boxShadow: isAnimated ? [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 2,
          )
        ] : [],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    bool isRunning = _currentState.stage != SpeedTestStage.idle && _currentState.stage != SpeedTestStage.finished && _currentState.stage != SpeedTestStage.error;
    
    if (_currentState.stage == SpeedTestStage.error) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _currentState.errorMessage ?? 'Error',
            style: GoogleFonts.inter(color: Colors.redAccent),
          ),
          const SizedBox(height: 16),
          _buildGoButton('RETRY', _startTest),
        ],
      );
    }

    if (isRunning) {
      return ScaleTransition(
        scale: _pulseAnimation,
        child: GestureDetector(
          onTap: _stopTest,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF131A2A),
              border: Border.all(color: Colors.redAccent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Center(
              child: Text(
                'STOP',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return _buildGoButton(_currentState.stage == SpeedTestStage.finished ? 'AGAIN' : 'GO', _startTest);
  }

  Widget _buildGoButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFF7000FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 5,
            )
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ),
    );
  }
}
