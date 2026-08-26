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

  /// `Pick a video`
  String get pickVideo {
    return Intl.message('Pick a video', name: 'pickVideo', desc: '', args: []);
  }

  /// `Pick another video`
  String get pickAnotherVideo {
    return Intl.message(
      'Pick another video',
      name: 'pickAnotherVideo',
      desc: '',
      args: [],
    );
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

  /// `Choose a video and I will remove its sound.`
  String get emptyHint {
    return Intl.message(
      'Choose a video and I will remove its sound.',
      name: 'emptyHint',
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
