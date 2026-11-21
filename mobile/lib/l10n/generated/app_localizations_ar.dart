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

  @override
  String get homeFeatured => 'مميز';

  @override
  String get homeLatest => 'أحدث الإعلانات';

  @override
  String get exploreSearchHint => 'ابحث عن عقار';

  @override
  String get txSale => 'للبيع';

  @override
  String get txRent => 'للإيجار';

  @override
  String get txShortTermRent => 'إيجار قصير';

  @override
  String get txInvestment => 'استثمار';

  @override
  String get filterAll => 'الكل';

  @override
  String get emptyProperties => 'لا توجد عقارات';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get negotiable => 'قابل للتفاوض';

  @override
  String get sqm => 'م²';

  @override
  String get loadMore => 'المزيد';

  @override
  String get specBedrooms => 'غرف النوم';

  @override
  String get specBathrooms => 'الحمامات';

  @override
  String get specArea => 'المساحة';

  @override
  String get specFloors => 'الطوابق';

  @override
  String get specCondition => 'الحالة';

  @override
  String get specFurnishing => 'الأثاث';

  @override
  String get specParking => 'موقف سيارات';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get descriptionTitle => 'الوصف';

  @override
  String get specsTitle => 'التفاصيل';

  @override
  String get ownerTitle => 'صاحب الإعلان';

  @override
  String get contactCall => 'اتصال';

  @override
  String get contactWhatsApp => 'واتساب';

  @override
  String get favoritesEmpty => 'لا توجد عقارات محفوظة بعد';

  @override
  String get condNew => 'جديد';

  @override
  String get condExcellent => 'ممتاز';

  @override
  String get condGood => 'جيد';

  @override
  String get condNeedsRenovation => 'يحتاج ترميم';

  @override
  String get condUnderConstruction => 'قيد الإنشاء';

  @override
  String get furnUnfurnished => 'غير مفروش';

  @override
  String get furnSemi => 'نصف مفروش';

  @override
  String get furnFurnished => 'مفروش';

  @override
  String get notFound => 'هذا الإعلان لم يعد متاحاً';

  @override
  String get views => 'المشاهدات';

  @override
  String get publishedOn => 'تاريخ النشر';

  @override
  String get fieldCategory => 'نوع العقار';

  @override
  String get fieldTransaction => 'نوع الإعلان';

  @override
  String get fieldTitle => 'عنوان الإعلان';

  @override
  String get fieldDescription => 'الوصف';

  @override
  String get fieldPrice => 'السعر';

  @override
  String get fieldCurrency => 'العملة';

  @override
  String get fieldNegotiable => 'السعر قابل للتفاوض';

  @override
  String get fieldGovernorate => 'المحافظة';

  @override
  String get fieldDistrict => 'القضاء';

  @override
  String get fieldArea => 'المساحة (م²)';

  @override
  String get fieldAddress => 'العنوان (اختياري)';

  @override
  String get fieldBedrooms => 'غرف النوم';

  @override
  String get fieldBathrooms => 'الحمامات';

  @override
  String get fieldFloors => 'الطوابق';

  @override
  String get saveDraft => 'حفظ المسودة';

  @override
  String get draftSaved => 'تم حفظ المسودة';

  @override
  String get validationRequired => 'مطلوب';

  @override
  String get validationTitleLen => 'العنوان من 5 إلى 120 حرفاً';

  @override
  String get validationNumber => 'أدخل رقماً صحيحاً';

  @override
  String get addPropertyIntro => 'تفاصيل العقار';

  @override
  String get mediaTitle => 'الصور';

  @override
  String get mediaAdd => 'إضافة صور';

  @override
  String get mediaEmpty => 'لا توجد صور بعد. يمكنك إضافة حتى 20 صورة.';

  @override
  String mediaUploading(int done, int total) {
    return 'جارٍ رفع $done من $total';
  }

  @override
  String get mediaFailed => 'فشل رفع بعض الصور';

  @override
  String get mediaDelete => 'حذف الصورة';

  @override
  String get mediaCover => 'الغلاف';

  @override
  String get mediaLimit => 'الحد الأقصى 20 صورة';

  @override
  String get mediaApiMissing => 'عنوان الخادم غير مضبوط';

  @override
  String get addPhotosNow => 'إضافة صور';

  @override
  String get profileGuestTitle => 'سجّل الدخول إلى حسابك';

  @override
  String get profileGuestBody =>
      'سجّل الدخول لحفظ المفضلة ونشر العقارات والتواصل مع الملاك.';

  @override
  String get authContinueGuest => 'المتابعة كزائر';

  @override
  String get authSignIn => 'تسجيل الدخول / إنشاء حساب';

  @override
  String get loginRequiredHint => 'سجّل الدخول للمتابعة';

  @override
  String get onboardingTitle => 'أكمل ملفك الشخصي';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get fieldFullName => 'الاسم الكامل';

  @override
  String get fieldAccountType => 'نوع الحساب';

  @override
  String get accountIndividual => 'فرد';

  @override
  String get accountOwner => 'مالك عقار';

  @override
  String get accountAgent => 'وسيط عقاري';

  @override
  String get accountCompany => 'شركة عقارية';

  @override
  String get accountDeveloper => 'مطوّر عقاري';

  @override
  String get saveProfile => 'حفظ';

  @override
  String get profileSaved => 'تم حفظ الملف الشخصي';

  @override
  String get roleMember => 'عضو';

  @override
  String get roleModerator => 'مشرف';

  @override
  String get roleAdmin => 'مدير';

  @override
  String get roleSuperAdmin => 'مدير عام';

  @override
  String get fieldGovernorateOptional => 'المحافظة (اختياري)';

  @override
  String get fieldDistrictOptional => 'القضاء (اختياري)';

  @override
  String get validationName => 'الاسم من 2 إلى 80 حرفاً';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountTitle => 'حذف حسابك؟';

  @override
  String get deleteAccountBody =>
      'ستتم إزالة بياناتك الشخصية ولن تظهر إعلاناتك بعد الآن. تُحفظ سجلات الدفع كما يقتضي القانون. لا يمكن التراجع عن ذلك.';

  @override
  String get deleteAccountConfirm => 'حذف';

  @override
  String get cancel => 'إلغاء';

  @override
  String get deleteAccountFailed => 'تعذّر حذف الحساب. حاول مرة أخرى.';

  @override
  String get photosSectionTitle => 'الصور';

  @override
  String get photosCoverHint => 'اضغط على صورة لجعلها صورة الغلاف.';

  @override
  String get photosRequired => 'أضف صورة واحدة على الأقل.';

  @override
  String get myPropertiesTitle => 'عقاراتي';

  @override
  String get myPropertiesEmpty => 'لم تضف أي عقار بعد.';

  @override
  String get statusDraft => 'مسودة';

  @override
  String get statusPendingPayment => 'بانتظار الدفع';

  @override
  String get statusPendingApproval => 'بانتظار الموافقة';

  @override
  String get statusPublished => 'منشور';

  @override
  String get statusRejected => 'مرفوض';
}
