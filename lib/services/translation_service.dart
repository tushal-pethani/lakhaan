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
    'Business Name *': {
      'en': 'Business Name *',
      'gu': 'વ્યવસાયનું નામ *',
      'hi': 'व्यवसाय का नाम *',
    },
    'Enter GST Number': {
      'en': 'Enter GST Number',
      'gu': 'જીએસટી નંબર દાખલ કરો',
      'hi': 'जीएसटी नंबर दर्ज करें',
    },
    'We will fetch business details automatically': {
      'en': 'We will fetch business details automatically',
      'gu': 'અમે વ્યવસાયની વિગતો આપમેળે લાવીશું',
      'hi': 'हम व्यवसाय विवरण स्वचालित रूप से प्राप्त करेंगे',
    },
    'Create account': {
      'en': 'Create account',
      'gu': 'ખાતું બનાવો',
      'hi': 'खाता बनाएं',
    },
    'Welcome back': {
      'en': 'Welcome back',
      'gu': 'પાછા ફરવા બદલ સ્વાગત છે',
      'hi': 'वापसी पर स्वागत है',
    },
    'Start generating professional invoices': {
      'en': 'Start generating professional invoices',
      'gu': 'વ્યાવસાયિક બિલ બનાવવાનું શરૂ કરો',
      'hi': 'पेशेवर इनवॉइस बनाना शुरू करें',
    },
    'Sign in to your account to continue': {
      'en': 'Sign in to your account to continue',
      'gu': 'ચાલુ રાખવા માટે તમારા ખાતામાં સાઇન ઇન કરો',
      'hi': 'जारी रखने के लिए अपने खाते में साइन इन करें',
    },
    'Full Name': {
      'en': 'Full Name',
      'gu': 'પૂરું નામ',
      'hi': 'पूरा नाम',
    },
    'Password': {
      'en': 'Password',
      'gu': 'પાસવર્ડ',
      'hi': 'पासवर्ड',
    },
    'Verified ✓': {
      'en': 'Verified ✓',
      'gu': 'ચકાસાયેલ ✓',
      'hi': 'सत्यापित ✓',
    },
    'Live Verify': {
      'en': 'Live Verify',
      'gu': 'જીવંત ચકાસણી',
      'hi': 'लाइव सत्यापन',
    },
    'Edit Profile': {
      'en': 'Edit Profile',
      'gu': 'પ્રોફાઇલ સંપાદિત કરો',
      'hi': 'प्रोफाइल संपादित करें',
    },
    'Update your business information': {
      'en': 'Update your business information',
      'gu': 'તમારા વ્યવસાયની માહિતી અપડેટ કરો',
      'hi': 'अपनी व्यावसायिक जानकारी अपडेट करें',
    },
    'Company Logo': {
      'en': 'Company Logo',
      'gu': 'કંપનીનો લોગો',
      'hi': 'कंपनी का लोगो',
    },
    'Bank Details': {
      'en': 'Bank Details',
      'gu': 'બેંકની વિગતો',
      'hi': 'बैंक विवरण',
    },
    'Save Changes': {
      'en': 'Save Changes',
      'gu': 'ફેરફારો સાચવો',
      'hi': 'परिवर्तन सहेजें',
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
