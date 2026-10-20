// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
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
  String get localeName => 'en';

  static String m0(limit) =>
      "This video is too long for Remove music. Choose a part up to ${limit} first.";

  static String m1(time) => "End ${time}";

  static String m2(start, end) => "Part ${start}–${end}";

  static String m3(time) => "Length ${time}";

  static String m4(time) => "Start ${time}";

  static String m5(limit) =>
      "Remove music works on parts up to ${limit}. Remove sound works on any length.";

  static String m6(current, total) => "Part ${current} of ${total}";

  static String m7(percent) => "${percent}%";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "appTitle": MessageLookupByLibrary.simpleMessage("Mute Video"),
    "choosePart": MessageLookupByLibrary.simpleMessage("Choose a part"),
    "choosePartTitle": MessageLookupByLibrary.simpleMessage("Choose a part"),
    "cutting": MessageLookupByLibrary.simpleMessage("Cutting the part..."),
    "downloadingModel": MessageLookupByLibrary.simpleMessage(
      "Getting ready, one time only...",
    ),
    "emptyHint": MessageLookupByLibrary.simpleMessage(
      "Choose a video and I will remove its sound.",
    ),
    "errorCutFailed": MessageLookupByLibrary.simpleMessage(
      "Could not cut that part of the video.",
    ),
    "errorModelDownload": MessageLookupByLibrary.simpleMessage(
      "Could not download the AI model. Check your internet and try again.",
    ),
    "errorModelMissing": MessageLookupByLibrary.simpleMessage(
      "The AI model is not ready yet. Try again.",
    ),
    "errorMusicRemoval": MessageLookupByLibrary.simpleMessage(
      "Could not remove the music from this video.",
    ),
    "errorMuteFailed": MessageLookupByLibrary.simpleMessage(
      "Could not remove the sound.",
    ),
    "errorNoAudioTrack": MessageLookupByLibrary.simpleMessage(
      "This video has no sound to work on.",
    ),
    "errorNoVideoTrack": MessageLookupByLibrary.simpleMessage(
      "This file has no video inside it.",
    ),
    "errorPermission": MessageLookupByLibrary.simpleMessage(
      "Permission denied. Allow gallery access to save.",
    ),
    "errorPickFailed": MessageLookupByLibrary.simpleMessage(
      "Could not open that video.",
    ),
    "errorSaveFailed": MessageLookupByLibrary.simpleMessage(
      "Could not save the video.",
    ),
    "errorTooLongChoosePart": m0,
    "labelMuted": MessageLookupByLibrary.simpleMessage("No sound"),
    "labelNoMusic": MessageLookupByLibrary.simpleMessage("No music"),
    "labelOriginal": MessageLookupByLibrary.simpleMessage("Original"),
    "partEnd": m1,
    "partLabel": m2,
    "partLength": m3,
    "partStart": m4,
    "partTooLongForMusic": m5,
    "pickAnotherVideo": MessageLookupByLibrary.simpleMessage(
      "Pick another video",
    ),
    "pickVideo": MessageLookupByLibrary.simpleMessage("Pick a video"),
    "readyToSave": MessageLookupByLibrary.simpleMessage(
      "Sound removed. You can save it now.",
    ),
    "readyToSaveMusic": MessageLookupByLibrary.simpleMessage(
      "Music removed. You can save it now.",
    ),
    "removeMusic": MessageLookupByLibrary.simpleMessage("Remove music only"),
    "removeSound": MessageLookupByLibrary.simpleMessage("Remove sound"),
    "removingMusic": MessageLookupByLibrary.simpleMessage(
      "Removing the music...",
    ),
    "saveToGallery": MessageLookupByLibrary.simpleMessage("Save to gallery"),
    "savedToGallery": MessageLookupByLibrary.simpleMessage(
      "Saved to your gallery",
    ),
    "saving": MessageLookupByLibrary.simpleMessage("Saving..."),
    "stepBuild": MessageLookupByLibrary.simpleMessage("Build the video"),
    "stepExtract": MessageLookupByLibrary.simpleMessage("Read the audio"),
    "stepModel": MessageLookupByLibrary.simpleMessage("Get the AI model"),
    "stepPart": m6,
    "stepPercent": m7,
    "stepSeparate": MessageLookupByLibrary.simpleMessage("Separate the voices"),
    "usePart": MessageLookupByLibrary.simpleMessage("Use this part"),
    "working": MessageLookupByLibrary.simpleMessage("Removing sound..."),
  };
}
