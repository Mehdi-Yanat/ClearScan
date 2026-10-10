// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'ClearScan';

  @override
  String get scanButton => 'Scannen';

  @override
  String get homeTitle => 'Startseite';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get toolsTitle => 'Werkzeuge';

  @override
  String get language => 'Sprache';

  @override
  String get english => 'Englisch';

  @override
  String get german => 'Deutsch';

  @override
  String get arabic => 'Arabisch';

  @override
  String get freePlan => 'Kostenloser Plan';

  @override
  String get on => 'Ein';

  @override
  String get off => 'Aus';

  @override
  String get comingSoon => 'Demnächst verfügbar';

  @override
  String get backupAndSync => 'Sicherung & Synchronisierung';

  @override
  String get appLock => 'App-Sperre';

  @override
  String get appLockAuthReason =>
      'Authentifizieren, um ClearScan zu entsperren.';

  @override
  String get appLockAuthenticationFailed =>
      'Authentifizierung fehlgeschlagen. Versuche erneut, ClearScan zu entsperren.';

  @override
  String appLockAuthenticationError(Object error) {
    return 'Authentifizierung fehlgeschlagen: $error';
  }

  @override
  String get appLockUnlockTitle => 'ClearScan ist gesperrt';

  @override
  String get appLockUnlockButton => 'ClearScan entsperren';

  @override
  String get appearance => 'Erscheinungsbild';

  @override
  String get rateClearScan => 'ClearScan bewerten';

  @override
  String get helpAndSupport => 'Hilfe & Support';

  @override
  String get about => 'Über';

  @override
  String get profile => 'Profil';

  @override
  String get settingsTooltip => 'Einstellungen';

  @override
  String get storage => 'Speicher';

  @override
  String get light => 'Hell';

  @override
  String get dark => 'Dunkel';

  @override
  String get system => 'System';

  @override
  String get rateStoreListing => 'Store öffnen';

  @override
  String get helpCenterEmail => 'Hilfezentrum / E-Mail öffnen';

  @override
  String helpEmailLaunchFailed(Object email) {
    return 'Die E-Mail-App konnte nicht geöffnet werden. Schreibe stattdessen an $email.';
  }

  @override
  String get scanAnythingSaveEverything => 'Alles scannen. Alles speichern.';

  @override
  String get quickActions => 'Schnelle Aktionen';

  @override
  String get recentDocuments => 'Kürzliche Dokumente';

  @override
  String get openPdf => 'PDF öffnen';

  @override
  String get notificationsTitle => 'Benachrichtigungen';

  @override
  String get notificationsRetry => 'Erneut versuchen';

  @override
  String get notificationsEmpty => 'Du bist auf dem neuesten Stand.';

  @override
  String get notificationsMarkAllRead => 'Alle als gelesen markieren';

  @override
  String get notificationsClearAll => 'Alle Benachrichtigungen löschen';

  @override
  String get notificationScanTitle => 'Scan aufgenommen';

  @override
  String get notificationImportTitle => 'Bild importiert';

  @override
  String get notificationFolderTitle => 'Ordner erstellt';

  @override
  String get seeAll => 'Alle sehen';

  @override
  String get idCards => 'Ausweise';

  @override
  String get passport => 'Reisepass';

  @override
  String get qrCode => 'QR-Code';

  @override
  String get import => 'Importieren';

  @override
  String get share => 'Teilen';

  @override
  String get rename => 'Umbenennen';

  @override
  String get delete => 'Löschen';

  @override
  String documentDeleteConfirmation(Object name) {
    return '\"$name\" löschen? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String documentRenameSuccess(Object name) {
    return 'Umbenannt in $name';
  }

  @override
  String documentDeleteSuccess(Object name) {
    return '$name gelöscht';
  }

  @override
  String get fast_and_smart =>
      'Schnelles, intelligentes und sicheres\nDokumentenscannen.';

  @override
  String get documentsTitle => 'Dokumente';

  @override
  String get documentsSortBy => 'Sortieren nach';

  @override
  String get documentsFilterAll => 'Alle';

  @override
  String get documentsFilterPdf => 'PDF';

  @override
  String get documentsFilterImages => 'Bilder';

  @override
  String get documentsFilterDocs => 'Dokumente';

  @override
  String get documentsFilterFavorites => 'Favoriten';

  @override
  String get sortDate => 'Datum';

  @override
  String get sortName => 'Name';

  @override
  String get sortSize => 'Größe';

  @override
  String get searchTooltip => 'Suchen';

  @override
  String get selectOption => 'Auswählen';

  @override
  String get newOption => 'Neu…';

  @override
  String get searchHint => 'Dokumente suchen';

  @override
  String get undo => 'Rückgängig';

  @override
  String get scanDocument => 'Dokument scannen';

  @override
  String get newFolder => 'Neuer Ordner';

  @override
  String get importFile => 'Datei importieren';

  @override
  String get removeFromFavorites => 'Aus Favoriten entfernen';

  @override
  String get addToFavorites => 'Zu Favoriten hinzufügen';

  @override
  String get items => 'Einträge';

  @override
  String get noDocumentsFound => 'Keine Dokumente gefunden';

  @override
  String get onboardingSlideScanTitle => 'Alles scannen';

  @override
  String get onboardingSlideScanSubtitle =>
      'Wandle Papier in klare, durchsuchbare PDFs\nin Sekunden, direkt von deinem Telefon.';

  @override
  String get onboardingSlideOrganizeTitle => 'Alles organisieren';

  @override
  String get onboardingSlideOrganizeSubtitle =>
      'Behalte Ausweise, Verträge und Quittungen\nordentlich sortiert in Ordnern.';

  @override
  String get onboardingSlideSignTitle => 'Bearbeiten & Unterschreiben';

  @override
  String get onboardingSlideSignSubtitle =>
      'Zusammenführen, komprimieren, unterschreiben und teilen\nDeine Dokumente in wenigen Tipps.';

  @override
  String get onboardingSkip => 'Überspringen';

  @override
  String get onboardingGetStarted => 'Los geht\'s';

  @override
  String get onboardingAgreeTerms =>
      'Indem du fortfährst, stimmst du den Nutzungsbedingungen und der Datenschutzerklärung zu.';

  @override
  String get onboardingTileIdCards => 'Ausweise';

  @override
  String get onboardingTileContracts => 'Verträge';

  @override
  String get onboardingTileReceipts => 'Quittungen';

  @override
  String get scanModeIdCardLabel => 'Personalausweis';

  @override
  String get scanModePassportLabel => 'Reisepass';

  @override
  String get scanModeDocumentLabel => 'Dokument';

  @override
  String get scanModeQrLabel => 'QR-Code';

  @override
  String get scanModeBookLabel => 'Buch';

  @override
  String get scanModeIdCardHint => 'Vorderseite des Ausweises aufnehmen.';

  @override
  String get scanModeBackSideHint =>
      'Vorderseite erfasst. Rückseite aufnehmen.';

  @override
  String get scanModePassportHint => 'Datenseite des Reisepasses erfassen.';

  @override
  String get scanModeDocumentHint => 'Dokument in den Rahmen legen.';

  @override
  String get scanModeQrHint => 'QR-Code erfassen.';

  @override
  String get scanModeBookHint => 'Beide Seiten in den Rahmen legen.';

  @override
  String get scanGuidanceHoldSteady => 'Ruhig halten.';

  @override
  String get scanGuidanceReduceGlare => 'Spiegelung vermeiden.';

  @override
  String get scanGuidanceImproveLighting => 'Beleuchtung verbessern.';

  @override
  String get scanGuidanceKeepInFrame => 'Karte im Rahmen halten.';

  @override
  String get scanGuidanceMoveCloser => 'Näher heran.';

  @override
  String get scanGuidanceMoveBack => 'Weiter weg.';

  @override
  String get scanGuidanceAlignCard => 'Karte im Rahmen ausrichten.';

  @override
  String get scanGuidanceMoveAwayFromEdge => 'Karte vom Rand weg.';

  @override
  String get settingsSectionScanning => 'SCANNEN';

  @override
  String get settingsSectionSecurity => 'SICHERHEIT';

  @override
  String get settingsSectionStorageSync => 'SPEICHER & SYNC';

  @override
  String get settingsSectionAbout => 'ÜBER';

  @override
  String get settingsAppLock => 'App-Sperre (PIN / Biometrie)';

  @override
  String get settingsHideInRecents => 'Ausblenden in Kürzlich verwendet';

  @override
  String get settingsAutoBackup => 'Automatisches Backup';

  @override
  String get settingsDefaultQuality => 'Standardqualität';

  @override
  String get settingsDefaultFormat => 'Standardformat';

  @override
  String get settingsClearCache => 'Cache leeren';

  @override
  String get settingsPrivacyPolicy => 'Datenschutzrichtlinie';

  @override
  String get settingsTermsOfService => 'Nutzungsbedingungen';

  @override
  String get settingsQualityLow => 'Niedrig';

  @override
  String get settingsQualityMedium => 'Mittel';

  @override
  String get settingsQualityHigh => 'Hoch';

  @override
  String get scannerGrid => 'Raster anzeigen';

  @override
  String get settingsFormatPdf => 'PDF';

  @override
  String get settingsFormatJpg => 'JPG';

  @override
  String get settingsClearCacheTitle => 'Cache leeren?';

  @override
  String get settingsClearCacheMessage =>
      'Temporäre Dateien werden gelöscht. Ihre Dokumente bleiben unverändert.';

  @override
  String get settingsCancel => 'Abbrechen';

  @override
  String get settingsClear => 'Leeren';

  @override
  String get settingsCacheCleared => 'Cache geleert';

  @override
  String settingsOpenLinkPlaceholder(Object title) {
    return '$title: Link hinzufügen';
  }

  @override
  String get cropAdjustBack => 'Zurück';

  @override
  String get cropAdjustTitle => 'Kanten anpassen';

  @override
  String get cropAdjustNext => 'Weiter';

  @override
  String get cropAdjustPage => 'Seite';

  @override
  String get cropAdjustRetake => 'Wiederholen';

  @override
  String get cropAdjustRotate => 'Drehen';

  @override
  String get cropAdjustAutoCrop => 'Automatisch zuschneiden';

  @override
  String get cropAdjustAddPage => 'Seite hinzufügen';

  @override
  String get cropAdjustErrorOpenImage => 'Konnte das Bild nicht öffnen.';

  @override
  String get cropAdjustErrorCropImage =>
      'Konnte das Bild nicht zuschneiden. Passe die Ecken an und versuche es erneut.';

  @override
  String get cropAdjustErrorDetectEdges =>
      'Dokumentkanten konnten nicht erkannt werden. Passe die Ecken manuell an.';

  @override
  String get workshopTitle => 'Werkstatt';

  @override
  String get workshopConvert => 'Konvertieren';

  @override
  String get workshopEditPdf => 'PDF bearbeiten';

  @override
  String get workshopMoreTools => 'Weitere Tools';

  @override
  String get toolImageToPdf => 'Bild zu PDF';

  @override
  String get toolPdfToImage => 'PDF zu Bild';

  @override
  String get toolPdfToWord => 'PDF zu Word';

  @override
  String get toolPdfToExcel => 'PDF zu Excel';

  @override
  String get toolMergePdf => 'PDFs verbinden';

  @override
  String get toolSplitPdf => 'PDF teilen';

  @override
  String get toolCompressPdf => 'PDF verkleinern';

  @override
  String get toolRotatePdf => 'PDF drehen';

  @override
  String get toolDeletePages => 'Seiten löschen';

  @override
  String get toolReorderPages => 'Seiten ordnen';

  @override
  String get toolExtractPages => 'Seiten extrahieren';

  @override
  String get toolAddPassword => 'Passwort setzen';

  @override
  String get toolSign => 'Dokument signieren';

  @override
  String get toolSignDesc => 'Signatur zu deinen Dokumenten hinzufügen';

  @override
  String get toolWatermark => 'Wasserzeichen';

  @override
  String get toolWatermarkDesc =>
      'Wasserzeichen zu deinen Dokumenten hinzufügen';

  @override
  String get toolOcr => 'OCR';

  @override
  String get toolOcrDesc => 'Text aus Bildern extrahieren';

  @override
  String get toolQrGenerator => 'QR-Code-Generator';

  @override
  String get toolQrGeneratorDesc => 'Erstelle deine eigenen QR-Codes';
}
