import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_notification.dart';
import 'app_localization.dart';

class PasswordChangeScreen extends StatefulWidget {
  const PasswordChangeScreen({Key? key}) : super(key: key);

  @override
  State<PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

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

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        showAppNotification(
          title: AppLocalization.getText('error'),
          message: AppLocalization.getText('userNotFound'),
          type: NotificationType.error,
        );
        setState(() => _isLoading = false);
        return;
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);

      // Update to new password
      await user.updatePassword(_newPasswordController.text.trim());

      if (mounted) {
        showAppNotification(
          title: AppLocalization.getText('success'),
          message: AppLocalization.getText('passwordChangedSuccessfully'),
          type: NotificationType.success,
        );

        // Wait 1 second then navigate back
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = AppLocalization.getText('currentPasswordIncorrect');
          break;
        case 'weak-password':
          errorMessage = AppLocalization.getText('newPasswordTooWeak');
          break;
        case 'requires-recent-login':
          errorMessage = AppLocalization.getText('pleaseSignInAgain');
          break;
        default:
          errorMessage = AppLocalization.getText('passwordChangeError');
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
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ValueListenableBuilder<String>(
            valueListenable: AppLocalization.currentLanguage,
            builder: (context, languageCode, child) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // Back button aligned to left
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDEDED),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.arrow_back,
                                size: 18, color: Color(0xFF6B7280)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Lock icon circle
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFEDEDED),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_reset_outlined,
                          size: 50,
                          color: primaryPurple,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      AppLocalization.getText('changePasswordTitle'),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                color: black,
                              ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      AppLocalization.getText('updatePasswordSecurely'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF97979A),
                            fontSize: 14,
                            height: 1.4,
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Current Password Label
                    Text(
                      AppLocalization.getText('currentPassword'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: labelGray,
                          ),
                    ),

                    const SizedBox(height: 8),

                    // Current Password Field
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrentPassword,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textGray,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Color(0xFFA0A0A0),
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrentPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF9E9E9E),
                            size: 20,
                          ),
                          onPressed: () => setState(() =>
                              _obscureCurrentPassword =
                                  !_obscureCurrentPassword),
                        ),
                        hintText: AppLocalization.getText('passwordHint'),
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFFEFEFF1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide:
                              const BorderSide(color: Colors.red, width: 1),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide:
                              const BorderSide(color: Colors.red, width: 1),
                        ),
                        errorStyle: const TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalization.getText('passwordValidation');
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // New Password Label
                    Text(
                      AppLocalization.getText('newPassword'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: labelGray,
                          ),
                    ),

                    const SizedBox(height: 8),

                    // New Password Field
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNewPassword,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textGray,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Color(0xFFA0A0A0),
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF9E9E9E),
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscureNewPassword = !_obscureNewPassword),
                        ),
                        hintText: AppLocalization.getText('passwordHint'),
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFFEFEFF1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide:
                              const BorderSide(color: Colors.red, width: 1),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide:
                              const BorderSide(color: Colors.red, width: 1),
                        ),
                        errorStyle: const TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return AppLocalization.getText(
                              'passwordValidationLength');
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Confirm Password Label
                    Text(
                      AppLocalization.getText('confirmNewPassword'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: labelGray,
                          ),
                    ),

                    const SizedBox(height: 8),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textGray,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Color(0xFFA0A0A0),
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF9E9E9E),
                            size: 20,
                          ),
                          onPressed: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                        ),
                        hintText:
                            AppLocalization.getText('confirmPasswordHint'),
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFFEFEFF1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide:
                              const BorderSide(color: Colors.red, width: 1),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide:
                              const BorderSide(color: Colors.red, width: 1),
                        ),
                        errorStyle: const TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      validator: (value) {
                        if (value != _newPasswordController.text) {
                          return AppLocalization.getText('passwordMismatch');
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Change Password Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _changePassword,
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
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: white,
                                  strokeWidth: 2.5,
                                  backgroundColor:
                                      primaryPurple.withOpacity(0.3),
                                ),
                              )
                            : Text(
                                AppLocalization.getText('changePassword'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Cancel Button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 0),
                      child: Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(26),
                        color: Colors.white,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(26),
                          onTap: () => Navigator.of(context).pop(),
                          splashColor: accentPurple.withOpacity(0.20),
                          highlightColor: accentPurple.withOpacity(0.15),
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: accentPurple.withOpacity(0.4),
                                width: 1.4,
                              ),
                            ),
                            child: Text(
                              AppLocalization.getText('cancel'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: accentPurple,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
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
