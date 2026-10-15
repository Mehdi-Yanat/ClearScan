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

  /// No description provided for @authGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get authGuestTitle;

  /// No description provided for @authGuestDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your account'**
  String get authGuestDescription;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// No description provided for @authTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get authTitle;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your ClearScan account.'**
  String get authSignInSubtitle;

  /// No description provided for @authSignUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account to get started.'**
  String get authSignUpSubtitle;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authFullName;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your name.'**
  String get authNameRequired;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get authInvalidEmail;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get authPasswordTooShort;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authHaveAccount;

  /// No description provided for @authNeedAccount.
  ///
  /// In en, this message translates to:
  /// **'New to ClearScan? Create an account'**
  String get authNeedAccount;

  /// No description provided for @authBackendNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Account sign-in is not set up yet.'**
  String get authBackendNotConfigured;

  /// No description provided for @authBackendSetupInstructions.
  ///
  /// In en, this message translates to:
  /// **'Run the VS Code task \"Run with Supabase\" or .\\tool\\flutter_with_supabase.ps1 run. This loads the URL and publishable key from .env. Never add secret keys to the app.'**
  String get authBackendSetupInstructions;

  /// No description provided for @authCheckEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email to confirm your account.'**
  String get authCheckEmail;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// No description provided for @authGoogleNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Set google_ID_client in .env to your Google Web client ID, then restart with Run with Supabase.'**
  String get authGoogleNotConfigured;

  /// No description provided for @cloudStorage.
  ///
  /// In en, this message translates to:
  /// **'Cloud storage'**
  String get cloudStorage;

  /// No description provided for @cloudStorageLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get cloudStorageLoading;

  /// No description provided for @cloudBackupCount.
  ///
  /// In en, this message translates to:
  /// **'{count} backups'**
  String cloudBackupCount(int count);

  /// No description provided for @cloudStorageUsed.
  ///
  /// In en, this message translates to:
  /// **'{size} used'**
  String cloudStorageUsed(Object size);

  /// No description provided for @cloudStoragePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Private backups, available only to your account.'**
  String get cloudStoragePrivacy;

  /// No description provided for @cloudBackupChooseDocuments.
  ///
  /// In en, this message translates to:
  /// **'Choose documents to back up'**
  String get cloudBackupChooseDocuments;

  /// No description provided for @cloudNoLocalDocuments.
  ///
  /// In en, this message translates to:
  /// **'No local documents found.'**
  String get cloudNoLocalDocuments;

  /// No description provided for @cloudBackupSelected.
  ///
  /// In en, this message translates to:
  /// **'Back up {count} selected'**
  String cloudBackupSelected(int count);

  /// No description provided for @cloudUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get cloudUploading;

  /// No description provided for @cloudUploadAction.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get cloudUploadAction;

  /// No description provided for @cloudUploadError.
  ///
  /// In en, this message translates to:
  /// **'Could not back up to cloud: {error}'**
  String cloudUploadError(Object error);

  /// No description provided for @cloudCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get cloudCopyLink;

  /// No description provided for @cloudLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied. It expires in 24 hours.'**
  String get cloudLinkCopied;

  /// No description provided for @cloudLinkError.
  ///
  /// In en, this message translates to:
  /// **'Could not create share link: {error}'**
  String cloudLinkError(Object error);

  /// No description provided for @cloudBackups.
  ///
  /// In en, this message translates to:
  /// **'Cloud backups'**
  String get cloudBackups;

  /// No description provided for @cloudNoBackups.
  ///
  /// In en, this message translates to:
  /// **'You have no cloud backups yet.'**
  String get cloudNoBackups;

  /// No description provided for @cloudRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore to this device'**
  String get cloudRestore;

  /// No description provided for @cloudCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cloudCancel;

  /// No description provided for @cloudDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete cloud backup?'**
  String get cloudDeleteConfirmTitle;

  /// No description provided for @cloudDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {name} from cloud backups? The local copy stays.'**
  String cloudDeleteConfirmMessage(Object name);

  /// No description provided for @cloudDeleteComplete.
  ///
  /// In en, this message translates to:
  /// **'Deleted {name} from cloud backups.'**
  String cloudDeleteComplete(Object name);

  /// No description provided for @cloudDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Could not delete cloud backup: {error}'**
  String cloudDeleteError(Object error);

  /// No description provided for @cloudBackupComplete.
  ///
  /// In en, this message translates to:
  /// **'Backed up {count} document(s).'**
  String cloudBackupComplete(int count);

  /// No description provided for @cloudBackupPartialFailure.
  ///
  /// In en, this message translates to:
  /// **'Backed up {count}; error: {error}'**
  String cloudBackupPartialFailure(int count, Object error);

  /// No description provided for @cloudRestoreComplete.
  ///
  /// In en, this message translates to:
  /// **'Restored {name} to this device.'**
  String cloudRestoreComplete(Object name);

  /// No description provided for @cloudStorageError.
  ///
  /// In en, this message translates to:
  /// **'Could not restore backup: {error}'**
  String cloudStorageError(Object error);

  /// No description provided for @cloudRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh backups'**
  String get cloudRefresh;

  /// No description provided for @cloudManageBackups.
  ///
  /// In en, this message translates to:
  /// **'Manage backups'**
  String get cloudManageBackups;

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
  /// **'Authentication failed. Try again.'**
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
  /// **'Can\'t open email. Contact {email}.'**
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
  /// **'Delete {name}? This can\'t be undone.'**
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
  /// **'Create clear, searchable PDFs\nfrom paper in seconds.'**
  String get onboardingSlideScanSubtitle;

  /// No description provided for @onboardingSlideOrganizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Organize Everything'**
  String get onboardingSlideOrganizeTitle;

  /// No description provided for @onboardingSlideOrganizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sort IDs, contracts and receipts\ninto folders.'**
  String get onboardingSlideOrganizeSubtitle;

  /// No description provided for @onboardingSlideSignTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit & Sign'**
  String get onboardingSlideSignTitle;

  /// No description provided for @onboardingSlideSignSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Merge, compress, sign and share\nin a few taps.'**
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
  /// **'ID'**
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
  /// **'Capture ID front.'**
  String get scanModeIdCardHint;

  /// No description provided for @scanModeBackSideHint.
  ///
  /// In en, this message translates to:
  /// **'Front captured. Capture back.'**
  String get scanModeBackSideHint;

  /// No description provided for @scanIdFrontLabel.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get scanIdFrontLabel;

  /// No description provided for @scanIdBackLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get scanIdBackLabel;

  /// No description provided for @scanRetakeIdFront.
  ///
  /// In en, this message translates to:
  /// **'Retake front'**
  String get scanRetakeIdFront;

  /// No description provided for @scanModePassportHint.
  ///
  /// In en, this message translates to:
  /// **'Frame the passport data page.'**
  String get scanModePassportHint;

  /// No description provided for @scanModeDocumentHint.
  ///
  /// In en, this message translates to:
  /// **'Fit document in frame.'**
  String get scanModeDocumentHint;

  /// No description provided for @scanModeQrHint.
  ///
  /// In en, this message translates to:
  /// **'Frame the QR code.'**
  String get scanModeQrHint;

  /// No description provided for @scanModeBookHint.
  ///
  /// In en, this message translates to:
  /// **'Fit both pages in frame.'**
  String get scanModeBookHint;

  /// No description provided for @scanGuidanceHoldSteady.
  ///
  /// In en, this message translates to:
  /// **'Hold steady.'**
  String get scanGuidanceHoldSteady;

  /// No description provided for @scanGuidanceReduceGlare.
  ///
  /// In en, this message translates to:
  /// **'Reduce glare.'**
  String get scanGuidanceReduceGlare;

  /// No description provided for @scanGuidanceImproveLighting.
  ///
  /// In en, this message translates to:
  /// **'Improve the lighting.'**
  String get scanGuidanceImproveLighting;

  /// No description provided for @scanGuidanceKeepInFrame.
  ///
  /// In en, this message translates to:
  /// **'Keep card in frame.'**
  String get scanGuidanceKeepInFrame;

  /// No description provided for @scanGuidanceMoveCloser.
  ///
  /// In en, this message translates to:
  /// **'Move closer.'**
  String get scanGuidanceMoveCloser;

  /// No description provided for @scanGuidanceMoveBack.
  ///
  /// In en, this message translates to:
  /// **'Move back.'**
  String get scanGuidanceMoveBack;

  /// No description provided for @scanGuidanceAlignCard.
  ///
  /// In en, this message translates to:
  /// **'Align card inside the frame.'**
  String get scanGuidanceAlignCard;

  /// No description provided for @scanGuidanceMoveAwayFromEdge.
  ///
  /// In en, this message translates to:
  /// **'Move the card away from the edge.'**
  String get scanGuidanceMoveAwayFromEdge;

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
  /// **'Temporary files will be deleted. Documents stay safe.'**
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
  /// **'Couldn\'t crop image. Adjust the corners and retry.'**
  String get cropAdjustErrorCropImage;

  /// No description provided for @cropAdjustErrorDetectEdges.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t detect edges. Adjust the corners manually.'**
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

  /// No description provided for @pdfToWordTitle.
  ///
  /// In en, this message translates to:
  /// **'PDF to Word'**
  String get pdfToWordTitle;

  /// No description provided for @pdfToWordSelectPdf.
  ///
  /// In en, this message translates to:
  /// **'Choose a PDF'**
  String get pdfToWordSelectPdf;

  /// No description provided for @pdfToWordHint.
  ///
  /// In en, this message translates to:
  /// **'Export PDF text to editable Word. Scans support Arabic, English, and German OCR; layout may change.'**
  String get pdfToWordHint;

  /// No description provided for @pdfToWordConverting.
  ///
  /// In en, this message translates to:
  /// **'Extracting PDF text and running OCR…'**
  String get pdfToWordConverting;

  /// No description provided for @pdfToWordProgress.
  ///
  /// In en, this message translates to:
  /// **'Processed {completed} of {total} pages'**
  String pdfToWordProgress(Object completed, Object total);

  /// No description provided for @pdfToWordShare.
  ///
  /// In en, this message translates to:
  /// **'Share Word document'**
  String get pdfToWordShare;

  /// No description provided for @pdfToWordConversionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not convert the PDF: {error}'**
  String pdfToWordConversionFailed(Object error);

  /// No description provided for @pdfToWordShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share the Word document: {error}'**
  String pdfToWordShareFailed(Object error);

  /// No description provided for @pdfToImageTitle.
  ///
  /// In en, this message translates to:
  /// **'PDF to Image'**
  String get pdfToImageTitle;

  /// No description provided for @pdfToImageSelectPdf.
  ///
  /// In en, this message translates to:
  /// **'Choose a PDF'**
  String get pdfToImageSelectPdf;

  /// No description provided for @pdfToImageHint.
  ///
  /// In en, this message translates to:
  /// **'Convert every page of a PDF into a PNG image.'**
  String get pdfToImageHint;

  /// No description provided for @pdfToImageConverting.
  ///
  /// In en, this message translates to:
  /// **'Converting PDF pages…'**
  String get pdfToImageConverting;

  /// No description provided for @pdfToImageProgress.
  ///
  /// In en, this message translates to:
  /// **'Converted {completed} of {total} pages'**
  String pdfToImageProgress(Object completed, Object total);

  /// No description provided for @pdfToImageConvertedPages.
  ///
  /// In en, this message translates to:
  /// **'Converted {count} pages'**
  String pdfToImageConvertedPages(Object count);

  /// No description provided for @pdfToImageShare.
  ///
  /// In en, this message translates to:
  /// **'Share images'**
  String get pdfToImageShare;

  /// No description provided for @pdfToImageConversionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not convert the PDF: {error}'**
  String pdfToImageConversionFailed(Object error);

  /// No description provided for @pdfToImageShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share the images: {error}'**
  String pdfToImageShareFailed(Object error);

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

  /// No description provided for @pdfToExcelTitle.
  ///
  /// In en, this message translates to:
  /// **'PDF to Excel'**
  String get pdfToExcelTitle;

  /// No description provided for @pdfToExcelSelectPdf.
  ///
  /// In en, this message translates to:
  /// **'Choose a PDF'**
  String get pdfToExcelSelectPdf;

  /// No description provided for @pdfToExcelHint.
  ///
  /// In en, this message translates to:
  /// **'Export PDF text to Excel by page and line. Scans support Arabic, English, and German OCR.'**
  String get pdfToExcelHint;

  /// No description provided for @pdfToExcelConverting.
  ///
  /// In en, this message translates to:
  /// **'Extracting PDF text and running OCR…'**
  String get pdfToExcelConverting;

  /// No description provided for @pdfToExcelProgress.
  ///
  /// In en, this message translates to:
  /// **'Processed {completed} of {total} pages'**
  String pdfToExcelProgress(Object completed, Object total);

  /// No description provided for @pdfToExcelShare.
  ///
  /// In en, this message translates to:
  /// **'Share Excel workbook'**
  String get pdfToExcelShare;

  /// No description provided for @pdfToExcelConversionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not convert the PDF: {error}'**
  String pdfToExcelConversionFailed(Object error);

  /// No description provided for @pdfToExcelShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share the Excel workbook: {error}'**
  String pdfToExcelShareFailed(Object error);

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

  /// No description provided for @signatureClear.
  ///
  /// In en, this message translates to:
  /// **'Clear signature'**
  String get signatureClear;

  /// No description provided for @signatureColor.
  ///
  /// In en, this message translates to:
  /// **'Signature color'**
  String get signatureColor;

  /// No description provided for @signatureBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get signatureBlack;

  /// No description provided for @signatureWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get signatureWhite;

  /// No description provided for @signaturePlacementHint.
  ///
  /// In en, this message translates to:
  /// **'Drag your signature on the page to position it.'**
  String get signaturePlacementHint;

  /// No description provided for @signaturePreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Preview unavailable. Select the PDF again.'**
  String get signaturePreviewUnavailable;

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

  /// No description provided for @watermarkText.
  ///
  /// In en, this message translates to:
  /// **'Watermark text'**
  String get watermarkText;

  /// No description provided for @watermarkTextHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. CONFIDENTIAL'**
  String get watermarkTextHint;

  /// No description provided for @watermarkOpacity.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get watermarkOpacity;

  /// No description provided for @watermarkPositionHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the watermark to set its position on every page.'**
  String get watermarkPositionHint;

  /// No description provided for @watermarkPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The page preview is unavailable.'**
  String get watermarkPreviewUnavailable;

  /// No description provided for @watermarkAllPagesHint.
  ///
  /// In en, this message translates to:
  /// **'Watermark will be added to all pages.'**
  String get watermarkAllPagesHint;

  /// No description provided for @watermarkApply.
  ///
  /// In en, this message translates to:
  /// **'Add watermark'**
  String get watermarkApply;

  /// No description provided for @watermarkPdfAccessFailed.
  ///
  /// In en, this message translates to:
  /// **'The selected PDF file could not be accessed.'**
  String get watermarkPdfAccessFailed;

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

  /// No description provided for @ocrHint.
  ///
  /// In en, this message translates to:
  /// **'Choose an image to recognize text in English, German, or Arabic.'**
  String get ocrHint;

  /// No description provided for @ocrSelectImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get ocrSelectImage;

  /// No description provided for @ocrProcessing.
  ///
  /// In en, this message translates to:
  /// **'Recognizing text…'**
  String get ocrProcessing;

  /// No description provided for @ocrResult.
  ///
  /// In en, this message translates to:
  /// **'Extracted text'**
  String get ocrResult;

  /// No description provided for @ocrNoText.
  ///
  /// In en, this message translates to:
  /// **'No text was found in this image.'**
  String get ocrNoText;

  /// No description provided for @ocrFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not recognize text: {error}'**
  String ocrFailed(Object error);

  /// No description provided for @ocrCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get ocrCopy;

  /// No description provided for @ocrCopied.
  ///
  /// In en, this message translates to:
  /// **'Text copied'**
  String get ocrCopied;

  /// No description provided for @ocrImagePreviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not display the selected image.'**
  String get ocrImagePreviewFailed;

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

  /// No description provided for @qrGeneratorHint.
  ///
  /// In en, this message translates to:
  /// **'Enter text or a link to create a QR code.'**
  String get qrGeneratorHint;

  /// No description provided for @qrGeneratorContent.
  ///
  /// In en, this message translates to:
  /// **'Text or link'**
  String get qrGeneratorContent;

  /// No description provided for @qrGeneratorContentHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the content to encode'**
  String get qrGeneratorContentHint;

  /// No description provided for @qrGeneratorShare.
  ///
  /// In en, this message translates to:
  /// **'Share QR code'**
  String get qrGeneratorShare;

  /// No description provided for @qrGeneratorTooLong.
  ///
  /// In en, this message translates to:
  /// **'This content is too long to fit in a QR code.'**
  String get qrGeneratorTooLong;

  /// No description provided for @pdfEditChoosePdf.
  ///
  /// In en, this message translates to:
  /// **'Choose PDF'**
  String get pdfEditChoosePdf;

  /// No description provided for @pdfEditSourcePassword.
  ///
  /// In en, this message translates to:
  /// **'PDF password (if protected)'**
  String get pdfEditSourcePassword;

  /// No description provided for @pdfEditSourcePasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'Check the password, then reopen the PDF.'**
  String get pdfEditSourcePasswordHelp;

  /// No description provided for @pdfEditOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open PDF. Check its password and retry.'**
  String get pdfEditOpenFailed;

  /// No description provided for @pdfEditLoadAgain.
  ///
  /// In en, this message translates to:
  /// **'Load PDF'**
  String get pdfEditLoadAgain;

  /// No description provided for @pdfEditPageCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pages'**
  String pdfEditPageCount(Object count);

  /// No description provided for @pdfEditPageRange.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pdfEditPageRange;

  /// No description provided for @pdfEditPageRangeHint.
  ///
  /// In en, this message translates to:
  /// **'1,3-5'**
  String get pdfEditPageRangeHint;

  /// No description provided for @pdfEditPageRangeHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter page numbers or ranges separated by commas.'**
  String get pdfEditPageRangeHelp;

  /// No description provided for @pdfEditSplitHint.
  ///
  /// In en, this message translates to:
  /// **'Each selected page will be saved as a separate PDF.'**
  String get pdfEditSplitHint;

  /// No description provided for @pdfEditRotateHint.
  ///
  /// In en, this message translates to:
  /// **'Selected pages will rotate 90° clockwise.'**
  String get pdfEditRotateHint;

  /// No description provided for @pdfEditReorderHint.
  ///
  /// In en, this message translates to:
  /// **'Arrange pages in the order you want.'**
  String get pdfEditReorderHint;

  /// No description provided for @pdfEditPage.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String pdfEditPage(Object page);

  /// No description provided for @pdfEditMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get pdfEditMoveUp;

  /// No description provided for @pdfEditMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get pdfEditMoveDown;

  /// No description provided for @pdfEditNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password (at least 6 characters)'**
  String get pdfEditNewPassword;

  /// No description provided for @pdfEditConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get pdfEditConfirmPassword;

  /// No description provided for @pdfEditPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get pdfEditPasswordsDoNotMatch;

  /// No description provided for @pdfEditCompressionNote.
  ///
  /// In en, this message translates to:
  /// **'Strong compression turns pages into images; text won\'t be selectable/searchable, and quality may drop.'**
  String get pdfEditCompressionNote;

  /// No description provided for @pdfEditCompressionWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Strong compression warning'**
  String get pdfEditCompressionWarningTitle;

  /// No description provided for @pdfEditCompressionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get pdfEditCompressionCancel;

  /// No description provided for @pdfEditCompressionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Compress anyway'**
  String get pdfEditCompressionConfirm;

  /// No description provided for @pdfEditCompressionNoReduction.
  ///
  /// In en, this message translates to:
  /// **'Compressed file was larger. Original kept.'**
  String get pdfEditCompressionNoReduction;

  /// No description provided for @pdfEditRun.
  ///
  /// In en, this message translates to:
  /// **'Run {tool}'**
  String pdfEditRun(Object tool);

  /// No description provided for @pdfEditDone.
  ///
  /// In en, this message translates to:
  /// **'Finished. Edited PDF files are saved to Documents.'**
  String get pdfEditDone;

  /// No description provided for @scannerTooltipClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get scannerTooltipClose;

  /// No description provided for @scannerTooltipFlash.
  ///
  /// In en, this message translates to:
  /// **'Flash'**
  String get scannerTooltipFlash;

  /// No description provided for @scannerTooltipSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get scannerTooltipSettings;

  /// No description provided for @scannerTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get scannerTryAgain;

  /// No description provided for @scannerErrorNoCamera.
  ///
  /// In en, this message translates to:
  /// **'No camera found on this device.'**
  String get scannerErrorNoCamera;

  /// No description provided for @scannerErrorPermission.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required to scan documents.'**
  String get scannerErrorPermission;

  /// No description provided for @scannerErrorStart.
  ///
  /// In en, this message translates to:
  /// **'Could not start the camera ({error}).'**
  String scannerErrorStart(Object error);

  /// No description provided for @folderMultiSelectBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get folderMultiSelectBack;

  /// No description provided for @folderMultiSelectChangeView.
  ///
  /// In en, this message translates to:
  /// **'Change view'**
  String get folderMultiSelectChangeView;

  /// No description provided for @folderMultiSelectMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get folderMultiSelectMoreOptions;

  /// No description provided for @folderMultiSelectDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get folderMultiSelectDateLabel;

  /// No description provided for @folderMultiSelectMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get folderMultiSelectMerge;

  /// No description provided for @folderMultiSelectExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get folderMultiSelectExport;

  /// No description provided for @homeTooltipClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get homeTooltipClose;

  /// No description provided for @homeTooltipFlash.
  ///
  /// In en, this message translates to:
  /// **'Flash'**
  String get homeTooltipFlash;

  /// No description provided for @homeTooltipSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeTooltipSettings;

  /// No description provided for @homeTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get homeTryAgain;

  /// No description provided for @scanActionCamera.
  ///
  /// In en, this message translates to:
  /// **'Scan with Camera'**
  String get scanActionCamera;

  /// No description provided for @scanActionGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get scanActionGallery;

  /// No description provided for @scanExportingPdf.
  ///
  /// In en, this message translates to:
  /// **'Exporting PDF…'**
  String get scanExportingPdf;

  /// No description provided for @scanExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get scanExportPdf;

  /// No description provided for @scanInfoHeader.
  ///
  /// In en, this message translates to:
  /// **'Scan an image'**
  String get scanInfoHeader;

  /// No description provided for @scanInfoHint.
  ///
  /// In en, this message translates to:
  /// **'Capture from camera or choose an image from gallery.'**
  String get scanInfoHint;
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
