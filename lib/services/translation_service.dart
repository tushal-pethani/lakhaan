import 'package:flutter/foundation.dart';

class TranslationService {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  final ValueNotifier<String> currentLanguage = ValueNotifier<String>('en');

  void setLanguage(String code) {
    if (['en', 'gu', 'hi'].contains(code)) {
      currentLanguage.value = code;
    }
  }

  // Dictionary: { 'TextKey': { 'en': 'English', 'gu': 'Gujarati', 'hi': 'Hindi' } }
  static const Map<String, Map<String, String>> _translations = {
    // Navbar / Common
    'Dashboard': {
      'en': 'Dashboard',
      'gu': 'ડેશબોર્ડ',
      'hi': 'डैशबोर्ड',
    },
    'Clients': {
      'en': 'Clients',
      'gu': 'ગ્રાહકો',
      'hi': 'ग्राहक',
    },
    'Add New Client': {
      'en': 'Add New Client',
      'gu': 'નવો ગ્રાહક ઉમેરો',
      'hi': 'नया ग्राहक जोड़ें',
    },
    'Logout': {
      'en': 'Logout',
      'gu': 'લૉગઆઉટ',
      'hi': 'लॉग आउट',
    },
    'User': {
      'en': 'User',
      'gu': 'વપરાશકર્તા',
      'hi': 'उपयोगकर्ता',
    },
    // Dashboard actions
    'New Invoice': {
      'en': 'New Invoice',
      'gu': 'નવું બિલ',
      'hi': 'नया इनवॉइस',
    },
    'Refresh': {
      'en': 'Refresh',
      'gu': 'તાજું કરો',
      'hi': 'रिफ्रेश करें',
    },
    'Add Invoice': {
      'en': 'Add Invoice',
      'gu': 'બિલ ઉમેરો',
      'hi': 'इनवॉइस जोड़ें',
    },
    'Invoices': {
      'en': 'Invoices',
      'gu': 'બિલો',
      'hi': 'इनवॉइस',
    },
    // Client Screen
    'Add Client': {
      'en': 'Add Client',
      'gu': 'ગ્રાહક ઉમેરો',
      'hi': 'ग्राहक जोड़ें',
    },
    'Edit Client': {
      'en': 'Edit Client',
      'gu': 'ગ્રાહકને સંશોધિત કરો',
      'hi': 'ग्राहक संपादित करें',
    },
    'Name': {
      'en': 'Name',
      'gu': 'નામ',
      'hi': 'नाम',
    },
    'GST Number': {
      'en': 'GST Number',
      'gu': 'જીએસટી નંબર',
      'hi': 'जीएसटी नंबर',
    },
    'PAN Number': {
      'en': 'PAN Number',
      'gu': 'પાન નંબર',
      'hi': 'पैन नंबर',
    },
    'Address': {
      'en': 'Address',
      'gu': 'સરનામું',
      'hi': 'पता',
    },
    'City': {
      'en': 'City',
      'gu': 'શહેર',
      'hi': 'शहर',
    },
    'State': {
      'en': 'State',
      'gu': 'રાજ્ય',
      'hi': 'राज्य',
    },
    'Pincode': {
      'en': 'Pincode',
      'gu': 'પીનકોડ',
      'hi': 'पिनकोड',
    },
    'Phone': {
      'en': 'Phone',
      'gu': 'ફોન નંબર',
      'hi': 'फ़ोन नंबर',
    },
    'Email': {
      'en': 'Email',
      'gu': 'ઈમેલ',
      'hi': 'ईमेल',
    },
    'Cancel': {
      'en': 'Cancel',
      'gu': 'રદ કરો',
      'hi': 'रद्द करें',
    },
    'Save': {
      'en': 'Save',
      'gu': 'સાચવો',
      'hi': 'सहेजें',
    },
    'Verify GST': {
      'en': 'Verify GST',
      'gu': 'જીએસટી ચકાસો',
      'hi': 'जीएसटी सत्यापित करें',
    },
    'Verifying...': {
      'en': 'Verifying...',
      'gu': 'ચકાસી રહ્યા છીએ...',
      'hi': 'सत्यापित कर रहा है...',
    },
    'Basic Details': {
      'en': 'Basic Details',
      'gu': 'મૂળભૂત વિગતો',
      'hi': 'बुनियादी विवरण',
    },
    'Location': {
      'en': 'Location',
      'gu': 'સ્થળ',
      'hi': 'स्थान',
    },
    'Contact': {
      'en': 'Contact',
      'gu': 'સંપર્ક',
      'hi': 'संपर्क',
    },
    'Delete': {
      'en': 'Delete',
      'gu': 'કાઢી નાખો',
      'hi': 'हटाएं',
    },
  };

  String translate(String key) {
    final curLang = currentLanguage.value;
    if (_translations.containsKey(key)) {
      if (_translations[key]!.containsKey(curLang)) {
        return _translations[key]![curLang]!;
      }
      return _translations[key]!['en']!; // fallback
    }
    return key; // return key itself if not found
  }
}

extension TranslateExtension on String {
  String get tr => TranslationService.instance.translate(this);
}
