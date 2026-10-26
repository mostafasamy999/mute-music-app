# 001 Mute Video: Start Here

**Last updated:** 2026-10-26  
**State:** 001 WP0, WP1, WP2, WP4 and 002–005 are coded at `3e8fde4` (branch `feature/004-app-language`, not merged to `main`). 94 unit tests pass, analyze is clean. Every feature still has a device check open. Open questions Q1–Q4, Q6–Q8 and 003 P1–P4 haven't been answered; the code uses the defaults.

## 1. Send the questions (10 min)

Send [open-questions.md](open-questions.md), 003 §8 P1–P4 and the business questions B1–B5 in [ROADMAP.md](../ROADMAP.md) §4 together.

## 2. Work you can do now (in order)

1. Device checks: 002 T6, 003 T6, 004 T5, 005 T3, then 001 T3.3 (memory on the lowest device).
2. Merge `feature/004-app-language` into `main` (ROADMAP R0.1).
3. **WP5** native correctness with the test clips, and **WP9** housekeeping.
4. Then the roadmap: 006 Share and 007 Cancel are first ([ROADMAP.md](../ROADMAP.md) §3).

## 3. Prompt to start a Claude session

Open a session in `~/StudioProjects/mute-music-app` and paste:

```
Read lib/doc/specs/README.md, lib/doc/specs/ROADMAP.md and lib/doc/specs/001-mute-video/{spec.md,tasks.md}.
Do 001 WP5 (T5.1 then T5.2).
Follow the constraints (don't touch the DSP math; every new string in EN and AR; no exception escapes a repository).
Tick each task in tasks.md only after its Verify step passes.
```

## 4. At the end of the day

- Tick the finished tasks in `tasks.md`.
- Update this file's **State** and next steps.
- Commit, for example `spec(001): progress — WP5 done`.

## Running the device tests

`integration_test/native_cleanup_test.dart` needs `test_clip.mp4` (with video and audio) in the app's files folder. `flutter test` uninstalls the app at the end, so stage the clip again before every run:

```bash
flutter build apk --debug && adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s emulator-5554 push test_clip.mp4 /data/local/tmp/
adb -s emulator-5554 shell run-as com.mostafasamy.mutemusic.mute_music_app mkdir -p files
adb -s emulator-5554 shell run-as com.mostafasamy.mutemusic.mute_music_app cp /data/local/tmp/test_clip.mp4 files/test_clip.mp4
flutter test integration_test/native_cleanup_test.dart -d emulator-5554
```

The clip used on 2026-10-19 was the video_player example `Butterfly-209.mp4` plus a `say`-generated AAC voice track (4.7 s). It is not in either repo. Tracked as part of T5.1 (`test_assets/`).
