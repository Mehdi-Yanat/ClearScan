// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'كليارسكان';

  @override
  String get scanButton => 'مسح';

  @override
  String get homeTitle => 'الرئيسية';

  @override
  String get settingsTitle => 'إعدادات';

  @override
  String get toolsTitle => 'أدوات';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'الإنجليزية';

  @override
  String get german => 'الألمانية';

  @override
  String get arabic => 'العربية';

  @override
  String get freePlan => 'خطة مجانية';

  @override
  String get authGuestTitle => 'زائر';

  @override
  String get authGuestDescription => 'سجّل الدخول للوصول إلى حسابك';

  @override
  String get authSignIn => 'تسجيل الدخول';

  @override
  String get authSignOut => 'تسجيل الخروج';

  @override
  String get authTitle => 'حسابك';

  @override
  String get authSignInSubtitle => 'سجّل الدخول إلى حساب ClearScan.';

  @override
  String get authSignUpSubtitle => 'أنشئ حسابًا للبدء.';

  @override
  String get authCreateAccount => 'إنشاء حساب';

  @override
  String get authFullName => 'الاسم الكامل';

  @override
  String get authEmail => 'البريد الإلكتروني';

  @override
  String get authPassword => 'كلمة المرور';

  @override
  String get authNameRequired => 'أدخل اسمك.';

  @override
  String get authInvalidEmail => 'أدخل عنوان بريد إلكتروني صالحًا.';

  @override
  String get authPasswordTooShort => 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل.';

  @override
  String get authHaveAccount => 'لديك حساب بالفعل؟ سجّل الدخول';

  @override
  String get authNeedAccount => 'جديد في ClearScan؟ أنشئ حسابًا';

  @override
  String get authBackendNotConfigured => 'لم يتم إعداد تسجيل الدخول إلى الحساب بعد.';

  @override
  String get authBackendSetupInstructions => 'شغّل مهمة VS Code ‏\"Run with Supabase\" أو الأمر .\\tool\\flutter_with_supabase.ps1 run. سيحمّل الرابط والمفتاح العام من .env. لا تضع مفاتيح سرية في التطبيق.';

  @override
  String get authCheckEmail => 'تحقق من بريدك الإلكتروني لتأكيد حسابك.';

  @override
  String get authContinueWithGoogle => 'المتابعة باستخدام Google';

  @override
  String get authOr => 'أو';

  @override
  String get authGoogleNotConfigured => 'عيّن google_ID_client في .env إلى معرّف Google Web، ثم أعد التشغيل عبر Run with Supabase.';

  @override
  String get cloudStorage => 'التخزين السحابي';

  @override
  String get cloudStorageLoading => 'جارٍ التحميل...';

  @override
  String cloudBackupCount(int count) {
    return '$count نسخة احتياطية';
  }

  @override
  String cloudStorageUsed(Object size) {
    return 'المستخدم: $size';
  }

  @override
  String get cloudStoragePrivacy => 'نسخ خاصة بحسابك فقط.';

  @override
  String get cloudBackupChooseDocuments => 'اختر المستندات لنسخها احتياطيًا';

  @override
  String get cloudNoLocalDocuments => 'لم يتم العثور على مستندات محلية.';

  @override
  String cloudBackupSelected(int count) {
    return 'نسخ $count المحددة احتياطيًا';
  }

  @override
  String get cloudUploading => 'جارٍ الرفع...';

  @override
  String get cloudUploadAction => 'نسخ سحابي';

  @override
  String cloudUploadError(Object error) {
    return 'تعذر النسخ إلى السحابة: $error';
  }

  @override
  String get cloudCopyLink => 'نسخ الرابط';

  @override
  String get cloudLinkCopied => 'تم نسخ الرابط. تنتهي صلاحيته خلال 24 ساعة.';

  @override
  String cloudLinkError(Object error) {
    return 'تعذر إنشاء رابط المشاركة: $error';
  }

  @override
  String get cloudBackups => 'النسخ السحابية';

  @override
  String get cloudNoBackups => 'لا توجد نسخ سحابية حتى الآن.';

  @override
  String get cloudRestore => 'استعادة إلى هذا الجهاز';

  @override
  String get cloudCancel => 'إلغاء';

  @override
  String get cloudDeleteConfirmTitle => 'حذف النسخة السحابية؟';

  @override
  String cloudDeleteConfirmMessage(Object name) {
    return 'حذف $name من السحابة؟ ستبقى النسخة المحلية.';
  }

  @override
  String cloudDeleteComplete(Object name) {
    return 'تم حذف $name من النسخ السحابية.';
  }

  @override
  String cloudDeleteError(Object error) {
    return 'تعذر حذف النسخة السحابية: $error';
  }

  @override
  String cloudBackupComplete(int count) {
    return 'تم نسخ $count مستند احتياطيًا.';
  }

  @override
  String cloudBackupPartialFailure(int count, Object error) {
    return 'تم نسخ $count؛ خطأ: $error';
  }

  @override
  String cloudRestoreComplete(Object name) {
    return 'تمت استعادة $name إلى هذا الجهاز.';
  }

  @override
  String cloudStorageError(Object error) {
    return 'تعذرت استعادة النسخة الاحتياطية: $error';
  }

  @override
  String get cloudRefresh => 'تحديث النسخ';

  @override
  String get cloudManageBackups => 'إدارة النسخ';

  @override
  String get on => 'مفعل';

  @override
  String get off => 'معطل';

  @override
  String get comingSoon => 'قريبًا';

  @override
  String get backupAndSync => 'النسخ الاحتياطي والمزامنة';

  @override
  String get appLock => 'قفل التطبيق';

  @override
  String get appLockAuthReason => 'تحقق من هويتك لفتح ClearScan.';

  @override
  String get appLockAuthenticationFailed => 'فشل التحقق. حاول مجددًا.';

  @override
  String appLockAuthenticationError(Object error) {
    return 'تعذر التحقق: $error';
  }

  @override
  String get appLockUnlockTitle => 'ClearScan مقفل';

  @override
  String get appLockUnlockButton => 'فتح ClearScan';

  @override
  String get appearance => 'المظهر';

  @override
  String get rateClearScan => 'قيم ClearScan';

  @override
  String get helpAndSupport => 'المساعدة والدعم';

  @override
  String get about => 'حول';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get settingsTooltip => 'الإعدادات';

  @override
  String get storage => 'تخزين';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String get system => 'النظام';

  @override
  String get rateStoreListing => 'فتح قائمة المتجر';

  @override
  String get helpCenterEmail => 'فتح مركز المساعدة / البريد الإلكتروني';

  @override
  String helpEmailLaunchFailed(Object email) {
    return 'تعذر فتح البريد. راسل $email.';
  }

  @override
  String get scanAnythingSaveEverything => 'امسح كل شيء. احفظ كل شيء.';

  @override
  String get quickActions => 'الإجراءات السريعة';

  @override
  String get recentDocuments => 'المستندات الأخيرة';

  @override
  String get openPdf => 'فتح ملف PDF';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsRetry => 'إعادة المحاولة';

  @override
  String get notificationsEmpty => 'أنت على اطلاع بكل جديد.';

  @override
  String get notificationsMarkAllRead => 'تحديد الكل كمقروء';

  @override
  String get notificationsClearAll => 'مسح كل الإشعارات';

  @override
  String get notificationScanTitle => 'تم التقاط المسح';

  @override
  String get notificationImportTitle => 'تم استيراد الصورة';

  @override
  String get notificationFolderTitle => 'تم إنشاء المجلد';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get idCards => 'بطاقات الهوية';

  @override
  String get passport => 'جواز السفر';

  @override
  String get qrCode => 'رمز الاستجابة السريعة';

  @override
  String get import => 'استيراد';

  @override
  String get share => 'مشاركة';

  @override
  String get rename => 'إعادة التسمية';

  @override
  String get delete => 'حذف';

  @override
  String documentDeleteConfirmation(Object name) {
    return 'حذف $name؟ لا يمكن التراجع.';
  }

  @override
  String documentRenameSuccess(Object name) {
    return 'تمت إعادة التسمية إلى $name';
  }

  @override
  String documentDeleteSuccess(Object name) {
    return 'تم حذف $name';
  }

  @override
  String get fast_and_smart => 'مسح سريع وذكي وآمن\nللمستندات.';

  @override
  String get documentsTitle => 'المستندات';

  @override
  String get documentsSortBy => 'ترتيب حسب';

  @override
  String get documentsFilterAll => 'الكل';

  @override
  String get documentsFilterPdf => 'PDF';

  @override
  String get documentsFilterImages => 'صور';

  @override
  String get documentsFilterDocs => 'مستندات';

  @override
  String get documentsFilterFavorites => 'المفضلة';

  @override
  String get sortDate => 'التاريخ';

  @override
  String get sortName => 'الاسم';

  @override
  String get sortSize => 'الحجم';

  @override
  String get searchTooltip => 'بحث';

  @override
  String get selectOption => 'اختيار';

  @override
  String get newOption => 'جديد…';

  @override
  String get searchHint => 'ابحث عن المستندات';

  @override
  String get undo => 'التراجع';

  @override
  String get scanDocument => 'مسح المستند';

  @override
  String get newFolder => 'مجلد جديد';

  @override
  String get importFile => 'استيراد ملف';

  @override
  String get removeFromFavorites => 'إزالة من المفضلة';

  @override
  String get addToFavorites => 'إضافة إلى المفضلة';

  @override
  String get items => 'العناصر';

  @override
  String get noDocumentsFound => 'لم يتم العثور على مستندات';

  @override
  String get onboardingSlideScanTitle => 'امسح كل شيء';

  @override
  String get onboardingSlideScanSubtitle => 'حوّل الورق إلى PDF واضح وقابل للبحث\nفي ثوانٍ.';

  @override
  String get onboardingSlideOrganizeTitle => 'نظم كل شيء';

  @override
  String get onboardingSlideOrganizeSubtitle => 'رتّب الهويات والعقود والإيصالات\nفي مجلدات.';

  @override
  String get onboardingSlideSignTitle => 'عدل ووقع';

  @override
  String get onboardingSlideSignSubtitle => 'ادمج مستنداتك واضغطها ووقّعها وشاركها\nبسهولة.';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get onboardingGetStarted => 'ابدأ الآن';

  @override
  String get onboardingAgreeTerms => 'بالمتابعة، أنت توافق على الشروط وسياسة الخصوصية';

  @override
  String get onboardingTileIdCards => 'بطاقات الهوية';

  @override
  String get onboardingTileContracts => 'العقود';

  @override
  String get onboardingTileReceipts => 'الإيصالات';

  @override
  String get scanModeIdCardLabel => 'بطاقة الهوية الوطنية';

  @override
  String get scanModePassportLabel => 'جواز السفر';

  @override
  String get scanModeDocumentLabel => 'مستند';

  @override
  String get scanModeQrLabel => 'رمز الاستجابة السريعة';

  @override
  String get scanModeBookLabel => 'كتاب';

  @override
  String get scanModeIdCardHint => 'التقط الوجه الأمامي للهوية.';

  @override
  String get scanModeBackSideHint => 'تم التقاط الأمام. التقط الخلف.';

  @override
  String get scanIdFrontLabel => 'الوجه الأمامي';

  @override
  String get scanIdBackLabel => 'الوجه الخلفي';

  @override
  String get scanRetakeIdFront => 'أعد التقاط الوجه الأمامي';

  @override
  String get scanModePassportHint => 'ضع صفحة بيانات الجواز في الإطار.';

  @override
  String get scanModeDocumentHint => 'ضع المستند داخل الإطار.';

  @override
  String get scanModeQrHint => 'ضع رمز QR في الإطار.';

  @override
  String get scanModeBookHint => 'ضع الصفحتين داخل الإطار.';

  @override
  String get scanGuidanceHoldSteady => 'اثبت الكاميرا.';

  @override
  String get scanGuidanceReduceGlare => 'خفف الانعكاس.';

  @override
  String get scanGuidanceImproveLighting => 'حسّن الإضاءة.';

  @override
  String get scanGuidanceKeepInFrame => 'أبقِ البطاقة داخل الإطار.';

  @override
  String get scanGuidanceMoveCloser => 'اقترب.';

  @override
  String get scanGuidanceMoveBack => 'ابتعد.';

  @override
  String get scanGuidanceAlignCard => 'حاذِ البطاقة داخل الإطار.';

  @override
  String get scanGuidanceMoveAwayFromEdge => 'أبعد البطاقة عن الحافة.';

  @override
  String get settingsSectionScanning => 'المسح';

  @override
  String get settingsSectionSecurity => 'الأمان';

  @override
  String get settingsSectionStorageSync => 'التخزين والمزامنة';

  @override
  String get settingsSectionAbout => 'حول';

  @override
  String get settingsAppLock => 'قفل التطبيق (رقم سري / بصمة)';

  @override
  String get settingsHideInRecents => 'إخفاء من المشغل';

  @override
  String get settingsAutoBackup => 'النسخ الاحتياطي التلقائي';

  @override
  String get settingsDefaultQuality => 'الجودة الافتراضية';

  @override
  String get settingsDefaultFormat => 'الشكل الافتراضي';

  @override
  String get settingsClearCache => 'مسح التخزين المؤقت';

  @override
  String get settingsPrivacyPolicy => 'سياسة الخصوصية';

  @override
  String get settingsTermsOfService => 'شروط الخدمة';

  @override
  String get settingsQualityLow => 'منخفضة';

  @override
  String get settingsQualityMedium => 'متوسطة';

  @override
  String get settingsQualityHigh => 'عالية';

  @override
  String get scannerGrid => 'إظهار الشبكة';

  @override
  String get settingsFormatPdf => 'PDF';

  @override
  String get settingsFormatJpg => 'JPG';

  @override
  String get settingsClearCacheTitle => 'مسح التخزين المؤقت؟';

  @override
  String get settingsClearCacheMessage => 'سيتم حذف الملفات المؤقتة فقط.';

  @override
  String get settingsCancel => 'إلغاء';

  @override
  String get settingsClear => 'مسح';

  @override
  String get settingsCacheCleared => 'تم مسح التخزين المؤقت';

  @override
  String settingsOpenLinkPlaceholder(Object title) {
    return '$title: أضف رابطك';
  }

  @override
  String get cropAdjustBack => 'العودة';

  @override
  String get cropAdjustTitle => 'ضبط الحواف';

  @override
  String get cropAdjustNext => 'التالي';

  @override
  String get cropAdjustPage => 'الصفحة';

  @override
  String get cropAdjustRetake => 'إعادة التقاط';

  @override
  String get cropAdjustRotate => 'تدوير';

  @override
  String get cropAdjustAutoCrop => 'قص تلقائي';

  @override
  String get cropAdjustAddPage => 'إضافة صفحة';

  @override
  String get cropAdjustErrorOpenImage => 'لم يتم فتح الصورة.';

  @override
  String get cropAdjustErrorCropImage => 'تعذر قص الصورة. اضبط الزوايا.';

  @override
  String get cropAdjustErrorDetectEdges => 'تعذر اكتشاف الحواف. اضبطها يدويًا.';

  @override
  String get workshopTitle => 'الورشة';

  @override
  String get workshopConvert => 'تحويل';

  @override
  String get workshopEditPdf => 'تعديل PDF';

  @override
  String get workshopMoreTools => 'المزيد من الأدوات';

  @override
  String get toolImageToPdf => 'صورة إلى PDF';

  @override
  String get toolPdfToImage => 'PDF إلى صورة';

  @override
  String get pdfToWordTitle => 'تحويل PDF إلى Word';

  @override
  String get pdfToWordSelectPdf => 'اختيار ملف PDF';

  @override
  String get pdfToWordHint => 'صدّر نص PDF إلى Word. يدعم OCR العربية والإنجليزية والألمانية؛ قد يختلف التنسيق.';

  @override
  String get pdfToWordConverting => 'جارٍ استخراج النص وتشغيل OCR…';

  @override
  String pdfToWordProgress(Object completed, Object total) {
    return 'تمت معالجة $completed من أصل $total صفحات';
  }

  @override
  String get pdfToWordShare => 'مشاركة مستند Word';

  @override
  String pdfToWordConversionFailed(Object error) {
    return 'تعذر تحويل ملف PDF: $error';
  }

  @override
  String pdfToWordShareFailed(Object error) {
    return 'تعذر مشاركة مستند Word: $error';
  }

  @override
  String get pdfToImageTitle => 'تحويل PDF إلى صورة';

  @override
  String get pdfToImageSelectPdf => 'اختيار ملف PDF';

  @override
  String get pdfToImageHint => 'حوّل كل صفحة من ملف PDF إلى صورة PNG.';

  @override
  String get pdfToImageConverting => 'جارٍ تحويل صفحات PDF…';

  @override
  String pdfToImageProgress(Object completed, Object total) {
    return 'تم تحويل $completed من أصل $total صفحات';
  }

  @override
  String pdfToImageConvertedPages(Object count) {
    return 'تم تحويل $count صفحات';
  }

  @override
  String get pdfToImageShare => 'مشاركة الصور';

  @override
  String pdfToImageConversionFailed(Object error) {
    return 'تعذر تحويل ملف PDF: $error';
  }

  @override
  String pdfToImageShareFailed(Object error) {
    return 'تعذرت مشاركة الصور: $error';
  }

  @override
  String get toolPdfToWord => 'PDF إلى Word';

  @override
  String get toolPdfToExcel => 'PDF إلى Excel';

  @override
  String get pdfToExcelTitle => 'تحويل PDF إلى Excel';

  @override
  String get pdfToExcelSelectPdf => 'اختيار ملف PDF';

  @override
  String get pdfToExcelHint => 'صدّر نص PDF إلى Excel حسب الصفحة والسطر. يدعم OCR العربية والإنجليزية والألمانية.';

  @override
  String get pdfToExcelConverting => 'جارٍ استخراج النص وتشغيل OCR…';

  @override
  String pdfToExcelProgress(Object completed, Object total) {
    return 'تمت معالجة $completed من أصل $total صفحات';
  }

  @override
  String get pdfToExcelShare => 'مشاركة ملف Excel';

  @override
  String pdfToExcelConversionFailed(Object error) {
    return 'تعذر تحويل ملف PDF: $error';
  }

  @override
  String pdfToExcelShareFailed(Object error) {
    return 'تعذر مشاركة ملف Excel: $error';
  }

  @override
  String get toolMergePdf => 'دمج PDF';

  @override
  String get toolSplitPdf => 'تقسيم PDF';

  @override
  String get toolCompressPdf => 'ضغط PDF';

  @override
  String get toolRotatePdf => 'تدوير PDF';

  @override
  String get toolDeletePages => 'حذف الصفحات';

  @override
  String get toolReorderPages => 'ترتيب الصفحات';

  @override
  String get toolExtractPages => 'استخراج الصفحات';

  @override
  String get toolAddPassword => 'إضافة كلمة مرور';

  @override
  String get toolSign => 'توقيع مستند';

  @override
  String get toolSignDesc => 'إضافة توقيع إلى مستنداتك';

  @override
  String get signatureClear => 'مسح التوقيع';

  @override
  String get signatureColor => 'لون التوقيع';

  @override
  String get signatureBlack => 'أسود';

  @override
  String get signatureWhite => 'أبيض';

  @override
  String get signaturePlacementHint => 'اسحب توقيعك على الصفحة إلى الموضع المطلوب.';

  @override
  String get signaturePreviewUnavailable => 'المعاينة غير متاحة. اختر PDF مجددًا.';

  @override
  String get toolWatermark => 'علامة مائية';

  @override
  String get toolWatermarkDesc => 'إضافة علامة مائية إلى مستنداتك';

  @override
  String get watermarkText => 'نص العلامة المائية';

  @override
  String get watermarkTextHint => 'مثال: سري';

  @override
  String get watermarkOpacity => 'العتامة';

  @override
  String get watermarkPositionHint => 'اسحب العلامة المائية لتحديد موضعها في كل الصفحات.';

  @override
  String get watermarkPreviewUnavailable => 'معاينة الصفحة غير متاحة.';

  @override
  String get watermarkAllPagesHint => 'ستُضاف العلامة المائية إلى كل صفحة.';

  @override
  String get watermarkApply => 'إضافة علامة مائية';

  @override
  String get watermarkPdfAccessFailed => 'تعذر الوصول إلى ملف PDF المحدد.';

  @override
  String get toolOcr => 'OCR';

  @override
  String get toolOcrDesc => 'استخراج النص من الصور';

  @override
  String get ocrHint => 'اختر صورة للتعرف على النص بالإنجليزية أو الألمانية أو العربية.';

  @override
  String get ocrSelectImage => 'اختر صورة';

  @override
  String get ocrProcessing => 'جارٍ التعرف على النص…';

  @override
  String get ocrResult => 'النص المستخرج';

  @override
  String get ocrNoText => 'لم يتم العثور على نص في هذه الصورة.';

  @override
  String ocrFailed(Object error) {
    return 'تعذر التعرف على النص: $error';
  }

  @override
  String get ocrCopy => 'نسخ النص';

  @override
  String get ocrCopied => 'تم نسخ النص';

  @override
  String get ocrImagePreviewFailed => 'تعذر عرض الصورة المحددة.';

  @override
  String get toolQrGenerator => 'مولّد رمز QR';

  @override
  String get toolQrGeneratorDesc => 'إنشاء رموز QR الخاصة بك';

  @override
  String get qrGeneratorHint => 'أدخل نصًا أو رابطًا لإنشاء رمز QR.';

  @override
  String get qrGeneratorContent => 'نص أو رابط';

  @override
  String get qrGeneratorContentHint => 'أدخل المحتوى المطلوب ترميزه';

  @override
  String get qrGeneratorShare => 'مشاركة رمز QR';

  @override
  String get qrGeneratorTooLong => 'هذا المحتوى أطول من أن يتسع له رمز QR.';

  @override
  String get pdfEditChoosePdf => 'اختر PDF';

  @override
  String get pdfEditSourcePassword => 'كلمة مرور PDF (إن كان محميًا)';

  @override
  String get pdfEditSourcePasswordHelp => 'تحقق من كلمة المرور ثم أعد فتح PDF.';

  @override
  String get pdfEditOpenFailed => 'تعذر فتح PDF. تحقق من كلمة المرور وحاول مجددًا.';

  @override
  String get pdfEditLoadAgain => 'تحميل PDF';

  @override
  String pdfEditPageCount(Object count) {
    return '$count صفحات';
  }

  @override
  String get pdfEditPageRange => 'الصفحات';

  @override
  String get pdfEditPageRangeHint => '1,3-5';

  @override
  String get pdfEditPageRangeHelp => 'أدخل أرقام الصفحات أو نطاقات مفصولة بفواصل.';

  @override
  String get pdfEditSplitHint => 'كل صفحة مختارة ستحفظ كملف PDF منفصل.';

  @override
  String get pdfEditRotateHint => 'الصفحات المختارة تدور 90° باتجاه عقارب الساعة.';

  @override
  String get pdfEditReorderHint => 'رتب الصفحات بالشكل المطلوب.';

  @override
  String pdfEditPage(Object page) {
    return 'الصفحة $page';
  }

  @override
  String get pdfEditMoveUp => 'تحريك لأعلى';

  @override
  String get pdfEditMoveDown => 'تحريك لأسفل';

  @override
  String get pdfEditNewPassword => 'كلمة مرور جديدة (على الأقل 6 أحرف)';

  @override
  String get pdfEditConfirmPassword => 'تأكيد كلمة المرور';

  @override
  String get pdfEditPasswordsDoNotMatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get pdfEditCompressionNote => 'الضغط القوي يحوّل الصفحات إلى صور؛ لن يمكن تحديد النص أو البحث عنه وقد تقل الجودة.';

  @override
  String get pdfEditCompressionWarningTitle => 'تحذير من الضغط القوي';

  @override
  String get pdfEditCompressionCancel => 'إلغاء';

  @override
  String get pdfEditCompressionConfirm => 'ضغط على أي حال';

  @override
  String get pdfEditCompressionNoReduction => 'النسخة المضغوطة أكبر. تم الاحتفاظ بالأصل.';

  @override
  String pdfEditRun(Object tool) {
    return 'تشغيل $tool';
  }

  @override
  String get pdfEditDone => 'تم الإنتهاء. تم حفظ ملفات PDF المعدلة في المستندات.';

  @override
  String get scannerTooltipClose => 'إغلاق';

  @override
  String get scannerTooltipFlash => 'فلاش';

  @override
  String get scannerTooltipSettings => 'الإعدادات';

  @override
  String get scannerTryAgain => 'حاول مرة أخرى';

  @override
  String get scannerErrorNoCamera => 'لم يتم العثور على كاميرا في هذا الجهاز.';

  @override
  String get scannerErrorPermission => 'إذن الكاميرا مطلوب لمسح المستندات.';

  @override
  String scannerErrorStart(Object error) {
    return 'فشل تشغيل الكاميرا ($error).';
  }

  @override
  String get folderMultiSelectBack => 'عودة';

  @override
  String get folderMultiSelectChangeView => 'تغيير العرض';

  @override
  String get folderMultiSelectMoreOptions => 'المزيد من الخيارات';

  @override
  String get folderMultiSelectDateLabel => 'التاريخ';

  @override
  String get folderMultiSelectMerge => 'دمج';

  @override
  String get folderMultiSelectExport => 'تصدير';

  @override
  String get homeTooltipClose => 'إغلاق';

  @override
  String get homeTooltipFlash => 'فلاش';

  @override
  String get homeTooltipSettings => 'الإعدادات';

  @override
  String get homeTryAgain => 'حاول مرة أخرى';

  @override
  String get scanActionCamera => 'المسح بالكاميرا';

  @override
  String get scanActionGallery => 'اختيار من المعرض';

  @override
  String get scanExportingPdf => 'جارٍ تصدير PDF…';

  @override
  String get scanExportPdf => 'تصدير كملف PDF';

  @override
  String get scanInfoHeader => 'مسح صورة';

  @override
  String get scanInfoHint => 'التقط من الكاميرا أو اختر صورة من المعرض.';
}
