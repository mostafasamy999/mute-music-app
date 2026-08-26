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

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "appTitle": MessageLookupByLibrary.simpleMessage("كتم الفيديو"),
    "emptyHint": MessageLookupByLibrary.simpleMessage(
      "اختر فيديو وسأزيل الصوت منه.",
    ),
    "errorMuteFailed": MessageLookupByLibrary.simpleMessage(
      "تعذرت إزالة الصوت.",
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
    "labelMuted": MessageLookupByLibrary.simpleMessage("بدون صوت"),
    "labelOriginal": MessageLookupByLibrary.simpleMessage("الأصلي"),
    "pickAnotherVideo": MessageLookupByLibrary.simpleMessage("اختر فيديو آخر"),
    "pickVideo": MessageLookupByLibrary.simpleMessage("اختر فيديو"),
    "readyToSave": MessageLookupByLibrary.simpleMessage(
      "تمت إزالة الصوت. يمكنك حفظه الآن.",
    ),
    "removeSound": MessageLookupByLibrary.simpleMessage("إزالة الصوت"),
    "saveToGallery": MessageLookupByLibrary.simpleMessage("حفظ في المعرض"),
    "savedToGallery": MessageLookupByLibrary.simpleMessage(
      "تم الحفظ في المعرض",
    ),
    "saving": MessageLookupByLibrary.simpleMessage("جاري الحفظ..."),
    "working": MessageLookupByLibrary.simpleMessage("جاري إزالة الصوت..."),
  };
}
