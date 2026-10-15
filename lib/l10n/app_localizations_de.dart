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
  String get authGuestTitle => 'Gast';

  @override
  String get authGuestDescription =>
      'Melde dich an, um auf dein Konto zuzugreifen';

  @override
  String get authSignIn => 'Anmelden';

  @override
  String get authSignOut => 'Abmelden';

  @override
  String get authTitle => 'Dein Konto';

  @override
  String get authSignInSubtitle => 'Melde dich bei deinem ClearScan-Konto an.';

  @override
  String get authSignUpSubtitle => 'Erstelle ein Konto, um loszulegen.';

  @override
  String get authCreateAccount => 'Konto erstellen';

  @override
  String get authFullName => 'Vollständiger Name';

  @override
  String get authEmail => 'E-Mail';

  @override
  String get authPassword => 'Passwort';

  @override
  String get authNameRequired => 'Gib deinen Namen ein.';

  @override
  String get authInvalidEmail => 'Gib eine gültige E-Mail-Adresse ein.';

  @override
  String get authPasswordTooShort =>
      'Das Passwort muss mindestens 6 Zeichen lang sein.';

  @override
  String get authHaveAccount => 'Du hast bereits ein Konto? Anmelden';

  @override
  String get authNeedAccount => 'Neu bei ClearScan? Konto erstellen';

  @override
  String get authBackendNotConfigured =>
      'Die Kontoanmeldung ist noch nicht eingerichtet.';

  @override
  String get authBackendSetupInstructions =>
      'Starte die VS-Code-Aufgabe \"Run with Supabase\" oder führe .\\tool\\flutter_with_supabase.ps1 run aus. URL und Publishable Key kommen aus .env. Keine geheimen Schlüssel in die App einfügen.';

  @override
  String get authCheckEmail =>
      'Bestätige dein Konto über den Link in deiner E-Mail.';

  @override
  String get authContinueWithGoogle => 'Mit Google fortfahren';

  @override
  String get authOr => 'oder';

  @override
  String get authGoogleNotConfigured =>
      'Setze google_ID_client in .env auf deine Google-Web-Client-ID und starte mit Run with Supabase neu.';

  @override
  String get cloudStorage => 'Cloud-Speicher';

  @override
  String get cloudStorageLoading => 'Wird geladen...';

  @override
  String cloudBackupCount(int count) {
    return '$count Sicherungen';
  }

  @override
  String cloudStorageUsed(Object size) {
    return '$size verwendet';
  }

  @override
  String get cloudStoragePrivacy => 'Private Sicherungen, nur für dein Konto.';

  @override
  String get cloudBackupChooseDocuments =>
      'Dokumente für die Sicherung auswählen';

  @override
  String get cloudNoLocalDocuments => 'Keine lokalen Dokumente gefunden.';

  @override
  String cloudBackupSelected(int count) {
    return '$count ausgewählte sichern';
  }

  @override
  String get cloudUploading => 'Wird hochgeladen...';

  @override
  String get cloudUploadAction => 'Backup';

  @override
  String cloudUploadError(Object error) {
    return 'Cloud-Sicherung fehlgeschlagen: $error';
  }

  @override
  String get cloudCopyLink => 'Link kopieren';

  @override
  String get cloudLinkCopied => 'Link kopiert. Er ist 24 Stunden gültig.';

  @override
  String cloudLinkError(Object error) {
    return 'Freigabelink konnte nicht erstellt werden: $error';
  }

  @override
  String get cloudBackups => 'Cloud-Sicherungen';

  @override
  String get cloudNoBackups => 'Du hast noch keine Cloud-Sicherungen.';

  @override
  String get cloudRestore => 'Auf diesem Gerät wiederherstellen';

  @override
  String get cloudCancel => 'Abbrechen';

  @override
  String get cloudDeleteConfirmTitle => 'Cloud-Sicherung löschen?';

  @override
  String cloudDeleteConfirmMessage(Object name) {
    return '$name aus der Cloud löschen? Die lokale Kopie bleibt.';
  }

  @override
  String cloudDeleteComplete(Object name) {
    return '$name wurde aus den Cloud-Sicherungen gelöscht.';
  }

  @override
  String cloudDeleteError(Object error) {
    return 'Cloud-Sicherung konnte nicht gelöscht werden: $error';
  }

  @override
  String cloudBackupComplete(int count) {
    return '$count Dokument(e) gesichert.';
  }

  @override
  String cloudBackupPartialFailure(int count, Object error) {
    return '$count gesichert; Fehler: $error';
  }

  @override
  String cloudRestoreComplete(Object name) {
    return '$name auf diesem Gerät wiederhergestellt.';
  }

  @override
  String cloudStorageError(Object error) {
    return 'Sicherung konnte nicht wiederhergestellt werden: $error';
  }

  @override
  String get cloudRefresh => 'Sicherungen aktualisieren';

  @override
  String get cloudManageBackups => 'Sicherungen verwalten';

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
      'Authentifizierung fehlgeschlagen. Bitte erneut versuchen.';

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
    return 'E-Mail-App nicht verfügbar. Schreibe an $email.';
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
    return '\"$name\" löschen? Dies ist endgültig.';
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
      'Erstelle klare, durchsuchbare PDFs\nin Sekunden aus Papier.';

  @override
  String get onboardingSlideOrganizeTitle => 'Alles organisieren';

  @override
  String get onboardingSlideOrganizeSubtitle =>
      'Sortiere Ausweise, Verträge und Belege\nin Ordnern.';

  @override
  String get onboardingSlideSignTitle => 'Bearbeiten & Unterschreiben';

  @override
  String get onboardingSlideSignSubtitle =>
      'Zusammenführen, komprimieren, signieren und teilen\nmit wenigen Fingertipps.';

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
  String get scanIdFrontLabel => 'Vorderseite';

  @override
  String get scanIdBackLabel => 'Rückseite';

  @override
  String get scanRetakeIdFront => 'Vorderseite erneut aufnehmen';

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
      'Temporäre Dateien löschen. Dokumente bleiben erhalten.';

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
      'Bildzuschnitt fehlgeschlagen. Passe die Ecken an.';

  @override
  String get cropAdjustErrorDetectEdges =>
      'Kanten nicht erkannt. Passe sie manuell an.';

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
  String get pdfToWordTitle => 'PDF zu Word';

  @override
  String get pdfToWordSelectPdf => 'PDF auswählen';

  @override
  String get pdfToWordHint =>
      'PDF-Text als Word exportieren. OCR für Arabisch, Englisch und Deutsch; Layout kann abweichen.';

  @override
  String get pdfToWordConverting =>
      'PDF-Text wird extrahiert und per OCR erkannt…';

  @override
  String pdfToWordProgress(Object completed, Object total) {
    return '$completed von $total Seiten verarbeitet';
  }

  @override
  String get pdfToWordShare => 'Word-Dokument teilen';

  @override
  String pdfToWordConversionFailed(Object error) {
    return 'PDF konnte nicht umgewandelt werden: $error';
  }

  @override
  String pdfToWordShareFailed(Object error) {
    return 'Word-Dokument konnte nicht geteilt werden: $error';
  }

  @override
  String get pdfToImageTitle => 'PDF zu Bild';

  @override
  String get pdfToImageSelectPdf => 'PDF auswählen';

  @override
  String get pdfToImageHint => 'Wandle jede PDF-Seite in ein PNG-Bild um.';

  @override
  String get pdfToImageConverting => 'PDF-Seiten werden umgewandelt…';

  @override
  String pdfToImageProgress(Object completed, Object total) {
    return '$completed von $total Seiten umgewandelt';
  }

  @override
  String pdfToImageConvertedPages(Object count) {
    return '$count Seiten umgewandelt';
  }

  @override
  String get pdfToImageShare => 'Bilder teilen';

  @override
  String pdfToImageConversionFailed(Object error) {
    return 'PDF konnte nicht umgewandelt werden: $error';
  }

  @override
  String pdfToImageShareFailed(Object error) {
    return 'Bilder konnten nicht geteilt werden: $error';
  }

  @override
  String get toolPdfToWord => 'PDF zu Word';

  @override
  String get toolPdfToExcel => 'PDF zu Excel';

  @override
  String get pdfToExcelTitle => 'PDF zu Excel';

  @override
  String get pdfToExcelSelectPdf => 'PDF auswählen';

  @override
  String get pdfToExcelHint =>
      'PDF-Text nach Seite und Zeile in Excel exportieren. OCR: Arabisch, Englisch und Deutsch.';

  @override
  String get pdfToExcelConverting =>
      'PDF-Text wird extrahiert und per OCR erkannt…';

  @override
  String pdfToExcelProgress(Object completed, Object total) {
    return '$completed von $total Seiten verarbeitet';
  }

  @override
  String get pdfToExcelShare => 'Excel-Datei teilen';

  @override
  String pdfToExcelConversionFailed(Object error) {
    return 'PDF konnte nicht umgewandelt werden: $error';
  }

  @override
  String pdfToExcelShareFailed(Object error) {
    return 'Excel-Datei konnte nicht geteilt werden: $error';
  }

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
  String get signatureClear => 'Signatur löschen';

  @override
  String get signatureColor => 'Signaturfarbe';

  @override
  String get signatureBlack => 'Schwarz';

  @override
  String get signatureWhite => 'Weiß';

  @override
  String get signaturePlacementHint =>
      'Ziehe deine Signatur auf der Seite an die gewünschte Position.';

  @override
  String get signaturePreviewUnavailable =>
      'Vorschau nicht verfügbar. Wähle die PDF erneut aus.';

  @override
  String get toolWatermark => 'Wasserzeichen';

  @override
  String get toolWatermarkDesc =>
      'Wasserzeichen zu deinen Dokumenten hinzufügen';

  @override
  String get watermarkText => 'Wasserzeichentext';

  @override
  String get watermarkTextHint => 'z. B. VERTRAULICH';

  @override
  String get watermarkOpacity => 'Deckkraft';

  @override
  String get watermarkPositionHint =>
      'Ziehe das Wasserzeichen an die gewünschte Position auf allen Seiten.';

  @override
  String get watermarkPreviewUnavailable =>
      'Die Seitenvorschau ist nicht verfügbar.';

  @override
  String get watermarkAllPagesHint =>
      'Das Wasserzeichen wird auf jeder Seite hinzugefügt.';

  @override
  String get watermarkApply => 'Wasserzeichen hinzufügen';

  @override
  String get watermarkPdfAccessFailed =>
      'Auf die ausgewählte PDF-Datei kann nicht zugegriffen werden.';

  @override
  String get toolOcr => 'OCR';

  @override
  String get toolOcrDesc => 'Text aus Bildern extrahieren';

  @override
  String get ocrHint =>
      'Wähle ein Bild aus, um Text auf Englisch, Deutsch oder Arabisch zu erkennen.';

  @override
  String get ocrSelectImage => 'Bild auswählen';

  @override
  String get ocrProcessing => 'Text wird erkannt…';

  @override
  String get ocrResult => 'Extrahierter Text';

  @override
  String get ocrNoText => 'In diesem Bild wurde kein Text gefunden.';

  @override
  String ocrFailed(Object error) {
    return 'Text konnte nicht erkannt werden: $error';
  }

  @override
  String get ocrCopy => 'Text kopieren';

  @override
  String get ocrCopied => 'Text kopiert';

  @override
  String get ocrImagePreviewFailed =>
      'Das ausgewählte Bild kann nicht angezeigt werden.';

  @override
  String get toolQrGenerator => 'QR-Code-Generator';

  @override
  String get toolQrGeneratorDesc => 'Erstelle deine eigenen QR-Codes';

  @override
  String get qrGeneratorHint =>
      'Gib Text oder einen Link ein, um einen QR-Code zu erstellen.';

  @override
  String get qrGeneratorContent => 'Text oder Link';

  @override
  String get qrGeneratorContentHint => 'Inhalt zum Kodieren eingeben';

  @override
  String get qrGeneratorShare => 'QR-Code teilen';

  @override
  String get qrGeneratorTooLong =>
      'Dieser Inhalt ist zu lang für einen QR-Code.';

  @override
  String get pdfEditChoosePdf => 'PDF auswählen';

  @override
  String get pdfEditSourcePassword => 'PDF-Passwort (falls geschützt)';

  @override
  String get pdfEditSourcePasswordHelp =>
      'Passwort prüfen und PDF erneut öffnen.';

  @override
  String get pdfEditOpenFailed =>
      'PDF konnte nicht geöffnet werden. Passwort prüfen und erneut versuchen.';

  @override
  String get pdfEditLoadAgain => 'PDF laden';

  @override
  String pdfEditPageCount(Object count) {
    return '$count Seiten';
  }

  @override
  String get pdfEditPageRange => 'Seiten';

  @override
  String get pdfEditPageRangeHint => '1,3-5';

  @override
  String get pdfEditPageRangeHelp =>
      'Seitennummern oder Bereiche durch Kommas trennen.';

  @override
  String get pdfEditSplitHint =>
      'Jede ausgewählte Seite wird als separate PDF gespeichert.';

  @override
  String get pdfEditRotateHint =>
      'Ausgewählte Seiten werden um 90° im Uhrzeigersinn gedreht.';

  @override
  String get pdfEditReorderHint =>
      'Seiten in die gewünschte Reihenfolge bringen.';

  @override
  String pdfEditPage(Object page) {
    return 'Seite $page';
  }

  @override
  String get pdfEditMoveUp => 'Nach oben';

  @override
  String get pdfEditMoveDown => 'Nach unten';

  @override
  String get pdfEditNewPassword => 'Neues Passwort (mindestens 6 Zeichen)';

  @override
  String get pdfEditConfirmPassword => 'Passwort bestätigen';

  @override
  String get pdfEditPasswordsDoNotMatch =>
      'Die Passwörter stimmen nicht überein.';

  @override
  String get pdfEditCompressionNote =>
      'Starke Komprimierung macht Seiten zu Bildern. Text ist nicht mehr auswählbar/durchsuchbar; Qualität kann sinken.';

  @override
  String get pdfEditCompressionWarningTitle =>
      'Warnung zur starken Komprimierung';

  @override
  String get pdfEditCompressionCancel => 'Abbrechen';

  @override
  String get pdfEditCompressionConfirm => 'Trotzdem komprimieren';

  @override
  String get pdfEditCompressionNoReduction =>
      'Komprimierte Datei wäre größer. Original behalten.';

  @override
  String pdfEditRun(Object tool) {
    return '$tool ausführen';
  }

  @override
  String get pdfEditDone =>
      'Fertig. Bearbeitete PDFs wurden unter Dokumente gespeichert.';

  @override
  String get scannerTooltipClose => 'Schließen';

  @override
  String get scannerTooltipFlash => 'Blitz';

  @override
  String get scannerTooltipSettings => 'Einstellungen';

  @override
  String get scannerTryAgain => 'Erneut versuchen';

  @override
  String get scannerErrorNoCamera => 'Keine Kamera auf diesem Gerät gefunden.';

  @override
  String get scannerErrorPermission =>
      'Kameraberechtigung ist erforderlich, um Dokumente zu scannen.';

  @override
  String scannerErrorStart(Object error) {
    return 'Kamera konnte nicht gestartet werden ($error).';
  }

  @override
  String get folderMultiSelectBack => 'Zurück';

  @override
  String get folderMultiSelectChangeView => 'Ansicht ändern';

  @override
  String get folderMultiSelectMoreOptions => 'Mehr Optionen';

  @override
  String get folderMultiSelectDateLabel => 'Datum';

  @override
  String get folderMultiSelectMerge => 'Zusammenführen';

  @override
  String get folderMultiSelectExport => 'Exportieren';

  @override
  String get homeTooltipClose => 'Schließen';

  @override
  String get homeTooltipFlash => 'Blitz';

  @override
  String get homeTooltipSettings => 'Einstellungen';

  @override
  String get homeTryAgain => 'Erneut versuchen';

  @override
  String get scanActionCamera => 'Mit Kamera scannen';

  @override
  String get scanActionGallery => 'Aus Galerie wählen';

  @override
  String get scanExportingPdf => 'Exportiere PDF…';

  @override
  String get scanExportPdf => 'Als PDF exportieren';

  @override
  String get scanInfoHeader => 'Bild scannen';

  @override
  String get scanInfoHint =>
      'Von Kamera aufnehmen oder Bild aus Galerie auswählen.';
}
