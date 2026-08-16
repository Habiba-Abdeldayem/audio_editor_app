// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'محرر الصوت';

  @override
  String get audioEditorAppBarTitle => 'محرر الصوت';

  @override
  String get chooseM4aFile => 'اختر ملف .m4a';

  @override
  String get loadingAudio => 'جارٍ تحميل الصوت...';

  @override
  String get readingFileInfo => 'جارٍ قراءة معلومات الملف...';

  @override
  String get generatingWaveform => 'جارٍ إنشاء الموجات الصوتية...';

  @override
  String get preparingPlayback => 'جارٍ تحضير التشغيل...';

  @override
  String get compress => 'ضغط';

  @override
  String get metadata => 'البيانات الوصفية';

  @override
  String get chooseDifferentFile => 'اختر ملفًا آخر';

  @override
  String get compressAudio => 'ضغط الصوت';

  @override
  String currentSize(String size) {
    return 'الحجم الحالي: $size';
  }

  @override
  String get compressing => 'جارٍ الضغط…';

  @override
  String get compressionComplete => 'اكتمل الضغط';

  @override
  String get compressionFailed => 'فشل الضغط.';

  @override
  String get chooseSizeToRetry => 'اختر حجمًا أدناه للمحاولة مرة أخرى.';

  @override
  String get smaller => 'smaller';

  @override
  String get editMetadata => 'تعديل البيانات الوصفية';

  @override
  String get fieldTitle => 'العنوان';

  @override
  String get fieldArtist => 'الفنان';

  @override
  String get fieldAlbum => 'الألبوم';

  @override
  String get fieldGenre => 'النوع';

  @override
  String get saveMetadata => 'حفظ البيانات الوصفية';

  @override
  String get split => 'تقسيم';

  @override
  String splitDescription(int minute, int seconds, String duration) {
    return 'يقسم إلى ملفين عند مؤشر التشغيل الحالي — الدقيقة $minute، $seconds ثانية ($duration).';
  }

  @override
  String get splitAtCurrentPosition => 'تقسيم عند الموقع الحالي';

  @override
  String get splitting => 'جاري التقسيم...';

  @override
  String get createdFiles => 'الملفات المنشأة';

  @override
  String get fileNoLongerExists => 'الملف لم يعد موجودًا.';

  @override
  String couldNotShareFile(String error) {
    return 'تعذر مشاركة الملف: $error';
  }

  @override
  String get rename => 'إعادة تسمية';

  @override
  String get fileName => 'اسم الملف';

  @override
  String get cancel => 'إلغاء';

  @override
  String renamedTo(String name) {
    return 'تمت إعادة التسمية إلى \"$name\"';
  }

  @override
  String couldNotOpenFolder(String error) {
    return 'تعذر فتح المجلد: $error';
  }

  @override
  String get showInFolder => 'إظهار في المجلد';

  @override
  String get share => 'مشاركة';

  @override
  String get back10s => 'رجوع 10 ثوانٍ';

  @override
  String get forward10s => 'تقديم 10 ثوانٍ';

  @override
  String get fileAccessError => 'تعذر الوصول إلى ملف الصوت.';

  @override
  String get unsupportedFormatError => 'ملفات .m4a فقط مدعومة.';

  @override
  String get playbackError => 'فشل التشغيل.';

  @override
  String get splitError => 'تعذر تقسيم ملف الصوت.';

  @override
  String get compressionError => 'تعذر ضغط ملف الصوت.';

  @override
  String get metadataError => 'تعذر قراءة أو كتابة البيانات الوصفية.';

  @override
  String get validationError => 'فشل التحقق.';

  @override
  String get unknownError => 'حدث خطأ ما.';

  @override
  String get settings => 'الإعدادات';

  @override
  String get theme => 'المظهر';

  @override
  String get systemDefault => 'الافتراضي للنظام';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String get language => 'اللغة';
}
