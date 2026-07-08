import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesSettings extends StatefulWidget {
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;

  const PreferencesSettings({
    super.key,
    required this.darkMode,
    required this.onDarkModeChanged,
  });

  @override
  State<PreferencesSettings> createState() => _PreferencesSettingsState();
}

class _PreferencesSettingsState extends State<PreferencesSettings> {
  bool _isLoading = false;
  String _selectedLanguage = 'en';
  OverlayEntry? _overlayEntry;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'it', 'name': 'Sri Lankano', 'flag': '🇱🇰'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          _selectedLanguage = doc.data()!['language'] ?? 'en';
        }
      }
    } catch (e) {
      print('Error loading preferences: $e');
      _selectedLanguage = 'en';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ NEW: Show compact bottom popup notification
  void _showBottomPopupNotification({
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).padding.bottom + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 100, end: 0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: Opacity(
                  opacity: (100 - value) / 100,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    // Auto dismiss after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _savePreferences(String code) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'language': code}, SetOptions(merge: true));
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', code);
      if (mounted) setState(() => _selectedLanguage = code);

      // Show compact bottom popup notification
      if (code == 'it') {
        _showBottomPopupNotification(
          message: '🇱🇰 Lingua impostata su Sri Lankano',
          backgroundColor: const Color(0xFF8E6AE8),
          icon: Icons.check_circle_rounded,
        );
      } else {
        _showBottomPopupNotification(
          message: '🇺🇸 Language set to English',
          backgroundColor: const Color(0xFF8E6AE8),
          icon: Icons.check_circle_rounded,
        );
      }
    } catch (e) {
      print('Error saving preferences: $e');

      // Show error notification
      if (_selectedLanguage == 'it') {
        _showBottomPopupNotification(
          message: 'Impossibile cambiare lingua',
          backgroundColor: const Color(0xFFEF4444),
          icon: Icons.error_rounded,
        );
      } else {
        _showBottomPopupNotification(
          message: 'Failed to change language',
          backgroundColor: const Color(0xFFEF4444),
          icon: Icons.error_rounded,
        );
      }
    }
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      backgroundColor: Colors.white,
      builder: (BuildContext modalContext) {
        return SafeBottomSheet(
          selectedLanguage: _selectedLanguage,
          languages: _languages,
          onLanguageChanged: (String code) {
            Navigator.pop(modalContext);
            if (_selectedLanguage != code) {
              _savePreferences(code);
            }
          },
        );
      },
    );
  }

  Widget _buildPreferenceItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF6B7280),
                    size: 14,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  String get _selectedLanguageName =>
      _languages.firstWhere((l) => l['code'] == _selectedLanguage,
          orElse: () => _languages.first)['name']!;
  String get _selectedLanguageFlag =>
      _languages.firstWhere((l) => l['code'] == _selectedLanguage,
          orElse: () => _languages.first)['flag']!;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF8E6AE8)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios,
                color: Color(0xFF8E6AE8), size: 20)),
        title: Text(
          _selectedLanguage == 'it' ? 'Preferenze' : 'Preferences',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8E6AE8).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.language_outlined,
                                color: Color(0xFF8E6AE8), size: 16),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _selectedLanguage == 'it'
                                ? 'Lingua e Regione'
                                : 'Language & Region',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildPreferenceItem(
                      title: _selectedLanguage == 'it' ? 'Lingua' : 'Language',
                      subtitle: '$_selectedLanguageFlag $_selectedLanguageName',
                      icon: Icons.translate_outlined,
                      iconColor: const Color(0xFF8E6AE8),
                      onTap: _showLanguageSelector,
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class SafeBottomSheet extends StatelessWidget {
  final String selectedLanguage;
  final List<Map<String, String>> languages;
  final Function(String) onLanguageChanged;

  const SafeBottomSheet({
    super.key,
    required this.selectedLanguage,
    required this.languages,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            selectedLanguage == 'it' ? 'Seleziona Lingua' : 'Select Language',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          ...languages.map((lang) {
            return ListTile(
              leading:
                  Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
              title: Text(lang['name']!,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A))),
              trailing: selectedLanguage == lang['code']
                  ? const Icon(Icons.check_circle,
                      color: Color(0xFF8E6AE8), size: 24)
                  : null,
              onTap: () => onLanguageChanged(lang['code']!),
            );
          }).toList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
