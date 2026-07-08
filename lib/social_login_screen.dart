import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

// Corrected imports as requested
import 'app_notification.dart';
import 'sign_up.dart';
import 'app_localization.dart';
import 'forget.dart'; // Import the forgot password screen
import 'user_panel.dart';

class SocialLoginScreen extends StatefulWidget {
  const SocialLoginScreen({Key? key}) : super(key: key);

  @override
  State<SocialLoginScreen> createState() => _SocialLoginScreenState();
}

class _SocialLoginScreenState extends State<SocialLoginScreen> {
  final TextEditingController _emailPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  bool _obscurePassword = true;
  bool _isSigningIn = false;
  bool _isUsingEmail = true; // Toggle between email and phone

  // Define bright error red color constant
  static const Color errorRed = Color(0xFFE53935); // Bright Material Red

  // ===== PURPLE THEME TOKENS (only visual change) =====
  static const Color primaryPurple = Color(0xFF4A22A8);
  static const Color accentPurple = Color(0xFF6D43D1);
  static const Color deepPurple = Color(0xFF38197F);
  static const Color lightPurple = Color(0xFF7E62C8);

  @override
  void initState() {
    super.initState();
    // Initialize AppLocalization when the screen loads
    _initializeLocalization();
  }

  Future<void> _initializeLocalization() async {
    await AppLocalization.initialize();
    if (mounted) {
      setState(() {}); // Refresh UI with loaded language
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ AUTO-REDIRECT: If user is already signed in, don't stay on login screen
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      debugPrint(
          "🔍 SocialLoginScreen: User already signed in (${user.uid}), auto-redirecting...");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => UserPanel()),
            (route) => false,
          );
        }
      });
    }
  }

  Future<void> _signInWithPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSigningIn = true);
    try {
      if (_isUsingEmail) {
        // Direct email sign-in - fastest method
        final credential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailPhoneController.text.trim().toLowerCase(),
          password: _passwordController.text,
        );

        if (credential.user != null) {
          debugPrint("✅ Sign-in successful: ${credential.user?.email}");
          showAppNotification(
            title: AppLocalization.getText('success'),
            message: AppLocalization.getText('signInSuccessful'),
            type: NotificationType.success,
          );

          // Explicitly navigate to Dashboard to ensure UI updates
          // Navigate immediately to UserPanel
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => UserPanel()),
              (route) => false,
            );
          }
        }
      } else {
        // Optimized phone number sign-in
        await _signInWithPhoneFromFirestore();
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = AppLocalization.getText('noAccountFoundEmail');
          break;
        case 'wrong-password':
          errorMessage = AppLocalization.getText('currentPasswordIncorrect');
          break;
        case 'invalid-credential':
          errorMessage = AppLocalization.getText('invalidCredentialError');
          break;
        case 'invalid-email':
          errorMessage = AppLocalization.getText('invalidEmailError');
          break;
        case 'too-many-requests':
          errorMessage = AppLocalization.getText('tooManyRequests');
          break;
        default:
          errorMessage = AppLocalization.getText('signInFailedError');
      }
      showAppNotification(
        title: AppLocalization.getText('error'),
        message: errorMessage,
        type: NotificationType.error,
      );
    } catch (e) {
      showAppNotification(
        title: AppLocalization.getText('error'),
        message: '${AppLocalization.getText('unexpectedErrorOccurred')} ($e)',
        type: NotificationType.error,
      );
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _signInWithPhoneFromFirestore() async {
    try {
      final resolvedPhoneNumber =
          _normalizePhoneNumber(_emailPhoneController.text);
      final resolvedPassword = _passwordController.text;
      final resolvedUserEmail =
          await _lookupAuthEmailByPhone(resolvedPhoneNumber);

      final resolvedCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: resolvedUserEmail,
        password: resolvedPassword,
      );

      if (resolvedCredential.user != null) {
        showAppNotification(
          title: AppLocalization.getText('success'),
          message: AppLocalization.getText('signInSuccessful'),
          type: NotificationType.success,
        );

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => UserPanel()),
            (route) => false,
          );
        }
      }
      return;

      // ✅ NORMALIZE: Remove all spaces and special characters except +
      String cleanedInput = _emailPhoneController.text
          .trim()
          .replaceAll(RegExp(r'[\s\-\(\)]'), '');

      // ✅ Ensure phone starts with +94 (format: +94768502166)
      String phoneNumber;
      if (cleanedInput.startsWith('+94')) {
        phoneNumber = cleanedInput; // Already correct: +94768502166
      } else if (cleanedInput.startsWith('94')) {
        phoneNumber = '+$cleanedInput'; // Add +: +94768502166
      } else if (cleanedInput.startsWith('0')) {
        phoneNumber =
            '+94${cleanedInput.substring(1)}'; // Remove leading 0 and add +94
      } else {
        phoneNumber = '+94$cleanedInput'; // Add +94: +94768502166
      }

      print('🔍 DEBUG: Normalized phone number: $phoneNumber');

      final password = _passwordController.text;

      // ✅ Query Firestore for user with EXACT phone match
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      print('🔍 DEBUG: Found ${querySnapshot.docs.length} matching users');

      if (querySnapshot.docs.isEmpty) {
        print('🔍 DEBUG: No user found with phone: $phoneNumber');
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: AppLocalization.getText('noAccountFoundPhone'),
        );
      }

      // ✅ Get user data from Firestore
      final userData = querySnapshot.docs.first.data();
      final String? userEmail = userData['email'];

      print('🔍 DEBUG: User email from Firestore: $userEmail');

      // ✅ Validate that email exists in Firestore
      if (userEmail == null || userEmail.isEmpty) {
        print('🔍 DEBUG: Email field is null or empty in Firestore');
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: AppLocalization.getText('accountErrorContactSupport'),
        );
      }

      print(
          '🔍 DEBUG: Attempting Firebase Auth sign-in with email: $userEmail');

      // ✅ Sign in with the email (real or temp email) and password
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: userEmail.trim().toLowerCase(),
        password: password,
      );

      print(
          '🔍 DEBUG: Firebase Auth sign-in successful! UID: ${credential.user?.uid}');

      if (credential.user != null) {
        showAppNotification(
          title: AppLocalization.getText('success'),
          message: AppLocalization.getText('signInSuccessful'),
          type: NotificationType.success,
        );

        // Explicitly navigate to Dashboard
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => UserPanel()),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      print(
          '🔍 DEBUG: FirebaseAuthException - Code: ${e.code}, Message: ${e.message}');

      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = AppLocalization.getText('currentPasswordIncorrect');
          break;
        case 'too-many-requests':
          errorMessage = AppLocalization.getText('tooManyRequests');
          break;
        case 'user-not-found':
          errorMessage = AppLocalization.getText('noAccountFoundPhone');
          break;
        case 'invalid-email':
          errorMessage = e.message ??
              AppLocalization.getText('accountErrorContactSupport');
          break;
        case 'invalid-credential':
          errorMessage = AppLocalization.getText('invalidCredentialError');
          break;
        default:
          errorMessage =
              '${AppLocalization.getText('signInFailedError')} (${e.code})';
      }

      showAppNotification(
        title: AppLocalization.getText('error'),
        message: errorMessage,
        type: NotificationType.error,
      );
      rethrow;
    } on FirebaseException catch (e) {
      showAppNotification(
        title: AppLocalization.getText('error'),
        message: e.message ??
            '${AppLocalization.getText('unexpectedErrorOccurred')} (${e.code})',
        type: NotificationType.error,
      );
      rethrow;
    } catch (e) {
      print('🔍 DEBUG: General Exception: $e');
      showAppNotification(
        title: AppLocalization.getText('error'),
        message: '${AppLocalization.getText('signInFailedError')} ($e)',
        type: NotificationType.error,
      );
      rethrow;
    }
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

  Future<String> _lookupAuthEmailByPhone(String phoneNumber) async {
    try {
      final callable = _functions.httpsCallable('lookupAuthEmailByPhone');
      final result = await callable.call<Map<String, dynamic>>({
        'phone': phoneNumber,
      });

      final data = Map<String, dynamic>.from(result.data);
      final authEmail =
          (data['authEmail'] ?? '').toString().trim().toLowerCase();
      if (authEmail.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: AppLocalization.getText('accountErrorContactSupport'),
        );
      }
      return authEmail;
    } on FirebaseFunctionsException catch (error) {
      throw FirebaseAuthException(
        code: _mapPhoneLookupErrorCode(error),
        message: _mapPhoneLookupErrorMessage(error),
      );
    }
  }

  String _mapPhoneLookupErrorCode(FirebaseFunctionsException error) {
    switch (error.code) {
      case 'not-found':
        return 'user-not-found';
      case 'invalid-argument':
        return 'invalid-phone-number';
      case 'failed-precondition':
        return 'invalid-email';
      default:
        return 'lookup-failed';
    }
  }

  String _mapPhoneLookupErrorMessage(FirebaseFunctionsException error) {
    switch (error.code) {
      case 'not-found':
        return AppLocalization.getText('noAccountFoundPhone');
      case 'invalid-argument':
        return AppLocalization.getText('phoneInvalidValidation');
      case 'failed-precondition':
        return AppLocalization.getText('accountErrorContactSupport');
      default:
        return error.message ?? AppLocalization.getText('signInFailedError');
    }
  }

  Future<void> _saveUserDataToFirestore(User user) async {
    final firestore = FirebaseFirestore.instance;
    final userDocRef = firestore.collection('users').doc(user.uid);

    final docSnapshot = await userDocRef.get();
    final existingData =
        docSnapshot.exists ? docSnapshot.data() as Map<String, dynamic> : null;
    final roles = Map<String, dynamic>.from(
      (existingData?['roles'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    roles['customer'] = true;

    await userDocRef.set({
      'uid': user.uid,
      'name': user.displayName ?? existingData?['name'] ?? 'No Name',
      'email': user.email ?? existingData?['email'],
      'profileImageUrl':
          user.photoURL ?? existingData?['profileImageUrl'] ?? '',
      'createdAt': existingData == null
          ? FieldValue.serverTimestamp()
          : (existingData['createdAt'] ?? FieldValue.serverTimestamp()),
      'updatedAt': FieldValue.serverTimestamp(),
      'phone': existingData?['phone'] ?? '',
      'countryCode': existingData?['countryCode'] ?? '',
      'country': existingData?['country'] ?? '',
      'language': AppLocalization.languageCode,
      'isEmailProvided': true,
      'user_category': existingData?['user_category'] ?? 'customer',
      'roles': roles,
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignUpTap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            SignUpScreen(selectedLanguage: AppLocalization.languageCode),
      ),
    );
  }

  // Navigate to Forgot Password Screen
  void _onForgotPasswordTap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ForgotPasswordScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Theme constants
    const Color lightGray = Color(0xFFEDEDED);
    const Color mediumGray = Color(0xFF97979A);
    const Color labelGray = Color(0xFF3C3C3C);
    const Color passwordIconGray = Color(0xFF9E9E9E);
    const Color textGray = Color(0xFF2A2A2A);
    const Color fieldGray = Color(0xFFEFEEF4);
    const Color footerGray = Color(0xFF6F6F6F);
    const Color black = Color(0xFF000000);
    const Color white = Color(0xFFFFFFFF);

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
                      top: MediaQuery.paddingOf(context).top + 24,
                      bottom: 44,
                      left: 30,
                      right: 30,
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
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              height: 88,
                              width: 88,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.storefront,
                                    size: 42, color: primaryPurple);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'NICO MART',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: white,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 1),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: white.withOpacity(0.55), width: 1.5),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                'LK',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: white,
                                      letterSpacing: 0.6,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          AppLocalization.getText('welcomeBack'),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: white,
                                letterSpacing: -0.2,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to continue ordering',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: white.withOpacity(0.85),
                                  ),
                        ),
                      ],
                    ),
                  ),

                  // ===== FORM =====
                  Padding(
                    padding: const EdgeInsets.fromLTRB(26, 26, 26, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text(
                              _isUsingEmail
                                  ? AppLocalization.getText('emailLabel')
                                  : AppLocalization.getText('phoneLabel'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: labelGray,
                                  ),
                            ),
                            const Spacer(),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFECEAF3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isUsingEmail = true;
                                        _emailPhoneController.clear();
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _isUsingEmail
                                            ? primaryPurple
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.email_outlined,
                                            size: 14,
                                            color: _isUsingEmail
                                                ? white
                                                : mediumGray,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Email',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _isUsingEmail
                                                  ? white
                                                  : mediumGray,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isUsingEmail = false;
                                        _emailPhoneController.clear();
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: !_isUsingEmail
                                            ? primaryPurple
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.phone_outlined,
                                            size: 14,
                                            color: !_isUsingEmail
                                                ? white
                                                : mediumGray,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Phone',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: !_isUsingEmail
                                                  ? white
                                                  : mediumGray,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.1, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _isUsingEmail
                              ? _buildEmailField()
                              : _buildPhoneField(),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            AppLocalization.getText('passwordLabel'),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: labelGray,
                                    ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: textGray,
                                  ),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 20),
                            prefixIcon: const Icon(Icons.lock_outlined,
                                color: passwordIconGray, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: passwordIconGray,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: fieldGray,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none),
                            // BRIGHT ERROR STYLING
                            errorStyle: const TextStyle(
                              color: errorRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide:
                                  const BorderSide(color: errorRed, width: 2),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide:
                                  const BorderSide(color: errorRed, width: 2.5),
                            ),
                          ),
                          validator: (value) => (value == null || value.isEmpty)
                              ? AppLocalization.getText('passwordValidation')
                              : null,
                        ),
                        const SizedBox(height: 12),
                        // Forgot Password Link with Language Support
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _onForgotPasswordTap,
                            child: Text(
                              AppLocalization.getText('forgotPassword'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: primaryPurple,
                                    decoration: TextDecoration.underline,
                                    decorationColor: primaryPurple,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed:
                                _isSigningIn ? null : _signInWithPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryPurple,
                              foregroundColor: white,
                              elevation: 2,
                              disabledBackgroundColor:
                                  primaryPurple.withOpacity(0.7),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            child: _isSigningIn
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
                                    AppLocalization.getText('signIn'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: white,
                                          letterSpacing: 0.5,
                                        ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppLocalization.getText('noAccount'),
                              style: TextStyle(color: footerGray, fontSize: 14),
                            ),
                            GestureDetector(
                              onTap: _onSignUpTap,
                              child: Text(
                                AppLocalization.getText('signUpHere'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: primaryPurple,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildEmailField() {
    return TextFormField(
      key: const ValueKey('email'),
      controller: _emailPhoneController,
      keyboardType: TextInputType.emailAddress,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2A2A2A),
          ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        prefixIcon: const Icon(Icons.email_outlined,
            color: Color(0xFFA0A0A0), size: 20),
        hintText: AppLocalization.getText('emailHint'),
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide:
                const BorderSide(color: primaryPurple, width: 2)), // Purple
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide:
                const BorderSide(color: primaryPurple, width: 2)), // Purple
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide:
                const BorderSide(color: primaryPurple, width: 2)), // Purple
        // BRIGHT ERROR STYLING FOR EMAIL
        errorStyle: const TextStyle(
          color: errorRed,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: errorRed, width: 2.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty)
          return AppLocalization.getText('emailValidation');
        if (!RegExp(r'^[\w\-\._]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(value)) {
          return AppLocalization.getText('emailInvalidValidation');
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    const countryCode = '+94';

    final validationRule = (String? value) {
      if (value == null || value.isEmpty) {
        return AppLocalization.getText('phoneValidation');
      }
      final cleanNumber = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      if (!RegExp(r'^[0-9]+$').hasMatch(cleanNumber)) {
        return AppLocalization.getText('phoneDigitsValidation');
      }
      if (cleanNumber.length < 9 || cleanNumber.length > 10) {
        return AppLocalization.getText('phoneInvalidValidation');
      }
      return null;
    };

    return TextFormField(
      key: ValueKey(AppLocalization.languageCode),
      controller: _emailPhoneController,
      keyboardType: TextInputType.phone,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2A2A2A),
          ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        prefixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 16),
            const Text('🇱🇰', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Text(
              countryCode,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2A2A2A),
                    fontSize: 14,
                  ),
            ),
            const SizedBox(width: 12),
            Container(height: 24, width: 1.5, color: Colors.grey.shade300),
            const SizedBox(width: 8),
          ],
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 120),
        hintText: AppLocalization.getText('phoneHint'),
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide:
                const BorderSide(color: primaryPurple, width: 2)), // Purple
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide:
                const BorderSide(color: primaryPurple, width: 2)), // Purple
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide:
                const BorderSide(color: primaryPurple, width: 2)), // Purple
        // BRIGHT ERROR STYLING FOR PHONE
        errorStyle: const TextStyle(
          color: errorRed,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: errorRed, width: 2.5),
        ),
      ),
      validator: validationRule,
    );
  }
}
