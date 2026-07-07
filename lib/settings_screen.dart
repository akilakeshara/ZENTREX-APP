import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsManager _manager = SettingsManager.instance;
  
  // Controllers for DNS
  late TextEditingController _primaryDnsController;
  late TextEditingController _secondaryDnsController;

  @override
  void initState() {
    super.initState();
    _primaryDnsController = TextEditingController(text: _manager.primaryDns);
    _secondaryDnsController = TextEditingController(text: _manager.secondaryDns);
  }

  @override
  void dispose() {
    _primaryDnsController.dispose();
    _secondaryDnsController.dispose();
    super.dispose();
  }
  
  void _saveDns() {
    _manager.setPrimaryDns(_primaryDnsController.text.trim());
    _manager.setSecondaryDns(_secondaryDnsController.text.trim());
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF131A2A),
        content: Text('DNS Servers updated.', style: GoogleFonts.inter(color: const Color(0xFF00E5FF))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Settings',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _manager,
                builder: (context, _) {
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8).copyWith(bottom: 120),
                    children: [
                      _buildSectionHeader('NETWORK', Icons.language_rounded),
                      const SizedBox(height: 12),
                      _buildSettingsCard(
                        children: [
                          _buildTextField('Primary DNS', _primaryDnsController),
                          const SizedBox(height: 12),
                          _buildTextField('Secondary DNS', _secondaryDnsController),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                                foregroundColor: const Color(0xFF00E5FF),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                                ),
                              ),
                              onPressed: _saveDns,
                              child: Text('Save DNS', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('CORE SETTINGS', Icons.settings_suggest_rounded),
                      const SizedBox(height: 12),
                      _buildSettingsCard(
                        children: [
                          _buildSwitch(
                            title: 'Enable Sniffing',
                            subtitle: 'Sniff domain from traffic to enhance routing.',
                            value: _manager.enableSniffing,
                            onChanged: (val) => _manager.setEnableSniffing(val),
                          ),
                          _buildDivider(),
                          _buildSwitch(
                            title: 'Multiplexing (Mux)',
                            subtitle: 'Reuse TCP connections to reduce latency.',
                            value: _manager.enableMux,
                            onChanged: (val) => _manager.setEnableMux(val),
                          ),
                          if (_manager.enableMux) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Concurrency',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [8, 16, 32].map((value) {
                                final isSelected = _manager.muxConcurrency == value;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () => _manager.setMuxConcurrency(value),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                                            : Colors.black.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF00E5FF)
                                              : Colors.transparent,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$value',
                                        style: GoogleFonts.inter(
                                          color: isSelected
                                              ? const Color(0xFF00E5FF)
                                              : Colors.white54,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          _buildDivider(),
                          _buildSwitch(
                            title: 'Bypass LAN',
                            subtitle: 'Bypass private/local IPs (e.g. 192.168.x.x).',
                            value: _manager.bypassLan,
                            onChanged: (val) => _manager.setBypassLan(val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('SECURITY', Icons.security_rounded),
                      const SizedBox(height: 12),
                      _buildSettingsCard(
                        children: [
                          _buildSwitch(
                            title: 'Allow Insecure (Global)',
                            subtitle: 'Override configs to allow untrusted certificates.',
                            value: _manager.allowInsecure,
                            onChanged: (val) => _manager.setAllowInsecure(val),
                            isWarning: true,
                          ),
                        ],
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00E5FF), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            color: const Color(0xFF00E5FF),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.2),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isWarning = false,
  }) {
    final activeColor = isWarning ? Colors.redAccent : const Color(0xFF00E5FF);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: activeColor,
          activeTrackColor: activeColor.withValues(alpha: 0.3),
          inactiveTrackColor: Colors.black.withValues(alpha: 0.3),
        ),
      ],
    );
  }
}
