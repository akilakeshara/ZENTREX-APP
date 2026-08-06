import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConfigsHeader extends StatelessWidget {
  final VoidCallback onImport;

  const ConfigsHeader({super.key, required this.onImport});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                onTap: onImport,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
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
    );
  }
}
