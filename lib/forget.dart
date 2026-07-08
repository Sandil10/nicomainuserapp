import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'app_notification.dart';
import 'app_localization.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeLocalization();
  }

  Future<void> _initializeLocalization() async {
    await AppLocalization.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  Future<bool> _checkEmailExistsInFirestore(String email) async => true;

  /// Check if email is a real email (not temp email like user@temp.com)
  bool _isRealEmail(String email) {
    final emailLower = email.toLowerCase().trim();
    // Check if it's a temporary email format
    return !emailLower.contains('@temp.com');
  }

  bool _looksLikePhone(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return cleaned.startsWith('+94') ||
        cleaned.startsWith('94') ||
        cleaned.startsWith('0');
  }

  String _normalizePhoneNumber(String input) {
    final cleanedInput = input.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (cleanedInput.startsWith('+94')) {
      return cleanedInput;
    }
    if (cleanedInput.startsWith('94')) {
      return '+$cleanedInput';
    }
    if (cleanedInput.startsWith('0')) {
      return '+94${cleanedInput.substring(1)}';
    }
    return '+94$cleanedInput';
  }

  Future<Map<String, dynamic>> _lookupAuthEmailByPhone(
      String phoneNumber) async {
    final callable = _functions.httpsCallable('lookupAuthEmailByPhone');
    final result = await callable.call<Map<String, dynamic>>({
      'phone': phoneNumber,
    });
    return Map<String, dynamic>.from(result.data);
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final rawInput = _emailController.text.trim();

    try {
      String email = rawInput.toLowerCase();
      String? maskedEmail;

      if (_looksLikePhone(rawInput)) {
        final lookup = await _lookupAuthEmailByPhone(
          _normalizePhoneNumber(rawInput),
        );
        email = (lookup['authEmail'] ?? '').toString().trim().toLowerCase();
        maskedEmail = (lookup['maskedEmail'] ?? '').toString().trim();
      }

      if (!_isRealEmail(email)) {
        if (mounted) {
          showAppNotification(
            title: AppLocalization.getText('error'),
            message: AppLocalization.getText('cannotResetTempEmail'),
            type: NotificationType.error,
          );
        }
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted) {
        showAppNotification(
          title: AppLocalization.getText('success'),
          message: maskedEmail != null && maskedEmail.isNotEmpty
              ? AppLocalization.getText(
                  'passwordResetEmailSentTo',
                  params: {'email': maskedEmail},
                )
              : AppLocalization.getText('passwordResetEmailSent'),
          type: NotificationType.success,
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
      return;

      // Step 1: Check if email exists in Firestore users collection
      print('🔍 Checking if email exists in Firestore: $email');
      final emailExists = await _checkEmailExistsInFirestore(email);

      if (!emailExists) {
        print('❌ Email not found in Firestore');
        if (mounted) {
          showAppNotification(
            title: AppLocalization.getText('error'),
            message: AppLocalization.getText('noAccountFoundEmail'),
            type: NotificationType.error,
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      print('✅ Email found in Firestore');

      // Step 2: Check if it's a real email (not temp email)
      if (!_isRealEmail(email)) {
        print('❌ Cannot send reset link to temporary email');
        if (mounted) {
          showAppNotification(
            title: AppLocalization.getText('error'),
            message: AppLocalization.getText('cannotResetTempEmail'),
            type: NotificationType.error,
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      print('✅ Valid email, sending password reset link...');

      // Step 3: Send Firebase password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      print('✅ Password reset email sent successfully');

      if (mounted) {
        showAppNotification(
          title: AppLocalization.getText('success'),
          message: AppLocalization.getText('passwordResetEmailSent'),
          type: NotificationType.success,
        );

        // Wait 2 seconds then navigate back
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } on FirebaseFunctionsException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'not-found':
          errorMessage = AppLocalization.getText('noAccountFoundPhone');
          break;
        case 'invalid-argument':
          errorMessage = AppLocalization.getText('phoneInvalidValidation');
          break;
        case 'failed-precondition':
          errorMessage = AppLocalization.getText('accountErrorContactSupport');
          break;
        default:
          errorMessage =
              e.message ?? AppLocalization.getText('failedToSendResetEmail');
      }

      if (mounted) {
        showAppNotification(
          title: AppLocalization.getText('error'),
          message: errorMessage,
          type: NotificationType.error,
        );
      }
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = AppLocalization.getText('noAccountFoundEmail');
          break;
        case 'invalid-email':
          errorMessage = AppLocalization.getText('invalidEmailError');
          break;
        case 'too-many-requests':
          errorMessage = AppLocalization.getText('tooManyRequests');
          break;
        default:
          errorMessage = AppLocalization.getText('failedToSendResetEmail');
      }

      if (mounted) {
        showAppNotification(
          title: AppLocalization.getText('error'),
          message: errorMessage,
          type: NotificationType.error,
        );
      }
    } catch (e) {
      print('❌ General Exception: $e');
      if (mounted) {
        showAppNotification(
          title: AppLocalization.getText('error'),
          message: AppLocalization.getText('unexpectedErrorOccurred'),
          type: NotificationType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF4A22A8);
    const Color accentPurple = Color(0xFF8E6AE8);
    const Color labelGray = Color(0xFF3C3C3C);
    const Color textGray = Color(0xFF2A2A2A);
    const Color white = Color(0xFFFFFFFF);
    const Color black = Color(0xFF000000);

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalization.getText('resetPasswordTitle'),
          style: const TextStyle(
            color: black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ValueListenableBuilder<String>(
            valueListenable: AppLocalization.currentLanguage,
            builder: (context, languageCode, child) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Info Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: accentPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: primaryPurple,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalization.getText('resetPasswordInfo'),
                              style: TextStyle(
                                color: textGray,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Email Or Phone Label
                    Text(
                      AppLocalization.getText('emailOrPhoneLabel'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: labelGray,
                          ),
                    ),

                    const SizedBox(height: 12),

                    // Email Or Phone Input Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [
                        AutofillHints.email,
                        AutofillHints.telephoneNumber,
                      ],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: textGray,
                          ),
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                        prefixIcon: const Icon(
                          Icons.alternate_email,
                          color: Color(0xFFA0A0A0),
                          size: 20,
                        ),
                        hintText: AppLocalization.getText('emailOrPhoneHint'),
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: accentPurple,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: accentPurple,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: accentPurple,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        // BRIGHT RED ERROR TEXT STYLING
                        errorStyle: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalization.getText(
                              'emailOrPhoneValidation');
                        }
                        if (_looksLikePhone(value)) {
                          final phone = _normalizePhoneNumber(value);
                          if (!RegExp(r'^\+94\d{9}$').hasMatch(phone)) {
                            return AppLocalization.getText(
                                'emailOrPhoneInvalidValidation');
                          }
                          return null;
                        }
                        if (!RegExp(r'^[\w\-\._]+@([\w\-]+\.)+[\w\-]{2,4}$')
                            .hasMatch(value.trim())) {
                          return AppLocalization.getText(
                              'emailOrPhoneInvalidValidation');
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Send Reset Link Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendResetLink,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          foregroundColor: white,
                          disabledBackgroundColor:
                              primaryPurple.withOpacity(0.7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: white,
                                  strokeWidth: 3.0,
                                  backgroundColor:
                                      primaryPurple.withOpacity(0.3),
                                ),
                              )
                            : Text(
                                AppLocalization.getText('sendResetLink'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Back to Sign In Button
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          AppLocalization.getText('backToSignIn'),
                          style: TextStyle(
                            color: accentPurple,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Additional Help Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.help_outline,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalization.getText('needHelp'),
                                style: TextStyle(
                                  color: textGray,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalization.getText('resetPasswordHelpText'),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
