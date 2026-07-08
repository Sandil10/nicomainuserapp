import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalization {
  static final ValueNotifier<String> currentLanguage = ValueNotifier('en');
  static const String _languageKey = 'selected_language';
  static bool _isInitialized = false;

  static final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      // === CONNECTIVITY NOTIFICATIONS ===
      'noInternetConnection': 'No Internet Connection',
      'pleaseConnectToNetwork': 'Please connect to the network',
      'backOnline': 'Back Online',
      'internetRestored': 'Internet connection restored',

      // === SIGN IN ERROR MESSAGES ===
      'invalidCredentialError': 'Invalid email or password',
      'signInFailedError': 'Sign-in failed. Please try again',
      'noAccountFoundPhone': 'No account found with this phone number',
      'accountErrorContactSupport': 'Account error. Please contact support',
      'googleSignInFailed': 'Google sign-in failed. Please try again',

      // === USER PANEL PRODUCTS SCREEN ===
      'hiGreeting': 'Hi, ',
      'goodMorning': 'Good Morning!',
      'goodAfternoon': 'Good Afternoon!',
      'goodEvening': 'Good Evening!',
      'goodNight': 'Good Night!',
      'goodDay': 'Good day!',
      'whatLookingFor': 'What are you looking for?',
      'viewProfile': 'View Profile',
      'guest': 'Guest',
      'user': 'User',

      // === PRODUCT CATEGORIES ===
      'groceries': 'Groceries',
      'waterBottles': 'Water Bottles',
      'fashion': 'Fashion',
      'schoolItems': 'School Items',
      'food': 'Food',
      'italyItems': 'Italy Items',

      // === FOOD PAGE ===
      'searchFood': 'Search for food...',
      'availableFood': 'Available Food',
      'noFoodFound': 'No food found.',
      'foodItem': 'Food Item',
      'deliciousAndFresh': 'Delicious and fresh.',

      // === GROCERIES PAGE ===
      'searchGroceries': 'Search for groceries...',
      'all': 'All',
      'organic': 'Organic',
      'onSale': 'On Sale',
      'new': 'New',
      'somethingWentWrong': 'Something went wrong',
      'noGroceriesFound': 'No groceries found.',
      'noResultsFound': 'No results found.',
      'freshGroceryItem': 'Fresh Grocery Item',
      'freshQualityGroceries': 'Fresh, quality groceries',
      'per': 'per',
      'add': 'Add',
      'addedToCart': 'Added to Cart',
      'addedToCartMessage': '"{productName}" has been added to your cart.',
      'addToCart': 'Add to cart',

      // === WATER BOTTLES PAGE ===
      'searchWaterBottles': 'Search for water bottles...',
      'availableWaterBottles': 'Available Water Bottles',
      'noWaterBottlesFound': 'No water bottles found.',
      'premiumWaterBottle': 'Premium Water Bottle',
      'freshPureWater': 'Fresh, pure water.',
      'noResultsFor': 'No results for',

      // === FASHION PAGE ===
      'searchFashionItems': 'Search for fashion items...',
      'availableFashionItems': 'Available Fashion Items',
      'noFashionItemsFound': 'No fashion items found.',
      'fashionItem': 'Fashion Item',
      'stylishAndTrendy': 'Stylish and trendy.',

      // === SCHOOL ITEMS PAGE ===
      'searchSchoolItems': 'Search for school items...',
      'availableSchoolItems': 'Available School Items',
      'noSchoolItemsFound': 'No school items found.',
      'schoolItem': 'School Item',
      'qualitySchoolSupplies': 'Quality school supplies.',

      // === ITALY ITEMS PAGE ===
      'searchItalyItems': 'Search for Italy items...',

      // === CART PAGE ===
      'yourCart': 'Your cart',
      'item': 'item',
      'items': 'items',
      'readyForCheckout': 'Ready for checkout',
      'quantity': 'Quantity',
      'unknownProduct': 'Unknown Product',
      'subtotal': 'Subtotal',
      'deliveryFee': 'Delivery fee',
      'total': 'Total',
      'checkout': 'Checkout',
      'order': 'Order',
      'backToMenu': 'Back to Menu',
      'cartEmpty': 'Your cart is empty',
      'addItemsToStart': 'Add some delicious items to get started!',
      'startShopping': '🛒 Start shopping',

      // === FREE DELIVERY BANNERS ===
      'freeDeliveryQualified': 'You qualify for FREE delivery!',
      'addMoreForFreeDelivery': 'Add Rs{amount} more for FREE delivery!',

      // === CHECKOUT PAGE ===
      'checkoutTitle': 'Checkout',
      'orderSummary': 'Order Summary',
      'date': 'Date',
      'time': 'Time',
      'delivery': 'Delivery',
      'continueToDeliveryDetails': 'Continue to Delivery Details',

      // === DELIVERY DETAILS PAGE ===
      'deliveryDetails': 'Delivery Details',
      'edit': 'Edit',
      'view': 'View',
      'orderTotal': 'Order Total',
      'contactInformation': 'Contact Information',
      'fullName': 'Full Name',
      'enterFullName': 'Enter your full name',
      'fullNameRequired': 'Full name is required',
      'phoneNumber': 'Phone Number',
      'enterPhoneNumber': 'Enter your phone number',
      'phoneNumberRequired': 'Phone number is required',
      'deliveryAddress': 'Delivery Address',
      'streetAddress': 'Street Address',
      'enterCompleteAddress': 'Enter your complete address',
      'addressRequired': 'Address is required',
      'city': 'City',
      'enterCity': 'Enter your city',
      'cityRequired': 'City is required',
      'zipCode': 'Zip Code',
      'zipCodeExample': 'e.g., 00100',
      'required': 'Required',
      'province': 'Province',
      'provinceExample': 'e.g., RM',
      'deliveryInstructions': 'Delivery Instructions (Optional)',
      'specialInstructions': 'Any special instructions...',
      'payWithCash': 'Pay with Cash',
      'payAmount': 'Pay Rs{amount}',
      'orderConfirmed': 'Order Confirmed!',
      'orderIdLabel': 'Order ID: {orderId}',
      'deliveryConfirmation':
          'Your delivery will be confirmed shortly.\nOrder is being processed.',
      'continue': 'Continue',
      'incompleteDetails': 'Incomplete Details',
      'fillAllFields': 'Please fill in all required delivery details.',
      'paymentError': 'Payment Error',
      'unexpectedError': 'An unexpected error occurred: {error}',
      'failedToLoadDetails': 'Failed to load details.',
      'retry': 'Retry',
      'orderFailed': 'Order Failed',
      'orderCreationFailed': 'Order Creation Failed',

      // === STOCK VALIDATION ===
      'stockUnavailable': 'Products Unavailable',
      'outOfStockItems': 'Out of Stock Items',
      'insufficientStock': 'Insufficient Stock',

      // === STRIPE PAYMENT PAGE ===
      'securePayment': 'Secure Payment',
      'paymentAmount': 'Payment Amount',
      'anErrorOccurred': 'An Error Occurred',
      'tryAgain': 'Try Again',
      'payAmountButton': 'Pay Rs{amount}',
      'processingPayment': 'Processing Payment...',
      'creatingOrder': 'Creating Order...',
      'paymentFailed': 'Payment Failed',
      'ok': 'OK',
      'orderPlaced': 'Order Placed',
      'orderPlacedSuccessfully': 'Order Placed Successfully!',
      'orderIdSuccess': 'Order ID: {orderId}',
      'amountPaid': 'Amount Paid',
      'orderDeliveryInfo':
          'Your order will be delivered soon. Check the \'My Orders\' section for additional information.',
      'paymentCancelled': 'Payment was cancelled by the user.',
      'soldOutProducts': 'Sold out products',

      // === SETTINGS PAGE ===
      'settingsTitle': 'Settings',
      'manageAccountSettings': 'Manage your account settings',
      'profileAccount': 'Profile & Account',
      'editPersonalInfo': 'Edit personal information',
      'ordersPayments': 'Orders & Payments',
      'viewHistoryMethods': 'View history and methods',
      'preferences': 'Preferences',
      'languageThemeMore': 'Language, theme, and more',
      'legalPrivacy': 'Legal & Privacy',
      'termsPrivacyPolicy': 'Terms, privacy policy',
      'signOut': 'Sign Out',
      'signOutAccount': 'Sign out of your account',
      'signOutTitle': 'Sign Out',
      'signOutConfirmation':
          'Are you sure you want to sign out of your account?',
      'cancel': 'Cancel',

      // === PROFILE SETTINGS PAGE ===
      'profileSettingsTitle': 'Profile & Settings',
      'basicInformation': 'Basic Information',
      'fullNameLabel': 'Full Name',
      'emailAddress': 'Email Address',
      'phoneNumberLabel': 'Phone Number',
      'gender': 'Gender',
      'accountSecurity': 'Account & Security',
      'dataPrivacy': 'Data & Privacy',
      'editName': 'Edit {field}',
      'selectGender': 'Select gender',
      'addPhoneNumber': 'Add phone number',
      'noEmail': 'No email',
      'male': 'Male',
      'female': 'Female',
      'other': 'Other',
      'preferNotToSay': 'Prefer not to say',
      'changePassword': 'Change Password',
      'updatePasswordSecurely': 'Update your password securely',
      'manageGoogleAccount': 'Manage Google Account',
      'openGoogleAccountSettings': 'Open Google account settings in browser',
      'deleteAccount': 'Delete Account',
      'permanentlyDeleteAccount': 'Permanently delete your account and data',
      'save': 'Save',
      'failedToLoadUserData': 'Failed to load user data',
      'couldNotOpenUrl': 'Could not open {url}',
      'failedToPickImage': 'Failed to pick image',
      'profilePictureUpdated': 'Profile picture updated successfully!',
      'failedToUpdateProfilePicture': 'Failed to update profile picture',
      'userNotFound': 'User not found. Please log in again.',
      'pleaseEnterValidValue': 'Please enter a valid value.',
      'updatedSuccessfully': 'Updated successfully!',
      'updateFailed': 'Update failed. Please try again.',
      'pleaseSelectGender': 'Please select a gender.',
      'googleAccountTitle': 'Google Account',
      'googleAccountMessage':
          'You signed in with Google. To manage your account settings, we will open Google Account management.',
      'openGoogleAccount': 'Open Google Account',
      'changePasswordTitle': 'Change Password',
      'currentPassword': 'Current Password',
      'newPassword': 'New Password',
      'confirmNewPassword': 'Confirm New Password',
      'pleaseEnterAllFields': 'Please fill in all fields.',
      'passwordsDoNotMatch': 'New passwords do not match.',
      'passwordTooShort': 'Password must be at least 6 characters.',
      'passwordChangedSuccessfully': 'Password changed successfully!',
      'currentPasswordIncorrect': 'Current password is incorrect.',
      'newPasswordTooWeak': 'New password is too weak.',
      'passwordChangeError': 'An error occurred. Please try again.',
      'deleteAccountTitle': 'Delete Account',
      'deleteAccountConfirmation':
          'Are you sure you want to delete your account? This action cannot be undone.',
      'delete': 'Delete',
      'accountDeletedSuccessfully': 'Account deleted successfully.',
      'accountDeleteFailed':
          'Failed to delete account. You may need to re-authenticate.',

      // === ORDERS & PAYMENTS PAGE ===
      'ordersTitle': 'Orders',
      'orderHistory': 'Order History',
      'viewPastCurrentOrders': 'View your orders',
      'orderHistoryTitle': 'Order History',
      'noOrdersYet': 'No orders yet',
      'pleaseSignInToView': 'Please sign in to view your order history.',
      'orderNumber': 'Order #{orderId}',
      'orderDate': 'Order Date',
      'deliveryDate': 'Delivery Date',
      'paymentInformation': 'Payment',
      'paymentMethod': 'Payment Method',
      'paymentStatus': 'Payment Status',
      'deliveryAddressLabel': 'Delivery Address',
      'address': 'Address',
      'deliveryNotes': 'Delivery Notes',
      'customerInformation': 'Customer Information',
      'name': 'Name',
      'phone': 'Phone',
      'deliveryStatus': 'Delivery Status',
      'yourItems': 'Your Items',
      'itemsCount': '{count} items',
      'qty': 'Qty: {quantity}',
      'each': 'Rs{price} each',
      'orderItemsNotAvailable': 'Order items not available',
      'unknownItem': 'Unknown Item',
      'unknownDate': 'Unknown Date',
      'unknownDateTime': 'Unknown Date & Time',
      'notAvailable': 'N/A',
      'processing': 'Processing',
      'preparing': 'Preparing',
      'onTheWay': 'On the Way',
      'delivered': 'Delivered',
      'cancelled': 'Cancelled',
      'pending': 'Pending',
      'completed': 'Completed',
      'failed': 'Failed',
      'confirmed': 'Confirmed',
      'cashOnDelivery': 'Cash on Delivery',
      'error': 'Error',

      // === NEW MISSING KEYS ===
      'trackPurchasesDelivery': 'Track your purchases',
      'orderOnTheWay': 'Your order is on the way! 🚴',
      'orderDetails': 'Order Details',
      'orderInformation': 'Order Information',

      // === USER PANEL NAVIGATION ===
      'products': 'Products',
      'cart': 'Cart',
      'settings': 'Settings',
      'about': 'About',

      // === AUTHENTICATION ===
      'emailLabel': 'Email',
      'phoneLabel': 'Phone Number',
      'passwordLabel': 'Password',
      'rememberMe': 'Remember me',
      'signIn': 'Sign in',
      'connectWith': 'You can connect with',
      'noAccount': 'Don\'t have an account? ',
      'signUpHere': 'Sign Up here',
      'continueWithGoogle': 'Continue with Google',
      'emailHint': 'Enter your email address',
      'phoneHint': '07X XXX XXXX',
      'emailValidation': 'Please enter an email.',
      'emailInvalidValidation': 'Please enter a valid email address.',
      'passwordValidation': 'Please enter a password.',
      'phoneValidation': 'Please enter a phone number.',
      'phoneInvalidValidation': 'Please enter a valid Sri Lankan phone number.',
      'phoneDigitsValidation': 'Phone number should contain only digits.',

      // === FORGOT PASSWORD SCREEN ===
      'forgotPassword': 'Forgot Password?',
      'resetPasswordTitle': 'Reset Password',
      'resetPasswordInfo':
          'Enter your email address or phone number and we\'ll help you reset your password.',
      'emailAddressLabel': 'Email Address',
      'emailOrPhoneLabel': 'Email or Phone Number',
      'emailOrPhoneHint': 'Enter your email or phone number',
      'emailOrPhoneValidation': 'Please enter your email or phone number.',
      'emailOrPhoneInvalidValidation':
          'Enter a valid email or Sri Lankan phone number.',
      'sendResetLink': 'Send Reset Link',
      'backToSignIn': 'Back to Sign In',
      'needHelp': 'Need Help?',
      'resetPasswordHelpText':
          '• Check your spam/junk folder if you don\'t receive the email\n• The reset link will expire in 1 hour\n• Contact support if you continue to have issues',
      'passwordResetEmailSent': 'Password reset email sent! Check your inbox.',
      'passwordResetEmailSentTo': 'Password reset email sent to {email}.',
      'noAccountFoundEmail': 'No account found with this email address.',
      'invalidEmailError': 'Invalid email address. Please check and try again.',
      'tooManyRequests': 'Too many requests. Please try again later.',
      'failedToSendResetEmail': 'Failed to send reset email. Please try again.',
      'unexpectedErrorOccurred':
          'An unexpected error occurred. Please try again.',

      // === SIGN UP SCREEN ===
      'createAccount': 'Create Account',
      'fillDetails': 'Fill in the details below to create your account.',
      'yourName': 'Your Name',
      'emailOptional': 'Email (Optional)',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'signUp': 'Sign Up',
      'alreadyHaveAccount': 'Already have an account? ',
      'signInHere': 'Sign In here',
      'nameHint': 'Enter your name',
      'phoneHintSignUp': '+94 7X XXX XXXX',
      'passwordHint': 'Enter your password',
      'confirmPasswordHint': 'Confirm your password',
      'nameValidation': 'Please enter your name.',
      'phoneValidationRequired': 'Phone number is required.',
      'phoneStartValidation': 'Phone number must start with +94 (Sri Lanka)',
      'phoneValidValidation': 'Please enter a valid Sri Lankan phone number',
      'passwordValidationLength': 'Password must be at least 6 characters.',
      'passwordMismatch': 'Passwords do not match.',
      'phoneStartError':
          'Phone number must start with Sri Lanka country code +94',
      'accountCreated': 'Your account was created successfully.',
      'signUpError': 'Sign-Up Error',
      'weakPassword': 'The password provided is too weak.',
      'emailInUse': 'An account already exists for that email.',
      'invalidEmail': 'The email address is not valid.',
      'signUpFailed': 'Sign-up failed. Please try again.',

      // === DUPLICATE EMAIL/PHONE ERROR MESSAGES (NEW) ===
      'emailAlreadyExists':
          'This email is already registered. Please use a different email or sign in.',
      'phoneAlreadyExists':
          'This phone number is already registered. Please use a different number or sign in.',

      // === TEMPORARY EMAIL ERROR (NEW) ===
      'cannotResetTempEmail':
          'Cannot send password reset to temporary email. Please contact support.',

      // === GOOGLE SIGN-IN SUCCESS MESSAGES ===
      'googleSignInSuccess': 'Google sign-in completed successfully!',
      'signInSuccessful': 'Sign-in successful!',
      'welcomeBack': 'Welcome back!',

      // === LEGAL SETTINGS PAGE ===
      'legalTitle': 'Legal',
      'legalDocuments': 'Legal Documents',
      'privacyPolicyTitle': 'Privacy Policy',
      'privacyPolicySubtitle': 'How we collect and use your data',
      'termsConditionsTitle': 'Terms & Conditions',
      'termsConditionsSubtitle': 'Our terms of service and user agreement',

      // === ABOUT PAGE ===
      'aboutTitle': 'About',
      'aboutUsTitle': 'About Us',
      'learnAboutCompany': 'Learn more about Nico Online Mart',
      'aboutCompanyDescription':
          'Nico Online Mart is an online ordering service that delivers bottled water and Sri Lankan food to your home in a simple, fast and reliable way.',
      'supportTitle': 'Support',
      'getHelpSupport': 'Get help and support',
      'faqsTitle': 'FAQs',
      'contactSupport': 'Contact Support',
      'reportProblem': 'Report a Problem',

      // === SUPPORT CHAT PAGE ===
      'supportChatTitle': 'Nico Support Chat',
      'welcomeMessage':
          '👋 Welcome to Nico Online Mart Support!\n\nHi {userName}! How can we help you today?\n\n• Order inquiries\n• Delivery questions\n• Product information\n• Technical support\n\nOur team will respond shortly!',
      'adminIsTyping': 'Admin is typing...',
      'connectedAs': 'Connected as {userName}',
      'offlineMode': 'Offline Mode',
      'typeYourMessage': 'Type your message...',
      'messageSentSuccessfully': 'Message sent successfully!',
      'failedToSendMessage': 'Failed to send message: {error}',
      'firebaseNotConfigured':
          'Firebase not configured. Please run "flutterfire configure" to enable real-time chat.',
      'guestUser': 'Guest User',
      'nicoSupport': 'Nico Support',

      // === ABOUT US PAGE ===
      'aboutUsPageTitle': 'About Us',
      'whatIsNicoOnlineMart': 'What is Nico Online Mart?',
      'nicoOnlineMartDescription':
          'Nico Mart is a mobile grocery shopping application that allows users to browse products, place home delivery orders, and make secure payments using cash. Delivering bottled water and Sri Lankan groceries to your home in a simple, fast and reliable way.',
      'waterChip': 'Water',
      'sriLankanGroceriesChip': 'Sri Lankan Groceries',
      'fastDeliveryChip': 'Fast Delivery',
      'nicoOnlineMartBanner': 'Nico Online Mart',
      'nicoOnlineMartBannerSubtitle':
          'Water and Sri Lankan Groceries – Everything to your home!',
      'solutionBanner':
          'The fastest and most reliable solution to receive water and groceries directly at home – only with Nico Online Mart!',
      'ourDirectors': 'Our CEO',
      'director': 'CEO',
      'drinkingWaterTitle': 'Drinking Water – Bottled Drinking Water',
      'orderAnyQuantity': 'Order any quantity',
      'noMoreHeavyTransport': 'No more heavy transport',
      'homeOfficeDelivery': 'Home or office delivery',
      'easyAppUse': 'Use the app easily',
      'simpleIntuitiveInterface': 'Simple and intuitive interface',
      'realtimeTracking': 'Real-time tracking',
      'paymentOnDelivery': 'Payment on delivery',
      'speedReliabilityPunctuality': 'Speed – Reliability – Punctuality',
      'alwaysPunctualDeliveries': 'Always punctual deliveries',
      'guaranteedCustomerSatisfaction': 'Guaranteed customer satisfaction',
      'orderNow': 'Order now!',
      'downloadApp': 'Download the app',
      'contactUs': 'Contact Us',
      'visitOurWebsite': 'Visit our website',
      'hotline': 'Hotline:',
      'tapToCopy': 'Tap to copy',
      'copied': 'Copied!',
      'textCopiedToClipboard': 'Text copied to clipboard',
      'phoneNumberCopied': 'Phone number copied to clipboard',

      // === FAQs PAGE ===
      'faqsPageTitle': 'FAQs',
      'faq1Question': 'How do I access the app?',
      'faq1Answer': 'Sign in using your email address and password.',
      'faq2Question': 'How can I place an order and make a payment?',
      'faq2Answer':
          'To place an order, sign in to the app, select the desired products, add to cart. After adding everything you want to the cart, select "Checkout", then enter your details (name, phone number and address) and finally confirm the payment.',
      'faq3Question': 'What do I do if I receive a wrong or missing item?',
      'faq3Answer':
          'You can contact this phone number via WhatsApp for more information about your order: +94 329 013 2841',
      'contactSupportDialog': 'Contact Support',
      'contactSupportDialogMessage':
          'For assistance, contact our team on WhatsApp at +94 329 013 2841.',
      'close': 'Close',
      'copyNumber': 'Copy Number',
      'contactOnWhatsApp': 'Contact on WhatsApp',

      // === CONTACT PAGE ===
      'contactPageTitle': 'Contact Us',
      'customerSupport': 'Customer Support',
      'customerSupportSubtitle':
          'We are here to help you! Contact us through the channels below.',
      'contactUsSection': 'Contact Us',
      'hotlineSection': 'Hotline',
      'supportTeamAvailable':
          'Our support team is available to help you with any questions or issues. Don\'t hesitate to contact us!',

      // === COMMON ===
      'success': 'Success',
      'profileUpdatedSuccess': 'Profile updated successfully',
      'profileUpdateError': 'Error updating profile',
      'selectLocation': 'Select Location',
      'searchAddress': 'Search for an address...',
      'itemDetails': 'Item Details',
      'billSummary': 'Bill Summary',
      'billDetails': 'Bill Details',
    },
  };

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey) ?? 'en';
      currentLanguage.value =
          _localizedStrings.containsKey(savedLanguage) ? savedLanguage : 'en';
      _isInitialized = true;

      if (kDebugMode) {
        print('🌐 ========== AppLocalization Debug ==========');
        print('📱 Language: ${currentLanguage.value}');
        print(
            '🔑 Total keys: ${_localizedStrings[currentLanguage.value]?.length ?? 0}');
        print(
            '📝 Map exists: ${_localizedStrings[currentLanguage.value] != null}');
        print('🌐 =========================================');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error in initialize: $e');
      currentLanguage.value = 'en';
      _isInitialized = true;
    }
  }

  static Future<void> setLanguage(String languageCode) async {
    if (!_localizedStrings.containsKey(languageCode)) {
      if (kDebugMode) print('❌ Language "$languageCode" not supported');
      return;
    }

    currentLanguage.value = languageCode;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      if (kDebugMode) print('✅ Language set to: $languageCode');
    } catch (e) {
      if (kDebugMode) print('❌ Error saving language: $e');
    }
  }

  static String getText(String key, {Map<String, String>? params}) {
    final currentLang = currentLanguage.value;
    final langMap = _localizedStrings[currentLang];

    if (langMap == null) {
      if (kDebugMode) print('❌ Language map null for: $currentLang');
      final fallbackMap = _localizedStrings['en'];
      if (fallbackMap != null && fallbackMap.containsKey(key)) {
        if (kDebugMode) print('🔄 Using English fallback for: $key');
        return _replaceParams(fallbackMap[key]!, params);
      }
      return key;
    }

    final translation = langMap[key];

    if (translation == null) {
      if (kDebugMode)
        print(
            '⚠️  Missing: $key in $currentLang (has ${langMap.keys.length} keys)');
      final fallback = _localizedStrings['en']?[key];
      if (fallback != null) {
        if (kDebugMode) print('🔄 Using English fallback: $fallback');
        return _replaceParams(fallback, params);
      }
      if (kDebugMode) print('❌ No fallback for: $key');
      return key;
    }

    return _replaceParams(translation, params);
  }

  static String _replaceParams(String text, Map<String, String>? params) {
    if (params == null) return text;

    String result = text;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }

  static String get languageCode => currentLanguage.value;
  static bool get isInitialized => _isInitialized;
}
