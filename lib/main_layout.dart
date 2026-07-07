import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_screen.dart';
import 'configs_screen.dart';
import 'data_usage_screen.dart';
import 'logs_screen.dart';
import 'settings_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    ConfigsScreen(),
    DataUsageScreen(),
    LogsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      extendBody: true,
      bottomNavigationBar: RepaintBoundary(
        child: Container(
          margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A2A).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                ),
                child: MediaQuery.removePadding(
                  context: context,
                  removeBottom: true,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: BottomNavigationBar(
                      type: BottomNavigationBarType.fixed,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      selectedItemColor: const Color(0xFF00E5FF),
                      unselectedItemColor: Colors.white38,
                      selectedLabelStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, fontSize: 12),
                      unselectedLabelStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.w500, fontSize: 12),
                      currentIndex: _currentIndex,
                      onTap: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.dashboard_rounded),
                          label: 'Home',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.list_alt_rounded),
                          label: 'Configs',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.bar_chart_rounded),
                          label: 'Stats',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.terminal_rounded),
                          label: 'Logs',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.settings_rounded),
                          label: 'Settings',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
