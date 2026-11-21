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

  @override
  String get homeFeatured => 'Featured';

  @override
  String get homeLatest => 'Latest listings';

  @override
  String get exploreSearchHint => 'Search properties';

  @override
  String get txSale => 'For sale';

  @override
  String get txRent => 'For rent';

  @override
  String get txShortTermRent => 'Short-term';

  @override
  String get txInvestment => 'Investment';

  @override
  String get filterAll => 'All';

  @override
  String get emptyProperties => 'No properties found';

  @override
  String get retry => 'Retry';

  @override
  String get negotiable => 'Negotiable';

  @override
  String get sqm => 'm²';

  @override
  String get loadMore => 'Load more';

  @override
  String get specBedrooms => 'Bedrooms';

  @override
  String get specBathrooms => 'Bathrooms';

  @override
  String get specArea => 'Area';

  @override
  String get specFloors => 'Floors';

  @override
  String get specCondition => 'Condition';

  @override
  String get specFurnishing => 'Furnishing';

  @override
  String get specParking => 'Parking';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get descriptionTitle => 'Description';

  @override
  String get specsTitle => 'Details';

  @override
  String get ownerTitle => 'Listed by';

  @override
  String get contactCall => 'Call';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get favoritesEmpty => 'No saved properties yet';

  @override
  String get condNew => 'New';

  @override
  String get condExcellent => 'Excellent';

  @override
  String get condGood => 'Good';

  @override
  String get condNeedsRenovation => 'Needs renovation';

  @override
  String get condUnderConstruction => 'Under construction';

  @override
  String get furnUnfurnished => 'Unfurnished';

  @override
  String get furnSemi => 'Semi-furnished';

  @override
  String get furnFurnished => 'Furnished';

  @override
  String get notFound => 'This listing is no longer available';

  @override
  String get views => 'Views';

  @override
  String get publishedOn => 'Published';

  @override
  String get fieldCategory => 'Property type';

  @override
  String get fieldTransaction => 'Listing type';

  @override
  String get fieldTitle => 'Title';

  @override
  String get fieldDescription => 'Description';

  @override
  String get fieldPrice => 'Price';

  @override
  String get fieldCurrency => 'Currency';

  @override
  String get fieldNegotiable => 'Price is negotiable';

  @override
  String get fieldGovernorate => 'Governorate';

  @override
  String get fieldDistrict => 'District';

  @override
  String get fieldArea => 'Area (m²)';

  @override
  String get fieldAddress => 'Address (optional)';

  @override
  String get fieldBedrooms => 'Bedrooms';

  @override
  String get fieldBathrooms => 'Bathrooms';

  @override
  String get fieldFloors => 'Floors';

  @override
  String get saveDraft => 'Save draft';

  @override
  String get draftSaved => 'Draft saved';

  @override
  String get validationRequired => 'Required';

  @override
  String get validationTitleLen => 'Title must be 5 to 120 characters';

  @override
  String get validationNumber => 'Enter a valid number';

  @override
  String get addPropertyIntro => 'Property details';

  @override
  String get mediaTitle => 'Photos';

  @override
  String get mediaAdd => 'Add photos';

  @override
  String get mediaEmpty => 'No photos yet. Add up to 20 photos.';

  @override
  String mediaUploading(int done, int total) {
    return 'Uploading $done of $total';
  }

  @override
  String get mediaFailed => 'Some photos failed to upload';

  @override
  String get mediaDelete => 'Delete photo';

  @override
  String get mediaCover => 'Cover';

  @override
  String get mediaLimit => 'Maximum 20 photos';

  @override
  String get mediaApiMissing => 'Server address is not configured';

  @override
  String get addPhotosNow => 'Add photos';

  @override
  String get profileGuestTitle => 'Sign in to your account';

  @override
  String get profileGuestBody =>
      'Sign in to save favorites, publish properties and contact owners.';

  @override
  String get authContinueGuest => 'Continue as guest';

  @override
  String get authSignIn => 'Sign in / Create account';

  @override
  String get loginRequiredHint => 'Sign in to continue';

  @override
  String get onboardingTitle => 'Complete your profile';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get fieldFullName => 'Full name';

  @override
  String get fieldAccountType => 'Account type';

  @override
  String get accountIndividual => 'Individual';

  @override
  String get accountOwner => 'Property owner';

  @override
  String get accountAgent => 'Real estate agent';

  @override
  String get accountCompany => 'Real estate company';

  @override
  String get accountDeveloper => 'Property developer';

  @override
  String get saveProfile => 'Save';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get roleMember => 'Member';

  @override
  String get roleModerator => 'Moderator';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleSuperAdmin => 'Super administrator';

  @override
  String get fieldGovernorateOptional => 'Governorate (optional)';

  @override
  String get fieldDistrictOptional => 'District (optional)';

  @override
  String get validationName => 'Name must be 2 to 80 characters';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'Your personal data will be removed and your listings will no longer be visible. Payment records are kept as required. This cannot be undone.';

  @override
  String get deleteAccountConfirm => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get deleteAccountFailed =>
      'Could not delete the account. Please try again.';

  @override
  String get photosSectionTitle => 'Photos';

  @override
  String get photosCoverHint => 'Tap a photo to make it the cover.';

  @override
  String get photosRequired => 'Add at least one photo.';

  @override
  String get myPropertiesTitle => 'My properties';

  @override
  String get myPropertiesEmpty => 'You have not added any property yet.';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusPendingPayment => 'Awaiting payment';

  @override
  String get statusPendingApproval => 'Awaiting approval';

  @override
  String get statusPublished => 'Published';

  @override
  String get statusRejected => 'Rejected';
}
