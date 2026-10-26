# 006 Media Workspace: Implementation Plan

**Spec:** [spec.md](spec.md) v2.2  
**Branch:** `feature/004-app-language` (as chosen), starting at `b504eaf`  
**Last updated:** 2026-10-26

## Where this plan lives

The first request pointed at `/Users/mostafasamy/work/specs-talentlink/specs`. That folder is the **TalentLink** worktree of the specs repo, not this app. This app's specs live in its own repo at `lib/doc/specs/` (001–005 are here), so the plan is in `lib/doc/specs/006-media-workspace/`.

## Rules

- **VIP rule (spec §0):** Remove music only must keep working exactly as today. Don't edit `music_removal_repository_impl.dart`, `separation_worker.dart`, `music_separator.dart`, `pcm_io.dart`, `core/audio/*`, `separation_model_repository_impl.dart`, `model_download_service.dart`, or the native `AudioPipeline` (Android, iOS). New features call them or add **new** methods next to them. A step that needs to touch them stops and asks for approval.
- One step at a time. A step is **Completed** only when its acceptance criteria and tests pass. Record the files that actually changed.
- Every step runs: `flutter analyze` (clean), `flutter test` (green, including `mdx_stft_test`, `mdx_tensor_test`, `music_removal_repository_impl_test`, `separation_worker_test`), and `git diff --stat` reviewed for unrelated changes and for **no diff in the VIP files**.
- Every new string in `intl_en.arb` and `intl_ar.arb`, then `dart run intl_utils:generate`.
- No exception escapes a repository; the screen never stays busy (001 R2).

## Summary

| Step | Title | Spec | Status |
|---|---|---|---|
| S1 | Codebase inspection and baseline | — | **Completed** |
| S2 | Lock the original/source/output invariants with tests | §6 | Pending |
| S3 | Previews handle missing or broken files | W11 | Pending |
| S4 | `MediaAsset` with a kind (image, audio, video) | §6 | Pending (approval: touches state and repositories) |
| S5 | Empty screen with the add widget, add sheet, Clear (x) | W1–W3 | Pending |
| S6 | Image and audio previews | §2.2 | Pending |
| S7 | Actions per file type and after edits | W4 | Pending (replaces the 005 layout) |
| S8 | Cut icon (video, then sound); original label and Full video | W5 | Pending (sound cut needs a new native method) |
| S9 | View original screen | W6 | Pending |
| S10 | Convert to audio (M4A, native) | F7, W7 | Pending |
| S11 | Save to Music (Android Music folder, iOS Files app) | F10, W7 | Pending |
| S12 | Extract text from an image (Tesseract, AR+EN) + Text screen | F8, §5, W8 | Pending (starts with a spike) |
| S13 | Remove music only on a sound file | F6 | Pending (approval: new native methods next to `AudioPipeline`) |
| S14 | Extract text from sound or video (Whisper, offline) | F8, W8 | Pending (starts with a spike) |
| S15 | Regression and device checks | AC1–AC10 | Pending |
| S16 | Final review | — | Pending |

Order note: every step is unblocked (Q4, Q5, Q7 answered 2026-10-26). S12 and S14 start with a spike whose result is written here before building.

---

## S1 Codebase inspection and baseline

- **Goal:** know exactly where the original, the part, the result and the cleanup live, before changing anything.
- **Files changed:** none in `lib/`. Added this spec and plan.
- **Status:** **Completed** (2026-10-26).

**Findings**

| Area | Where | What it does today |
|---|---|---|
| Media state | `bloc/mute_video/mute_video_state.dart` | `original` = the picked video. `source` = the part, or the original. `muted` = the latest result. `hasPart` compares paths. Video only (`VideoAsset`). |
| Pick | `MuteVideoCubit._pick` → `withNewSource` | Video only, via `image_picker`. Deletes the old source, original and result after the swap. |
| Trim | `openChoosePart` → `ChoosePartScreen` → `MuteVideoCubit._usePart` | Always opens and cuts the **original**, with the last range set. Back = no change. The old part is deleted only after a new cut succeeds. |
| Results | `_mute`, `_separate` → `_showResult` | Sets `muted`, deletes only the previous result. Every action runs on `source`, never on `muted` (no chaining today, see Q8). |
| Remove music | `MusicRemovalRepositoryImpl` + `SeparationWorker` + `MusicSeparator` + native extract/mux | **VIP**, unchanged by this plan. Needs a video track at the mux step, so a sound-only file needs new native ends (S13). No cancel. |
| Cleanup | `TempFilesDatasource` | Deletes only files inside the temp folders; leftovers by prefix (`muted_`, `nomusic_`, `audio_`, `part_`) at launch. |
| Preview | `VideoPreviewPanel` + `VideoPreview` | Video only. A failed `initialize()` isn't caught: a missing file spins forever and throws. |
| Save | `Gal.putVideo(album: 'Mute Video')` | Videos only. No audio save. |
| Main layout | `MuteVideoContent` + `MuteVideoActions` (005) | Stage-based buttons with More actions. Replaced by S5/S7. |

**Not in the app at all:** picking images or sound files, audio playback, MP3/audio export, Save to Music, text recognition, speech to text, a text screen, Clear (x).

**Baseline:** `flutter test`: 94 pass. `flutter analyze`: no issues. (2026-10-26, `b504eaf`.)

---

## S2 Lock the original/source/output invariants with tests

- **Goal:** prove today's rules before building on them. Tests only.
- **Files likely to change:** `test/mute_video_cubit_test.dart`, `test/choose_part_cubit_test.dart`.
- **Dependencies:** S1.
- **Tasks:** tests for (1) pick → part → Remove sound keeps `original`, `source`, `muted` separate and never discards the original; (2) part → part again discards the old part only after success; (3) a failed cut keeps the old part and result; (4) two results in a row discard only the first; (5) a new pick discards everything old.
- **Acceptance:** all pass on the current code. A failure is a bug: record it and fix it as its own step.
- **Tests:** the two files, then the full suite.
- **Risks:** duplicates of existing tests; check `choose_part_cubit_test.dart` first.
- **Status:** Pending.

## S3 Previews handle missing or broken files

- **Goal:** no endless spinner (W11); needed before the original screen and new previews.
- **Files likely to change:** `widgets/mute_video/video_preview.dart`, ARB (`previewUnavailable`), new `test/video_preview_test.dart`.
- **Dependencies:** S1.
- **Tasks:** catch a failed `initialize()`, dispose the controller, show `previewUnavailable`; ignore a late load after a newer path.
- **Acceptance:** a bad path shows the message, no uncaught exception; a good path after it plays.
- **Tests:** new widget test (fake `VideoPlayerPlatform` or an injected controller factory), full suite.
- **Risks:** `video_player` in widget tests needs a fake platform.
- **Status:** Pending.

## S4 `MediaAsset` with a kind

- **Goal:** one asset type for image, audio and video, without changing behavior.
- **Files likely to change:** `domain/entities/video_asset.dart` (→ `media_asset.dart` + `MediaKind`), state, cubit, use cases, `VideoRepository`, tests. **Not** the VIP files: `MusicRemovalRepository` keeps taking a video asset (an adapter or a typedef keeps its signature).
- **Dependencies:** S2.
- **Tasks:** add `MediaKind { image, audio, video }`; add `kind` to the asset (video by default); keep `VideoAsset` as a typedef or thin alias so the VIP files compile unchanged.
- **Acceptance:** zero behavior change; all 94+ tests green; `git diff --stat` shows no VIP files.
- **Risks:** a wide rename. **Ask for approval** before starting, with the exact file list.
- **Status:** Pending.

## S5 Empty screen, add sheet, Clear (x)

- **Goal:** W1–W3.
- **Files likely to change:** `screens/mute_video_screen.dart`, `widgets/mute_video/empty_preview_hint.dart` (→ add widget), new `add_media_sheet.dart`, new `clear_button.dart`, cubit (`addMedia(kind)`, `clear()`), new `PickMediaUseCase`, `VideoRepositoryImpl` (pick by kind), `pubspec.yaml` (`file_picker` for sound), Android/iOS permissions for audio, ARB, tests.
- **Dependencies:** S4.
- **Tasks:** add widget centered under the app bar; sheet with Image/Sound/Video; pick and copy into temp; `clear()` drops all refs and deletes temp copies; x disabled while busy.
- **Acceptance:** spec AC1, AC8 (for a video). Remove music on a video still works end to end (VIP).
- **Tests:** cubit tests for add per kind, cancel, clear; widget tests for the empty layout and x.
- **Risks:** new picker package and permissions (`READ_MEDIA_AUDIO` on Android 13+). The image_picker copy of a video must still land in temp.
- **Status:** Pending.

## S6 Image and audio previews

- **Goal:** preview per kind (§2.2).
- **Files likely to change:** new `image_preview.dart`, new `audio_preview.dart` (play/pause, seek, time), `video_preview_panel.dart` (switch by kind), `pubspec.yaml` (an audio player, e.g. `just_audio`, or `video_player` for audio files), tests.
- **Dependencies:** S3, S5.
- **Acceptance:** each kind previews; labels per §2.3; a bad file shows `previewUnavailable`.
- **Risks:** a second player package; check it works next to `video_player` on iOS.
- **Status:** Pending.

## S7 Actions per file type and after edits

- **Goal:** W4: exactly the tables in spec §3 and §3.1.
- **Files likely to change:** `widgets/mute_video/mute_video_actions.dart` (rewritten), `more_actions_toggle.dart` (removed), state (`availableActions` derived from kind + output), tests (`mute_video_actions_test.dart` rewritten for the new tables).
- **Dependencies:** S5, S6.
- **Tasks:** derive the action list in state (pure, tested); buttons for actions not built yet (Convert to audio, Extract text, Save to Music) stay hidden behind a flag until their step lands.
- **Acceptance:** state tests for every row of §3/§3.1, including AC5's video → cut → Remove music case. The 005 "too long" snackbar still opens the cut screen.
- **Risks:** Q8 (chaining) and Q9 (Remove sound after an edit) change the tables; use the defaults and keep the table in one place.
- **Status:** Pending.

## S8 Cut icon; original label and Full video

- **Goal:** W5 and the re-trim items from spec v1.0 (T1, T2). Cut always uses the first added file.
- **Sound:** a new native `cutAudio` (Android `MediaExtractor`+`MediaMuxer` copy, iOS passthrough export to `.m4a`) and an audio player on the cut screen. New methods only.
- **Files likely to change:** `video_preview_panel.dart` (cut icon over the video), `choose_part_button.dart` (entry moves), `screens/choose_part_screen.dart` (Original label, Full video button), ARB, `test/choose_part_widgets_test.dart`.
- **Dependencies:** S7.
- **Acceptance:** cut icon only on videos; the screen says Original; Full video resets both handles; Use this part with the full range goes back to the original (existing cubit path).
- **Status:** Pending.

## S9 View original screen

- **Goal:** W6.
- **Files likely to change:** new route `/original` + `screens/original_screen.dart` (video or audio player, view only), an original icon on the preview of edited files, a state field `lastInput` (the file before the last operation, Q1), kept alive until the next operation or Clear, position hand-off (Q3), ARB, tests.
- **Dependencies:** S3, S6, S8.
- **Acceptance:** spec AC7; the icon hides when the original file is gone.
- **Risks:** two players alive at once (pause the edited preview before pushing).
- **Status:** Pending.

## S10 Convert to audio (M4A)

- **Goal:** F7 (decision: M4A, native, no package).
- **Files likely to change:** new `AudioExporter.kt` / `AudioExporter.swift` + a new `exportAudio` method on the existing channel, `VideoMuteDatasource`, new `AudioRepository` (or a method on `VideoRepository`), `ConvertToAudioUseCase`, cubit action, `TempFilesDatasource` prefix `export_`, ARB, tests, `integration_test/audio_export_test.dart`.
- **Tasks:** Android: copy the AAC track with `MediaExtractor`+`MediaMuxer` (MPEG-4 output); if the track isn't AAC, decode and re-encode to AAC 192 kbps with `MediaCodec`. iOS: `AVAssetExportSession` preset `AVAssetExportPresetAppleM4A`. Release resources on every path; delete partial output on error.
- **Acceptance:** a 1-min phone video converts in under 2 s (copy path); the `.m4a` length matches the video ±50 ms; no audio track → `errorNoAudioTrack`.
- **Risks:** **new methods only** (VIP rule); `VideoMuter`/`AudioPipeline` untouched.
- **Status:** Pending.

## S11 Save to Music

- **Goal:** F10.
- **Files likely to change:** native `saveAudio` (Android), `Info.plist` (iOS), new `SaveAudioUseCase`, cubit action, ARB, tests.
- **Tasks:** Android: `MediaStore.Audio.Media` insert into `Music/Mute Video` (API 29+), `WRITE_EXTERNAL_STORAGE` path for ≤ 28. iOS: copy into the app's `Documents/` with `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` so it shows in Files › On My iPhone › Mute Video (Q5).
- **Acceptance:** spec AC6 on both platforms.
- **Dependencies:** S10.
- **Status:** Pending.

## S12 Extract text from an image + Text screen

- **Goal:** F8 (image), §5, W8.
- **Files likely to change:** new `TextRecognitionRepository` + datasource, use case, cubit action, new route `/text` + `screens/text_screen.dart` (editable field, Copy, RTL by content), `pubspec.yaml`, ARB, tests.
- **Dependencies:** S7.
- **Tasks:**
  1. **Spike:** Tesseract (eng + ara, `tessdata_fast` vs `tessdata_best`) through a maintained Flutter plugin or own platform code; measure accuracy on 5 sample images (printed Arabic, printed English, mixed, a phone photo of a page, a screenshot) and time on the SM-A515F. Decide bundled vs downloaded language data. Record here.
  2. Build: repository, use case, cubit action, Text screen.
- **Acceptance:** spec AC2, AC10.
- **Status:** Pending.

## S13 Remove music only on a sound file

- **Goal:** F6, with the same separation.
- **Approach (needs approval):** the separation core (model, worker, chunks) is reused as is. Only two **new** native methods are added beside `AudioPipeline`: read PCM from a sound-only file, and encode the voices PCM to an `.m4a`. A new small repository method wires them around the existing worker call. The existing `extract`/`mux` methods and `MusicRemovalRepositoryImpl` are not edited.
- **Dependencies:** S5, S6, S10 (shares the audio writer).
- **Acceptance:** spec AC3; video Remove music output byte-for-byte unchanged on the test clip (VIP).
- **Status:** Pending (approval).

## S14 Extract text from sound or video

- **Goal:** F8 for sound and video, offline, Arabic + English.
- **Tasks:**
  1. **Spike:** whisper.cpp through a maintained Flutter binding or own FFI; models `base` and `small` (multilingual); accuracy on Arabic and English clips and speed on the SM-A515F; memory peak. Pick the model, record here.
  2. Model download (new, separate from the separation model; size + SHA-256; progress; ask on mobile data).
  3. Audio in: call the existing extract method (allowed: calling, not editing) and resample to 16 kHz mono in a **new** file; run in a background isolate with steps.
  4. Length limit (default 5 min, cut first), cancel-safe cleanup, Text screen reuse.
- **Acceptance:** spec AC2 for a sound and a video clip in each language; UI stays responsive (R1).
- **Risks:** app size, model download size, slow phones; VIP files untouched.
- **Dependencies:** S12 (Text screen), S10 (audio paths).
- **Status:** Pending.

## S15 Regression and device checks

- **Tasks:** AC1–AC10 on the SM-A515F and an iOS simulator/device; repeated cuts; several outputs from one file; original screen during playback; a 20-min video with a part and Remove music (chunked separation and merge, VIP); Clear during and after jobs; relaunch cleanup; Arabic.
- **Tests:** full suite, `integration_test/video_cutter_test.dart`, `native_cleanup_test.dart`, manual notes with device, clip and timings.
- **Status:** Pending.

## S16 Final review

- **Tasks:** analyze, tests, full diff review (VIP files untouched), update this plan with real results and files, fold answers into `spec.md` (bump the version), update the README index, mark 005 as superseded, list remaining issues.
- **Status:** Pending.

---

## Change log

| Date | Step | Result | Files |
|---|---|---|---|
| 2026-10-26 | — | Spec v2.2: Q4 M4A native, Q5 Files app, Q7 offline AR+EN (Tesseract, Whisper). S10, S11, S14 unblocked | `spec.md`, this file |
| 2026-10-26 | — | Spec v2.1 from `manual_summery`: original icon = file before the last operation; cut on sound too | `spec.md`, this file |
| 2026-10-26 | — | Spec v2.0: image, sound and video workspace. Plan rebuilt (S1–S16). Folder renamed | `006-media-workspace/{spec,implementation_plan}.md` |
| 2026-10-26 | — | Q1 and Q3 answered (spec v1.1) | `spec.md`, this file |
| 2026-10-26 | S1 | Completed. Baseline 94 tests pass, analyze clean | `006-media-workspace/{spec,implementation_plan}.md`, `README.md` |
