import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../app_notification.dart';
import 'app_localization.dart';
import 'password_change.dart';

class ProfileSettings extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final Function(String) onSuccess;
  final Function(String) onError;

  const ProfileSettings({
    Key? key,
    this.userData,
    required this.onSuccess,
    required this.onError,
  }) : super(key: key);

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings>
    with SingleTickerProviderStateMixin {
  // Theme colors matching SocialLoginScreen
  static const Color primaryPurple = Color(0xFF4A22A8);
  static const Color accentPurple = Color(0xFF8E6AE8);
  static const Color labelGray = Color(0xFF3C3C3C);
  static const Color textGray = Color(0xFF2A2A2A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  String _selectedCountryCode = '+94';
  User? _cachedUser;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ✅ FIX: Store gender keys (not translated values)
  static const String GENDER_MALE = 'male';
  static const String GENDER_FEMALE = 'female';
  static const String GENDER_OTHER = 'other';
  static const String GENDER_PREFER_NOT = 'prefer_not_to_say';

  // ✅ Get translated gender options
  List<Map<String, String>> get _genderOptions => [
        {'key': GENDER_MALE, 'label': AppLocalization.getText('male')},
        {'key': GENDER_FEMALE, 'label': AppLocalization.getText('female')},
        {'key': GENDER_OTHER, 'label': AppLocalization.getText('other')},
        {
          'key': GENDER_PREFER_NOT,
          'label': AppLocalization.getText('preferNotToSay')
        },
      ];

  @override
  void initState() {
    super.initState();
    _cachedUser = FirebaseAuth.instance.currentUser;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadUserDataFast();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDataFast() async {
    if (widget.userData != null && widget.userData!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _userData = widget.userData;
        });
      }
      return;
    }

    if (_cachedUser != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_cachedUser!.uid)
            .get()
            .timeout(const Duration(seconds: 3));

        if (mounted) {
          setState(() {
            _userData = userDoc.exists ? userDoc.data() : {};
          });
        }
      } catch (e) {
        print('Load error: $e');
        if (mounted) {
          setState(() {
            _userData = {};
          });
        }
      }
    }
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

  String get _displayName {
    if (_userData?['name']?.toString().isNotEmpty == true) {
      return _userData!['name'].toString();
    }
    if (_userData?['username']?.toString().isNotEmpty == true) {
      return _userData!['username'].toString();
    }
    if (_cachedUser?.displayName?.isNotEmpty == true) {
      return _cachedUser!.displayName!;
    }
    if (_cachedUser?.email?.isNotEmpty == true) {
      return _extractNameFromEmail(_cachedUser!.email!);
    }
    return AppLocalization.getText('user');
  }

  String get _displayEmail {
    if (_userData?['email']?.toString().isNotEmpty == true) {
      return _userData!['email'].toString();
    }
    return _cachedUser?.email ?? AppLocalization.getText('noEmail');
  }

  String get _displayPhone {
    if (_userData?['phone']?.toString().isNotEmpty == true) {
      return _userData!['phone'].toString();
    }
    if (_userData?['phoneNumber']?.toString().isNotEmpty == true) {
      return _userData!['phoneNumber'].toString();
    }
    if (_userData?['defaultDeliveryDetails']?['phone']?.toString().isNotEmpty ==
        true) {
      return _userData!['defaultDeliveryDetails']['phone'].toString();
    }
    return AppLocalization.getText('addPhoneNumber');
  }

  // ✅ FIX: Translate gender key to display label
  String get _displayGender {
    final savedGender = _userData?['gender']?.toString();
    if (savedGender == null || savedGender.isEmpty) {
      return AppLocalization.getText('selectGender');
    }

    // Convert stored key to translated label
    switch (savedGender.toLowerCase()) {
      case GENDER_MALE:
      case 'male':
        return AppLocalization.getText('male');
      case GENDER_FEMALE:
      case 'female':
        return AppLocalization.getText('female');
      case GENDER_OTHER:
      case 'other':
        return AppLocalization.getText('other');
      case GENDER_PREFER_NOT:
      case 'prefer not to say':
      case 'prefer_not_to_say':
        return AppLocalization.getText('preferNotToSay');
      default:
        return AppLocalization.getText('selectGender');
    }
  }

  bool get _isGoogleAccount {
    return _cachedUser?.providerData
            .any((provider) => provider.providerId == 'google.com') ??
        false;
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      showAppNotification(
        title: AppLocalization.getText('error'),
        message: AppLocalization.getText('couldNotOpenUrl',
            params: {'url': urlString}),
        type: NotificationType.error,
      );
    }
  }

  void _editField(String field, String title, String currentValue,
      {bool isPhone = false, bool isGender = false}) {
    if (isGender) {
      _showGenderEditModal(field, title, currentValue);
      return;
    }

    final controller = TextEditingController(
        text: isPhone
            ? _extractPhoneNumber(currentValue)
            : (currentValue.contains('Add') || currentValue.contains('Select'))
                ? ''
                : currentValue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalization.getText('editName',
                        params: {'field': title}),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isPhone) ...{
                    Row(
                      children: [
                        Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: accentPurple, width: 2),
                            borderRadius: BorderRadius.circular(30),
                            color: white,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🇱🇰', style: TextStyle(fontSize: 22)),
                              SizedBox(width: 8),
                              Text('+94',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: textGray)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildEditTextField(
                              controller,
                              AppLocalization.getText('phoneNumberLabel'),
                              Icons.phone_outlined,
                              keyboardType: TextInputType.phone),
                        ),
                      ],
                    ),
                  } else
                    _buildEditTextField(
                        controller, title, Icons.person_outline),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed:
                              isSaving ? null : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFFF3F4F6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text(
                            AppLocalization.getText('cancel'),
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  setModalState(() => isSaving = true);
                                  try {
                                    await _saveField(
                                        field, controller.text, isPhone);
                                    if (mounted) Navigator.pop(modalContext);
                                  } catch (e) {
                                    print('Save failed: $e');
                                  } finally {
                                    if (mounted)
                                      setModalState(() => isSaving = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSaving ? white : primaryPurple,
                            foregroundColor: isSaving ? primaryPurple : white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            elevation: 0,
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          primaryPurple)),
                                )
                              : Text(AppLocalization.getText('save'),
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ✅ FIX: Gender modal with proper key/label handling
  void _showGenderEditModal(String field, String title, String currentValue) {
    // Get current gender key from stored value
    String selectedGenderKey = '';
    if (_userData?['gender']?.toString().isNotEmpty == true) {
      final storedGender = _userData!['gender'].toString().toLowerCase();
      if (storedGender == GENDER_MALE || storedGender == 'male') {
        selectedGenderKey = GENDER_MALE;
      } else if (storedGender == GENDER_FEMALE || storedGender == 'female') {
        selectedGenderKey = GENDER_FEMALE;
      } else if (storedGender == GENDER_OTHER || storedGender == 'other') {
        selectedGenderKey = GENDER_OTHER;
      } else if (storedGender == GENDER_PREFER_NOT ||
          storedGender == 'prefer not to say' ||
          storedGender == 'prefer_not_to_say') {
        selectedGenderKey = GENDER_PREFER_NOT;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                color: white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalization.getText('editName',
                        params: {'field': title}),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: accentPurple, width: 2),
                      borderRadius: BorderRadius.circular(30),
                      color: white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedGenderKey.isEmpty
                            ? null
                            : selectedGenderKey,
                        hint: Row(
                          children: [
                            const Icon(Icons.wc_outlined,
                                color: Color(0xFF9CA3AF), size: 22),
                            const SizedBox(width: 12),
                            Text(
                              AppLocalization.getText('selectGender'),
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: primaryPurple, size: 24),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textGray,
                        ),
                        items: _genderOptions.map((genderMap) {
                          return DropdownMenuItem<String>(
                            value: genderMap['key']!,
                            child: Row(
                              children: [
                                const Icon(Icons.wc_outlined,
                                    color: primaryPurple, size: 22),
                                const SizedBox(width: 12),
                                Text(genderMap['label']!),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setModalState(
                              () => selectedGenderKey = newValue ?? '');
                        },
                        isExpanded: true,
                        dropdownColor: white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed:
                              isSaving ? null : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFFF3F4F6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text(
                            AppLocalization.getText('cancel'),
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (selectedGenderKey.isEmpty) {
                                    showAppNotification(
                                      title: AppLocalization.getText('error'),
                                      message: AppLocalization.getText(
                                          'pleaseSelectGender'),
                                      type: NotificationType.error,
                                    );
                                    return;
                                  }
                                  setModalState(() => isSaving = true);
                                  try {
                                    // Save gender key (not translated label)
                                    await _saveField(
                                        field, selectedGenderKey, false);
                                    if (mounted) Navigator.pop(modalContext);
                                  } catch (e) {
                                    print('Gender save failed: $e');
                                  } finally {
                                    if (mounted)
                                      setModalState(() => isSaving = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSaving ? white : primaryPurple,
                            foregroundColor: isSaving ? primaryPurple : white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            elevation: 0,
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          primaryPurple)),
                                )
                              : Text(AppLocalization.getText('save'),
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEditTextField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType? keyboardType}) {
    return Container(
      height: 56,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType ?? TextInputType.text,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w500, color: textGray),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w400),
          prefixIcon: Icon(icon, color: primaryPurple, size: 22),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: accentPurple, width: 2)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: accentPurple, width: 2)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: accentPurple, width: 2.5)),
          filled: true,
          fillColor: white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  String _extractPhoneNumber(String fullPhone) {
    if (fullPhone == AppLocalization.getText('addPhoneNumber')) return '';
    if (fullPhone.startsWith('+94')) {
      return fullPhone.substring(3).trim();
    }
    return fullPhone;
  }

  Future<void> _saveField(String field, String value, bool isPhone) async {
    if (_cachedUser == null) {
      showAppNotification(
        title: AppLocalization.getText('error'),
        message: AppLocalization.getText('userNotFound'),
        type: NotificationType.error,
      );
      return;
    }

    try {
      String finalValue = value.trim();

      if (isPhone && finalValue.isNotEmpty) {
        finalValue = '+94' + finalValue.replaceAll(' ', '');
      }

      if (finalValue.isEmpty &&
          !['phoneNumber', 'phone', 'gender'].contains(field)) {
        showAppNotification(
          title: AppLocalization.getText('error'),
          message: AppLocalization.getText('pleaseEnterValidValue'),
          type: NotificationType.error,
        );
        return;
      }

      String phoneFieldName = isPhone ? 'phone' : field;
      Map<String, dynamic> updateData = {
        phoneFieldName: finalValue,
        'updatedAt': FieldValue.serverTimestamp()
      };

      if (field == 'username' && finalValue.isNotEmpty) {
        updateData['name'] = finalValue;
        try {
          await _cachedUser!.updateDisplayName(finalValue);
        } catch (e) {
          print('Display name update warning: $e');
        }
      }

      if (isPhone && finalValue.isNotEmpty) {
        updateData['countryCode'] = '+94';
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_cachedUser!.uid)
          .get();

      if (userDoc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_cachedUser!.uid)
            .update(updateData);
      } else {
        updateData['createdAt'] = FieldValue.serverTimestamp();
        updateData['email'] = _cachedUser!.email;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_cachedUser!.uid)
            .set(updateData);
      }

      if (mounted) {
        setState(() {
          if (_userData == null) {
            _userData = {};
          }
          _userData![phoneFieldName] = finalValue;
          if (field == 'username') {
            _userData!['name'] = finalValue;
          }
          if (isPhone && finalValue.isNotEmpty) {
            _userData!['countryCode'] = '+94';
          }
        });
      }

      showAppNotification(
        title: AppLocalization.getText('success'),
        message: AppLocalization.getText('updatedSuccessfully'),
        type: NotificationType.success,
      );
    } catch (e) {
      print('Save field error: $e');
      showAppNotification(
        title: AppLocalization.getText('error'),
        message: AppLocalization.getText('updateFailed'),
        type: NotificationType.error,
      );
    }
  }

  void _showPasswordChangeDialog() {
    if (_isGoogleAccount) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(AppLocalization.getText('googleAccountTitle'),
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          content: Text(
            AppLocalization.getText('googleAccountMessage'),
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalization.getText('cancel'),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _launchUrl('https://myaccount.google.com/');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(AppLocalization.getText('openGoogleAccount'),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: white)),
            ),
          ],
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PasswordChangeScreen(),
        ),
      );
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalization.getText('deleteAccountTitle'),
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: Colors.red)),
        content: Text(
          AppLocalization.getText('deleteAccountConfirmation'),
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalization.getText('cancel'),
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount();
            },
            child: Text(AppLocalization.getText('delete'),
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    if (_cachedUser == null) return;

    final overlay = OverlayEntry(
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryPurple),
        ),
      ),
    );
    Overlay.of(context).insert(overlay);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_cachedUser!.uid)
          .delete();
      await _cachedUser!.delete();

      showAppNotification(
        title: AppLocalization.getText('success'),
        message: AppLocalization.getText('accountDeletedSuccessfully'),
        type: NotificationType.success,
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      showAppNotification(
        title: AppLocalization.getText('error'),
        message: AppLocalization.getText('accountDeleteFailed'),
        type: NotificationType.error,
      );
    } finally {
      overlay.remove();
    }
  }

  Widget _buildProfileOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isReadOnly = false,
    bool isDestructive = false,
    bool showDivider = true,
  }) {
    final iconColor = isDestructive
        ? Colors.red
        : (isReadOnly ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280));
    final titleColor = isDestructive
        ? Colors.red
        : (isReadOnly ? const Color(0xFF9CA3AF) : const Color(0xFF1F2937));

    return Column(
      children: [
        InkWell(
          onTap: isReadOnly ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.red.shade50
                        : (isReadOnly
                            ? const Color(0xFFF3F4F6)
                            : const Color(0xFFF3F4F6)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isReadOnly)
                  const Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: Color(0xFF9CA3AF),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isDestructive ? Colors.red : const Color(0xFF9CA3AF),
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: const Color(0xFFE5E5E5),
            indent: 72,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalization.currentLanguage,
      builder: (context, currentLanguage, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF5F5F5),
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF374151),
                size: 20,
              ),
            ),
            title: Text(
              AppLocalization.getText('profileSettingsTitle'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
                letterSpacing: -0.2,
              ),
            ),
            centerTitle: false,
          ),
          body: _isLoading
              ? const Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryPurple),
                    ),
                  ),
                )
              : SafeArea(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          // Profile Header Section
                          Container(
                            color: const Color(0xFFF5F5F5),
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFE5E5E5),
                                    border: Border.all(
                                      color: const Color(0xFFD1D5DB),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _displayName.isNotEmpty
                                          ? _displayName[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _displayName,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF1F2937),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          InkWell(
                                            onTap: () => _editField('username',
                                                'Name', _displayName),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE5E5E5),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.edit_outlined,
                                                size: 18,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        AppLocalization.getText(
                                            'basicInformation'),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Profile Options Card
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE5E5E5),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildProfileOptionTile(
                                  title:
                                      AppLocalization.getText('fullNameLabel'),
                                  subtitle: _displayName,
                                  icon: Icons.person_outline,
                                  onTap: () => _editField(
                                      'username',
                                      AppLocalization.getText('fullNameLabel'),
                                      _displayName),
                                  showDivider: true,
                                ),
                                _buildProfileOptionTile(
                                  title: AppLocalization.getText(
                                      'phoneNumberLabel'),
                                  subtitle: _displayPhone,
                                  icon: Icons.phone_outlined,
                                  onTap: () {},
                                  isReadOnly: true,
                                  showDivider: true,
                                ),
                                _buildProfileOptionTile(
                                  title:
                                      AppLocalization.getText('emailAddress'),
                                  subtitle: _displayEmail,
                                  icon: Icons.email_outlined,
                                  onTap: () {},
                                  isReadOnly: true,
                                  showDivider: true,
                                ),
                                _buildProfileOptionTile(
                                  title: AppLocalization.getText('gender'),
                                  subtitle: _displayGender,
                                  icon: Icons.wc_outlined,
                                  onTap: () => _editField(
                                      'gender',
                                      AppLocalization.getText('gender'),
                                      _displayGender,
                                      isGender: true),
                                  showDivider: true,
                                ),
                                _buildProfileOptionTile(
                                  title:
                                      AppLocalization.getText('changePassword'),
                                  subtitle: AppLocalization.getText(
                                      'updatePasswordSecurely'),
                                  icon: Icons.lock_outline,
                                  onTap: _showPasswordChangeDialog,
                                  showDivider: false,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Delete Account Card
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE5E5E5),
                                width: 1,
                              ),
                            ),
                            child: _buildProfileOptionTile(
                              title: AppLocalization.getText('deleteAccount'),
                              subtitle: AppLocalization.getText(
                                  'permanentlyDeleteAccount'),
                              icon: Icons.delete_outline,
                              onTap: _showDeleteAccountDialog,
                              isDestructive: true,
                              showDivider: false,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Version & Region Info
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Sri Lanka ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    Text(
                                      '🇱🇰',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'App Version 1.0.0',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
