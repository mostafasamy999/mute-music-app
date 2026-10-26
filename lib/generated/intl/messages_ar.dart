// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ar locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'ar';

  static String m0(length) => "الأصلي · ${length}";

  static String m1(limit) =>
      "هذا الفيديو طويل جدًا لإزالة الموسيقى. اختر جزءًا حتى ${limit} أولًا.";

  static String m2(limit) =>
      "هذا الملف أطول من أن يُقرأ. اختر جزءًا حتى ${limit} أولًا.";

  static String m3(time) => "النهاية ${time}";

  static String m4(start, end) => "جزء ${start}–${end}";

  static String m5(time) => "المدة ${time}";

  static String m6(time) => "البداية ${time}";

  static String m7(limit) =>
      "إزالة الموسيقى تعمل على أجزاء حتى ${limit}. إزالة الصوت تعمل على أي مدة.";

  static String m8(size) =>
      "قراءة الكلام في الصوت أو الفيديو تعمل دون إنترنت بعد تنزيل لمرة واحدة بحجم ${size} ميغابايت تقريبًا. يُفضَّل استخدام Wi-Fi.";

  static String m9(current, total) => "الجزء ${current} من ${total}";

  static String m10(percent) => "${percent}%";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "addFileHint": MessageLookupByLibrary.simpleMessage(
      "أضف صورة أو صوتًا أو فيديو",
    ),
    "addFileTitle": MessageLookupByLibrary.simpleMessage("أضف ملفًا"),
    "addImage": MessageLookupByLibrary.simpleMessage("صورة"),
    "addSound": MessageLookupByLibrary.simpleMessage("صوت"),
    "addVideo": MessageLookupByLibrary.simpleMessage("فيديو"),
    "appTitle": MessageLookupByLibrary.simpleMessage("كتم الفيديو"),
    "audioReady": MessageLookupByLibrary.simpleMessage("ملف الصوت جاهز."),
    "cancel": MessageLookupByLibrary.simpleMessage("إلغاء"),
    "chooseFullLength": MessageLookupByLibrary.simpleMessage("الطول الكامل"),
    "chooseOriginal": m0,
    "choosePart": MessageLookupByLibrary.simpleMessage("اختر جزءًا"),
    "choosePartTitle": MessageLookupByLibrary.simpleMessage("اختر جزءًا"),
    "clearFile": MessageLookupByLibrary.simpleMessage("إزالة هذا الملف"),
    "convertToAudio": MessageLookupByLibrary.simpleMessage("تحويل إلى صوت"),
    "converting": MessageLookupByLibrary.simpleMessage(
      "جارٍ إنشاء ملف الصوت...",
    ),
    "copied": MessageLookupByLibrary.simpleMessage("تم النسخ."),
    "copyText": MessageLookupByLibrary.simpleMessage("نسخ"),
    "cutting": MessageLookupByLibrary.simpleMessage("جاري قص الجزء..."),
    "download": MessageLookupByLibrary.simpleMessage("تنزيل"),
    "downloadingModel": MessageLookupByLibrary.simpleMessage(
      "جاري التجهيز، لمرة واحدة فقط...",
    ),
    "downloadingSpeechModel": MessageLookupByLibrary.simpleMessage(
      "جارٍ تنزيل نموذج الكلام...",
    ),
    "errorConvertFailed": MessageLookupByLibrary.simpleMessage(
      "تعذّر إنشاء ملف صوت من هذا الفيديو.",
    ),
    "errorCutFailed": MessageLookupByLibrary.simpleMessage(
      "تعذر قص هذا الجزء من الفيديو.",
    ),
    "errorExtractFailed": MessageLookupByLibrary.simpleMessage(
      "تعذّرت قراءة النص من هذا الملف.",
    ),
    "errorLanguageSave": MessageLookupByLibrary.simpleMessage(
      "تعذر حفظ اللغة. ستعود للإعداد السابق في المرة القادمة.",
    ),
    "errorModelDownload": MessageLookupByLibrary.simpleMessage(
      "تعذر تنزيل نموذج الذكاء الاصطناعي. تحقق من الإنترنت وحاول مرة أخرى.",
    ),
    "errorModelMissing": MessageLookupByLibrary.simpleMessage(
      "نموذج الذكاء الاصطناعي غير جاهز. حاول مرة أخرى.",
    ),
    "errorMusicRemoval": MessageLookupByLibrary.simpleMessage(
      "تعذرت إزالة الموسيقى من هذا الفيديو.",
    ),
    "errorMuteFailed": MessageLookupByLibrary.simpleMessage(
      "تعذرت إزالة الصوت.",
    ),
    "errorNoAudioTrack": MessageLookupByLibrary.simpleMessage(
      "هذا الفيديو لا يحتوي على صوت.",
    ),
    "errorNoText": MessageLookupByLibrary.simpleMessage(
      "لم يُعثر على نص في هذا الملف.",
    ),
    "errorNoVideoTrack": MessageLookupByLibrary.simpleMessage(
      "هذا الملف لا يحتوي على فيديو.",
    ),
    "errorPermission": MessageLookupByLibrary.simpleMessage(
      "تم رفض الإذن. اسمح بالوصول للمعرض للحفظ.",
    ),
    "errorPickFailed": MessageLookupByLibrary.simpleMessage(
      "تعذر فتح هذا الفيديو.",
    ),
    "errorSaveFailed": MessageLookupByLibrary.simpleMessage(
      "تعذر حفظ الفيديو.",
    ),
    "errorSpeechModelDownload": MessageLookupByLibrary.simpleMessage(
      "تعذّر تنزيل نموذج الكلام. تحقّق من الاتصال وحاول مرة أخرى.",
    ),
    "errorSpeechModelMissing": MessageLookupByLibrary.simpleMessage(
      "لم يتم تنزيل نموذج الكلام بعد.",
    ),
    "errorTooLongChoosePart": m1,
    "errorTooLongForText": m2,
    "extractText": MessageLookupByLibrary.simpleMessage("استخراج النص"),
    "extracting": MessageLookupByLibrary.simpleMessage("جارٍ قراءة النص..."),
    "labelAudio": MessageLookupByLibrary.simpleMessage("صوت (M4A)"),
    "labelImage": MessageLookupByLibrary.simpleMessage("صورة"),
    "labelMuted": MessageLookupByLibrary.simpleMessage("بدون صوت"),
    "labelNoMusic": MessageLookupByLibrary.simpleMessage("بدون موسيقى"),
    "labelOriginal": MessageLookupByLibrary.simpleMessage("الأصلي"),
    "language": MessageLookupByLibrary.simpleMessage("اللغة"),
    "languageSystem": MessageLookupByLibrary.simpleMessage("لغة الهاتف"),
    "listening": MessageLookupByLibrary.simpleMessage(
      "جارٍ الاستماع إلى الكلام...",
    ),
    "originalTitle": MessageLookupByLibrary.simpleMessage("قبل آخر تغيير"),
    "partEnd": m3,
    "partLabel": m4,
    "partLength": m5,
    "partStart": m6,
    "partTooLongForMusic": m7,
    "previewUnavailable": MessageLookupByLibrary.simpleMessage(
      "لا يمكن تشغيل هذا الملف. ربما نُقل أو حُذف.",
    ),
    "readAgain": MessageLookupByLibrary.simpleMessage("اقرأ مرة أخرى"),
    "readyToSave": MessageLookupByLibrary.simpleMessage(
      "تمت إزالة الصوت. يمكنك حفظه الآن.",
    ),
    "readyToSaveMusic": MessageLookupByLibrary.simpleMessage(
      "تمت إزالة الموسيقى. يمكنك حفظه الآن.",
    ),
    "removeMusic": MessageLookupByLibrary.simpleMessage("إزالة الموسيقى فقط"),
    "removeSound": MessageLookupByLibrary.simpleMessage("إزالة الصوت"),
    "removingMusic": MessageLookupByLibrary.simpleMessage(
      "جاري إزالة الموسيقى...",
    ),
    "saveToGallery": MessageLookupByLibrary.simpleMessage("حفظ في المعرض"),
    "saveToMusic": MessageLookupByLibrary.simpleMessage("حفظ في الموسيقى"),
    "savedToGallery": MessageLookupByLibrary.simpleMessage(
      "تم الحفظ في المعرض",
    ),
    "savedToMusicAndroid": MessageLookupByLibrary.simpleMessage(
      "تم الحفظ في الموسيقى › Mute Video.",
    ),
    "savedToMusicIos": MessageLookupByLibrary.simpleMessage(
      "تم الحفظ في الملفات › على iPhone › Mute Video.",
    ),
    "saving": MessageLookupByLibrary.simpleMessage("جاري الحفظ..."),
    "showOriginal": MessageLookupByLibrary.simpleMessage(
      "اعرض الملف قبل هذا التغيير",
    ),
    "speechModelBody": m8,
    "speechModelTitle": MessageLookupByLibrary.simpleMessage(
      "تنزيل نموذج الكلام؟",
    ),
    "stepBuild": MessageLookupByLibrary.simpleMessage("تجهيز الفيديو"),
    "stepExtract": MessageLookupByLibrary.simpleMessage("قراءة الصوت"),
    "stepModel": MessageLookupByLibrary.simpleMessage(
      "تحميل نموذج الذكاء الاصطناعي",
    ),
    "stepPart": m9,
    "stepPercent": m10,
    "stepSeparate": MessageLookupByLibrary.simpleMessage("فصل الأصوات"),
    "textTitle": MessageLookupByLibrary.simpleMessage("النص"),
    "usePart": MessageLookupByLibrary.simpleMessage("استخدم هذا الجزء"),
    "working": MessageLookupByLibrary.simpleMessage("جاري إزالة الصوت..."),
  };
}
