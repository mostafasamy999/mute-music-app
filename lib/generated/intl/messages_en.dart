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

  static String m0(current, total) => "Part ${current} of ${total}";

  static String m1(percent) => "${percent}%";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "appTitle": MessageLookupByLibrary.simpleMessage("Mute Video"),
    "downloadingModel": MessageLookupByLibrary.simpleMessage(
      "Getting ready, one time only...",
    ),
    "emptyHint": MessageLookupByLibrary.simpleMessage(
      "Choose a video and I will remove its sound.",
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
    "labelMuted": MessageLookupByLibrary.simpleMessage("No sound"),
    "labelNoMusic": MessageLookupByLibrary.simpleMessage("No music"),
    "labelOriginal": MessageLookupByLibrary.simpleMessage("Original"),
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
    "stepPart": m0,
    "stepPercent": m1,
    "stepSeparate": MessageLookupByLibrary.simpleMessage("Separate the voices"),
    "working": MessageLookupByLibrary.simpleMessage("Removing sound..."),
  };
}
