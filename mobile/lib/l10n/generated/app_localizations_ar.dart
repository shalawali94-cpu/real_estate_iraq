// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'عقارات العراق';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navExplore => 'استكشاف';

  @override
  String get navAdd => 'إضافة';

  @override
  String get navFavorites => 'المفضلة';

  @override
  String get navProfile => 'الملف الشخصي';

  @override
  String get addPropertyTitle => 'إضافة عقار';

  @override
  String get phaseNotice => 'سيتم بناء هذا القسم في المرحلة ٥';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsTheme => 'المظهر';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get languageKurdish => 'کوردی';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get authWelcomeTitle => 'أهلاً بك';

  @override
  String get authPhoneLabel => 'رقم الجوال';

  @override
  String get authPhoneHelp => 'أدخل رقمك لاستلام رمز التحقق';

  @override
  String get authSendCode => 'إرسال الرمز';

  @override
  String get authEnterCodeTitle => 'رمز التحقق';

  @override
  String authCodeSentTo(String phone) {
    return 'تم إرسال الرمز إلى $phone';
  }

  @override
  String get authVerify => 'تحقق';

  @override
  String get authResend => 'إعادة إرسال الرمز';

  @override
  String get authInvalidPhone => 'أدخل رقم جوال عراقي صحيح';

  @override
  String get authInvalidCode => 'الرمز مكوّن من 6 أرقام';

  @override
  String get authGenericError => 'حدث خطأ، حاول مرة أخرى';

  @override
  String get authSignOut => 'تسجيل الخروج';

  @override
  String get authChangeNumber => 'تغيير الرقم';
}
