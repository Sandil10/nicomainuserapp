// // lib/translation.dart
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class Translation {
//   // Current language code (e.g., "en", "it")
//   static String currentLang = "en";
//
//   // Notifier for lightweight rebuilds in widgets using Translation directly
//   static ValueNotifier<String> langNotifier = ValueNotifier<String>(currentLang);
//
//   // Centralized translations map. Keep keys consistent across the app.
//   static final Map<String, Map<String, String>> _translations = {
//     "en": {
//       // PreferencesSettings keys
//       "preferences_title": "Preferences",
//       "language_region": "Language & Region",
//       "language_label": "Language",
//       "select_language": "Select Language",
//       "language_changed_success": "Language changed successfully",
//       "error_changing_language": "Error changing language",
//       "save_failed": "Save failed",
//
//       // Login flow keys
//       "email": "Email",
//       "password": "Password",
//       "signIn": "Sign in",
//       "rememberMe": "Remember me",
//       "continueWithGoogle": "Continue with Google",
//
//       // Optional helper/hints (if used anywhere)
//       "phone": "Phone",
//       "phoneLabel": "Phone Number",
//       "emailHint": "Enter your email address",
//       "phoneHint": "123 456 7890",
//       "passwordRequired": "Please enter a password.",
//       "emailRequired": "Please enter an email.",
//       "emailInvalid": "Please enter a valid email address.",
//       "phoneRequired": "Please enter a phone number.",
//       "phoneInvalidLength": "Please enter a valid Sri Lankan phone number.",
//       "phoneDigitsOnly": "Phone number should contain only digits.",
//       "connectWith": "You can connect with",
//       "noAccount": "Don't have an account?",
//       "signUpHere": "Sign Up here",
//
//       // Auth messages (if referenced)
//       "successSignIn": "Successfully signed in!",
//       "errorSignIn": "Sign-in failed. Please try again.",
//       "noAccountFound": "No account found with this credential.",
//       "wrongPassword": "Incorrect password. Please try again.",
//       "invalidCredential": "Invalid email or password.",
//       "successPhoneSignIn": "Successfully signed in with phone number!",
//       "accountNoEmail": "Account found but no email associated. Please contact support.",
//       "incorrectPasswordPhone": "Incorrect password for this phone number.",
//       "tooManyRequestsPhone": "Too many failed attempts. Please try again later.",
//       "failedPhoneSignIn": "Failed to sign in with phone number.",
//       "successGoogle": "Successfully signed in with Google!",
//       "googleSignInFailed": "Google sign-in failed. Please try again.",
//     },
//     "it": {
//       // PreferencesSettings keys
//       "preferences_title": "Preferenze",
//       "language_region": "Lingua e regione",
//       "language_label": "Lingua",
//       "select_language": "Seleziona lingua",
//       "language_changed_success": "Lingua cambiata con successo",
//       "error_changing_language": "Errore nel cambiare lingua",
//       "save_failed": "Salvataggio non riuscito",
//
//       // Login flow keys
//       "email": "Email (IT)",
//       "password": "Password (IT)",
//       "signIn": "Accedi",
//       "rememberMe": "Ricordami",
//       "continueWithGoogle": "Continua con Google",
//
//       // Optional helper/hints (if used anywhere)
//       "phone": "Telefono",
//       "phoneLabel": "Numero di telefono",
//       "emailHint": "Inserisci il tuo indirizzo email",
//       "phoneHint": "123 456 7890",
//       "passwordRequired": "Inserisci una password.",
//       "emailRequired": "Inserisci un'email.",
//       "emailInvalid": "Inserisci un indirizzo email valido.",
//       "phoneRequired": "Inserisci un numero di telefono.",
//       "phoneInvalidLength": "Inserisci un numero di telefono italiano valido.",
//       "phoneDigitsOnly": "Il numero deve contenere solo cifre.",
//       "connectWith": "Puoi connetterti con",
//       "noAccount": "Non hai un account?",
//       "signUpHere": "Registrati qui",
//
//       // Auth messages (if referenced)
//       "successSignIn": "Accesso effettuato con successo!",
//       "errorSignIn": "Accesso non riuscito. Riprova.",
//       "noAccountFound": "Nessun account trovato con questa credenziale.",
//       "wrongPassword": "Password errata. Riprova.",
//       "invalidCredential": "Email o password non valida.",
//       "successPhoneSignIn": "Accesso con numero di telefono riuscito!",
//       "accountNoEmail": "Account trovato ma senza email associata. Contatta il supporto.",
//       "incorrectPasswordPhone": "Password errata per questo numero di telefono.",
//       "tooManyRequestsPhone": "Troppi tentativi non riusciti. Riprova più tardi.",
//       "failedPhoneSignIn": "Accesso con numero di telefono non riuscito.",
//       "successGoogle": "Accesso con Google riuscito!",
//       "googleSignInFailed": "Accesso con Google non riuscito. Riprova.",
//     },
//   };
//
//   // Translate with safe fallback to key
//   static String t(String key) => _translations[currentLang]?[key] ?? key;
//
//   // Load language from SharedPreferences (uses unified key: 'app_language')
//   static Future<void> loadSavedLanguage() async {
//     final prefs = await SharedPreferences.getInstance();
//     currentLang = prefs.getString('app_language') ?? "en";
//     langNotifier.value = currentLang; // notify listeners
//   }
//
//   // Save language to SharedPreferences (uses unified key: 'app_language')
//   static Future<void> saveLanguage(String langCode) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('app_language', langCode);
//     currentLang = langCode;
//     langNotifier.value = langCode; // notify listeners
//   }
//
//   // Sync Translation with external locale changes (e.g., LocaleNotifier)
//   static void updateLocale(String langCode) {
//     currentLang = langCode;
//     langNotifier.value = langCode; // notify listeners
//   }
//
//   // Utility: check supported
//   static bool isSupported(String code) => _translations.containsKey(code);
// }
