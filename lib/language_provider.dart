import 'package:flutter/foundation.dart';
import 'app_localization.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = AppLocalization.languageCode;

  String get currentLanguage => _currentLanguage;

  void loadLanguage() {
    _currentLanguage = AppLocalization.languageCode;
    notifyListeners();
  }

  void setLanguage(String languageCode) {
    AppLocalization.setLanguage(languageCode);
    _currentLanguage = languageCode;
    notifyListeners();
  }
}
