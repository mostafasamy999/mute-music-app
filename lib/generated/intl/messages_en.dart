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

  static String m0(length) => "Original · ${length}";

  static String m1(limit) =>
      "This video is too long for Remove music. Choose a part up to ${limit} first.";

  static String m2(limit) =>
      "This file is too long to read. Choose a part up to ${limit} first.";

  static String m3(time) => "End ${time}";

  static String m4(start, end) => "Part ${start}–${end}";

  static String m5(time) => "Length ${time}";

  static String m6(time) => "Start ${time}";

  static String m7(limit) =>
      "Remove music works on parts up to ${limit}. Remove sound works on any length.";

  static String m8(size) =>
      "Reading the words in a sound or video works offline, with a one-time download of about ${size} MB. Wi-Fi is recommended.";

  static String m9(current, total) => "Part ${current} of ${total}";

  static String m10(percent) => "${percent}%";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "addFileHint": MessageLookupByLibrary.simpleMessage(
      "Add an image, a sound or a video",
    ),
    "addFileTitle": MessageLookupByLibrary.simpleMessage("Add a file"),
    "addImage": MessageLookupByLibrary.simpleMessage("Image"),
    "addSound": MessageLookupByLibrary.simpleMessage("Sound"),
    "addVideo": MessageLookupByLibrary.simpleMessage("Video"),
    "appTitle": MessageLookupByLibrary.simpleMessage("Mute Video"),
    "audioReady": MessageLookupByLibrary.simpleMessage(
      "The audio file is ready.",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "chooseFullLength": MessageLookupByLibrary.simpleMessage("Full length"),
    "chooseOriginal": m0,
    "choosePart": MessageLookupByLibrary.simpleMessage("Choose a part"),
    "choosePartTitle": MessageLookupByLibrary.simpleMessage("Choose a part"),
    "clearFile": MessageLookupByLibrary.simpleMessage("Clear this file"),
    "convertToAudio": MessageLookupByLibrary.simpleMessage("Convert to audio"),
    "converting": MessageLookupByLibrary.simpleMessage(
      "Making the audio file...",
    ),
    "copied": MessageLookupByLibrary.simpleMessage("Copied."),
    "copyText": MessageLookupByLibrary.simpleMessage("Copy"),
    "cutting": MessageLookupByLibrary.simpleMessage("Cutting the part..."),
    "download": MessageLookupByLibrary.simpleMessage("Download"),
    "downloadingModel": MessageLookupByLibrary.simpleMessage(
      "Getting ready, one time only...",
    ),
    "downloadingSpeechModel": MessageLookupByLibrary.simpleMessage(
      "Downloading the speech model...",
    ),
    "errorConvertFailed": MessageLookupByLibrary.simpleMessage(
      "Could not make an audio file from this video.",
    ),
    "errorCutFailed": MessageLookupByLibrary.simpleMessage(
      "Could not cut that part of the video.",
    ),
    "errorExtractFailed": MessageLookupByLibrary.simpleMessage(
      "Could not read the text from this file.",
    ),
    "errorLanguageSave": MessageLookupByLibrary.simpleMessage(
      "Could not save the language. It will reset next time.",
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
    "errorNoText": MessageLookupByLibrary.simpleMessage(
      "No text was found in this file.",
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
    "errorSpeechModelDownload": MessageLookupByLibrary.simpleMessage(
      "Could not download the speech model. Check your connection and try again.",
    ),
    "errorSpeechModelMissing": MessageLookupByLibrary.simpleMessage(
      "The speech model is not downloaded yet.",
    ),
    "errorTooLongChoosePart": m1,
    "errorTooLongForText": m2,
    "extractText": MessageLookupByLibrary.simpleMessage("Extract text"),
    "extracting": MessageLookupByLibrary.simpleMessage("Reading the text..."),
    "labelAudio": MessageLookupByLibrary.simpleMessage("Audio (M4A)"),
    "labelImage": MessageLookupByLibrary.simpleMessage("Image"),
    "labelMuted": MessageLookupByLibrary.simpleMessage("No sound"),
    "labelNoMusic": MessageLookupByLibrary.simpleMessage("No music"),
    "labelOriginal": MessageLookupByLibrary.simpleMessage("Original"),
    "language": MessageLookupByLibrary.simpleMessage("Language"),
    "languageSystem": MessageLookupByLibrary.simpleMessage("Phone language"),
    "listening": MessageLookupByLibrary.simpleMessage(
      "Listening to the words...",
    ),
    "originalTitle": MessageLookupByLibrary.simpleMessage(
      "Before the last change",
    ),
    "partEnd": m3,
    "partLabel": m4,
    "partLength": m5,
    "partStart": m6,
    "partTooLongForMusic": m7,
    "previewUnavailable": MessageLookupByLibrary.simpleMessage(
      "This file can\'t be played. It may have been moved or deleted.",
    ),
    "readAgain": MessageLookupByLibrary.simpleMessage("Read again"),
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
    "saveToMusic": MessageLookupByLibrary.simpleMessage("Save to Music"),
    "savedToGallery": MessageLookupByLibrary.simpleMessage(
      "Saved to your gallery",
    ),
    "savedToMusicAndroid": MessageLookupByLibrary.simpleMessage(
      "Saved to Music › Mute Video.",
    ),
    "savedToMusicIos": MessageLookupByLibrary.simpleMessage(
      "Saved to Files › On My iPhone › Mute Video.",
    ),
    "saving": MessageLookupByLibrary.simpleMessage("Saving..."),
    "showOriginal": MessageLookupByLibrary.simpleMessage(
      "Show the file before this change",
    ),
    "speechModelBody": m8,
    "speechModelTitle": MessageLookupByLibrary.simpleMessage(
      "Download the speech model?",
    ),
    "stepBuild": MessageLookupByLibrary.simpleMessage("Build the video"),
    "stepExtract": MessageLookupByLibrary.simpleMessage("Read the audio"),
    "stepModel": MessageLookupByLibrary.simpleMessage("Get the AI model"),
    "stepPart": m9,
    "stepPercent": m10,
    "stepSeparate": MessageLookupByLibrary.simpleMessage("Separate the voices"),
    "textTitle": MessageLookupByLibrary.simpleMessage("Text"),
    "usePart": MessageLookupByLibrary.simpleMessage("Use this part"),
    "working": MessageLookupByLibrary.simpleMessage("Removing sound..."),
  };
}
