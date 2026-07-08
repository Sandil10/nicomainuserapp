import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Added the required imports
import 'app_notification.dart';
import 'app_localization.dart'; // Import the centralized localization
import 'user_panel.dart';

class SignUpScreen extends StatefulWidget {
  final String selectedLanguage;

  const SignUpScreen({Key? key, required this.selectedLanguage})
      : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // State variables
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSigningUp = false;

  // ===== PURPLE THEME TOKENS (only visual change) =====
  static const Color primaryPurple = Color(0xFF4A22A8);
  static const Color accentPurple = Color(0xFF6D43D1);
  static const Color lightPurple = Color(0xFF7E62C8);

  @override
  void initState() {
    super.initState();
    // Set initial language from parent screen
    AppLocalization.setLanguage(widget.selectedLanguage);

    // Pre-fill with Sri Lankan phone code (always +94 regardless of language)
    _phoneController.text = '+94 ';
  }

  /// Check if email already exists in Firestore
  Future<bool> _isEmailAlreadyRegistered(String email) async {
    if (email.isEmpty) return false; // Email is optional

    try {
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      return result.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  /// Check if phone number already exists in Firestore
  Future<bool> _isPhoneAlreadyRegistered(String phone) async {
    try {
      // ✅ Normalize phone before checking (remove ALL spaces)
      final String normalizedPhone = phone.trim().replaceAll(' ', '');

      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: normalizedPhone)
          .limit(1)
          .get();

      return result.docs.isNotEmpty;
    } catch (e) {
      print('Error checking phone: $e');
      return false;
    }
  }

  String _normalizedPhone(String phone) => phone.trim().replaceAll(' ', '');

  Future<QueryDocumentSnapshot?> _findExistingUser() async {
    return null;
  }

  Map<String, dynamic> _mergedRoles(Map<String, dynamic>? data, String role) {
    final existingRoles = Map<String, dynamic>.from(
      (data?['roles'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    existingRoles[role] = true;
    return existingRoles;
  }

  Future<void> _signUpWithPassword() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    // Always validate Sri Lankan phone number
    if (!_phoneController.text.startsWith('+94')) {
      showAppNotification(
        title: AppLocalization.getText('error'),
        message: AppLocalization.getText('phoneStartError'),
        type: NotificationType.error,
      );
      return;
    }

    setState(() => _isSigningUp = true);

    try {
      final emailForAuth = _emailController.text.trim().toLowerCase();
      UserCredential credential;

      try {
        credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailForAuth,
          password: _passwordController.text,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code != 'email-already-in-use') rethrow;
        credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailForAuth,
          password: _passwordController.text,
        );
      }

      final User? user = credential.user;
      if (user != null) {
        await Future.wait([
          user.updateDisplayName(_nameController.text.trim()),
          _saveUserDataToFirestore(user, emailForAuth, true),
        ]);

        showAppNotification(
          title: AppLocalization.getText('success'),
          message: AppLocalization.getText('accountCreated'),
          type: NotificationType.success,
        );

        // Navigate immediately to UserPanel
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => UserPanel()),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorKey;
      switch (e.code) {
        case 'weak-password':
          errorKey = 'weakPassword';
          break;
        case 'email-already-in-use':
          errorKey = 'emailInUse';
          break;
        case 'invalid-email':
          errorKey = 'invalidEmail';
          break;
        default:
          errorKey = 'signUpFailed';
      }
      showAppNotification(
        title: AppLocalization.getText('signUpError'),
        message: AppLocalization.getText(errorKey),
        type: NotificationType.error,
      );
    } catch (e) {
      showAppNotification(
        title: AppLocalization.getText('error'),
        message: AppLocalization.getText('unexpectedError'),
        type: NotificationType.error,
      );
    } finally {
      if (mounted) setState(() => _isSigningUp = false);
    }
  }

  Future<void> _saveUserDataToFirestore(
      User user, String actualEmail, bool isEmailProvided) async {
    final CollectionReference users =
        FirebaseFirestore.instance.collection('users');

    // ✅ CRITICAL FIX: Remove ALL spaces from phone number before saving
    final String normalizedPhone =
        _phoneController.text.trim().replaceAll(' ', '');
    final userDoc = users.doc(user.uid);
    final existingSnapshot = await userDoc.get();
    final existingData = existingSnapshot.exists
        ? existingSnapshot.data() as Map<String, dynamic>
        : null;

    print('🔍 DEBUG: Saving phone to Firestore: $normalizedPhone'); // Debug log

    await userDoc.set({
      'uid': user.uid,
      'name': _nameController.text.trim(),
      'email': actualEmail, // Always save the email used for authentication
      'phone': normalizedPhone, // ✅ Save as: +94718643655 (NO SPACES)
      'createdAt': existingData?['createdAt'] ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'profileImageUrl': existingData?['profileImageUrl'] ?? '',
      'isEmailProvided':
          isEmailProvided, // Track whether user provided their own email
      'countryCode': '+94', // Always Sri Lankan
      'country': 'SRILANKA', // Always SRILANKA
      'language': AppLocalization.languageCode,
      'user_category': existingData?['user_category'] ?? 'customer',
      'roles': _mergedRoles(existingData, 'customer'),
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final white = Colors.white;
    final footerGray = const Color(0xFF6F6F6F);

    return Scaffold(
      backgroundColor: white,
      body: ValueListenableBuilder<String>(
        valueListenable: AppLocalization.currentLanguage,
        builder: (context, languageCode, child) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ===== PURPLE GRADIENT HERO =====
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      top: MediaQuery.paddingOf(context).top + 12,
                      bottom: 30,
                      left: 24,
                      right: 24,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [primaryPurple, lightPurple],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(38),
                        bottomRight: Radius.circular(38),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: white.withOpacity(0.16),
                                ),
                                child: const Icon(Icons.arrow_back_ios_new,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                            _buildLanguageDisplay(),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          AppLocalization.getText('createAccount'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: white,
                              letterSpacing: -0.2),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppLocalization.getText('fillDetails'),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: white.withOpacity(0.85)),
                        ),
                      ],
                    ),
                  ),

                  // ===== FORM =====
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Name Field
                        _buildTextField(
                          controller: _nameController,
                          label: AppLocalization.getText('yourName'),
                          hint: AppLocalization.getText('nameHint'),
                          icon: Icons.person_outline,
                          validator: (value) => (value == null || value.isEmpty)
                              ? AppLocalization.getText('nameValidation')
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Email Field
                        _buildTextField(
                          controller: _emailController,
                          label: AppLocalization.getText('emailAddress'),
                          hint: AppLocalization.getText('emailHint'),
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty || !email.contains('@')) {
                              return AppLocalization.getText('emailValidation');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Phone Number Field (Required with Sri Lankan code)
                        _buildPhoneField(),
                        const SizedBox(height: 16),

                        // Password Field
                        _buildPasswordField(
                          controller: _passwordController,
                          label: AppLocalization.getText('password'),
                          hint: AppLocalization.getText('passwordHint'),
                          isObscured: _obscurePassword,
                          onToggleVisibility: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          validator: (value) =>
                              (value == null || value.length < 6)
                                  ? AppLocalization.getText(
                                      'passwordValidationLength')
                                  : null,
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password Field
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          label: AppLocalization.getText('confirmPassword'),
                          hint: AppLocalization.getText('confirmPasswordHint'),
                          isObscured: _obscureConfirmPassword,
                          onToggleVisibility: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                          validator: (value) =>
                              (value != _passwordController.text)
                                  ? AppLocalization.getText('passwordMismatch')
                                  : null,
                        ),
                        const SizedBox(height: 40),

                        // Sign Up Button with visible loading indicator
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed:
                                _isSigningUp ? null : _signUpWithPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryPurple,
                              foregroundColor: white,
                              elevation: 2,
                              disabledBackgroundColor:
                                  primaryPurple.withOpacity(0.7),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            child: _isSigningUp
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                        color: white,
                                        strokeWidth: 3.0,
                                        backgroundColor:
                                            primaryPurple.withOpacity(0.3)),
                                  )
                                : Text(
                                    AppLocalization.getText('signUp'),
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Sign In Link
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: footerGray),
                            children: [
                              TextSpan(
                                  text: AppLocalization.getText(
                                      'alreadyHaveAccount')),
                              TextSpan(
                                text: AppLocalization.getText('signInHere'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: primaryPurple,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.of(context).pop();
                                  },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguageDisplay() {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalization.currentLanguage,
      builder: (context, languageCode, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            languageCode == 'it' ? 'ITA' : 'ENG',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final labelGray = const Color(0xFF3C3C3C);
    final iconGray = const Color(0xFFA0A0A0);
    final textGray = const Color(0xFF2A2A2A);
    final white = Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: labelGray,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: textGray, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            prefixIcon: Icon(icon, color: iconGray, size: 20),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: primaryPurple, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: primaryPurple, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: primaryPurple, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            errorStyle: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    final theme = Theme.of(context);
    final labelGray = const Color(0xFF3C3C3C);
    final iconGray = const Color(0xFFA0A0A0);
    final textGray = const Color(0xFF2A2A2A);
    final white = Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalization.getText('phoneNumber'),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: labelGray,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: textGray, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            prefixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 16),
                const Text('🇱🇰', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Icon(Icons.phone_outlined, color: iconGray, size: 20),
                const SizedBox(width: 8),
              ],
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 88),
            filled: true,
            fillColor: white,
            hintText: AppLocalization.getText('phoneHintSignUp'),
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: primaryPurple, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: primaryPurple, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: primaryPurple, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            errorStyle: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalization.getText('phoneValidationRequired');
            }
            if (!value.startsWith('+94')) {
              return AppLocalization.getText('phoneStartValidation');
            }
            if (value.replaceAll(' ', '').length < 12) {
              return AppLocalization.getText('phoneValidValidation');
            }
            return null;
          },
          onChanged: (value) {
            // Ensure the user cannot delete the +94 prefix
            if (!value.startsWith('+94 ')) {
              _phoneController.text = '+94 ';
              _phoneController.selection = TextSelection.fromPosition(
                TextPosition(offset: _phoneController.text.length),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isObscured,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final labelGray = const Color(0xFF3C3C3C);
    final passwordIconGray = const Color(0xFF9E9E9E);
    final textGray = const Color(0xFF2A2A2A);
    final fieldGray = const Color(0xFFEFEEF4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: labelGray,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isObscured,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: textGray, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            prefixIcon:
                Icon(Icons.lock_outline, color: passwordIconGray, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                isObscured
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: passwordIconGray,
                size: 20,
              ),
              onPressed: onToggleVisibility,
            ),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: fieldGray,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            errorStyle: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
