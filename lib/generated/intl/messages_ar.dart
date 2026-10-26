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

  static String m2(time) => "النهاية ${time}";

  static String m3(start, end) => "جزء ${start}–${end}";

  static String m4(time) => "المدة ${time}";

  static String m5(time) => "البداية ${time}";

  static String m6(limit) =>
      "إزالة الموسيقى تعمل على أجزاء حتى ${limit}. إزالة الصوت تعمل على أي مدة.";

  static String m7(current, total) => "الجزء ${current} من ${total}";

  static String m8(percent) => "${percent}%";

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
    "chooseFullLength": MessageLookupByLibrary.simpleMessage("الطول الكامل"),
    "chooseOriginal": m0,
    "choosePart": MessageLookupByLibrary.simpleMessage("اختر جزءًا"),
    "choosePartTitle": MessageLookupByLibrary.simpleMessage("اختر جزءًا"),
    "clearFile": MessageLookupByLibrary.simpleMessage("إزالة هذا الملف"),
    "convertToAudio": MessageLookupByLibrary.simpleMessage("تحويل إلى صوت"),
    "converting": MessageLookupByLibrary.simpleMessage(
      "جارٍ إنشاء ملف الصوت...",
    ),
    "cutting": MessageLookupByLibrary.simpleMessage("جاري قص الجزء..."),
    "downloadingModel": MessageLookupByLibrary.simpleMessage(
      "جاري التجهيز، لمرة واحدة فقط...",
    ),
    "errorConvertFailed": MessageLookupByLibrary.simpleMessage(
      "تعذّر إنشاء ملف صوت من هذا الفيديو.",
    ),
    "errorCutFailed": MessageLookupByLibrary.simpleMessage(
      "تعذر قص هذا الجزء من الفيديو.",
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
    "errorTooLongChoosePart": m1,
    "labelAudio": MessageLookupByLibrary.simpleMessage("صوت (M4A)"),
    "labelImage": MessageLookupByLibrary.simpleMessage("صورة"),
    "labelMuted": MessageLookupByLibrary.simpleMessage("بدون صوت"),
    "labelNoMusic": MessageLookupByLibrary.simpleMessage("بدون موسيقى"),
    "labelOriginal": MessageLookupByLibrary.simpleMessage("الأصلي"),
    "language": MessageLookupByLibrary.simpleMessage("اللغة"),
    "languageSystem": MessageLookupByLibrary.simpleMessage("لغة الهاتف"),
    "originalTitle": MessageLookupByLibrary.simpleMessage("قبل آخر تغيير"),
    "partEnd": m2,
    "partLabel": m3,
    "partLength": m4,
    "partStart": m5,
    "partTooLongForMusic": m6,
    "previewUnavailable": MessageLookupByLibrary.simpleMessage(
      "لا يمكن تشغيل هذا الملف. ربما نُقل أو حُذف.",
    ),
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
    "savedToGallery": MessageLookupByLibrary.simpleMessage(
      "تم الحفظ في المعرض",
    ),
    "saving": MessageLookupByLibrary.simpleMessage("جاري الحفظ..."),
    "showOriginal": MessageLookupByLibrary.simpleMessage(
      "اعرض الملف قبل هذا التغيير",
    ),
    "stepBuild": MessageLookupByLibrary.simpleMessage("تجهيز الفيديو"),
    "stepExtract": MessageLookupByLibrary.simpleMessage("قراءة الصوت"),
    "stepModel": MessageLookupByLibrary.simpleMessage(
      "تحميل نموذج الذكاء الاصطناعي",
    ),
    "stepPart": m7,
    "stepPercent": m8,
    "stepSeparate": MessageLookupByLibrary.simpleMessage("فصل الأصوات"),
    "usePart": MessageLookupByLibrary.simpleMessage("استخدم هذا الجزء"),
    "working": MessageLookupByLibrary.simpleMessage("جاري إزالة الصوت..."),
  };
}
