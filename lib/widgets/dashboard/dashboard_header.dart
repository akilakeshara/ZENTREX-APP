import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../speed_test_screen.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox(width: double.infinity),
          Column(
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
          Positioned(
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.speed_rounded, color: Color(0xFF00E5FF), size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SpeedTestScreen()),
                );
              },
              tooltip: 'Speed Test',
            ),
          ),
        ],
      ),
    );
  }
}
