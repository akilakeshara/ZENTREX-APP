import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config_manager.dart';
import 'utils/vpn_uri_parser.dart';

class AdvancedEditScreen extends StatefulWidget {
  final VpnConfig config;

  const AdvancedEditScreen({super.key, required this.config});

  @override
  State<AdvancedEditScreen> createState() => _AdvancedEditScreenState();
}

class _AdvancedEditScreenState extends State<AdvancedEditScreen> {
  late VpnParameters _params;
  bool _isLoading = false;
  bool _isRawJson = false;

  final TextEditingController _rawJsonController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _sniController = TextEditingController();
  final TextEditingController _pbkController = TextEditingController();
  final TextEditingController _sidController = TextEditingController();
  final TextEditingController _spxController = TextEditingController();
  final TextEditingController _fpController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();
  final TextEditingController _hostController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _parseConfig();
  }

  void _parseConfig() {
    if (widget.config.protocol == 'JSON') {
      _isRawJson = true;
      _rawJsonController.text = widget.config.url;
      _params = VpnParameters(protocol: 'JSON', remarks: widget.config.name);
      return;
    }

    try {
      _params = VpnParameters.parse(widget.config.url);
      _remarksController.text =
          _params.remarks.isNotEmpty ? _params.remarks : widget.config.name;
      _addressController.text = _params.address;
      _portController.text = _params.port.toString();
      _idController.text = _params.id;
      _sniController.text = _params.sni;
      _pbkController.text = _params.publicKey;
      _sidController.text = _params.shortId;
      _spxController.text = _params.spiderX;
      _fpController.text = _params.fingerprint;
      _pathController.text = _params.path;
      _hostController.text = _params.host;
    } catch (e) {
      // Fallback
      _params = VpnParameters(
          protocol: widget.config.protocol, remarks: widget.config.name);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to parse URL completely.')));
    }
  }

  void _saveConfig() async {
    setState(() {
      _isLoading = true;
    });

    String newUrl;
    String newName;

    if (_isRawJson) {
      newUrl = _rawJsonController.text.trim();
      newName = widget.config.name;
    } else {
      _params.remarks = _remarksController.text.trim();
      _params.address = _addressController.text.trim();
      _params.port = int.tryParse(_portController.text.trim()) ?? 443;
      _params.id = _idController.text.trim();
      _params.sni = _sniController.text.trim();
      _params.publicKey = _pbkController.text.trim();
      _params.shortId = _sidController.text.trim();
      _params.spiderX = _spxController.text.trim();
      _params.fingerprint = _fpController.text.trim();
      _params.path = _pathController.text.trim();
      _params.host = _hostController.text.trim();

      newUrl = _params.toUriString();
      newName = _params.remarks.isNotEmpty ? _params.remarks : 'Unnamed Config';
    }

    try {
      final updatedConfig = VpnConfig(
        id: widget.config.id,
        name: newName,
        url: newUrl,
        protocol: _params.protocol,
        addedAt: widget.config.addedAt,
      );

      await ConfigManager.instance.updateConfig(updatedConfig);

      if (mounted) {
        Navigator.pop(context, true); // Return true to signal refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save config: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            style: GoogleFonts.inter(
                color: const Color(0xFF00E5FF),
                fontSize: 14,
                fontWeight: FontWeight.w600),
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF131A2A),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items,
      Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF131A2A),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value.isEmpty ? items.first : value,
                isExpanded: true,
                dropdownColor: const Color(0xFF131A2A),
                icon: const Icon(Icons.unfold_more_rounded,
                    color: Color(0xFF00E5FF)),
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                          color: const Color(0xFF00E5FF),
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E17),
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Config: ${_params.protocol}',
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Color(0xFF00E5FF), strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveConfig,
              child: Text(
                'Save',
                style: GoogleFonts.inter(
                    color: const Color(0xFF00E5FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: _isRawJson
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Raw JSON Configuration',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _rawJsonController,
                    style: GoogleFonts.robotoMono(
                        color: const Color(0xFF00E5FF), fontSize: 12),
                    maxLines: 20,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.2),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF00E5FF), width: 1.5),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField('Remarks', _remarksController),
                  _buildTextField('Address', _addressController),
                  _buildTextField('Port', _portController, isNumber: true),
                  _buildTextField('ID (UUID / Password)', _idController),
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 8),
                  _buildDropdown(
                      'Network',
                      _params.network.isEmpty ? 'tcp' : _params.network,
                      ['tcp', 'ws', 'grpc', 'h2'], (val) {
                    if (val != null) setState(() => _params.network = val);
                  }),
                  _buildDropdown(
                      'Security (TLS)',
                      _params.security.isEmpty ? 'none' : _params.security,
                      ['none', 'tls', 'reality'], (val) {
                    if (val != null) setState(() => _params.security = val);
                  }),
                  _buildDropdown(
                      'Encryption',
                      _params.encryption.isEmpty ? 'none' : _params.encryption,
                      ['none', 'auto', 'aes-128-gcm', 'chacha20-poly1305'],
                      (val) {
                    if (val != null) setState(() => _params.encryption = val);
                  }),
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 8),
                  _buildTextField('SNI', _sniController),
                  _buildTextField('Fingerprint (fp)', _fpController),
                  if (_params.security == 'reality') ...[
                    _buildTextField('PublicKey (pbk)', _pbkController),
                    _buildTextField('ShortId (sid)', _sidController),
                    _buildTextField('SpiderX (spx)', _spxController),
                  ],
                  if (_params.network == 'ws' || _params.network == 'grpc') ...[
                    _buildTextField('Path', _pathController),
                    _buildTextField('Host', _hostController),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
      ),
    );
  }
}
