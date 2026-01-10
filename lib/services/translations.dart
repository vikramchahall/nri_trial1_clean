class AppTexts {
  static const Map<String, Map<String, String>> data = {
'welcome': {
  'en': 'DASVANDH\n(NRI CONNECT)',
  'hi': 'दसवंध\n(NRI कनेक्ट)',
  'pa': 'ਦਸਵੰਧ\n(NRI ਕਨੇਕਟ)',
},

    'login': {
      'en': 'Login',
      'hi': 'लॉगिन',
      'pa': 'ਲੌਗਇਨ',
    },
    'register': {
      'en': 'Register Now',
      'hi': 'रजिस्टर करें',
      'pa': 'ਰਜਿਸਟਰ ਕਰੋ',
    },
    'email': {
      'en': 'Email',
      'hi': 'ईमेल',
      'pa': 'ਈਮੇਲ',
    },
    'password': {
      'en': 'Password',
      'hi': 'पासवर्ड',
      'pa': 'ਪਾਸਵਰਡ',
    },
    'forgot_pw': {
      'en': 'Forgot Password?',
      'hi': 'पासवर्ड भूल गए?',
      'pa': 'ਪਾਸਵਰਡ ਭੁੱਲ ਗਏ?',
    },
    'no_account': {
      'en': 'Not a member? Register now',
      'hi': 'सदस्य नहीं हैं? अभी रजिस्टर करें',
      'pa': 'ਮੈਂਬਰ ਨਹੀਂ ਹੋ? ਹੁਣੇ ਰਜਿਸਟਰ ਕਰੋ',
    },
    'logout': {
      'en': 'Logout',
      'hi': 'लॉग आउट',
      'pa': 'ਲੌਗ ਆਉਟ',
    },
    'settings': {
      'en': 'Settings',
      'hi': 'सेटिंग्स',
      'pa': 'ਸੈਟਿੰਗਾਂ',
    },
    'feed': {
      'en': 'Village Feed',
      'hi': 'गाँव की फीड',
      'pa': 'ਪਿੰਡ ਦੀ ਫੀਡ',
    },
  };

  /// ✅ SAFE TRANSLATION METHOD
  /// `languageState` MUST be AppLanguage from LanguageCubit
  static String get(String key, dynamic languageState) {
    String langCode = 'en';

    if (languageState.toString().contains('hindi')) {
      langCode = 'hi';
    } else if (languageState.toString().contains('punjabi')) {
      langCode = 'pa';
    }

    return data[key]?[langCode] ?? key;
  }
}
