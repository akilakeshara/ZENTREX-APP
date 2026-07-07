import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'data_usage_manager.dart';

class DataUsageScreen extends StatefulWidget {
  const DataUsageScreen({super.key});

  @override
  State<DataUsageScreen> createState() => _DataUsageScreenState();
}

class _DataUsageScreenState extends State<DataUsageScreen> {
  bool _isDailyView = true;

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final manager = DataUsageManager.instance;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
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
                    'Statistics',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  _buildToggle(),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: manager,
                builder: (context, _) {
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8).copyWith(bottom: 120),
                    children: [
                      _buildMainStatCard(
                        title: _isDailyView ? "Today's Usage" : "This Month's Usage",
                        value: _formatBytes(_isDailyView ? manager.todayBytes : manager.monthBytes),
                        icon: _isDailyView ? Icons.today_rounded : Icons.calendar_month_rounded,
                        gradientColors: _isDailyView 
                            ? [const Color(0xFF00E676), const Color(0xFF1DE9B6)]
                            : [const Color(0xFF7000FF), const Color(0xFF00E5FF)],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        _isDailyView ? 'Last 7 Days' : 'Last 6 Months',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _BarChart(
                        data: _isDailyView ? manager.dailyHistory : manager.monthlyHistory,
                        isDaily: _isDailyView,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            title: 'Daily',
            isActive: _isDailyView,
            onTap: () => setState(() => _isDailyView = true),
          ),
          _buildToggleButton(
            title: 'Monthly',
            isActive: !_isDailyView,
            onTap: () => setState(() => _isDailyView = false),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({required String title, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            color: isActive ? Colors.white : Colors.white54,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMainStatCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuint,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: gradientColors.map((c) => c.withValues(alpha: 0.2)).toList(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(icon, color: gradientColors.last, size: 32),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final Map<String, int> data;
  final bool isDaily;

  const _BarChart({required this.data, required this.isDaily});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    List<String> keys = [];
    
    if (isDaily) {
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        keys.add("${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}");
      }
    } else {
      for (int i = 5; i >= 0; i--) {
        int year = now.year;
        int month = now.month - i;
        while (month <= 0) {
          month += 12;
          year -= 1;
        }
        keys.add("${year}-${month.toString().padLeft(2, '0')}");
      }
    }

    List<int> values = keys.map((k) => data[k] ?? 0).toList();
    int maxVal = values.fold(0, max);
    if (maxVal == 0) maxVal = 1; // avoid division by zero

    return Container(
      height: 260,
      padding: const EdgeInsets.only(top: 24, bottom: 16, left: 8, right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: SizedBox(
          key: ValueKey(isDaily),
          width: double.infinity,
          height: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(keys.length, (index) {
          final fraction = values[index] / maxVal;
          final height = fraction * 140; 
          
          String label = '';
          if (isDaily) {
            final parts = keys[index].split('-');
            final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            label = DateFormat('EEE').format(dt); 
          } else {
            final parts = keys[index].split('-');
            final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
            label = DateFormat('MMM').format(dt); 
          }

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
              if (values[index] > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatCompact(values[index]),
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                width: isDaily ? 24 : 32,
                height: height > 0 ? (height < 4 ? 4 : height) : 0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDaily 
                        ? [const Color(0xFF00E676), const Color(0xFF1DE9B6)]
                        : [const Color(0xFF7000FF), const Color(0xFF00E5FF)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    if (height > 0)
                      BoxShadow(
                        color: (isDaily ? const Color(0xFF00E676) : const Color(0xFF00E5FF)).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, -2),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: index == keys.length - 1 ? Colors.white : Colors.white54,
                  fontSize: 12,
                  fontWeight: index == keys.length - 1 ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
        }),
          ),
        ),
      ),
    );
  }

  String _formatCompact(int bytes) {
    if (bytes == 0) return '';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()}K';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}M';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}G';
  }
}
