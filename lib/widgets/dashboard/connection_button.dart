import 'package:flutter/material.dart';

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
            width: 150,
            height: 150,
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: isConnecting
                    ? const SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Color(0xFF00E5FF),
                        ),
                      )
                    : Icon(
                        Icons.power_settings_new_rounded,
                        key: ValueKey<bool>(isConnected),
                        size: 64,
                        color: isConnected ? const Color(0xFF00E676) : const Color(0xFF00E5FF),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
