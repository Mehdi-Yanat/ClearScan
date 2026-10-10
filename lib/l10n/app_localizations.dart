import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
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
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ClearScan'**
  String get appTitle;

  /// No description provided for @scanButton.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scanButton;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @toolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get toolsTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @freePlan.
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get freePlan;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @backupAndSync.
  ///
  /// In en, this message translates to:
  /// **'Backup & Sync'**
  String get backupAndSync;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get appLock;

  /// No description provided for @appLockAuthReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to unlock ClearScan.'**
  String get appLockAuthReason;

  /// No description provided for @appLockAuthenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Try again to unlock ClearScan.'**
  String get appLockAuthenticationFailed;

  /// No description provided for @appLockAuthenticationError.
  ///
  /// In en, this message translates to:
  /// **'Could not authenticate: {error}'**
  String appLockAuthenticationError(Object error);

  /// No description provided for @appLockUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'ClearScan is locked'**
  String get appLockUnlockTitle;

  /// No description provided for @appLockUnlockButton.
  ///
  /// In en, this message translates to:
  /// **'Unlock ClearScan'**
  String get appLockUnlockButton;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @rateClearScan.
  ///
  /// In en, this message translates to:
  /// **'Rate ClearScan'**
  String get rateClearScan;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @rateStoreListing.
  ///
  /// In en, this message translates to:
  /// **'Open store listing'**
  String get rateStoreListing;

  /// No description provided for @helpCenterEmail.
  ///
  /// In en, this message translates to:
  /// **'Open help center / email'**
  String get helpCenterEmail;

  /// No description provided for @helpEmailLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open your email app. Contact {email} instead.'**
  String helpEmailLaunchFailed(Object email);

  /// No description provided for @scanAnythingSaveEverything.
  ///
  /// In en, this message translates to:
  /// **'Scan Anything. Save Everything.'**
  String get scanAnythingSaveEverything;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @recentDocuments.
  ///
  /// In en, this message translates to:
  /// **'Recent Documents'**
  String get recentDocuments;

  /// No description provided for @openPdf.
  ///
  /// In en, this message translates to:
  /// **'Open PDF'**
  String get openPdf;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get notificationsRetry;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all notifications'**
  String get notificationsClearAll;

  /// No description provided for @notificationScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan captured'**
  String get notificationScanTitle;

  /// No description provided for @notificationImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Image imported'**
  String get notificationImportTitle;

  /// No description provided for @notificationFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Folder created'**
  String get notificationFolderTitle;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @idCards.
  ///
  /// In en, this message translates to:
  /// **'ID Cards'**
  String get idCards;

  /// No description provided for @passport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get passport;

  /// No description provided for @qrCode.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qrCode;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @documentDeleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? This cannot be undone.'**
  String documentDeleteConfirmation(Object name);

  /// No description provided for @documentRenameSuccess.
  ///
  /// In en, this message translates to:
  /// **'Renamed to {name}'**
  String documentRenameSuccess(Object name);

  /// No description provided for @documentDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Deleted {name}'**
  String documentDeleteSuccess(Object name);

  /// No description provided for @fast_and_smart.
  ///
  /// In en, this message translates to:
  /// **'Fast, smart and secure\ndocument scanning.'**
  String get fast_and_smart;

  /// No description provided for @documentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documentsTitle;

  /// No description provided for @documentsSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get documentsSortBy;

  /// No description provided for @documentsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get documentsFilterAll;

  /// No description provided for @documentsFilterPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get documentsFilterPdf;

  /// No description provided for @documentsFilterImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get documentsFilterImages;

  /// No description provided for @documentsFilterDocs.
  ///
  /// In en, this message translates to:
  /// **'Docs'**
  String get documentsFilterDocs;

  /// No description provided for @documentsFilterFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get documentsFilterFavorites;

  /// No description provided for @sortDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get sortDate;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortName;

  /// No description provided for @sortSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sortSize;

  /// No description provided for @searchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTooltip;

  /// No description provided for @selectOption.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectOption;

  /// No description provided for @newOption.
  ///
  /// In en, this message translates to:
  /// **'New…'**
  String get newOption;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search documents'**
  String get searchHint;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @scanDocument.
  ///
  /// In en, this message translates to:
  /// **'Scan document'**
  String get scanDocument;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get newFolder;

  /// No description provided for @importFile.
  ///
  /// In en, this message translates to:
  /// **'Import file'**
  String get importFile;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get items;

  /// No description provided for @noDocumentsFound.
  ///
  /// In en, this message translates to:
  /// **'No documents found'**
  String get noDocumentsFound;

  /// No description provided for @onboardingSlideScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Anything'**
  String get onboardingSlideScanTitle;

  /// No description provided for @onboardingSlideScanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn paper into crisp, searchable PDFs\nin seconds, right from your phone.'**
  String get onboardingSlideScanSubtitle;

  /// No description provided for @onboardingSlideOrganizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Organize Everything'**
  String get onboardingSlideOrganizeTitle;

  /// No description provided for @onboardingSlideOrganizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep IDs, contracts and receipts\nneatly sorted in folders.'**
  String get onboardingSlideOrganizeSubtitle;

  /// No description provided for @onboardingSlideSignTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit & Sign'**
  String get onboardingSlideSignTitle;

  /// No description provided for @onboardingSlideSignSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Merge, compress, sign and share\nyour documents in a few taps.'**
  String get onboardingSlideSignSubtitle;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingAgreeTerms.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to Terms & Privacy'**
  String get onboardingAgreeTerms;

  /// No description provided for @onboardingTileIdCards.
  ///
  /// In en, this message translates to:
  /// **'ID Cards'**
  String get onboardingTileIdCards;

  /// No description provided for @onboardingTileContracts.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get onboardingTileContracts;

  /// No description provided for @onboardingTileReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get onboardingTileReceipts;

  /// No description provided for @scanModeIdCardLabel.
  ///
  /// In en, this message translates to:
  /// **'ID Card'**
  String get scanModeIdCardLabel;

  /// No description provided for @scanModePassportLabel.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get scanModePassportLabel;

  /// No description provided for @scanModeDocumentLabel.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get scanModeDocumentLabel;

  /// No description provided for @scanModeQrLabel.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get scanModeQrLabel;

  /// No description provided for @scanModeBookLabel.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get scanModeBookLabel;

  /// No description provided for @scanModeIdCardHint.
  ///
  /// In en, this message translates to:
  /// **'Place your ID card inside the frame'**
  String get scanModeIdCardHint;

  /// No description provided for @scanModePassportHint.
  ///
  /// In en, this message translates to:
  /// **'Align the photo page with the frame'**
  String get scanModePassportHint;

  /// No description provided for @scanModeDocumentHint.
  ///
  /// In en, this message translates to:
  /// **'Align the document with the frame'**
  String get scanModeDocumentHint;

  /// No description provided for @scanModeQrHint.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at a QR code'**
  String get scanModeQrHint;

  /// No description provided for @scanModeBookHint.
  ///
  /// In en, this message translates to:
  /// **'Open the book and fit both pages in the frame'**
  String get scanModeBookHint;

  /// No description provided for @settingsSectionScanning.
  ///
  /// In en, this message translates to:
  /// **'SCANNING'**
  String get settingsSectionScanning;

  /// No description provided for @settingsSectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'SECURITY'**
  String get settingsSectionSecurity;

  /// No description provided for @settingsSectionStorageSync.
  ///
  /// In en, this message translates to:
  /// **'STORAGE & SYNC'**
  String get settingsSectionStorageSync;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get settingsSectionAbout;

  /// No description provided for @settingsAppLock.
  ///
  /// In en, this message translates to:
  /// **'App lock (PIN / biometric)'**
  String get settingsAppLock;

  /// No description provided for @settingsHideInRecents.
  ///
  /// In en, this message translates to:
  /// **'Hide in recents'**
  String get settingsHideInRecents;

  /// No description provided for @settingsAutoBackup.
  ///
  /// In en, this message translates to:
  /// **'Auto backup'**
  String get settingsAutoBackup;

  /// No description provided for @settingsDefaultQuality.
  ///
  /// In en, this message translates to:
  /// **'Default quality'**
  String get settingsDefaultQuality;

  /// No description provided for @settingsDefaultFormat.
  ///
  /// In en, this message translates to:
  /// **'Default format'**
  String get settingsDefaultFormat;

  /// No description provided for @settingsClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get settingsClearCache;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get settingsTermsOfService;

  /// No description provided for @settingsQualityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get settingsQualityLow;

  /// No description provided for @settingsQualityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get settingsQualityMedium;

  /// No description provided for @settingsQualityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get settingsQualityHigh;

  /// No description provided for @scannerGrid.
  ///
  /// In en, this message translates to:
  /// **'Show grid'**
  String get scannerGrid;

  /// No description provided for @settingsFormatPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get settingsFormatPdf;

  /// No description provided for @settingsFormatJpg.
  ///
  /// In en, this message translates to:
  /// **'JPG'**
  String get settingsFormatJpg;

  /// No description provided for @settingsClearCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear cache?'**
  String get settingsClearCacheTitle;

  /// No description provided for @settingsClearCacheMessage.
  ///
  /// In en, this message translates to:
  /// **'Temporary files will be deleted. Your documents are not affected.'**
  String get settingsClearCacheMessage;

  /// No description provided for @settingsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsCancel;

  /// No description provided for @settingsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsClear;

  /// No description provided for @settingsCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get settingsCacheCleared;

  /// No description provided for @settingsOpenLinkPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'{title}: add your link'**
  String settingsOpenLinkPlaceholder(Object title);

  /// No description provided for @cropAdjustBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get cropAdjustBack;

  /// No description provided for @cropAdjustTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust edges'**
  String get cropAdjustTitle;

  /// No description provided for @cropAdjustNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get cropAdjustNext;

  /// No description provided for @cropAdjustPage.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get cropAdjustPage;

  /// No description provided for @cropAdjustRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get cropAdjustRetake;

  /// No description provided for @cropAdjustRotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get cropAdjustRotate;

  /// No description provided for @cropAdjustAutoCrop.
  ///
  /// In en, this message translates to:
  /// **'Auto crop'**
  String get cropAdjustAutoCrop;

  /// No description provided for @cropAdjustAddPage.
  ///
  /// In en, this message translates to:
  /// **'Add page'**
  String get cropAdjustAddPage;

  /// No description provided for @cropAdjustErrorOpenImage.
  ///
  /// In en, this message translates to:
  /// **'Could not open this image.'**
  String get cropAdjustErrorOpenImage;

  /// No description provided for @cropAdjustErrorCropImage.
  ///
  /// In en, this message translates to:
  /// **'Could not crop the image. Adjust the corners and try again.'**
  String get cropAdjustErrorCropImage;

  /// No description provided for @cropAdjustErrorDetectEdges.
  ///
  /// In en, this message translates to:
  /// **'Could not detect document edges. Adjust the corners manually.'**
  String get cropAdjustErrorDetectEdges;

  /// No description provided for @workshopTitle.
  ///
  /// In en, this message translates to:
  /// **'Workshop'**
  String get workshopTitle;

  /// No description provided for @workshopConvert.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get workshopConvert;

  /// No description provided for @workshopEditPdf.
  ///
  /// In en, this message translates to:
  /// **'Edit PDF'**
  String get workshopEditPdf;

  /// No description provided for @workshopMoreTools.
  ///
  /// In en, this message translates to:
  /// **'More Tools'**
  String get workshopMoreTools;

  /// No description provided for @toolImageToPdf.
  ///
  /// In en, this message translates to:
  /// **'Image to PDF'**
  String get toolImageToPdf;

  /// No description provided for @toolPdfToImage.
  ///
  /// In en, this message translates to:
  /// **'PDF to Image'**
  String get toolPdfToImage;

  /// No description provided for @toolPdfToWord.
  ///
  /// In en, this message translates to:
  /// **'PDF to Word'**
  String get toolPdfToWord;

  /// No description provided for @toolPdfToExcel.
  ///
  /// In en, this message translates to:
  /// **'PDF to Excel'**
  String get toolPdfToExcel;

  /// No description provided for @toolMergePdf.
  ///
  /// In en, this message translates to:
  /// **'Merge PDF'**
  String get toolMergePdf;

  /// No description provided for @toolSplitPdf.
  ///
  /// In en, this message translates to:
  /// **'Split PDF'**
  String get toolSplitPdf;

  /// No description provided for @toolCompressPdf.
  ///
  /// In en, this message translates to:
  /// **'Compress PDF'**
  String get toolCompressPdf;

  /// No description provided for @toolRotatePdf.
  ///
  /// In en, this message translates to:
  /// **'Rotate PDF'**
  String get toolRotatePdf;

  /// No description provided for @toolDeletePages.
  ///
  /// In en, this message translates to:
  /// **'Delete Pages'**
  String get toolDeletePages;

  /// No description provided for @toolReorderPages.
  ///
  /// In en, this message translates to:
  /// **'Reorder Pages'**
  String get toolReorderPages;

  /// No description provided for @toolExtractPages.
  ///
  /// In en, this message translates to:
  /// **'Extract Pages'**
  String get toolExtractPages;

  /// No description provided for @toolAddPassword.
  ///
  /// In en, this message translates to:
  /// **'Add Password'**
  String get toolAddPassword;

  /// No description provided for @toolSign.
  ///
  /// In en, this message translates to:
  /// **'Sign Document'**
  String get toolSign;

  /// No description provided for @toolSignDesc.
  ///
  /// In en, this message translates to:
  /// **'Add signature to your documents'**
  String get toolSignDesc;

  /// No description provided for @toolWatermark.
  ///
  /// In en, this message translates to:
  /// **'Watermark'**
  String get toolWatermark;

  /// No description provided for @toolWatermarkDesc.
  ///
  /// In en, this message translates to:
  /// **'Add watermark to your documents'**
  String get toolWatermarkDesc;

  /// No description provided for @toolOcr.
  ///
  /// In en, this message translates to:
  /// **'OCR'**
  String get toolOcr;

  /// No description provided for @toolOcrDesc.
  ///
  /// In en, this message translates to:
  /// **'Extract text from images'**
  String get toolOcrDesc;

  /// No description provided for @toolQrGenerator.
  ///
  /// In en, this message translates to:
  /// **'QR Code Generator'**
  String get toolQrGenerator;

  /// No description provided for @toolQrGeneratorDesc.
  ///
  /// In en, this message translates to:
  /// **'Create your own QR codes'**
  String get toolQrGeneratorDesc;
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
      <String>['ar', 'de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
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
