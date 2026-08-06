import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config_manager.dart';

class ConfigListItem extends StatelessWidget {
  final VpnConfig config;
  final bool isActive;
  final int? ping;
  final Function(VpnConfig) onActivate;
  final Function(VpnConfig) onEdit;
  final Function(VpnConfig) onDelete;
  final Future<bool> Function(VpnConfig) confirmDismiss;
  final VoidCallback onDismissed;

  const ConfigListItem({
    super.key,
    required this.config,
    required this.isActive,
    required this.ping,
    required this.onActivate,
    required this.onEdit,
    required this.onDelete,
    required this.confirmDismiss,
    required this.onDismissed,
  });

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
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => confirmDismiss(config),
      onDismissed: (_) => onDismissed(),
      child: GestureDetector(
        onTap: () => onActivate(config),
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
                      ? Colors.cyanAccent.withValues(alpha: 0.2)
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
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
                        if (ping != null)
                          _buildPingBadge(ping!),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    color: Colors.white.withValues(alpha: 0.5)),
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit(config);
                  } else if (value == 'delete') {
                    onDelete(config);
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
                            color: Color(0xFF00E5FF), size: 18),
                        const SizedBox(width: 12),
                        Text('Edit',
                            style: GoogleFonts.inter(color: Colors.white)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'copy',
                    child: Row(
                      children: [
                        const Icon(Icons.copy_rounded,
                            color: Color(0xFF00E676), size: 18),
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
                            color: Colors.redAccent, size: 18),
                        const SizedBox(width: 12),
                        Text('Delete',
                            style: GoogleFonts.inter(color: Colors.redAccent)),
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
  }
}
