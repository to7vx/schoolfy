import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  
  Locale get currentLocale => _currentLocale;
  
  String get currentLanguageName {
    switch (_currentLocale.languageCode) {
      case 'ar':
        return 'العربية';
      case 'en':
      default:
        return 'English';
    }
  }

  String get currentLanguageCode => _currentLocale.languageCode;

  Future<void> initialize() async {
    // Initialize with default English locale
    _currentLocale = const Locale('en');
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_currentLocale == locale) return;
    
    _currentLocale = locale;
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    await setLocale(Locale(languageCode));
  }

  bool isArabic() => _currentLocale.languageCode == 'ar';
  bool isEnglish() => _currentLocale.languageCode == 'en';
}
