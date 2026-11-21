// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Central Kurdish (`ckb`).
class AppLocalizationsCkb extends AppLocalizations {
  AppLocalizationsCkb([String locale = 'ckb']) : super(locale);

  @override
  String get appTitle => 'خانووبەرەی عێراق';

  @override
  String get navHome => 'سەرەکی';

  @override
  String get navExplore => 'گەڕان';

  @override
  String get navAdd => 'زیادکردن';

  @override
  String get navFavorites => 'دڵخوازەکان';

  @override
  String get navProfile => 'پرۆفایل';

  @override
  String get addPropertyTitle => 'زیادکردنی خانووبەرە';

  @override
  String get phaseNotice => 'ئەم بەشە لە قۆناغی ٥ دروست دەکرێت';

  @override
  String get settingsLanguage => 'زمان';

  @override
  String get settingsTheme => 'ڕووکار';

  @override
  String get themeSystem => 'سیستەم';

  @override
  String get themeLight => 'ڕووناک';

  @override
  String get themeDark => 'تاریک';

  @override
  String get languageKurdish => 'کوردی';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get authWelcomeTitle => 'بەخێربێیت';

  @override
  String get authPhoneLabel => 'ژمارەی مۆبایل';

  @override
  String get authPhoneHelp => 'ژمارەکەت بنووسە بۆ وەرگرتنی کۆدی پشتڕاستکردنەوە';

  @override
  String get authSendCode => 'ناردنی کۆد';

  @override
  String get authEnterCodeTitle => 'کۆدی پشتڕاستکردنەوە';

  @override
  String authCodeSentTo(String phone) {
    return 'کۆد نێردرا بۆ $phone';
  }

  @override
  String get authVerify => 'پشتڕاستکردنەوە';

  @override
  String get authResend => 'ناردنەوەی کۆد';

  @override
  String get authInvalidPhone => 'ژمارەی مۆبایلی عێراقیی دروست بنووسە';

  @override
  String get authInvalidCode => 'کۆدەکە ٦ ژمارەیە';

  @override
  String get authGenericError => 'هەڵەیەک ڕوویدا، دووبارە هەوڵبدەرەوە';

  @override
  String get authSignOut => 'چوونەدەرەوە';

  @override
  String get authChangeNumber => 'گۆڕینی ژمارە';

  @override
  String get homeFeatured => 'تایبەت';

  @override
  String get homeLatest => 'دوایین ڕیکلامەکان';

  @override
  String get exploreSearchHint => 'گەڕان بەدوای موڵک';

  @override
  String get txSale => 'بۆ فرۆشتن';

  @override
  String get txRent => 'بۆ کرێ';

  @override
  String get txShortTermRent => 'کرێی کورتخایەن';

  @override
  String get txInvestment => 'وەبەرهێنان';

  @override
  String get filterAll => 'هەموو';

  @override
  String get emptyProperties => 'هیچ موڵکێک نەدۆزرایەوە';

  @override
  String get retry => 'دووبارە هەوڵبدەرەوە';

  @override
  String get negotiable => 'قابیلی دانوستان';

  @override
  String get sqm => 'م²';

  @override
  String get loadMore => 'زیاتر';

  @override
  String get specBedrooms => 'ژووری نووستن';

  @override
  String get specBathrooms => 'حەمام';

  @override
  String get specArea => 'ڕووبەر';

  @override
  String get specFloors => 'نهۆم';

  @override
  String get specCondition => 'دۆخ';

  @override
  String get specFurnishing => 'کەلوپەل';

  @override
  String get specParking => 'پارکینگ';

  @override
  String get yes => 'بەڵێ';

  @override
  String get no => 'نەخێر';

  @override
  String get descriptionTitle => 'وەسف';

  @override
  String get specsTitle => 'وردەکاری';

  @override
  String get ownerTitle => 'ڕیکلامکەر';

  @override
  String get contactCall => 'پەیوەندی';

  @override
  String get contactWhatsApp => 'واتسئاپ';

  @override
  String get favoritesEmpty => 'هێشتا هیچ موڵکێکت پاشەکەوت نەکردووە';

  @override
  String get condNew => 'نوێ';

  @override
  String get condExcellent => 'زۆر باش';

  @override
  String get condGood => 'باش';

  @override
  String get condNeedsRenovation => 'پێویستی بە نۆژەنکردنەوە هەیە';

  @override
  String get condUnderConstruction => 'لە ژێر بیناکردندایە';

  @override
  String get furnUnfurnished => 'بێ کەلوپەل';

  @override
  String get furnSemi => 'نیوە کەلوپەل';

  @override
  String get furnFurnished => 'بە کەلوپەل';

  @override
  String get notFound => 'ئەم ڕیکلامە چیتر بەردەست نییە';

  @override
  String get views => 'بینراو';

  @override
  String get publishedOn => 'بڵاوکراوەتەوە';

  @override
  String get fieldCategory => 'جۆری موڵک';

  @override
  String get fieldTransaction => 'جۆری ڕیکلام';

  @override
  String get fieldTitle => 'ناونیشانی ڕیکلام';

  @override
  String get fieldDescription => 'وەسف';

  @override
  String get fieldPrice => 'نرخ';

  @override
  String get fieldCurrency => 'دراو';

  @override
  String get fieldNegotiable => 'نرخ قابیلی دانوستانە';

  @override
  String get fieldGovernorate => 'پارێزگا';

  @override
  String get fieldDistrict => 'قەزا';

  @override
  String get fieldArea => 'ڕووبەر (م²)';

  @override
  String get fieldAddress => 'ناونیشان (ئارەزوومەندانە)';

  @override
  String get fieldBedrooms => 'ژووری نووستن';

  @override
  String get fieldBathrooms => 'حەمام';

  @override
  String get fieldFloors => 'نهۆم';

  @override
  String get saveDraft => 'پاشەکەوتکردنی ڕەشنووس';

  @override
  String get draftSaved => 'ڕەشنووس پاشەکەوت کرا';

  @override
  String get validationRequired => 'پێویستە';

  @override
  String get validationTitleLen => 'ناونیشان دەبێت لە ٥ بۆ ١٢٠ پیت بێت';

  @override
  String get validationNumber => 'ژمارەیەکی دروست بنووسە';

  @override
  String get addPropertyIntro => 'زانیاری موڵک';

  @override
  String get mediaTitle => 'وێنەکان';

  @override
  String get mediaAdd => 'زیادکردنی وێنە';

  @override
  String get mediaEmpty => 'هێشتا وێنەت نییە. دەتوانیت تا ٢٠ وێنە زیاد بکەیت.';

  @override
  String mediaUploading(int done, int total) {
    return 'بارکردنی $done لە $total';
  }

  @override
  String get mediaFailed => 'هەندێک وێنە بار نەکران';

  @override
  String get mediaDelete => 'سڕینەوەی وێنە';

  @override
  String get mediaCover => 'بەرگ';

  @override
  String get mediaLimit => 'زۆرینە ٢٠ وێنە';

  @override
  String get mediaApiMissing => 'ناونیشانی سێرڤەر ڕێکنەخراوە';

  @override
  String get addPhotosNow => 'زیادکردنی وێنە';

  @override
  String get profileGuestTitle => 'بچۆ ژوورەوە بۆ ئەکاونتەکەت';

  @override
  String get profileGuestBody =>
      'بچۆ ژوورەوە بۆ پاشەکەوتکردنی دڵخوازەکان، بڵاوکردنەوەی موڵک و پەیوەندی بە خاوەنەکانەوە.';

  @override
  String get authContinueGuest => 'بەردەوامبە وەک میوان';

  @override
  String get authSignIn => 'چوونەژوورەوە / دروستکردنی ئەکاونت';

  @override
  String get loginRequiredHint => 'بۆ بەردەوامبوون بچۆ ژوورەوە';

  @override
  String get onboardingTitle => 'پرۆفایلەکەت تەواو بکە';

  @override
  String get editProfile => 'دەستکاریکردنی پرۆفایل';

  @override
  String get fieldFullName => 'ناوی تەواو';

  @override
  String get fieldAccountType => 'جۆری ئەکاونت';

  @override
  String get accountIndividual => 'تاک';

  @override
  String get accountOwner => 'خاوەن موڵک';

  @override
  String get accountAgent => 'دەلاڵ';

  @override
  String get accountCompany => 'کۆمپانیای موڵک';

  @override
  String get accountDeveloper => 'گەشەپێدەری موڵک';

  @override
  String get saveProfile => 'پاشەکەوتکردن';

  @override
  String get profileSaved => 'پرۆفایل پاشەکەوت کرا';

  @override
  String get roleMember => 'ئەندام';

  @override
  String get roleModerator => 'چاودێر';

  @override
  String get roleAdmin => 'بەڕێوەبەر';

  @override
  String get roleSuperAdmin => 'بەڕێوەبەری باڵا';

  @override
  String get fieldGovernorateOptional => 'پارێزگا (ئارەزوومەندانە)';

  @override
  String get fieldDistrictOptional => 'قەزا (ئارەزوومەندانە)';

  @override
  String get validationName => 'ناو دەبێت لە ٢ بۆ ٨٠ پیت بێت';
}
