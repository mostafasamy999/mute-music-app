// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Mute Video`
  String get appTitle {
    return Intl.message('Mute Video', name: 'appTitle', desc: '', args: []);
  }

  /// `Remove sound`
  String get removeSound {
    return Intl.message(
      'Remove sound',
      name: 'removeSound',
      desc: '',
      args: [],
    );
  }

  /// `Save to gallery`
  String get saveToGallery {
    return Intl.message(
      'Save to gallery',
      name: 'saveToGallery',
      desc: '',
      args: [],
    );
  }

  /// `Removing sound...`
  String get working {
    return Intl.message(
      'Removing sound...',
      name: 'working',
      desc: '',
      args: [],
    );
  }

  /// `Saving...`
  String get saving {
    return Intl.message('Saving...', name: 'saving', desc: '', args: []);
  }

  /// `Saved to your gallery`
  String get savedToGallery {
    return Intl.message(
      'Saved to your gallery',
      name: 'savedToGallery',
      desc: '',
      args: [],
    );
  }

  /// `Sound removed. You can save it now.`
  String get readyToSave {
    return Intl.message(
      'Sound removed. You can save it now.',
      name: 'readyToSave',
      desc: '',
      args: [],
    );
  }

  /// `Original`
  String get labelOriginal {
    return Intl.message('Original', name: 'labelOriginal', desc: '', args: []);
  }

  /// `No sound`
  String get labelMuted {
    return Intl.message('No sound', name: 'labelMuted', desc: '', args: []);
  }

  /// `Could not open that video.`
  String get errorPickFailed {
    return Intl.message(
      'Could not open that video.',
      name: 'errorPickFailed',
      desc: '',
      args: [],
    );
  }

  /// `Could not remove the sound.`
  String get errorMuteFailed {
    return Intl.message(
      'Could not remove the sound.',
      name: 'errorMuteFailed',
      desc: '',
      args: [],
    );
  }

  /// `Could not save the video.`
  String get errorSaveFailed {
    return Intl.message(
      'Could not save the video.',
      name: 'errorSaveFailed',
      desc: '',
      args: [],
    );
  }

  /// `This file has no video inside it.`
  String get errorNoVideoTrack {
    return Intl.message(
      'This file has no video inside it.',
      name: 'errorNoVideoTrack',
      desc: '',
      args: [],
    );
  }

  /// `Permission denied. Allow gallery access to save.`
  String get errorPermission {
    return Intl.message(
      'Permission denied. Allow gallery access to save.',
      name: 'errorPermission',
      desc: '',
      args: [],
    );
  }

  /// `Could not download the AI model. Check your internet and try again.`
  String get errorModelDownload {
    return Intl.message(
      'Could not download the AI model. Check your internet and try again.',
      name: 'errorModelDownload',
      desc: '',
      args: [],
    );
  }

  /// `Remove music only`
  String get removeMusic {
    return Intl.message(
      'Remove music only',
      name: 'removeMusic',
      desc: '',
      args: [],
    );
  }

  /// `Getting ready, one time only...`
  String get downloadingModel {
    return Intl.message(
      'Getting ready, one time only...',
      name: 'downloadingModel',
      desc: '',
      args: [],
    );
  }

  /// `Removing the music...`
  String get removingMusic {
    return Intl.message(
      'Removing the music...',
      name: 'removingMusic',
      desc: '',
      args: [],
    );
  }

  /// `No music`
  String get labelNoMusic {
    return Intl.message('No music', name: 'labelNoMusic', desc: '', args: []);
  }

  /// `Music removed. You can save it now.`
  String get readyToSaveMusic {
    return Intl.message(
      'Music removed. You can save it now.',
      name: 'readyToSaveMusic',
      desc: '',
      args: [],
    );
  }

  /// `The AI model is not ready yet. Try again.`
  String get errorModelMissing {
    return Intl.message(
      'The AI model is not ready yet. Try again.',
      name: 'errorModelMissing',
      desc: '',
      args: [],
    );
  }

  /// `This video has no sound to work on.`
  String get errorNoAudioTrack {
    return Intl.message(
      'This video has no sound to work on.',
      name: 'errorNoAudioTrack',
      desc: '',
      args: [],
    );
  }

  /// `Could not remove the music from this video.`
  String get errorMusicRemoval {
    return Intl.message(
      'Could not remove the music from this video.',
      name: 'errorMusicRemoval',
      desc: '',
      args: [],
    );
  }

  /// `Get the AI model`
  String get stepModel {
    return Intl.message(
      'Get the AI model',
      name: 'stepModel',
      desc: '',
      args: [],
    );
  }

  /// `Read the audio`
  String get stepExtract {
    return Intl.message(
      'Read the audio',
      name: 'stepExtract',
      desc: '',
      args: [],
    );
  }

  /// `Separate the voices`
  String get stepSeparate {
    return Intl.message(
      'Separate the voices',
      name: 'stepSeparate',
      desc: '',
      args: [],
    );
  }

  /// `Build the video`
  String get stepBuild {
    return Intl.message(
      'Build the video',
      name: 'stepBuild',
      desc: '',
      args: [],
    );
  }

  /// `Part {current} of {total}`
  String stepPart(int current, int total) {
    return Intl.message(
      'Part $current of $total',
      name: 'stepPart',
      desc: '',
      args: [current, total],
    );
  }

  /// `{percent}%`
  String stepPercent(int percent) {
    return Intl.message(
      '$percent%',
      name: 'stepPercent',
      desc: '',
      args: [percent],
    );
  }

  /// `Choose a part`
  String get choosePart {
    return Intl.message(
      'Choose a part',
      name: 'choosePart',
      desc: '',
      args: [],
    );
  }

  /// `Choose a part`
  String get choosePartTitle {
    return Intl.message(
      'Choose a part',
      name: 'choosePartTitle',
      desc: '',
      args: [],
    );
  }

  /// `Use this part`
  String get usePart {
    return Intl.message('Use this part', name: 'usePart', desc: '', args: []);
  }

  /// `Start {time}`
  String partStart(String time) {
    return Intl.message(
      'Start $time',
      name: 'partStart',
      desc: '',
      args: [time],
    );
  }

  /// `End {time}`
  String partEnd(String time) {
    return Intl.message('End $time', name: 'partEnd', desc: '', args: [time]);
  }

  /// `Length {time}`
  String partLength(String time) {
    return Intl.message(
      'Length $time',
      name: 'partLength',
      desc: '',
      args: [time],
    );
  }

  /// `Part {start}–{end}`
  String partLabel(String start, String end) {
    return Intl.message(
      'Part $start–$end',
      name: 'partLabel',
      desc: '',
      args: [start, end],
    );
  }

  /// `Remove music works on parts up to {limit}. Remove sound works on any length.`
  String partTooLongForMusic(String limit) {
    return Intl.message(
      'Remove music works on parts up to $limit. Remove sound works on any length.',
      name: 'partTooLongForMusic',
      desc: '',
      args: [limit],
    );
  }

  /// `Cutting the part...`
  String get cutting {
    return Intl.message(
      'Cutting the part...',
      name: 'cutting',
      desc: '',
      args: [],
    );
  }

  /// `Could not cut that part of the video.`
  String get errorCutFailed {
    return Intl.message(
      'Could not cut that part of the video.',
      name: 'errorCutFailed',
      desc: '',
      args: [],
    );
  }

  /// `This video is too long for Remove music. Choose a part up to {limit} first.`
  String errorTooLongChoosePart(String limit) {
    return Intl.message(
      'This video is too long for Remove music. Choose a part up to $limit first.',
      name: 'errorTooLongChoosePart',
      desc: '',
      args: [limit],
    );
  }

  /// `Language`
  String get language {
    return Intl.message('Language', name: 'language', desc: '', args: []);
  }

  /// `Phone language`
  String get languageSystem {
    return Intl.message(
      'Phone language',
      name: 'languageSystem',
      desc: '',
      args: [],
    );
  }

  /// `Could not save the language. It will reset next time.`
  String get errorLanguageSave {
    return Intl.message(
      'Could not save the language. It will reset next time.',
      name: 'errorLanguageSave',
      desc: '',
      args: [],
    );
  }

  /// `This file can't be played. It may have been moved or deleted.`
  String get previewUnavailable {
    return Intl.message(
      'This file can\'t be played. It may have been moved or deleted.',
      name: 'previewUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `Add an image, a sound or a video`
  String get addFileHint {
    return Intl.message(
      'Add an image, a sound or a video',
      name: 'addFileHint',
      desc: '',
      args: [],
    );
  }

  /// `Add a file`
  String get addFileTitle {
    return Intl.message('Add a file', name: 'addFileTitle', desc: '', args: []);
  }

  /// `Image`
  String get addImage {
    return Intl.message('Image', name: 'addImage', desc: '', args: []);
  }

  /// `Sound`
  String get addSound {
    return Intl.message('Sound', name: 'addSound', desc: '', args: []);
  }

  /// `Video`
  String get addVideo {
    return Intl.message('Video', name: 'addVideo', desc: '', args: []);
  }

  /// `Clear this file`
  String get clearFile {
    return Intl.message(
      'Clear this file',
      name: 'clearFile',
      desc: '',
      args: [],
    );
  }

  /// `Image`
  String get labelImage {
    return Intl.message('Image', name: 'labelImage', desc: '', args: []);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ar'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
