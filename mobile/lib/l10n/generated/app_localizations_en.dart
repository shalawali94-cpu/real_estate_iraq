// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Real Estate Iraq';

  @override
  String get navHome => 'Home';

  @override
  String get navExplore => 'Explore';

  @override
  String get navAdd => 'Add';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navProfile => 'Profile';

  @override
  String get addPropertyTitle => 'Add Property';

  @override
  String get phaseNotice => 'This section is built in Phase 5';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageKurdish => 'کوردی';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get authWelcomeTitle => 'Welcome';

  @override
  String get authPhoneLabel => 'Mobile number';

  @override
  String get authPhoneHelp =>
      'Enter your number to receive a verification code';

  @override
  String get authSendCode => 'Send code';

  @override
  String get authEnterCodeTitle => 'Verification code';

  @override
  String authCodeSentTo(String phone) {
    return 'Code sent to $phone';
  }

  @override
  String get authVerify => 'Verify';

  @override
  String get authResend => 'Resend code';

  @override
  String get authInvalidPhone => 'Enter a valid Iraqi mobile number';

  @override
  String get authInvalidCode => 'The code is 6 digits';

  @override
  String get authGenericError => 'Something went wrong, please try again';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get authChangeNumber => 'Change number';
}
