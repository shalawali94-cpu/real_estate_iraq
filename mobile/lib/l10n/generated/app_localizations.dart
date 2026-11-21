import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_ckb.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('ckb'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Real Estate Iraq'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get navAdd;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @addPropertyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Property'**
  String get addPropertyTitle;

  /// No description provided for @phaseNotice.
  ///
  /// In en, this message translates to:
  /// **'This section is built in Phase 5'**
  String get phaseNotice;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @languageKurdish.
  ///
  /// In en, this message translates to:
  /// **'کوردی'**
  String get languageKurdish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @authWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get authWelcomeTitle;

  /// No description provided for @authPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get authPhoneLabel;

  /// No description provided for @authPhoneHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter your number to receive a verification code'**
  String get authPhoneHelp;

  /// No description provided for @authSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get authSendCode;

  /// No description provided for @authEnterCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get authEnterCodeTitle;

  /// No description provided for @authCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {phone}'**
  String authCodeSentTo(String phone);

  /// No description provided for @authVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get authVerify;

  /// No description provided for @authResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authResend;

  /// No description provided for @authInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Iraqi mobile number'**
  String get authInvalidPhone;

  /// No description provided for @authInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'The code is 6 digits'**
  String get authInvalidCode;

  /// No description provided for @authGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong, please try again'**
  String get authGenericError;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// No description provided for @authChangeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get authChangeNumber;

  /// No description provided for @homeFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get homeFeatured;

  /// No description provided for @homeLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest listings'**
  String get homeLatest;

  /// No description provided for @exploreSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search properties'**
  String get exploreSearchHint;

  /// No description provided for @txSale.
  ///
  /// In en, this message translates to:
  /// **'For sale'**
  String get txSale;

  /// No description provided for @txRent.
  ///
  /// In en, this message translates to:
  /// **'For rent'**
  String get txRent;

  /// No description provided for @txShortTermRent.
  ///
  /// In en, this message translates to:
  /// **'Short-term'**
  String get txShortTermRent;

  /// No description provided for @txInvestment.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get txInvestment;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @emptyProperties.
  ///
  /// In en, this message translates to:
  /// **'No properties found'**
  String get emptyProperties;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @negotiable.
  ///
  /// In en, this message translates to:
  /// **'Negotiable'**
  String get negotiable;

  /// No description provided for @sqm.
  ///
  /// In en, this message translates to:
  /// **'m²'**
  String get sqm;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @specBedrooms.
  ///
  /// In en, this message translates to:
  /// **'Bedrooms'**
  String get specBedrooms;

  /// No description provided for @specBathrooms.
  ///
  /// In en, this message translates to:
  /// **'Bathrooms'**
  String get specBathrooms;

  /// No description provided for @specArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get specArea;

  /// No description provided for @specFloors.
  ///
  /// In en, this message translates to:
  /// **'Floors'**
  String get specFloors;

  /// No description provided for @specCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get specCondition;

  /// No description provided for @specFurnishing.
  ///
  /// In en, this message translates to:
  /// **'Furnishing'**
  String get specFurnishing;

  /// No description provided for @specParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get specParking;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @descriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionTitle;

  /// No description provided for @specsTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get specsTitle;

  /// No description provided for @ownerTitle.
  ///
  /// In en, this message translates to:
  /// **'Listed by'**
  String get ownerTitle;

  /// No description provided for @contactCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get contactCall;

  /// No description provided for @contactWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get contactWhatsApp;

  /// No description provided for @favoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved properties yet'**
  String get favoritesEmpty;

  /// No description provided for @condNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get condNew;

  /// No description provided for @condExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get condExcellent;

  /// No description provided for @condGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get condGood;

  /// No description provided for @condNeedsRenovation.
  ///
  /// In en, this message translates to:
  /// **'Needs renovation'**
  String get condNeedsRenovation;

  /// No description provided for @condUnderConstruction.
  ///
  /// In en, this message translates to:
  /// **'Under construction'**
  String get condUnderConstruction;

  /// No description provided for @furnUnfurnished.
  ///
  /// In en, this message translates to:
  /// **'Unfurnished'**
  String get furnUnfurnished;

  /// No description provided for @furnSemi.
  ///
  /// In en, this message translates to:
  /// **'Semi-furnished'**
  String get furnSemi;

  /// No description provided for @furnFurnished.
  ///
  /// In en, this message translates to:
  /// **'Furnished'**
  String get furnFurnished;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'This listing is no longer available'**
  String get notFound;

  /// No description provided for @views.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get views;

  /// No description provided for @publishedOn.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get publishedOn;

  /// No description provided for @fieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Property type'**
  String get fieldCategory;

  /// No description provided for @fieldTransaction.
  ///
  /// In en, this message translates to:
  /// **'Listing type'**
  String get fieldTransaction;

  /// No description provided for @fieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get fieldTitle;

  /// No description provided for @fieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get fieldDescription;

  /// No description provided for @fieldPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get fieldPrice;

  /// No description provided for @fieldCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get fieldCurrency;

  /// No description provided for @fieldNegotiable.
  ///
  /// In en, this message translates to:
  /// **'Price is negotiable'**
  String get fieldNegotiable;

  /// No description provided for @fieldGovernorate.
  ///
  /// In en, this message translates to:
  /// **'Governorate'**
  String get fieldGovernorate;

  /// No description provided for @fieldDistrict.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get fieldDistrict;

  /// No description provided for @fieldArea.
  ///
  /// In en, this message translates to:
  /// **'Area (m²)'**
  String get fieldArea;

  /// No description provided for @fieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get fieldAddress;

  /// No description provided for @fieldBedrooms.
  ///
  /// In en, this message translates to:
  /// **'Bedrooms'**
  String get fieldBedrooms;

  /// No description provided for @fieldBathrooms.
  ///
  /// In en, this message translates to:
  /// **'Bathrooms'**
  String get fieldBathrooms;

  /// No description provided for @fieldFloors.
  ///
  /// In en, this message translates to:
  /// **'Floors'**
  String get fieldFloors;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get saveDraft;

  /// No description provided for @draftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get draftSaved;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get validationRequired;

  /// No description provided for @validationTitleLen.
  ///
  /// In en, this message translates to:
  /// **'Title must be 5 to 120 characters'**
  String get validationTitleLen;

  /// No description provided for @validationNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get validationNumber;

  /// No description provided for @addPropertyIntro.
  ///
  /// In en, this message translates to:
  /// **'Property details'**
  String get addPropertyIntro;

  /// No description provided for @mediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get mediaTitle;

  /// No description provided for @mediaAdd.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get mediaAdd;

  /// No description provided for @mediaEmpty.
  ///
  /// In en, this message translates to:
  /// **'No photos yet. Add up to 20 photos.'**
  String get mediaEmpty;

  /// No description provided for @mediaUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading {done} of {total}'**
  String mediaUploading(int done, int total);

  /// No description provided for @mediaFailed.
  ///
  /// In en, this message translates to:
  /// **'Some photos failed to upload'**
  String get mediaFailed;

  /// No description provided for @mediaDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete photo'**
  String get mediaDelete;

  /// No description provided for @mediaCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get mediaCover;

  /// No description provided for @mediaLimit.
  ///
  /// In en, this message translates to:
  /// **'Maximum 20 photos'**
  String get mediaLimit;

  /// No description provided for @mediaApiMissing.
  ///
  /// In en, this message translates to:
  /// **'Server address is not configured'**
  String get mediaApiMissing;

  /// No description provided for @addPhotosNow.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get addPhotosNow;

  /// No description provided for @profileGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get profileGuestTitle;

  /// No description provided for @profileGuestBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save favorites, publish properties and contact owners.'**
  String get profileGuestBody;

  /// No description provided for @authContinueGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get authContinueGuest;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in / Create account'**
  String get authSignIn;

  /// No description provided for @loginRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginRequiredHint;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get onboardingTitle;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @fieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fieldFullName;

  /// No description provided for @fieldAccountType.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get fieldAccountType;

  /// No description provided for @accountIndividual.
  ///
  /// In en, this message translates to:
  /// **'Individual'**
  String get accountIndividual;

  /// No description provided for @accountOwner.
  ///
  /// In en, this message translates to:
  /// **'Property owner'**
  String get accountOwner;

  /// No description provided for @accountAgent.
  ///
  /// In en, this message translates to:
  /// **'Real estate agent'**
  String get accountAgent;

  /// No description provided for @accountCompany.
  ///
  /// In en, this message translates to:
  /// **'Real estate company'**
  String get accountCompany;

  /// No description provided for @accountDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Property developer'**
  String get accountDeveloper;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveProfile;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @roleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get roleMember;

  /// No description provided for @roleModerator.
  ///
  /// In en, this message translates to:
  /// **'Moderator'**
  String get roleModerator;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get roleAdmin;

  /// No description provided for @roleSuperAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super administrator'**
  String get roleSuperAdmin;

  /// No description provided for @fieldGovernorateOptional.
  ///
  /// In en, this message translates to:
  /// **'Governorate (optional)'**
  String get fieldGovernorateOptional;

  /// No description provided for @fieldDistrictOptional.
  ///
  /// In en, this message translates to:
  /// **'District (optional)'**
  String get fieldDistrictOptional;

  /// No description provided for @validationName.
  ///
  /// In en, this message translates to:
  /// **'Name must be 2 to 80 characters'**
  String get validationName;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Your personal data will be removed and your listings will no longer be visible. Payment records are kept as required. This cannot be undone.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAccountConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the account. Please try again.'**
  String get deleteAccountFailed;

  /// No description provided for @photosSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photosSectionTitle;

  /// No description provided for @photosCoverHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a photo to make it the cover.'**
  String get photosCoverHint;

  /// No description provided for @photosRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one photo.'**
  String get photosRequired;

  /// No description provided for @myPropertiesTitle.
  ///
  /// In en, this message translates to:
  /// **'My properties'**
  String get myPropertiesTitle;

  /// No description provided for @myPropertiesEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have not added any property yet.'**
  String get myPropertiesEmpty;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusPendingPayment.
  ///
  /// In en, this message translates to:
  /// **'Awaiting payment'**
  String get statusPendingPayment;

  /// No description provided for @statusPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Awaiting approval'**
  String get statusPendingApproval;

  /// No description provided for @statusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get statusPublished;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review and publish'**
  String get reviewTitle;

  /// No description provided for @reviewFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Publishing fee'**
  String get reviewFeeLabel;

  /// No description provided for @reviewFeeNote.
  ///
  /// In en, this message translates to:
  /// **'Paid once per sale listing. Payment does not guarantee approval: every listing is reviewed before it is published.'**
  String get reviewFeeNote;

  /// No description provided for @reviewContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue to payment'**
  String get reviewContinue;

  /// No description provided for @payChooseMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose payment method'**
  String get payChooseMethod;

  /// No description provided for @payFib.
  ///
  /// In en, this message translates to:
  /// **'FIB'**
  String get payFib;

  /// No description provided for @payQi.
  ///
  /// In en, this message translates to:
  /// **'Qi Card'**
  String get payQi;

  /// No description provided for @payPayNow.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get payPayNow;

  /// No description provided for @payNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Online payment is not available yet: the payment provider is still being set up. Your listing is saved and nothing was charged.'**
  String get payNotConfigured;

  /// No description provided for @payOpened.
  ///
  /// In en, this message translates to:
  /// **'Complete the payment in the page that opened, then check the status.'**
  String get payOpened;

  /// No description provided for @payCheck.
  ///
  /// In en, this message translates to:
  /// **'Check payment status'**
  String get payCheck;

  /// No description provided for @payStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Payment received. Your listing is now waiting for review.'**
  String get payStatusPaid;

  /// No description provided for @payStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Payment is not confirmed yet.'**
  String get payStatusPending;

  /// No description provided for @payStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'The payment failed or expired. Please try again.'**
  String get payStatusFailed;

  /// No description provided for @reviewWaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Your listing is waiting for review by our team.'**
  String get reviewWaitingApproval;

  /// No description provided for @reviewPublished.
  ///
  /// In en, this message translates to:
  /// **'Your listing is published.'**
  String get reviewPublished;

  /// No description provided for @reviewNoFee.
  ///
  /// In en, this message translates to:
  /// **'No publishing fee applies to this listing type. It will be sent for review.'**
  String get reviewNoFee;

  /// No description provided for @reviewSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send for review'**
  String get reviewSubmit;

  /// No description provided for @messagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTitle;

  /// No description provided for @messagesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet.'**
  String get messagesEmpty;

  /// No description provided for @contactMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get contactMessage;

  /// No description provided for @chatHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message…'**
  String get chatHint;

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'Say hello to start the conversation.'**
  String get chatEmpty;

  /// No description provided for @chatSendFailed.
  ///
  /// In en, this message translates to:
  /// **'The message was not sent. Please try again.'**
  String get chatSendFailed;

  /// No description provided for @chatOwnListing.
  ///
  /// In en, this message translates to:
  /// **'This is your own listing.'**
  String get chatOwnListing;

  /// No description provided for @chatOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the conversation.'**
  String get chatOpenFailed;

  /// No description provided for @chatTyping.
  ///
  /// In en, this message translates to:
  /// **'typing…'**
  String get chatTyping;

  /// No description provided for @chatOnline.
  ///
  /// In en, this message translates to:
  /// **'online'**
  String get chatOnline;

  /// No description provided for @fieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @validationEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get validationEmail;

  /// No description provided for @authEmailSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get authEmailSignIn;

  /// No description provided for @authUsePhone.
  ///
  /// In en, this message translates to:
  /// **'Sign in with phone number'**
  String get authUsePhone;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Have an account? Sign in'**
  String get authToSignIn;

  /// No description provided for @authToCreate.
  ///
  /// In en, this message translates to:
  /// **'New here? Create account'**
  String get authToCreate;

  /// No description provided for @authPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authPasswordShort;

  /// No description provided for @authWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password'**
  String get authWrongCredentials;

  /// No description provided for @adminReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review listings'**
  String get adminReviewTitle;

  /// No description provided for @adminStatusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get adminStatusSuspended;

  /// No description provided for @adminApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminApprove;

  /// No description provided for @adminReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get adminReject;

  /// No description provided for @adminSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get adminSuspend;

  /// No description provided for @adminUnsuspend.
  ///
  /// In en, this message translates to:
  /// **'Unsuspend'**
  String get adminUnsuspend;

  /// No description provided for @adminView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get adminView;

  /// No description provided for @adminEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get adminEmpty;

  /// No description provided for @adminDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get adminDone;

  /// No description provided for @adminReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get adminReasonTitle;

  /// No description provided for @adminReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Write the reason (the owner will see it)'**
  String get adminReasonHint;

  /// No description provided for @adminConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get adminConfirm;

  /// No description provided for @adminOpenButton.
  ///
  /// In en, this message translates to:
  /// **'Review listings'**
  String get adminOpenButton;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filterTitle;

  /// No description provided for @filterMinPrice.
  ///
  /// In en, this message translates to:
  /// **'Min price'**
  String get filterMinPrice;

  /// No description provided for @filterMaxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max price'**
  String get filterMaxPrice;

  /// No description provided for @filterMinBedrooms.
  ///
  /// In en, this message translates to:
  /// **'Bedrooms (minimum)'**
  String get filterMinBedrooms;

  /// No description provided for @filterSort.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get filterSort;

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filterApply;

  /// No description provided for @filterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filterReset;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @sortPriceAsc.
  ///
  /// In en, this message translates to:
  /// **'Lowest price'**
  String get sortPriceAsc;

  /// No description provided for @sortPriceDesc.
  ///
  /// In en, this message translates to:
  /// **'Highest price'**
  String get sortPriceDesc;

  /// No description provided for @sortArea.
  ///
  /// In en, this message translates to:
  /// **'Largest area'**
  String get sortArea;

  /// No description provided for @sortPopular.
  ///
  /// In en, this message translates to:
  /// **'Most popular'**
  String get sortPopular;

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifTitle;

  /// No description provided for @notifMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notifMarkAllRead;

  /// No description provided for @notifEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notifEmpty;

  /// No description provided for @notifNewMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get notifNewMessage;

  /// No description provided for @notifPropertyApproved.
  ///
  /// In en, this message translates to:
  /// **'Your listing was approved'**
  String get notifPropertyApproved;

  /// No description provided for @notifPropertyRejected.
  ///
  /// In en, this message translates to:
  /// **'Your listing was rejected'**
  String get notifPropertyRejected;

  /// No description provided for @notifPropertySuspended.
  ///
  /// In en, this message translates to:
  /// **'Your listing was suspended'**
  String get notifPropertySuspended;

  /// No description provided for @notifPropertyRestored.
  ///
  /// In en, this message translates to:
  /// **'Your listing was restored'**
  String get notifPropertyRestored;

  /// No description provided for @notifPropertyExpired.
  ///
  /// In en, this message translates to:
  /// **'Your listing expired'**
  String get notifPropertyExpired;

  /// No description provided for @notifPaymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get notifPaymentSuccess;

  /// No description provided for @notifPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get notifPaymentFailed;

  /// No description provided for @notifAiVideoDone.
  ///
  /// In en, this message translates to:
  /// **'Your video is ready'**
  String get notifAiVideoDone;

  /// No description provided for @notifAiVideoFailed.
  ///
  /// In en, this message translates to:
  /// **'Video generation failed'**
  String get notifAiVideoFailed;

  /// No description provided for @notificationsButton.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'ckb', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'ckb':
      return AppLocalizationsCkb();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
