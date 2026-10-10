// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ClearScan';

  @override
  String get scanButton => 'Scan';

  @override
  String get homeTitle => 'Home';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get toolsTitle => 'Tools';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get german => 'German';

  @override
  String get arabic => 'Arabic';

  @override
  String get freePlan => 'Free plan';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get backupAndSync => 'Backup & Sync';

  @override
  String get appLock => 'App Lock';

  @override
  String get appLockAuthReason => 'Authenticate to unlock ClearScan.';

  @override
  String get appLockAuthenticationFailed =>
      'Authentication failed. Try again to unlock ClearScan.';

  @override
  String appLockAuthenticationError(Object error) {
    return 'Could not authenticate: $error';
  }

  @override
  String get appLockUnlockTitle => 'ClearScan is locked';

  @override
  String get appLockUnlockButton => 'Unlock ClearScan';

  @override
  String get appearance => 'Appearance';

  @override
  String get rateClearScan => 'Rate ClearScan';

  @override
  String get helpAndSupport => 'Help & Support';

  @override
  String get about => 'About';

  @override
  String get profile => 'Profile';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get storage => 'Storage';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get rateStoreListing => 'Open store listing';

  @override
  String get helpCenterEmail => 'Open help center / email';

  @override
  String helpEmailLaunchFailed(Object email) {
    return 'Could not open your email app. Contact $email instead.';
  }

  @override
  String get scanAnythingSaveEverything => 'Scan Anything. Save Everything.';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get recentDocuments => 'Recent Documents';

  @override
  String get openPdf => 'Open PDF';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsRetry => 'Retry';

  @override
  String get notificationsEmpty => 'You\'re all caught up.';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsClearAll => 'Clear all notifications';

  @override
  String get notificationScanTitle => 'Scan captured';

  @override
  String get notificationImportTitle => 'Image imported';

  @override
  String get notificationFolderTitle => 'Folder created';

  @override
  String get seeAll => 'See all';

  @override
  String get idCards => 'ID Cards';

  @override
  String get passport => 'Passport';

  @override
  String get qrCode => 'QR Code';

  @override
  String get import => 'Import';

  @override
  String get share => 'Share';

  @override
  String get rename => 'Rename';

  @override
  String get delete => 'Delete';

  @override
  String documentDeleteConfirmation(Object name) {
    return 'Delete $name? This cannot be undone.';
  }

  @override
  String documentRenameSuccess(Object name) {
    return 'Renamed to $name';
  }

  @override
  String documentDeleteSuccess(Object name) {
    return 'Deleted $name';
  }

  @override
  String get fast_and_smart => 'Fast, smart and secure\ndocument scanning.';

  @override
  String get documentsTitle => 'Documents';

  @override
  String get documentsSortBy => 'Sort by';

  @override
  String get documentsFilterAll => 'All';

  @override
  String get documentsFilterPdf => 'PDF';

  @override
  String get documentsFilterImages => 'Images';

  @override
  String get documentsFilterDocs => 'Docs';

  @override
  String get documentsFilterFavorites => 'Favorites';

  @override
  String get sortDate => 'Date';

  @override
  String get sortName => 'Name';

  @override
  String get sortSize => 'Size';

  @override
  String get searchTooltip => 'Search';

  @override
  String get selectOption => 'Select';

  @override
  String get newOption => 'New…';

  @override
  String get searchHint => 'Search documents';

  @override
  String get undo => 'Undo';

  @override
  String get scanDocument => 'Scan document';

  @override
  String get newFolder => 'New folder';

  @override
  String get importFile => 'Import file';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get items => 'items';

  @override
  String get noDocumentsFound => 'No documents found';

  @override
  String get onboardingSlideScanTitle => 'Scan Anything';

  @override
  String get onboardingSlideScanSubtitle =>
      'Turn paper into crisp, searchable PDFs\nin seconds, right from your phone.';

  @override
  String get onboardingSlideOrganizeTitle => 'Organize Everything';

  @override
  String get onboardingSlideOrganizeSubtitle =>
      'Keep IDs, contracts and receipts\nneatly sorted in folders.';

  @override
  String get onboardingSlideSignTitle => 'Edit & Sign';

  @override
  String get onboardingSlideSignSubtitle =>
      'Merge, compress, sign and share\nyour documents in a few taps.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboardingAgreeTerms =>
      'By continuing you agree to Terms & Privacy';

  @override
  String get onboardingTileIdCards => 'ID Cards';

  @override
  String get onboardingTileContracts => 'Contracts';

  @override
  String get onboardingTileReceipts => 'Receipts';

  @override
  String get scanModeIdCardLabel => 'ID';

  @override
  String get scanModePassportLabel => 'Passport';

  @override
  String get scanModeDocumentLabel => 'Document';

  @override
  String get scanModeQrLabel => 'QR Code';

  @override
  String get scanModeBookLabel => 'Book';

  @override
  String get scanModeIdCardHint => 'Capture ID front.';

  @override
  String get scanModeBackSideHint => 'Front captured. Capture back.';

  @override
  String get scanModePassportHint => 'Frame the passport data page.';

  @override
  String get scanModeDocumentHint => 'Fit document in frame.';

  @override
  String get scanModeQrHint => 'Frame the QR code.';

  @override
  String get scanModeBookHint => 'Fit both pages in frame.';

  @override
  String get scanGuidanceHoldSteady => 'Hold steady.';

  @override
  String get scanGuidanceReduceGlare => 'Reduce glare.';

  @override
  String get scanGuidanceImproveLighting => 'Improve the lighting.';

  @override
  String get scanGuidanceKeepInFrame => 'Keep card in frame.';

  @override
  String get scanGuidanceMoveCloser => 'Move closer.';

  @override
  String get scanGuidanceMoveBack => 'Move back.';

  @override
  String get scanGuidanceAlignCard => 'Align card in frame.';

  @override
  String get scanGuidanceMoveAwayFromEdge => 'Move card from edge.';

  @override
  String get settingsSectionScanning => 'SCANNING';

  @override
  String get settingsSectionSecurity => 'SECURITY';

  @override
  String get settingsSectionStorageSync => 'STORAGE & SYNC';

  @override
  String get settingsSectionAbout => 'ABOUT';

  @override
  String get settingsAppLock => 'App lock (PIN / biometric)';

  @override
  String get settingsHideInRecents => 'Hide in recents';

  @override
  String get settingsAutoBackup => 'Auto backup';

  @override
  String get settingsDefaultQuality => 'Default quality';

  @override
  String get settingsDefaultFormat => 'Default format';

  @override
  String get settingsClearCache => 'Clear cache';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsTermsOfService => 'Terms of service';

  @override
  String get settingsQualityLow => 'Low';

  @override
  String get settingsQualityMedium => 'Medium';

  @override
  String get settingsQualityHigh => 'High';

  @override
  String get scannerGrid => 'Show grid';

  @override
  String get settingsFormatPdf => 'PDF';

  @override
  String get settingsFormatJpg => 'JPG';

  @override
  String get settingsClearCacheTitle => 'Clear cache?';

  @override
  String get settingsClearCacheMessage =>
      'Temporary files will be deleted. Your documents are not affected.';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsClear => 'Clear';

  @override
  String get settingsCacheCleared => 'Cache cleared';

  @override
  String settingsOpenLinkPlaceholder(Object title) {
    return '$title: add your link';
  }

  @override
  String get cropAdjustBack => 'Back';

  @override
  String get cropAdjustTitle => 'Adjust edges';

  @override
  String get cropAdjustNext => 'Next';

  @override
  String get cropAdjustPage => 'Page';

  @override
  String get cropAdjustRetake => 'Retake';

  @override
  String get cropAdjustRotate => 'Rotate';

  @override
  String get cropAdjustAutoCrop => 'Auto crop';

  @override
  String get cropAdjustAddPage => 'Add page';

  @override
  String get cropAdjustErrorOpenImage => 'Could not open this image.';

  @override
  String get cropAdjustErrorCropImage =>
      'Could not crop the image. Adjust the corners and try again.';

  @override
  String get cropAdjustErrorDetectEdges =>
      'Could not detect document edges. Adjust the corners manually.';

  @override
  String get workshopTitle => 'Workshop';

  @override
  String get workshopConvert => 'Convert';

  @override
  String get workshopEditPdf => 'Edit PDF';

  @override
  String get workshopMoreTools => 'More Tools';

  @override
  String get toolImageToPdf => 'Image to PDF';

  @override
  String get toolPdfToImage => 'PDF to Image';

  @override
  String get toolPdfToWord => 'PDF to Word';

  @override
  String get toolPdfToExcel => 'PDF to Excel';

  @override
  String get toolMergePdf => 'Merge PDF';

  @override
  String get toolSplitPdf => 'Split PDF';

  @override
  String get toolCompressPdf => 'Compress PDF';

  @override
  String get toolRotatePdf => 'Rotate PDF';

  @override
  String get toolDeletePages => 'Delete Pages';

  @override
  String get toolReorderPages => 'Reorder Pages';

  @override
  String get toolExtractPages => 'Extract Pages';

  @override
  String get toolAddPassword => 'Add Password';

  @override
  String get toolSign => 'Sign Document';

  @override
  String get toolSignDesc => 'Add signature to your documents';

  @override
  String get toolWatermark => 'Watermark';

  @override
  String get toolWatermarkDesc => 'Add watermark to your documents';

  @override
  String get toolOcr => 'OCR';

  @override
  String get toolOcrDesc => 'Extract text from images';

  @override
  String get toolQrGenerator => 'QR Code Generator';

  @override
  String get toolQrGeneratorDesc => 'Create your own QR codes';
}
