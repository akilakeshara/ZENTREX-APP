import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ConnectionButton extends StatelessWidget {
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onTap;
  final Animation<double> pulseAnimation;

  const ConnectionButton({
    super.key,
    required this.isConnected,
    required this.isConnecting,
    required this.onTap,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: ScaleTransition(
          scale: pulseAnimation,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF131A2A),
              border: Border.all(
                color: (isConnected ? const Color(0xFF00E676) : const Color(0xFF00E5FF)).withValues(alpha: 0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isConnected
                          ? const Color(0xFF00E676)
                          : const Color(0xFF00E5FF))
                      .withValues(
                          alpha:
                              isConnecting ? 0.5 : 0.15),
                  blurRadius: isConnecting ? 50 : 25,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Center(
              child: SizedBox(
                width: 140,
                height: 140,
                child: Lottie.asset(
                  isConnected
                      ? 'assets/lottie/connected.json'
                      : (isConnecting
                          ? 'assets/lottie/connecting.json'
                          : 'assets/lottie/disconnected.json'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
