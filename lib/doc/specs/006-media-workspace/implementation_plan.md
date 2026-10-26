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
- [x] **S3** Previews handle missing or broken files (W11)
- [x] **S4** `MediaAsset` with a kind: image, audio, video (§6). *Approved: typedef approach*
- [x] **S5** Empty screen with the add widget, add sheet, Clear (x) (W1–W3)
- [x] **S6** Image and audio previews (§2.2)
- [x] **S7** Actions per file type and after edits (W4). *Replaced the 005 layout*
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

**Status:** Completed (2026-10-26)  
**Goal:** no endless spinner (W11); needed before the original screen and new previews.  
**Dependencies:** S1  
**Files likely to change:** `widgets/mute_video/video_preview.dart`, ARB (`previewUnavailable`), new `test/video_preview_test.dart`  
**Files changed:** `lib/src/presentation/widgets/mute_video/video_preview.dart`, `lib/l10n/intl_{en,ar}.arb`, `lib/generated/**` (regenerated), `pubspec.yaml` + `pubspec.lock` (dev dependency `video_player_platform_interface`, already in the lock as transitive), new `test/video_preview_test.dart`

**Tasks**
- [x] Catch a failed `initialize()` and dispose the controller *(dispose is not awaited there: if creating the player itself failed, `VideoPlayerController.dispose` waits forever)*
- [x] Show `previewUnavailable` (EN + AR) with an icon in that state
- [x] Ignore a late load that finishes after a newer path was asked for *(it disposes its own player)*

**Acceptance**
- [x] A bad path shows the message, with no uncaught exception
- [x] A good path after it plays

**Tests**
- [x] New widget test with a fake `VideoPlayerPlatform`: 4 tests (missing file, good after missing, late slow load, Arabic message)
- [x] Full suite: 102 pass (98 → 102)

**Every-step checks**
- [x] `flutter analyze` is clean
- [x] `flutter test` is green, including the VIP tests
- [x] `git diff --stat` reviewed, no VIP diff

**Notes:** only the first load is covered. An error during playback (after the file opened) still shows the player as is. `dart format` also joined one existing line in `_player` (format only). Not checked on a device yet (S15).

**Risks:** `video_player` in widget tests needs a fake platform. Done with `VideoPlayerPlatform.instance = fake`.

---

## S4 `MediaAsset` with a kind

**Status:** Completed (2026-10-26). Approved by the user with the typedef approach.  
**Goal:** one asset type for image, audio and video, without changing behavior.  
**Dependencies:** S2  
**Files changed:** new `lib/src/domain/entities/media_asset.dart`, `lib/src/domain/entities/video_asset.dart` (now a typedef that re-exports `media_asset.dart`), new `test/media_asset_test.dart`

**Tasks**
- [x] Get approval with the exact file list *(approved 2026-10-26: only `video_asset.dart`, new `media_asset.dart` and tests)*
- [x] Add `MediaKind { image, audio, video }` *(plus `isImage`, `isAudio`, `isVideo`)*
- [x] Add `kind` to the asset (video by default) *(part of `==` and `hashCode`)*
- [x] Keep `VideoAsset` as a typedef, so the VIP files compile unchanged

**Acceptance**
- [x] Zero behavior change *(every existing test passes unchanged)*
- [x] `git diff --stat` shows no VIP files *(no diff under `lib/src/data`, `bloc`, `core`, `android`, `ios`, `integration_test`)*

**Tests**
- [x] All existing tests green, plus 4 new `media_asset_test` tests: 106 pass (102 → 106)

**Every-step checks**
- [x] `flutter analyze` is clean
- [x] `flutter test` is green, including the VIP tests
- [x] `git diff --stat` reviewed, no VIP diff

**Notes:** code that should be generic (state, cubit, pick) still says `VideoAsset`; S5 and later move it to `MediaAsset` as each one is touched anyway.

---

## S5 Empty screen, add sheet, Clear (x)

**Status:** Completed (2026-10-26)  
**Goal:** W1–W3.  
**Dependencies:** S4  
**Files changed:**
- New: `data/local/audio_file_datasource.dart`, `widgets/mute_video/add_media_button.dart`, `add_media_sheet.dart`, `clear_file_button.dart`, `test/add_media_test.dart`
- Renamed: `use_cases/pick_video_use_case.dart` → `pick_media_use_case.dart` (`PickMediaUseCase.call([MediaKind kind = video])`)
- Changed: `domain/repositories/video_repository.dart` (`pickFromGallery()` → `pick(MediaKind)`), `data/repositories/video_repository_impl.dart`, `bloc/mute_video/mute_video_cubit.dart` (`addMedia`, `clear`), `core/di/injector.dart`, `widgets/mute_video/mute_video_content.dart`, `video_preview_panel.dart`, ARB + generated l10n, `pubspec.yaml`/`.lock` (`file_picker` 11.0.3), `macos/Flutter/GeneratedPluginRegistrant.swift` (generated)
- Deleted: `widgets/mute_video/empty_preview_hint.dart` (replaced by the add widget)
- Tests updated for the new API/screen: `video_repository_impl_test.dart`, `widget_test.dart`, `language_sheet_test.dart`, `integration_test/native_cleanup_test.dart` (`_QueuedPick.call` signature)

**Tasks**
- [x] Add widget centered under the app bar (only widget on the empty screen)
- [x] Sheet with Image / Sound / Video, each opening the right picker *(image/video: `image_picker`; sound: `file_picker` with a fixed extension list, so iOS opens Files, not the Apple Music library)*
- [x] Copy the picked file into temp *(both pickers already hand back a copy in the temp folder: Android `cacheDir`, iOS `tmp/`; no extra copy needed)*
- [x] `clear()` drops all refs and deletes the temp copies *(each file once; never the user's own file)*
- [x] x disabled while busy *(and `clear()` itself does nothing while busy)*

**Acceptance**
- [x] Spec AC1 *(widget tests: empty screen, sheet, cancel)*
- [x] Spec AC8 (for a video) *(cubit tests: clear deletes part, original and result)*
- [x] Remove music on a video still works end to end (VIP) *(no diff in the VIP files; all Remove music tests pass. Not re-run on a device: S15)*

**Tests**
- [x] Cubit tests: add per kind, replace, cancel, clear, clear while busy (7)
- [x] Widget tests: the empty layout, sheet, closing the sheet, x, x while busy (5)
- [x] Repository tests: image pick, sound pick, closed sound picker, sound picker error (4)
- [x] Full suite: 122 pass (106 → 122)

**Every-step checks**
- [x] `flutter analyze` is clean
- [x] `flutter test` is green, including the VIP tests
- [x] `git diff --stat` reviewed, no VIP diff *(a repo-wide `dart format` had touched 3 VIP files and 3 others; reverted, and only own files are formatted from now on)*

**Notes:**
- The status line still says "Choose a video and I will remove its sound." for any picked file, and the old action buttons (Pick another video, etc.) still show until S7.
- An image or a sound file shows the "can't be played" preview until S6.
- No `READ_MEDIA_AUDIO` permission needed: the document picker grants access to the chosen file.

**Risks:** new picker package. `flutter build apk --debug` succeeds with `file_picker` (2026-10-26). iOS build not checked yet (S15).

---

## S6 Image and audio previews

**Status:** Completed (2026-10-26)  
**Goal:** preview per kind (§2.2).  
**Dependencies:** S3, S5  
**Files changed:**
- New: `widgets/mute_video/player_host.dart` (the S3 load/fail/late-load logic, shared), `audio_preview.dart`, `image_preview.dart`, `preview_unavailable.dart`, `test/media_previews_test.dart`, `test/helpers/fake_video_player.dart` (moved out of `video_preview_test.dart`)
- Changed: `video_preview.dart` (now a thin `PlayerHost` user), `video_preview_panel.dart` (switch by kind, *Image* label), ARB + generated l10n (`labelImage`), `test/video_preview_test.dart` (uses the shared fake)

**Tasks**
- [x] Image preview *(`Image.file`, fitted; broken file → `PreviewUnavailable`)*
- [x] Audio preview with play/pause, seek bar and time *(uses `video_player`, which plays sound files too: no new package)*
- [x] Panel switches the preview by kind
- [x] Labels per spec §2.3 *(Image for images; Original / Part / No sound / No music as before)*

**Acceptance**
- [x] Each kind previews
- [x] A bad file shows `previewUnavailable` *(image and audio; video from S3)*

**Tests**
- [x] Widget tests per kind: 9 in `media_previews_test.dart` (audio time, play, seek, missing, LTR time in Arabic; image file and missing; panel per kind)
- [x] Full suite: 131 pass (122 → 131); the 4 S3 tests still pass after the move into `PlayerHost`

**Every-step checks**
- [x] `flutter analyze` is clean
- [x] `flutter test` is green, including the VIP tests
- [x] `git diff --stat` reviewed, no VIP diff

**Notes:** a widget test can't decode a real image file (it hangs), so the image test checks the file and fit, and the missing-file test covers the error path. Audio playback not checked on a device yet (S15).

**Risks:** a second player package. Avoided: `video_player` plays audio files on Android (ExoPlayer) and iOS (AVPlayer).

---

## S7 Actions per file type and after edits

**Status:** Completed (2026-10-26)  
**Goal:** W4: exactly the tables in spec §3 and §3.1.  
**Dependencies:** S5, S6  
**Files changed:**
- `bloc/mute_video/mute_video_state.dart`: `ActionStage`/`stage` (005) replaced by `MediaAction`, `MediaOperation`, `current`, `isChanged`, `applied`, `actions`; `canSave` now true for a part too
- `bloc/mute_video/mute_video_cubit.dart`: Save saves `current` (the result, or the part after only a cut)
- `widgets/mute_video/mute_video_actions.dart` rewritten (no toggle; buttons from `state.actions`)
- New `widgets/mute_video/cut_file_button.dart` (cut icon over videos + `openChoosePart`, moved from the deleted `choose_part_button.dart`); `mute_video_content.dart` places it; `screens/mute_video_screen.dart` import
- `widgets/mute_video/status_message.dart`: no line for a freshly added file
- Deleted: `more_actions_toggle.dart`, `pick_video_button.dart`, `choose_part_button.dart`; strings `pickVideo`, `pickAnotherVideo`, `moreActions`, `fewerActions`, `emptyHint` (ARB + generated)
- Tests: `mute_video_actions_test.dart` rewritten, `choose_part_cubit_test.dart` (+2), new `too_long_snackbar_test.dart`

**Tasks**
- [x] Keep the list of operations applied since the last cut (`applied`) *(derived from the result for now: every operation on offer so far makes the first result, and a cut drops results. S10 turns it into a stored list when Convert to audio chains on a result)*
- [x] Derive the action list in state from the file kind + `applied` (pure, tested)
- [x] Rule A1: an operation is never offered twice
- [x] After Remove sound: only Save to gallery
- [x] Delete `more_actions_toggle.dart` and its strings (005 removed, Q17)
- [x] Hide actions not built yet (Convert to audio, Extract text, Save to Music) behind a flag until their step lands *(`MuteVideoActions.built`)*

**Acceptance**
- [x] State tests for every row of spec §3/§3.1 *(empty, image, sound, video, video part, music removed, sound removed, sound part, sound with music removed)*
- [x] AC5: video → cut → Remove music case
- [x] The "too long" snackbar still opens the cut screen *(widget test: the snackbar shows the Choose a part action)*

**Tests**
- [x] State tests for the action tables (11)
- [x] Rewritten `mute_video_actions_test.dart` widgets (6): order, after Remove sound, image, sound hides Remove music until S13, cut icon off during a job, no toggle
- [x] Cubit: Save after only a cut saves the part; Save on the untouched file does nothing (2)
- [x] Full suite: 143 pass (131 → 143); `flutter build apk --debug` OK

**Every-step checks**
- [x] `flutter analyze` is clean
- [x] `flutter test` is green, including the VIP tests
- [x] `git diff --stat` reviewed, no VIP diff

**Notes:**
- The Pick another video button is gone, as in the spec: x, then add.
- The cut entry moved from a button to the **cut icon over videos** now, not in S8, so cutting never disappears between steps. S8 still adds it for sound, plus the Original label and Full video.
- An image or a sound currently shows no action button: Extract text lands in S12, and Remove music only on a sound file in S13 (the video pipeline can't mux without a video track), so both are hidden until then.
- Not checked on a device yet (S15).

---

## S8 Cut icon; original label and Full video

**Status:** Pending  
**Goal:** W5 and the re-trim items from spec v1.0 (T1, T2). Cut always uses the first added file.  
**Dependencies:** S7  
**Files likely to change:** `video_preview_panel.dart` (cut icon over the file), `choose_part_button.dart` (entry moves), `screens/choose_part_screen.dart` (Original label, Full video button), ARB, `test/choose_part_widgets_test.dart`; for sound, new native `cutAudio`

**Tasks**
- [ ] Cut icon over every video and sound (input or output) *(videos done early in S7; sound left)*
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
| 2026-10-26 | S7 | Completed. Action tables in state (A1, Q12), new actions widget, cut icon over videos, 005 removed; 143 tests, analyze clean, VIP untouched | see S7 |
| 2026-10-26 | S6 | Completed. Image and audio previews, shared `PlayerHost`; 9 tests; 131 tests, analyze clean, VIP untouched | `player_host.dart`, `audio_preview.dart`, `image_preview.dart`, `preview_unavailable.dart`, panel, tests |
| 2026-10-26 | S5 | Completed. Add widget, sheet (image/sound/video), Clear (x); `file_picker`; 16 tests; 122 tests, analyze clean, Android build OK, VIP untouched | see S5 |
| 2026-10-26 | S4 | Completed. `MediaAsset` + `MediaKind`; `VideoAsset` is a typedef; 4 tests; 106 tests, analyze clean, VIP files untouched | `media_asset.dart`, `video_asset.dart`, `test/media_asset_test.dart` |
| 2026-10-26 | S3 | Completed. Preview shows `previewUnavailable` for a missing/broken file; late loads ignored; 4 widget tests; 102 tests, analyze clean, VIP files untouched | `video_preview.dart`, ARB, generated l10n, `pubspec.yaml`/`.lock`, `test/video_preview_test.dart` |
| 2026-10-26 | — | Plan reformatted with checkboxes | this file |
| 2026-10-26 | S2 | Completed. 4 invariant tests, all pass; 98 tests, analyze clean, VIP files untouched | `test/choose_part_cubit_test.dart` |
| 2026-10-26 | — | Spec v2.4: Q12 resolved (after only a cut: all four actions + Save) | `spec.md` |
| 2026-10-26 | — | Spec v2.3: answers 1–9 from the manual_summery check (rule A1, Remove sound → Save only, cut on any video/sound, 005 removed) | `spec.md`, this file |
| 2026-10-26 | — | Spec v2.2: Q4 M4A native, Q5 Files app, Q7 offline AR+EN (Tesseract, Whisper). S10, S11, S14 unblocked | `spec.md`, this file |
| 2026-10-26 | — | Spec v2.1 from `manual_summery`: original icon = file before the last operation; cut on sound too | `spec.md`, this file |
| 2026-10-26 | — | Spec v2.0: image, sound and video workspace. Plan rebuilt (S1–S16). Folder renamed | `006-media-workspace/{spec,implementation_plan}.md` |
| 2026-10-26 | — | Q1 and Q3 answered (spec v1.1) | `spec.md`, this file |
| 2026-10-26 | S1 | Completed. Baseline 94 tests pass, analyze clean | `006-media-workspace/{spec,implementation_plan}.md`, `README.md` |
