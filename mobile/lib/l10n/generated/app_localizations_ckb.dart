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

  @override
  String get deleteAccount => 'سڕینەوەی ئەکاونت';

  @override
  String get deleteAccountTitle => 'ئەکاونتەکەت دەسڕیتەوە؟';

  @override
  String get deleteAccountBody =>
      'زانیارییە کەسییەکانت دەسڕدرێنەوە و ڕیکلامەکانت چیتر نابینرێن. تۆمارەکانی پارەدان بەپێی پێویست دەمێننەوە. ئەم کارە ناگەڕێتەوە.';

  @override
  String get deleteAccountConfirm => 'بسڕەوە';

  @override
  String get cancel => 'هەڵوەشاندنەوە';

  @override
  String get deleteAccountFailed =>
      'نەتوانرا ئەکاونتەکە بسڕدرێتەوە. دووبارە هەوڵبدەرەوە.';

  @override
  String get photosSectionTitle => 'وێنەکان';

  @override
  String get photosCoverHint =>
      'لەسەر وێنەیەک دابگرە بۆ ئەوەی ببێتە وێنەی بەرگ.';

  @override
  String get photosRequired => 'لانیکەم یەک وێنە زیاد بکە.';

  @override
  String get myPropertiesTitle => 'مولکەکانم';

  @override
  String get myPropertiesEmpty => 'هێشتا هیچ مولکێکت زیاد نەکردووە.';

  @override
  String get statusDraft => 'دراف';

  @override
  String get statusPendingPayment => 'چاوەڕێی پارەدان';

  @override
  String get statusPendingApproval => 'چاوەڕێی پەسەندکردن';

  @override
  String get statusPublished => 'بڵاوکراوەتەوە';

  @override
  String get statusRejected => 'ڕەتکرایەوە';

  @override
  String get reviewTitle => 'پێداچوونەوە و بڵاوکردنەوە';

  @override
  String get reviewFeeLabel => 'کرێی بڵاوکردنەوە';

  @override
  String get reviewFeeNote =>
      'یەک جار بۆ هەر ڕیکلامی فرۆشتنێک دەدرێت. پارەدان گەرەنتی پەسەندکردن نییە: هەموو ڕیکلامێک پێش بڵاوکردنەوە پێداچوونەوەی بۆ دەکرێت.';

  @override
  String get reviewContinue => 'بەردەوامبوون بۆ پارەدان';

  @override
  String get payChooseMethod => 'شێوازی پارەدان هەڵبژێرە';

  @override
  String get payFib => 'FIB';

  @override
  String get payQi => 'کارتی کیو (Qi Card)';

  @override
  String get payPayNow => 'پارەدان';

  @override
  String get payNotConfigured =>
      'پارەدانی ئۆنلاین هێشتا بەردەست نییە: دابینکەری پارەدان هێشتا ڕێکدەخرێت. ڕیکلامەکەت پاشەکەوت کراوە و هیچ پارەیەک نەبڕدراوە.';

  @override
  String get payOpened =>
      'پارەدانەکە لەو پەڕەیەی کرایەوە تەواو بکە، پاشان دۆخەکەی بپشکنە.';

  @override
  String get payCheck => 'پشکنینی دۆخی پارەدان';

  @override
  String get payStatusPaid =>
      'پارەدان وەرگیرا. ڕیکلامەکەت ئێستا چاوەڕێی پێداچوونەوەیە.';

  @override
  String get payStatusPending => 'پارەدان هێشتا پشتڕاست نەکراوەتەوە.';

  @override
  String get payStatusFailed =>
      'پارەدان سەرنەکەوت یان بەسەرچوو. تکایە دووبارە هەوڵبدەرەوە.';

  @override
  String get reviewWaitingApproval =>
      'ڕیکلامەکەت چاوەڕێی پێداچوونەوەی تیمەکەمانە.';

  @override
  String get reviewPublished => 'ڕیکلامەکەت بڵاوکراوەتەوە.';

  @override
  String get reviewNoFee =>
      'بۆ ئەم جۆرە ڕیکلامە کرێی بڵاوکردنەوە نییە. ڕاستەوخۆ دەنێردرێت بۆ پێداچوونەوە.';

  @override
  String get reviewSubmit => 'ناردن بۆ پێداچوونەوە';

  @override
  String get messagesTitle => 'نامەکان';

  @override
  String get messagesEmpty => 'هێشتا هیچ گفتوگۆیەک نییە.';

  @override
  String get contactMessage => 'نامە';

  @override
  String get chatHint => 'نامەیەک بنووسە…';

  @override
  String get chatEmpty => 'سڵاو بکە بۆ دەستپێکردنی گفتوگۆ.';

  @override
  String get chatSendFailed => 'نامەکە نەنێردرا. تکایە دووبارە هەوڵبدەرەوە.';

  @override
  String get chatOwnListing => 'ئەمە ڕیکلامی خۆتە.';

  @override
  String get chatOpenFailed => 'نەتوانرا گفتوگۆکە بکرێتەوە.';

  @override
  String get chatTyping => 'دەنووسێت…';

  @override
  String get chatOnline => 'ئۆنلاینە';

  @override
  String get fieldEmail => 'ئیمەیڵ';

  @override
  String get validationEmail => 'ئیمەیڵێکی دروست بنووسە.';

  @override
  String get authEmailSignIn => 'چوونەژوورەوە بە ئیمەیڵ';

  @override
  String get authUsePhone => 'چوونەژوورەوە بە ژمارەی مۆبایل';

  @override
  String get authPassword => 'پاسوۆرد';

  @override
  String get authCreateAccount => 'دروستکردنی ئەکاونت';

  @override
  String get authToSignIn => 'ئەکاونتت هەیە؟ بچۆ ژوورەوە';

  @override
  String get authToCreate => 'نوێیت؟ ئەکاونت دروست بکە';

  @override
  String get authPasswordShort => 'پاسوۆرد دەبێت لانیکەم ٦ پیت بێت';

  @override
  String get authWrongCredentials => 'ئیمەیڵ یان پاسوۆرد هەڵەیە';

  @override
  String get adminReviewTitle => 'پشکنینی ئیعلانەکان';

  @override
  String get adminStatusSuspended => 'ڕاگیراو';

  @override
  String get adminApprove => 'پەسەندکردن';

  @override
  String get adminReject => 'ڕەتکردنەوە';

  @override
  String get adminSuspend => 'ڕاگرتن';

  @override
  String get adminUnsuspend => 'لابردنی ڕاگرتن';

  @override
  String get adminView => 'بینین';

  @override
  String get adminEmpty => 'هیچ نییە';

  @override
  String get adminDone => 'کرا';

  @override
  String get adminReasonTitle => 'هۆکار';

  @override
  String get adminReasonHint => 'هۆکارەکە بنووسە (خاوەنەکەی دەیبینێت)';

  @override
  String get adminConfirm => 'دڵنیابوونەوە';

  @override
  String get adminOpenButton => 'پشکنینی ئیعلانەکان';

  @override
  String get filterTitle => 'فیلتەر';

  @override
  String get filterMinPrice => 'کەمترین نرخ';

  @override
  String get filterMaxPrice => 'زۆرترین نرخ';

  @override
  String get filterMinBedrooms => 'ژووری نوستن (کەمترین)';

  @override
  String get filterSort => 'ڕیزکردن بەپێی';

  @override
  String get filterApply => 'جێبەجێکردن';

  @override
  String get filterReset => 'گەڕاندنەوە';

  @override
  String get sortNewest => 'نوێترین';

  @override
  String get sortPriceAsc => 'کەمترین نرخ';

  @override
  String get sortPriceDesc => 'زۆرترین نرخ';

  @override
  String get sortArea => 'گەورەترین ڕووبەر';

  @override
  String get sortPopular => 'بەناوبانگترین';

  @override
  String get notifTitle => 'ئاگادارکردنەوەکان';

  @override
  String get notifMarkAllRead => 'هەمووی وەک خوێندراو دیاری بکە';

  @override
  String get notifEmpty => 'هێشتا هیچ ئاگادارکردنەوەیەک نییە';

  @override
  String get notifNewMessage => 'نامەی نوێ';

  @override
  String get notifPropertyApproved => 'ئیعلانەکەت پەسەند کرا';

  @override
  String get notifPropertyRejected => 'ئیعلانەکەت ڕەتکرایەوە';

  @override
  String get notifPropertySuspended => 'ئیعلانەکەت ڕاگیرا';

  @override
  String get notifPropertyRestored => 'ئیعلانەکەت گەڕێندرایەوە';

  @override
  String get notifPropertyExpired => 'ئیعلانەکەت بەسەرچوو';

  @override
  String get notifPaymentSuccess => 'پارەدان وەرگیرا';

  @override
  String get notifPaymentFailed => 'پارەدان سەرکەوتوو نەبوو';

  @override
  String get notifAiVideoDone => 'ڤیدیۆکەت ئامادەیە';

  @override
  String get notifAiVideoFailed => 'دروستکردنی ڤیدیۆ سەرکەوتوو نەبوو';

  @override
  String get notificationsButton => 'ئاگادارکردنەوەکان';
}
