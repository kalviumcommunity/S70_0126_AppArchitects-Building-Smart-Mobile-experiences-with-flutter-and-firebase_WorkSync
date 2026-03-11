import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:async';
import 'package:translator/translator.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'English';
  final GoogleTranslator _translator = GoogleTranslator();
  Timer? _notifyTimer;
  
  // Cache for dynamically translated strings: Map<Language, Map<OriginalString, TranslatedString>>
  final Map<String, Map<String, String>> _dynamicCache = {};

  String get currentLanguage => _currentLanguage;

  LanguageProvider() {
    _loadUserLanguage();
  }

  Future<void> _loadUserLanguage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()!.containsKey('language')) {
        _currentLanguage = doc.data()!['language'];
        notifyListeners();
      }
    }
  }

  void setLanguage(String lang) {
    if (_currentLanguage != lang) {
      _currentLanguage = lang;
      notifyListeners();
    }
  }

  String translate(String key) {
    // 1. Check static translations first
    if (_translations[_currentLanguage]?.containsKey(key) == true) {
      return _translations[_currentLanguage]![key]!;
    }
    
    // 2. If it's English, no need to translate
    if (_currentLanguage == 'English') {
      return key;
    }
    
    // 3. Check dynamic cache
    if (_dynamicCache[_currentLanguage]?.containsKey(key) == true) {
      return _dynamicCache[_currentLanguage]![key]!;
    }
    
    // 4. Not translated yet, start translation and return original key for now
    _translateDynamically(key);
    return key;
  }
  
  Future<void> _translateDynamically(String key) async {
    // Initialize cache map if not exists
    _dynamicCache[_currentLanguage] ??= {};
    
    // Mark as pending to avoid multiple translation requests for the same string
    if (_dynamicCache[_currentLanguage]!.containsKey(key)) return;
    _dynamicCache[_currentLanguage]![key] = key; // temporary placeholder
    
    try {
      final languageCode = _getLanguageCode(_currentLanguage);
      if (languageCode.isEmpty) return; // Unsupported language
      
      final translation = await _translator.translate(key, to: languageCode);
      _dynamicCache[_currentLanguage]![key] = translation.text;
      _debouncedNotifyListeners(); // Rebuild UI with translated text
    } catch (e) {
      print("Translation error: $e");
    }
  }
  
  String _getLanguageCode(String language) {
    switch (language) {
      case 'Hindi': return 'hi';
      case 'Bengali': return 'bn';
      case 'Telugu': return 'te';
      case 'Marathi': return 'mr';
      case 'Tamil': return 'ta';
      case 'Urdu': return 'ur';
      case 'Gujarati': return 'gu';
      case 'Kannada': return 'kn';
      case 'Odia': return 'or'; // Odia language code for Google Translate
      case 'Malayalam': return 'ml';
      case 'Mandarin': return 'zh-cn'; // Simplified Chinese
      case 'Spanish': return 'es';
      case 'French': return 'fr';
      case 'Arabic': return 'ar';
      case 'Russian': return 'ru';
      case 'Portuguese': return 'pt';
      case 'German': return 'de';
      case 'Japanese': return 'ja';
      default: return '';
    }
  }

  void _debouncedNotifyListeners() {
    if (_notifyTimer?.isActive ?? false) _notifyTimer!.cancel();
    _notifyTimer = Timer(const Duration(milliseconds: 150), () {
      notifyListeners();
    });
  }

  static const Map<String, Map<String, String>> _translations = {
    'English': {
      'WorkSync': 'WorkSync',
      'Dashboard': 'Dashboard',
      'Projects': 'Projects',
      'Tasks': 'Tasks',
      'Clients': 'Clients',
      'Profile': 'Profile',
      'Team': 'Team',
      'Account Settings': 'Account Settings',
      'Edit Profile': 'Edit Profile',
      'Notifications': 'Notifications',
      'Security': 'Security',
      'Preferences': 'Preferences',
      'Language': 'Language',
      'Dark Mode': 'Dark Mode',
      'More': 'More',
      'Help Center': 'Help Center',
      'About WorkSync': 'About WorkSync',
      'Logout': 'Logout',
      'Add Task': 'Add Task',
      'Add Project': 'Add Project',
      'Due Today': 'Due Today',
      'Due Soon': 'Due Soon',
      'Completed': 'Completed',
      'In Progress': 'In Progress',
      'Pending': 'Pending',
      'Coming soon!': 'Coming soon!',
    },
    'Hindi': {
      'WorkSync': 'वर्कसिंक',
      'Dashboard': 'डैशबोर्ड',
      'Projects': 'परियोजनाएं',
      'Tasks': 'कार्य',
      'Clients': 'ग्राहक',
      'Profile': 'प्रोफ़ाइल',
      'Team': 'टीम',
      'Account Settings': 'खाता सेटिंग्स',
      'Edit Profile': 'प्रोफ़ाइल संपादित करें',
      'Notifications': 'सूचनाएं',
      'Security': 'सुरक्षा',
      'Preferences': 'प्राथमिकताएं',
      'Language': 'भाषा',
      'Dark Mode': 'डार्क मोड',
      'More': 'अधिक',
      'Help Center': 'सहायता केंद्र',
      'About WorkSync': 'WorkSync के बारे में',
      'Logout': 'लॉग आउट',
      'Add Task': 'कार्य जोड़ें',
      'Add Project': 'परियोजना जोड़ें',
      'Due Today': 'आज देय',
      'Due Soon': 'जल्द ही देय',
      'Completed': 'पूरा हुआ',
      'In Progress': 'प्रगति पर',
      'Pending': 'लंबित',
      'Coming soon!': 'जल्द आ रहा है!',
    },
    'Bengali': {
      'WorkSync': 'ওয়ার্কসিঙ্ক',
      'Dashboard': 'ড্যাশবোর্ড',
      'Projects': 'প্রকল্প',
      'Tasks': 'কাজ',
      'Clients': 'গ্রাহক',
      'Profile': 'প্রোফাইল',
      'Team': 'দল',
      'Account Settings': 'অ্যাকাউন্ট সেটিংস',
      'Edit Profile': 'প্রোফাইল সম্পাদনা করুন',
      'Notifications': 'বিজ্ঞপ্তি',
      'Security': 'নিরাপত্তা',
      'Preferences': 'পছন্দসমূহ',
      'Language': 'ভাষা',
      'Dark Mode': 'ডার্ক মোড',
      'More': 'আরও',
      'Help Center': 'সহায়তা কেন্দ্র',
      'About WorkSync': 'WorkSync সম্পর্কে',
      'Logout': 'লগআউট',
      'Add Task': 'কাজ যোগ করুন',
      'Add Project': 'প্রকল্প যোগ করুন',
      'Due Today': 'আজ জমা',
      'Due Soon': 'শীঘ্রই জমা',
      'Completed': 'সম্পন্ন',
      'In Progress': 'চলমান',
      'Pending': 'বিচারাধীন',
      'Coming soon!': 'শীঘ্রই আসছে!',
    },
    'Telugu': {
      'WorkSync': 'వర్క్‌సింక్',
      'Dashboard': 'డాష్‌బోర్డ్',
      'Projects': 'ప్రాజెక్ట్‌లు',
      'Tasks': 'పనులు',
      'Clients': 'క్లయింట్లు',
      'Profile': 'ప్రొఫైల్',
      'Team': 'బృందం',
      'Account Settings': 'ఖాతా సెట్టింగ్‌లు',
      'Edit Profile': 'ప్రొఫైల్ సవరించండి',
      'Notifications': 'నోటిఫికేషన్లు',
      'Security': 'భద్రత',
      'Preferences': 'ప్రాధాన్యతలు',
      'Language': 'భాష',
      'Dark Mode': 'డార్క్ మోడ్',
      'More': 'మరింత',
      'Help Center': 'సహాయ కేంద్రం',
      'About WorkSync': 'WorkSync గురించి',
      'Logout': 'లాగ్అవుట్',
      'Add Task': 'పనిని జోడించండి',
      'Add Project': 'ప్రాజెక్ట్‌ను జోడించండి',
      'Due Today': 'ఈరోజు బకాయి',
      'Due Soon': 'త్వరలో బకాయి',
      'Completed': 'పూర్తయింది',
      'In Progress': 'కొనసాగుతోంది',
      'Pending': 'పెండింగ్',
      'Coming soon!': 'త్వరలో రాబోతోంది!',
    },
    'Marathi': {
      'WorkSync': 'वर्कसिंक',
      'Dashboard': 'डॅशबोर्ड',
      'Projects': 'प्रकल्प',
      'Tasks': 'कामे',
      'Clients': 'क्लायंट्स',
      'Profile': 'प्रोफाइल',
      'Team': 'टीम',
      'Account Settings': 'खाते सेटिंग्ज',
      'Edit Profile': 'प्रोफाइल संपादित करा',
      'Notifications': 'सूचना',
      'Security': 'सुरक्षा',
      'Preferences': 'प्राधान्ये',
      'Language': 'भाषा',
      'Dark Mode': 'डार्क मोड',
      'More': 'अधिक',
      'Help Center': 'मदत केंद्र',
      'About WorkSync': 'WorkSync बद्दल',
      'Logout': 'लॉगआउट',
      'Add Task': 'काम जोडा',
      'Add Project': 'प्रकल्प जोडा',
      'Due Today': 'आज देय',
      'Due Soon': 'लवकरच देय',
      'Completed': 'पूर्ण झाले',
      'In Progress': 'प्रगतीपथावर',
      'Pending': 'प्रलंबित',
      'Coming soon!': 'लवकरच येत आहे!',
    },
    'Tamil': {
      'WorkSync': 'வொர்க்சிங்க்',
      'Dashboard': 'முகப்பு',
      'Projects': 'திட்டங்கள்',
      'Tasks': 'பணிகள்',
      'Clients': 'வாடிக்கையாளர்கள்',
      'Profile': 'சுயவிவரம்',
      'Team': 'குழு',
      'Account Settings': 'கணக்கு அமைப்புகள்',
      'Edit Profile': 'சுயவிவரத்தைத் திருத்து',
      'Notifications': 'அறிவிப்புகள்',
      'Security': 'பாதுகாப்பு',
      'Preferences': 'விருப்பங்கள்',
      'Language': 'மொழி',
      'Dark Mode': 'இருண்ட முறை',
      'More': 'மேலும்',
      'Help Center': 'உதவி மையம்',
      'About WorkSync': 'WorkSync பற்றி',
      'Logout': 'வெளியேறு',
      'Add Task': 'பணியைச் சேர்',
      'Add Project': 'திட்டத்தைச் சேர்',
      'Due Today': 'இன்று நிலுவை',
      'Due Soon': 'விரைவில் நிலுவை',
      'Completed': 'முடிந்தது',
      'In Progress': 'செயலில்',
      'Pending': 'நிலுவையில்',
      'Coming soon!': 'விரைவில் வருகிறது!',
    },
    'Urdu': {
      'WorkSync': 'ورک سنک',
      'Dashboard': 'ڈیش بورڈ',
      'Projects': 'منصوبے',
      'Tasks': 'کاما',
      'Clients': 'کلائنٹس',
      'Profile': 'پروفائل',
      'Team': 'ٹیم',
      'Account Settings': 'اکاؤنٹ کی ترتیبات',
      'Edit Profile': 'پروفائل میں ترمیم کریں',
      'Notifications': 'اطلاعات',
      'Security': 'سیکیورٹی',
      'Preferences': 'ترجیحات',
      'Language': 'زبان',
      'Dark Mode': 'ڈارک موڈ',
      'More': 'مزید',
      'Help Center': 'ہیلپ سینٹر',
      'About WorkSync': 'WorkSync کے بارے میں',
      'Logout': 'لاگ آؤٹ',
      'Add Task': 'کام شامل کریں',
      'Add Project': 'پروجیکٹ شامل کریں',
      'Due Today': 'آج مقرر',
      'Due Soon': 'جلد مقرر',
      'Completed': 'مکمل',
      'In Progress': 'جاری ہے',
      'Pending': 'زیر التوا',
      'Coming soon!': 'جلد آرہا ہے!',
    },
    'Gujarati': {
      'WorkSync': 'વર્કસિંક',
      'Dashboard': 'ડેશબોર્ડ',
      'Projects': 'પ્રોજેક્ટ્સ',
      'Tasks': 'કાર્યો',
      'Clients': 'ગ્રાહકો',
      'Profile': 'પ્રોફાઇલ',
      'Team': 'ટીમ',
      'Account Settings': 'એકાઉન્ટ સેટિંગ્સ',
      'Edit Profile': 'પ્રોફાઇલ સંપાદિત કરો',
      'Notifications': 'સૂચનાઓ',
      'Security': 'સુરક્ષા',
      'Preferences': 'પસંદગીઓ',
      'Language': 'ભાષા',
      'Dark Mode': 'ડાર્ક મોડ',
      'More': 'વધુ',
      'Help Center': 'સહાય કેન્દ્ર',
      'About WorkSync': 'WorkSync વિશે',
      'Logout': 'લૉગ આઉટ',
      'Add Task': 'કાર્ય ઉમેરો',
      'Add Project': 'પ્રોજેક્ટ ઉમેરો',
      'Due Today': 'આજે બાકી',
      'Due Soon': 'જલ્દી બાકી',
      'Completed': 'પૂર્ણ',
      'In Progress': 'પ્રગતિમાં',
      'Pending': 'બાકી',
      'Coming soon!': 'જલ્દી આવે છે!',
    },
    'Kannada': {
      'WorkSync': 'ವರ್ಕ್ ಸಿಂಕ್',
      'Dashboard': 'ಡ್ಯಾಶ್‌ಬೋರ್ಡ್',
      'Projects': 'ಯೋಜನೆಗಳು',
      'Tasks': 'ಕಾರ್ಯಗಳು',
      'Clients': 'ಗ್ರಾಹಕರು',
      'Profile': 'ಪ್ರೊಫೈಲ್',
      'Team': 'ತಂಡ',
      'Account Settings': 'ಖಾತೆ ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
      'Edit Profile': 'ಪ್ರೊಫೈಲ್ ಸಂಪಾದಿಸಿ',
      'Notifications': 'ಅಧಿಸೂಚನೆಗಳು',
      'Security': 'ಭದ್ರತೆ',
      'Preferences': 'ಆದ್ಯತೆಗಳು',
      'Language': 'ಭಾಷೆ',
      'Dark Mode': 'ಡಾರ್ಕ್ ಮೋಡ್',
      'More': 'ಹೆಚ್ಚು',
      'Help Center': 'ಸಹಾಯ ಕೇಂದ್ರ',
      'About WorkSync': 'WorkSync ಬಗ್ಗೆ',
      'Logout': 'ಲಾಗ್ ಔಟ್',
      'Add Task': 'ಕಾರ್ಯ ಸೇರಿಸಿ',
      'Add Project': 'ಯೋಜನೆ ಸೇರಿಸಿ',
      'Due Today': 'ಇಂದು ಬಾಕಿ',
      'Due Soon': 'ಶೀಘ್ರದಲ್ಲೇ ಬಾಕಿ',
      'Completed': 'ಪೂರ್ಣಗೊಂಡಿದೆ',
      'In Progress': 'ಪ್ರಗತಿಯಲ್ಲಿದೆ',
      'Pending': 'ಬಾಕಿ ಉಳಿದಿದೆ',
      'Coming soon!': 'ಶೀಘ್ರದಲ್ಲೇ ಬರಲಿದೆ!',
    },
    'Odia': {
      'WorkSync': 'ୱାର୍କସିଙ୍କ',
      'Dashboard': 'ଡ୍ୟାସବୋର୍ଡ',
      'Projects': 'ପ୍ରକଳ୍ପ',
      'Tasks': 'କାର୍ଯ୍ୟ',
      'Clients': 'ଗ୍ରାହକ',
      'Profile': 'ପ୍ରୋଫାଇଲ୍',
      'Team': 'ଦଳ',
      'Account Settings': 'ଆକାଉଣ୍ଟ ସେଟିଂସ',
      'Edit Profile': 'ପ୍ରୋଫାଇଲ୍ ଏଡିଟ୍ କରନ୍ତୁ',
      'Notifications': 'ବିଜ୍ଞପ୍ତି',
      'Security': 'ସୁରକ୍ଷା',
      'Preferences': 'ପସନ୍ଦ',
      'Language': 'ଭାଷା',
      'Dark Mode': 'ଡାର୍କ ମୋଡ୍',
      'More': 'ଅଧିକ',
      'Help Center': 'ସାହାଯ୍ୟ କେନ୍ଦ୍ର',
      'About WorkSync': 'WorkSync ବିଷୟରେ',
      'Logout': 'ଲଗଆଉଟ୍',
      'Add Task': 'କାର୍ଯ୍ୟ ଯୋଡନ୍ତୁ',
      'Add Project': 'ପ୍ରକଳ୍ପ ଯୋଡନ୍ତୁ',
      'Due Today': 'ଆଜି ବାକି',
      'Due Soon': 'ଶୀଘ୍ର ବାକି',
      'Completed': 'ସମ୍ପୂର୍ଣ୍ଣ',
      'In Progress': 'ପ୍ରଗତିରେ ଅଛି',
      'Pending': 'ପେଣ୍ଡିଂ',
      'Coming soon!': 'ଶୀଘ୍ର ଆସୁଛି!',
    },
    'Malayalam': {
      'WorkSync': 'വർക്ക്സിങ്ക്',
      'Dashboard': 'ഡാഷ്ബോർഡ്',
      'Projects': 'പ്രോജക്റ്റുകൾ',
      'Tasks': 'ചുമതലകൾ',
      'Clients': 'ക്ലയന്റുകൾ',
      'Profile': 'പ്രൊഫൈൽ',
      'Team': 'ടീം',
      'Account Settings': 'അക്കൗണ്ട് ക്രമീകരണങ്ങൾ',
      'Edit Profile': 'പ്രൊഫൈൽ എഡിറ്റ് ചെയ്യുക',
      'Notifications': 'അറിയിപ്പുകൾ',
      'Security': 'സുരക്ഷ',
      'Preferences': 'മുൻഗണനകൾ',
      'Language': 'ഭാഷ',
      'Dark Mode': 'ഡാർക്ക് മോഡ്',
      'More': 'കൂടുതൽ',
      'Help Center': 'സഹായ കേന്ദ്രം',
      'About WorkSync': 'WorkSync കുറിച്ച്',
      'Logout': 'ലോഗൗട്ട്',
      'Add Task': 'ചുമതല ചേർക്കുക',
      'Add Project': 'പ്രോജക്റ്റ് ചേർക്കുക',
      'Due Today': 'ഇന്ന് നൽകേണ്ടത്',
      'Due Soon': 'ഉടൻ നൽകേണ്ടത്',
      'Completed': 'പൂർത്തിയായി',
      'In Progress': 'പുരോഗമിക്കുന്നു',
      'Pending': 'തീരുമാനിച്ചിട്ടില്ല',
      'Coming soon!': 'ഉടൻ വരുന്നു!',
    },
    'Mandarin': {
      'WorkSync': 'WorkSync',
      'Dashboard': '仪表板',
      'Projects': '项目',
      'Tasks': '任务',
      'Clients': '客户',
      'Profile': '简介',
      'Team': '团队',
      'Account Settings': '账户设置',
      'Edit Profile': '编辑简介',
      'Notifications': '通知',
      'Security': '安全',
      'Preferences': '偏好',
      'Language': '语言',
      'Dark Mode': '暗黑模式',
      'More': '更多',
      'Help Center': '帮助中心',
      'About WorkSync': '关于 WorkSync',
      'Logout': '登出',
      'Add Task': '添加任务',
      'Add Project': '添加项目',
      'Due Today': '今日到期',
      'Due Soon': '即将到期',
      'Completed': '已完成',
      'In Progress': '进行中',
      'Pending': '待处理',
      'Coming soon!': '敬请期待！',
    },
    'Spanish': {
      'WorkSync': 'WorkSync',
      'Dashboard': 'Tablero',
      'Projects': 'Proyectos',
      'Tasks': 'Tareas',
      'Clients': 'Clientes',
      'Profile': 'Perfil',
      'Team': 'Equipo',
      'Account Settings': 'Configuración de cuenta',
      'Edit Profile': 'Editar perfil',
      'Notifications': 'Notificaciones',
      'Security': 'Seguridad',
      'Preferences': 'Preferencias',
      'Language': 'Idioma',
      'Dark Mode': 'Modo oscuro',
      'More': 'Más',
      'Help Center': 'Centro de ayuda',
      'About WorkSync': 'Acerca de WorkSync',
      'Logout': 'Cerrar sesión',
      'Add Task': 'Agregar tarea',
      'Add Project': 'Agregar proyecto',
      'Due Today': 'Vence hoy',
      'Due Soon': 'Vence pronto',
      'Completed': 'Completado',
      'In Progress': 'En progreso',
      'Pending': 'Pendiente',
      'Coming soon!': '¡Próximamente!',
    },
    'French': {
      'WorkSync': 'WorkSync',
      'Dashboard': 'Tableau de bord',
      'Projects': 'Projets',
      'Tasks': 'Tâches',
      'Clients': 'Clients',
      'Profile': 'Profil',
      'Team': 'Équipe',
      'Account Settings': 'Paramètres du compte',
      'Edit Profile': 'Modifier le profil',
      'Notifications': 'Notifications',
      'Security': 'Sécurité',
      'Preferences': 'Préférences',
      'Language': 'Langue',
      'Dark Mode': 'Mode sombre',
      'More': 'Plus',
      'Help Center': 'Centre d\'aide',
      'About WorkSync': 'À propos de WorkSync',
      'Logout': 'Déconnexion',
      'Add Task': 'Ajouter une tâche',
      'Add Project': 'Ajouter un projet',
      'Due Today': 'Dû aujourd\'hui',
      'Due Soon': 'Dû bientôt',
      'Completed': 'Terminé',
      'In Progress': 'En cours',
      'Pending': 'En attente',
      'Coming soon!': 'Bientôt disponible!',
    },
    'Arabic': {
      'WorkSync': 'WorkSync',
      'Dashboard': 'لوحة القيادة',
      'Projects': 'المشاريع',
      'Tasks': 'المهام',
      'Clients': 'العملاء',
      'Profile': 'الملف الشخصي',
      'Team': 'فريق',
      'Account Settings': 'إعدادات الحساب',
      'Edit Profile': 'تعديل الملف الشخصي',
      'Notifications': 'الإشعارات',
      'Security': 'الأمان',
      'Preferences': 'التفضيلات',
      'Language': 'اللغة',
      'Dark Mode': 'الوضع المظلم',
      'More': 'المزيد',
      'Help Center': 'مركز المساعدة',
      'About WorkSync': 'حول WorkSync',
      'Logout': 'تسجيل الخروج',
      'Add Task': 'إضافة مهمة',
      'Add Project': 'إضافة مشروع',
      'Due Today': 'مستحق اليوم',
      'Due Soon': 'مستحق قريبا',
      'Completed': 'مكتمل',
      'In Progress': 'قيد التقدم',
      'Pending': 'قيد الانتظار',
      'Coming soon!': 'قريباً!',
    },
    'Russian': {
      'WorkSync': 'WorkSync',
      'Dashboard': 'Панель приборов',
      'Projects': 'Проекты',
      'Tasks': 'Задачи',
      'Clients': 'Клиенты',
      'Profile': 'Профиль',
      'Team': 'Команда',
      'Account Settings': 'Настройки аккаунта',
      'Edit Profile': 'Редактировать профиль',
      'Notifications': 'Уведомления',
      'Security': 'Безопасность',
      'Preferences': 'Предпочтения',
      'Language': 'Язык',
      'Dark Mode': 'Темный режим',
      'More': 'Больше',
      'Help Center': 'Справочный центр',
      'About WorkSync': 'О WorkSync',
      'Logout': 'Выйти',
      'Add Task': 'Добавить задачу',
      'Add Project': 'Добавить проект',
      'Due Today': 'Срок сегодня',
      'Due Soon': 'Скоро срок',
      'Completed': 'Завершено',
      'In Progress': 'В процессе',
      'Pending': 'В ожидании',
      'Coming soon!': 'Скоро!',
    },
    'Portuguese': {
      'WorkSync': 'WorkSync',
      'Dashboard': 'Painel',
      'Projects': 'Projetos',
      'Tasks': 'Tarefas',
      'Clients': 'Clientes',
      'Profile': 'Perfil',
      'Team': 'Equipe',
      'Account Settings': 'Configurações da conta',
      'Edit Profile': 'Editar Perfil',
      'Notifications': 'Notificações',
      'Security': 'Segurança',
      'Preferences': 'Preferências',
      'Language': 'Idioma',
      'Dark Mode': 'Modo Escuro',
      'More': 'Mais',
      'Help Center': 'Centro de Ajuda',
      'About WorkSync': 'Sobre WorkSync',
      'Logout': 'Sair',
      'Add Task': 'Adicionar tarefa',
      'Add Project': 'Adicionar projeto',
      'Due Today': 'Vence hoje',
      'Due Soon': 'Vence em breve',
      'Completed': 'Concluído',
      'In Progress': 'Em andamento',
      'Pending': 'Pendente',
      'Coming soon!': 'Em breve!',
    },
    'German': {
      'WorkSync': 'WorkSync',
      'Dashboard': 'Armaturenbrett',
      'Projects': 'Projekte',
      'Tasks': 'Aufgaben',
      'Clients': 'Kunden',
      'Profile': 'Profil',
      'Team': 'Team',
      'Account Settings': 'Kontoeinstellungen',
      'Edit Profile': 'Profil bearbeiten',
      'Notifications': 'Benachrichtigungen',
      'Security': 'Sicherheit',
      'Preferences': 'Präferenzen',
      'Language': 'Sprache',
      'Dark Mode': 'Dunkler Modus',
      'More': 'Mehr',
      'Help Center': 'Hilfezentrum',
      'About WorkSync': 'Über WorkSync',
      'Logout': 'Abmelden',
      'Add Task': 'Aufgabe hinzufügen',
      'Add Project': 'Projekt hinzufügen',
      'Due Today': 'Heute fällig',
      'Due Soon': 'Bald fällig',
      'Completed': 'Abgeschlossen',
      'In Progress': 'In Bearbeitung',
      'Pending': 'Ausstehend',
      'Coming soon!': 'Demnächst!',
    },
    'Japanese': {
      'WorkSync': 'WorkSync',
      'Dashboard': 'ダッシュボード',
      'Projects': 'プロジェクト',
      'Tasks': 'タスク',
      'Clients': 'クライアント',
      'Profile': 'プロフィール',
      'Team': 'チーム',
      'Account Settings': 'アカウント設定',
      'Edit Profile': 'プロフィール編集',
      'Notifications': '通知',
      'Security': 'セキュリティ',
      'Preferences': '設定',
      'Language': '言語',
      'Dark Mode': 'ダークモード',
      'More': 'もっと',
      'Help Center': 'ヘルプセンター',
      'About WorkSync': 'WorkSyncについて',
      'Logout': 'ログアウト',
      'Add Task': 'タスクを追加',
      'Add Project': 'プロジェクトを追加',
      'Due Today': '今日が期限',
      'Due Soon': 'もうすぐ期限',
      'Completed': '完了',
      'In Progress': '進行中',
      'Pending': '保留中',
      'Coming soon!': '近日公開！',
    },
  };
}
