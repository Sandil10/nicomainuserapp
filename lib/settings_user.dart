import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'profile_settings.dart';
import 'legal_settings.dart';
import 'orders_payments.dart';
import 'app_localization.dart';
import 'app_notification.dart'; // ✅ Import app_notification

class SettingsUser extends StatefulWidget {
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;

  const SettingsUser({
    super.key,
    required this.darkMode,
    required this.onDarkModeChanged,
  });

  @override
  State<SettingsUser> createState() => _SettingsUserState();
}

class _SettingsUserState extends State<SettingsUser> {
  bool _isLoading = false;
  bool _isInitialized = false;

  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _initializeComponent();
  }

  Future<void> _initializeComponent() async {
    // Ensure AppLocalization is initialized
    await AppLocalization.initialize();

    _loadUserData();

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          setState(() {
            _userData = doc.data()!;
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  String get _displayName {
    final user = FirebaseAuth.instance.currentUser;
    if (_userData?['username']?.toString().isNotEmpty == true) {
      return _userData!['username'].toString();
    }
    if (user?.displayName?.isNotEmpty == true) {
      return user!.displayName!;
    }
    if (user?.email?.isNotEmpty == true) {
      return _extractNameFromEmail(user!.email!);
    }
    return AppLocalization.getText('user');
  }

  String _extractNameFromEmail(String email) {
    if (email.isEmpty) return AppLocalization.getText('user');
    final namePart = email.split('@').first;
    return namePart
        .replaceAll(RegExp(r'[._]'), ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ');
  }

  Future<void> _signOutUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ValueListenableBuilder<String>(
        valueListenable: AppLocalization.currentLanguage,
        builder: (context, languageCode, child) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.logout_rounded,
                        color: Colors.grey.shade600, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalization.getText('signOutTitle'),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalization.getText('signOutConfirmation'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey.shade600, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(AppLocalization.getText('cancel'),
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade800,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(AppLocalization.getText('signOut'),
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted)
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } catch (e) {
        if (mounted)
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    }
  }

  Widget _buildSettingsCard(
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color iconColor,
      required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: iconColor, size: 22)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
                Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.arrow_forward_ios,
                        color: Color(0xFF6B7280), size: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountActionCard(
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color iconColor,
      required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: iconColor, size: 22)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: iconColor)),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: iconColor.withOpacity(0.6), size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4A22A8),
          ),
        ),
      );
    }

    return ValueListenableBuilder<String>(
      valueListenable: AppLocalization.currentLanguage,
      builder: (context, currentLanguage, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section with Gradient
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFF4A22A8), Color(0xFF8E6AE8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 15,
                            offset: Offset(0, 8))
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2)),
                            child: Center(
                                child: Text(
                                    _displayName.isNotEmpty
                                        ? _displayName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white))),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppLocalization.getText('settingsTitle'),
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                                const SizedBox(height: 4),
                                Text(
                                    AppLocalization.getText(
                                        'manageAccountSettings'),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xDDFFFFFF),
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Settings Options
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile & Account
                        _buildSettingsCard(
                          title: AppLocalization.getText('profileAccount'),
                          subtitle: AppLocalization.getText('editPersonalInfo'),
                          icon: Icons.person_outline,
                          iconColor: const Color(0xFF4A22A8),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ProfileSettings(
                                      userData: _userData,
                                      onSuccess: (msg) => showAppNotification(
                                            title: AppLocalization.getText(
                                                'success'),
                                            message: msg,
                                            type: NotificationType.success,
                                          ),
                                      onError: (msg) => showAppNotification(
                                            title: AppLocalization.getText(
                                                'error'),
                                            message: msg,
                                            type: NotificationType.error,
                                          )))),
                        ),

                        // Orders & Payments
                        _buildSettingsCard(
                          title: AppLocalization.getText('ordersPayments'),
                          subtitle:
                              AppLocalization.getText('viewHistoryMethods'),
                          icon: Icons.receipt_long_outlined,
                          iconColor: const Color(0xFFEA580C),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => OrdersPayments())),
                        ),

                        // Legal & Privacy
                        _buildSettingsCard(
                          title: AppLocalization.getText('legalPrivacy'),
                          subtitle:
                              AppLocalization.getText('termsPrivacyPolicy'),
                          icon: Icons.gavel_outlined,
                          iconColor: const Color(0xFF7C3AED),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LegalSettings())),
                        ),

                        const SizedBox(height: 20),

                        // Sign Out Action
                        _buildAccountActionCard(
                          title: AppLocalization.getText('signOut'),
                          subtitle: AppLocalization.getText('signOutAccount'),
                          icon: Icons.logout_outlined,
                          iconColor: const Color(0xFFDC2626),
                          onTap: _signOutUser,
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
