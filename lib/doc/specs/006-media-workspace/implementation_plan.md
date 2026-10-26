# 006 Media Workspace: Implementation Plan

**Spec:** [spec.md](spec.md) v2.4  
**Branch:** `feature/004-app-language` (as chosen), starting at `b504eaf`  
**Last updated:** 2026-10-26

## Where this plan lives

The first request pointed at `/Users/mostafasamy/work/specs-talentlink/specs`. That folder is the **TalentLink** worktree of the specs repo, not this app. This app's specs live in its own repo at `lib/doc/specs/` (001–005 are here), so the plan is in `lib/doc/specs/006-media-workspace/`.

## Rules

- **VIP rule (spec §0):** Remove music only must keep working exactly as today. Don't edit `music_removal_repository_impl.dart`, `separation_worker.dart`, `music_separator.dart`, `pcm_io.dart`, `core/audio/*`, `separation_model_repository_impl.dart`, `model_download_service.dart`, or the native `AudioPipeline` (Android, iOS). New features call them or add **new** methods next to them. A step that needs to touch them stops and asks for approval.
- One step at a time. A step is **Completed** only when every box under it is ticked. Record the files that actually changed.
- Tick a box `[x]` only when it is really done or verified. Leave it `[ ]` otherwise, and write why under it if it is skipped.
- Every step ends with the **Every-step checks** below.
- Every new string in `intl_en.arb` and `intl_ar.arb`, then `dart run intl_utils:generate`.
- No exception escapes a repository; the screen never stays busy (001 R2).

### Every-step checks (copy under each step when you tick it)

- [ ] `flutter analyze` is clean
- [ ] `flutter test` is green, including `mdx_stft_test`, `mdx_tensor_test`, `music_removal_repository_impl_test`, `separation_worker_test`
- [ ] `git diff --stat` reviewed: no unrelated changes, **no diff in the VIP files**

## Summary

Status: `[x]` Completed · `[ ]` Pending, In Progress or Blocked (the note says which).

- [x] **S1** Codebase inspection and baseline
- [x] **S2** Lock the original/source/output invariants with tests (spec §6)
- [ ] **S3** Previews handle missing or broken files (W11)
- [ ] **S4** `MediaAsset` with a kind: image, audio, video (§6). *Needs approval: touches state and repositories*
- [ ] **S5** Empty screen with the add widget, add sheet, Clear (x) (W1–W3)
- [ ] **S6** Image and audio previews (§2.2)
- [ ] **S7** Actions per file type and after edits (W4). *Replaces the 005 layout*
- [ ] **S8** Cut icon (video, then sound); original label and Full video (W5). *Sound cut needs a new native method*
- [ ] **S9** View original screen (W6)
- [ ] **S10** Convert to audio: M4A, native (F7, W7)
- [ ] **S11** Save to Music: Android Music folder, iOS Files app (F10, W7)
- [ ] **S12** Extract text from an image (Tesseract, AR+EN) + Text screen (F8, §5, W8). *Starts with a spike*
- [ ] **S13** Remove music only on a sound file (F6). *Needs approval: new native methods next to `AudioPipeline`*
- [ ] **S14** Extract text from sound or video (Whisper, offline) (F8, W8). *Starts with a spike*
- [ ] **S15** Regression and device checks (AC1–AC10)
- [ ] **S16** Final review

Order note: every step is unblocked (Q4, Q5, Q7 answered 2026-10-26). S12 and S14 start with a spike whose result is written here before building.

---

## S1 Codebase inspection and baseline

**Status:** Completed (2026-10-26)  
**Goal:** know exactly where the original, the part, the result and the cleanup live, before changing anything.  
**Files changed:** none in `lib/`. Added this spec and plan.

**Tasks**
- [x] Map the media state, pick, trim, results, Remove music, cleanup, preview, save and main layout (table below)
- [x] List what isn't in the app at all
- [x] Record the baseline: `flutter test` 94 pass, `flutter analyze` no issues (2026-10-26, `b504eaf`)

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

---

## S2 Lock the original/source/output invariants with tests

**Status:** Completed (2026-10-26)  
**Goal:** prove today's rules before building on them. Tests only.  
**Dependencies:** S1  
**Files likely to change:** `test/mute_video_cubit_test.dart`, `test/choose_part_cubit_test.dart`  
**Files changed:** `test/choose_part_cubit_test.dart`

**Tasks**
- [x] Pick → part → Remove sound keeps `original`, `source`, `muted` separate and never discards the original *(new test)*
- [x] Part → part again discards the old part only after success *(already covered; new order test added)*
- [x] A failed cut keeps the old part and result *(new test)*
- [x] Two results in a row discard only the first *(new test, on a part)*
- [x] A new pick discards everything old *(already covered in both test files)*

**Acceptance**
- [x] All pass on the current code. **No bug found.**

**Tests**
- [x] `flutter test test/choose_part_cubit_test.dart`: 15 pass (11 → 15)
- [x] Full suite: 98 pass (94 → 98)

**Every-step checks**
- [x] `flutter analyze` is clean
- [x] `flutter test` is green, including the VIP tests
- [x] `git diff --stat` reviewed: no diff under `lib/src`, `android`, `ios`

**Risks:** duplicates of existing tests. Checked first: only the 4 missing cases were added.

---

## S3 Previews handle missing or broken files

**Status:** Pending  
**Goal:** no endless spinner (W11); needed before the original screen and new previews.  
**Dependencies:** S1  
**Files likely to change:** `widgets/mute_video/video_preview.dart`, ARB (`previewUnavailable`), new `test/video_preview_test.dart`

**Tasks**
- [ ] Catch a failed `initialize()` and dispose the controller
- [ ] Show `previewUnavailable` (EN + AR) with an icon in that state
- [ ] Ignore a late load that finishes after a newer path was asked for

**Acceptance**
- [ ] A bad path shows the message, with no uncaught exception
- [ ] A good path after it plays

**Tests**
- [ ] New widget test (fake `VideoPlayerPlatform` or an injected controller factory)
- [ ] Full suite

**Every-step checks**
- [ ] `flutter analyze` is clean
- [ ] `flutter test` is green, including the VIP tests
- [ ] `git diff --stat` reviewed, no VIP diff

**Risks:** `video_player` in widget tests needs a fake platform.

---

## S4 `MediaAsset` with a kind

**Status:** Pending. **Ask for approval** before starting, with the exact file list.  
**Goal:** one asset type for image, audio and video, without changing behavior.  
**Dependencies:** S2  
**Files likely to change:** `domain/entities/video_asset.dart` (→ `media_asset.dart` + `MediaKind`), state, cubit, use cases, `VideoRepository`, tests. **Not** the VIP files: `MusicRemovalRepository` keeps taking a video asset (an adapter or a typedef keeps its signature).

**Tasks**
- [ ] Get approval with the exact file list
- [ ] Add `MediaKind { image, audio, video }`
- [ ] Add `kind` to the asset (video by default)
- [ ] Keep `VideoAsset` as a typedef or thin alias, so the VIP files compile unchanged

**Acceptance**
- [ ] Zero behavior change
- [ ] `git diff --stat` shows no VIP files

**Tests**
- [ ] All existing tests green (98+)

**Every-step checks**
- [ ] `flutter analyze` is clean
- [ ] `flutter test` is green, including the VIP tests
- [ ] `git diff --stat` reviewed, no VIP diff

**Risks:** a wide rename.

---

## S5 Empty screen, add sheet, Clear (x)

**Status:** Pending  
**Goal:** W1–W3.  
**Dependencies:** S4  
**Files likely to change:** `screens/mute_video_screen.dart`, `widgets/mute_video/empty_preview_hint.dart` (→ add widget), new `add_media_sheet.dart`, new `clear_button.dart`, cubit (`addMedia(kind)`, `clear()`), new `PickMediaUseCase`, `VideoRepositoryImpl` (pick by kind), `pubspec.yaml` (`file_picker` for sound), Android/iOS permissions for audio, ARB, tests

**Tasks**
- [ ] Add widget centered under the app bar (only widget on the empty screen)
- [ ] Sheet with Image / Sound / Video, each opening the right picker
- [ ] Copy the picked file into temp
- [ ] `clear()` drops all refs and deletes the temp copies
- [ ] x disabled while busy

**Acceptance**
- [ ] Spec AC1
- [ ] Spec AC8 (for a video)
- [ ] Remove music on a video still works end to end (VIP)

**Tests**
- [ ] Cubit tests: add per kind, cancel, clear
- [ ] Widget tests: the empty layout and x

**Every-step checks**
- [ ] `flutter analyze` is clean
- [ ] `flutter test` is green, including the VIP tests
- [ ] `git diff --stat` reviewed, no VIP diff

**Risks:** new picker package and permissions (`READ_MEDIA_AUDIO` on Android 13+). The image_picker copy of a video must still land in temp.

---

## S6 Image and audio previews

**Status:** Pending  
**Goal:** preview per kind (§2.2).  
**Dependencies:** S3, S5  
**Files likely to change:** new `image_preview.dart`, new `audio_preview.dart` (play/pause, seek, time), `video_preview_panel.dart` (switch by kind), `pubspec.yaml` (an audio player, e.g. `just_audio`, or `video_player` for audio files), tests

**Tasks**
- [ ] Image preview
- [ ] Audio preview with play/pause, seek bar and time
- [ ] Panel switches the preview by kind
- [ ] Labels per spec §2.3

**Acceptance**
- [ ] Each kind previews
- [ ] A bad file shows `previewUnavailable`

**Tests**
- [ ] Widget tests per kind
- [ ] Full suite

**Every-step checks**
- [ ] `flutter analyze` is clean
- [ ] `flutter test` is green, including the VIP tests
- [ ] `git diff --stat` reviewed, no VIP diff

**Risks:** a second player package; check it works next to `video_player` on iOS.

---

## S7 Actions per file type and after edits

**Status:** Pending  
**Goal:** W4: exactly the tables in spec §3 and §3.1.  
**Dependencies:** S5, S6  
**Files likely to change:** `widgets/mute_video/mute_video_actions.dart` (rewritten), `more_actions_toggle.dart` (removed), state (`availableActions` derived from kind + output), tests (`mute_video_actions_test.dart` rewritten for the new tables)

**Tasks**
- [ ] Keep the list of operations applied since the last cut (`applied`)
- [ ] Derive the action list in state from the file kind + `applied` (pure, tested)
- [ ] Rule A1: an operation is never offered twice
- [ ] After Remove sound: only Save to gallery
- [ ] Delete `more_actions_toggle.dart` and its strings (005 removed, Q17)
- [ ] Hide actions not built yet (Convert to audio, Extract text, Save to Music) behind a flag until their step lands

**Acceptance**
- [ ] State tests for every row of spec §3/§3.1
- [ ] AC5: video → cut → Remove music case
- [ ] The "too long" snackbar still opens the cut screen

**Tests**
- [ ] State tests for the action tables
- [ ] Rewritten `mute_video_actions_test.dart`

**Every-step checks**
- [ ] `flutter analyze` is clean
- [ ] `flutter test` is green, including the VIP tests
- [ ] `git diff --stat` reviewed, no VIP diff

**Risks:** keep the action table in one place so later answers change one spot.

---

## S8 Cut icon; original label and Full video

**Status:** Pending  
**Goal:** W5 and the re-trim items from spec v1.0 (T1, T2). Cut always uses the first added file.  
**Dependencies:** S7  
**Files likely to change:** `video_preview_panel.dart` (cut icon over the file), `choose_part_button.dart` (entry moves), `screens/choose_part_screen.dart` (Original label, Full video button), ARB, `test/choose_part_widgets_test.dart`; for sound, new native `cutAudio`

**Tasks**
- [ ] Cut icon over every video and sound (input or output)
- [ ] The cut screen says it shows the Original
- [ ] Full video button resets both handles
- [ ] Sound: new native `cutAudio` (Android `MediaExtractor`+`MediaMuxer` copy, iOS passthrough export to `.m4a`). New methods only
- [ ] Sound: audio player on the cut screen

**Acceptance**
- [ ] The cut always uses the first added file (Q14)
- [ ] Use this part with the full range goes back to the original (existing cubit path)

**Tests**
- [ ] `test/choose_part_widgets_test.dart` updated
- [ ] Integration test for `cutAudio` on a device

**Every-step checks**
- [ ] `flutter analyze` is clean
- [ ] `flutter test` is green, including the VIP tests
- [ ] `git diff --stat` reviewed, no VIP diff

---

## S9 View original screen

**Status:** Pending  
**Goal:** W6.  
**Dependencies:** S3, S6, S8  
**Files likely to change:** new route `/original` + `screens/original_screen.dart`, the original icon on edited files, state field `lastInput`, ARB, tests

**Tasks**
- [ ] State field `lastInput`: the file before the last operation (Q1), kept until the next operation or Clear
- [ ] Original icon on every edited file
- [ ] View-only original screen with a video or audio player
- [ ] Start at the same playback position (Q3)
- [ ] Pause the edited preview before opening the screen

**Acceptance**
- [ ] Spec AC7
- [ ] The icon hides when the original file is gone

**Tests**
- [ ] State tests for `lastInput`
- [ ] Widget tests for the icon and the screen

**Every-step checks**
- [ ] `flutter analyze` is clean
- [ ] `flutter test` is green, including the VIP tests
- [ ] `git diff --stat` reviewed, no VIP diff

**Risks:** two players alive at once.

---

## S10 Convert to audio (M4A)

**Status:** Pending  
**Goal:** F7 (decision: M4A, native, no package).  
**Files likely to change:** new `AudioExporter.kt` / `AudioExporter.swift` + a new `exportAudio` method on the existing channel, `VideoMuteDatasource`, new `AudioRepository` (or a method on `VideoRepository`), `ConvertToAudioUseCase`, cubit action, `TempFilesDatasource` prefix `export_`, ARB, tests, `integration_test/audio_export_test.dart`

**Tasks**
- [ ] Android: copy the AAC track with `MediaExtractor`+`MediaMuxer` (MPEG-4 output)
- [ ] Android: if the track isn't AAC, decode and re-encode to AAC 192 kbps with `MediaCodec`
- [ ] iOS: `AVAssetExportSession` with preset `AVAssetExportPresetAppleM4A`
- [ ] Release resources on every path; delete partial output on error
- [ ] Dart side: datasource, repository, use case, cubit action, `export_` cleanup prefix

**Acceptance**
- [ ] A 1-min phone video converts in under 2 s (copy path)
- [ ] The `.m4a` length matches the video ±50 ms
- [ ] No audio track → `errorNoAudioTrack`

**Tests**
- [ ] Repository and cubit tests
- [ ] `integration_test/audio_export_test.dart` on a device

**Every-step checks**
- [ ] `flutter analyze` is clean
- [ ] `flutter test` is green, including the VIP tests
- [ ] `git diff --stat` reviewed, no VIP diff (`VideoMuter`/`AudioPipeline` untouched)

---

## S11 Save to Music

**Status:** Pending  
**Goal:** F10.  
**Dependencies:** S10  
**Files likely to change:** native `saveAudio` (Android), `Info.plist` (iOS), new `SaveAudioUseCase`, cubit action, ARB, tests

**Tasks**
- [ ] Android: `MediaStore.Audio.Media` insert into `Music/Mute Video` (API 29+)
- [ ] Android: `WRITE_EXTERNAL_STORAGE` path for API ≤ 28
- [ ] iOS: copy into the app's `Documents/` with `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` (Files › On My iPhone › Mute Video, Q5)

**Acceptance**
- [ ] Spec AC6 on Android
- [ ] Spec AC6 on iOS

**Tests**
- [ ] Repository and cubit tests
- [ ] Manual check on both platforms

**Every-step checks**
- [ ] `flutter analyze` is clean
- [ ] `flutter test` is green, including the VIP tests
- [ ] `git diff --stat` reviewed, no VIP diff

---

## S12 Extract text from an image + Text screen

**Status:** Pending  
**Goal:** F8 (image), §5, W8.  
**Dependencies:** S7  
**Files likely to change:** new `TextRecognitionRepository` + datasource, use case, cubit action, new route `/text` + `screens/text_screen.dart`, `pubspec.yaml`, ARB, tests

**Tasks**
- [ ] **Spike:** Tesseract (eng + ara, `tessdata_fast` vs `tessdata_best`) through a maintained Flutter plugin or own platform code
- [ ] Spike: measure accuracy on 5 sample images (printed Arabic, printed English, mixed, a phone photo of a page, a screenshot) and time on the SM-A515F
- [ ] Spike: decide bundled vs downloaded language data, and record the result here
- [ ] Repository, use case, cubit action
- [ ] Text screen: editable field, Copy button, RTL by content

**Acceptance**
- [ ] Spec AC2
- [ ] Spec AC10

**Tests**
- [ ] Repository and cubit tests
- [ ] Widget test: edit, then Copy puts the edited text on the clipboard

**Every-step checks**
- [ ] `flutter analyze` is clean
- [ ] `flutter test` is green, including the VIP tests
- [ ] `git diff --stat` reviewed, no VIP diff

---

## S13 Remove music only on a sound file

**Status:** Pending. **Needs approval.**  
**Goal:** F6, with the same separation.  
**Dependencies:** S5, S6, S10 (shares the audio writer)  
**Approach:** the separation core (model, worker, chunks) is reused as is. Only two **new** native methods are added beside `AudioPipeline`: read PCM from a sound-only file, and encode the voices PCM to an `.m4a`. A new small repository method wires them around the existing worker call. The existing `extract`/`mux` methods and `MusicRemovalRepositoryImpl` are not edited.

**Tasks**
- [ ] Get approval
- [ ] New native method: read PCM from a sound-only file (Android, iOS)
- [ ] New native method: encode the voices PCM to `.m4a` (Android, iOS)
- [ ] New repository method that wires them around the existing worker call

**Acceptance**
- [ ] Spec AC3
- [ ] Video Remove music output byte-for-byte unchanged on the test clip (VIP)

**Tests**
- [ ] Repository tests for the new method
- [ ] Device check with a sound file

**Every-step checks**
- [ ] `flutter analyze` is clean
- [ ] `flutter test` is green, including the VIP tests
- [ ] `git diff --stat` reviewed, no VIP diff

---

## S14 Extract text from sound or video

**Status:** Pending  
**Goal:** F8 for sound and video, offline, Arabic + English.  
**Dependencies:** S12 (Text screen), S10 (audio paths)

**Tasks**
- [ ] **Spike:** whisper.cpp through a maintained Flutter binding or own FFI; models `base` and `small` (multilingual)
- [ ] Spike: accuracy on Arabic and English clips, speed and memory peak on the SM-A515F; pick the model and record it here
- [ ] Model download (separate from the separation model; size + SHA-256; progress; ask on mobile data)
- [ ] Audio in: call the existing extract method (calling, not editing) and resample to 16 kHz mono in a **new** file
- [ ] Run in a background isolate with steps
- [ ] Length limit (default 5 min, cut first) and cancel-safe cleanup
- [ ] Reuse the Text screen

**Acceptance**
- [ ] Spec AC2 for a sound clip in Arabic and in English
- [ ] Spec AC2 for a video clip in Arabic and in English
- [ ] The UI stays responsive (R1)

**Tests**
- [ ] Repository, worker and cubit tests
- [ ] Device check

**Every-step checks**
- [ ] `flutter analyze` is clean
- [ ] `flutter test` is green, including the VIP tests
- [ ] `git diff --stat` reviewed, no VIP diff

**Risks:** app size, model download size, slow phones.

---

## S15 Regression and device checks

**Status:** Pending

**Tasks**
- [ ] AC1–AC10 on the SM-A515F
- [ ] AC1–AC10 on an iOS simulator or device
- [ ] Repeated cuts
- [ ] Several outputs from one file
- [ ] Original screen during playback
- [ ] A 20-min video with a part and Remove music (chunked separation and merge, VIP)
- [ ] Clear during and after jobs
- [ ] Relaunch cleanup
- [ ] Arabic

**Tests**
- [ ] Full suite
- [ ] `integration_test/video_cutter_test.dart`
- [ ] `integration_test/native_cleanup_test.dart`
- [ ] Manual notes here with device, clip and timings

---

## S16 Final review

**Status:** Pending

**Tasks**
- [ ] `flutter analyze` and `flutter test`
- [ ] Full diff review (VIP files untouched)
- [ ] Update this plan with real results and files
- [ ] Fold answers into `spec.md` and bump the version
- [ ] Update the README index
- [ ] Mark 005 as superseded
- [ ] List remaining issues

---

## Change log

| Date | Step | Result | Files |
|---|---|---|---|
| 2026-10-26 | — | Plan reformatted with checkboxes | this file |
| 2026-10-26 | S2 | Completed. 4 invariant tests, all pass; 98 tests, analyze clean, VIP files untouched | `test/choose_part_cubit_test.dart` |
| 2026-10-26 | — | Spec v2.4: Q12 resolved (after only a cut: all four actions + Save) | `spec.md` |
| 2026-10-26 | — | Spec v2.3: answers 1–9 from the manual_summery check (rule A1, Remove sound → Save only, cut on any video/sound, 005 removed) | `spec.md`, this file |
| 2026-10-26 | — | Spec v2.2: Q4 M4A native, Q5 Files app, Q7 offline AR+EN (Tesseract, Whisper). S10, S11, S14 unblocked | `spec.md`, this file |
| 2026-10-26 | — | Spec v2.1 from `manual_summery`: original icon = file before the last operation; cut on sound too | `spec.md`, this file |
| 2026-10-26 | — | Spec v2.0: image, sound and video workspace. Plan rebuilt (S1–S16). Folder renamed | `006-media-workspace/{spec,implementation_plan}.md` |
| 2026-10-26 | — | Q1 and Q3 answered (spec v1.1) | `spec.md`, this file |
| 2026-10-26 | S1 | Completed. Baseline 94 tests pass, analyze clean | `006-media-workspace/{spec,implementation_plan}.md`, `README.md` |
