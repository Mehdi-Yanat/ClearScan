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
  String get appLockAuthenticationFailed =>
      'فشل التحقق. حاول مرة أخرى لفتح ClearScan.';

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
    return 'تعذر فتح تطبيق البريد الإلكتروني. راسل $email مباشرةً.';
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
    return 'هل تريد حذف $name؟ لا يمكن التراجع عن هذا الإجراء.';
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
  String get onboardingSlideScanSubtitle =>
      'حول الورق إلى PDFs واضحة وقابلة للبحث\nفي ثوانٍ، مباشرة من هاتفك.';

  @override
  String get onboardingSlideOrganizeTitle => 'نظم كل شيء';

  @override
  String get onboardingSlideOrganizeSubtitle =>
      'احتفظ ببطاقات الهوية والعقود والإيصالات\nمرتبة بشكل منظم في المجلدات.';

  @override
  String get onboardingSlideSignTitle => 'عدل ووقع';

  @override
  String get onboardingSlideSignSubtitle =>
      'دمج، ضغط، التوقيع والمشاركة\nمستنداتك في بضع نقرات.';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get onboardingGetStarted => 'ابدأ الآن';

  @override
  String get onboardingAgreeTerms =>
      'بالمتابعة، أنت توافق على الشروط وسياسة الخصوصية';

  @override
  String get onboardingTileIdCards => 'بطاقات الهوية';

  @override
  String get onboardingTileContracts => 'العقود';

  @override
  String get onboardingTileReceipts => 'الإيصالات';

  @override
  String get scanModeIdCardLabel => 'بطاقة الهوية';

  @override
  String get scanModePassportLabel => 'جواز السفر';

  @override
  String get scanModeDocumentLabel => 'مستند';

  @override
  String get scanModeQrLabel => 'رمز الاستجابة السريعة';

  @override
  String get scanModeBookLabel => 'كتاب';

  @override
  String get scanModeIdCardHint => 'ضع بطاقة الهوية داخل الإطار';

  @override
  String get scanModePassportHint => 'محاذاة صفحة الصورة مع الإطار';

  @override
  String get scanModeDocumentHint => 'محاذاة المستند مع الإطار';

  @override
  String get scanModeQrHint => 'وجه كاميرتك نحو رمز الاستجابة السريعة';

  @override
  String get scanModeBookHint => 'افتح الكتاب واضبط صفحتين داخل الإطار';

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
  String get settingsClearCacheMessage =>
      'سيتم حذف الملفات المؤقتة. مستنداتك لن تتأثر.';

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
  String get cropAdjustErrorCropImage =>
      'لم يتم قص الصورة. اضبط الزوايا وحاول مرة أخرى.';

  @override
  String get cropAdjustErrorDetectEdges =>
      'تعذر اكتشاف حواف المستند. اضبط الزوايا يدويًا.';

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
  String get toolPdfToWord => 'PDF إلى Word';

  @override
  String get toolPdfToExcel => 'PDF إلى Excel';

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
  String get toolSignDesc => 'أضف توقيعًا إلى مستنداتك';

  @override
  String get toolWatermark => 'علامة مائية';

  @override
  String get toolWatermarkDesc => 'أضف علامة مائية إلى مستنداتك';

  @override
  String get toolOcr => 'OCR';

  @override
  String get toolOcrDesc => 'استخراج النص من الصور';

  @override
  String get toolQrGenerator => 'مولّد رمز QR';

  @override
  String get toolQrGeneratorDesc => 'أنشئ رموز QR الخاصة بك';
}
