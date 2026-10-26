# 006 Media Workspace: Image, Sound and Video

**Version:** v3.0  
**Status:** **Implemented** (plan S1–S16, 2026-10-26). Checked by 208 unit tests and device tests on the iOS simulator and the Android emulator; **real phones and a manual walk-through are still open** (§8, plan S15). Q10 uses its default.  
**App:** `~/StudioProjects/mute-music-app` (Flutter, Android + iOS)  
**Builds on:** [001](../001-mute-video/spec.md) (Remove sound, Remove music, Save), [002](../002-music-removal-isolate/spec.md) (isolate, steps), [003](../003-choose-part/spec.md) (cut). **Replaces** the main-screen layout of 001 §4 and **removes** [005](../005-fewer-actions/spec.md) (More actions, deleted in plan S7).  
**Last updated:** 2026-10-26

### Changelog
- **v3.0 (2026-10-26):** Implemented. Acceptance results added (§8). Two existing iOS bugs in the Remove music video path fixed with the user's approval (§0).
- **v2.6 (2026-10-26):** Speech to text decided by the S14 spike: whisper.cpp (`whisper_cpp_flutter_plus`), multilingual `base` model with SHA-256, asked before the one-time download.
- **v2.5 (2026-10-26):** OCR engine decided by the plan's S12 spike: Tesseract (bundled tessdata_fast, eng + ara) on Android, Apple Vision on iOS. Still offline, Arabic + English.
- **v2.4 (2026-10-26):** Q12 resolved: after only a cut, all four actions plus Save to gallery.
- **v2.3 (2026-10-26):** Answers to the manual_summery check: after Remove sound only Save to gallery; an operation is never offered again once it ran (A1); cut and actions work on any video or sound, input or output, and cut always starts from the first added file; Save to Music also for sound with the music removed; Text screen = edit then Copy; More actions (005) removed; three icons on the file (x, cut, original).
- **v2.2 (2026-10-26):** Q4 decided (M4A, see F7). Q5 resolved (Files app on iOS). Q7 resolved: every feature works **offline**, in **Arabic and English**, for images, sound and video (F8).
- **v2.1 (2026-10-26):** From `manual_summery`: the original icon shows the file **before the last operation**; **cut** is also on sound files and always starts from the first added file. Q11 resolved.
- **v2.0 (2026-10-26):** The app becomes a workspace for **image, sound and video**: one add button, actions per file type, Convert to MP3, Extract text, Save to Music, and a View original screen. Folder renamed from `006-original-and-compare`.
- **v1.1 (2026-10-26):** Q1 resolved (Original = the part before the operation). Q3 resolved (keep the playback position).
- **v1.0 (2026-10-26):** Re-trim from the original and compare (video only).

---

## 0. VIP rule: Remove music only must not change

The Remove music only pipeline (download the model, extract, background isolate, **chunked separation of large videos**, merge, mux, step progress, 5 min limit with Choose a part) took a lot of work and is correct. **It must keep working exactly as it does today.**

- Don't edit: `music_removal_repository_impl.dart`, `separation_worker.dart`, `music_separator.dart`, `pcm_io.dart`, `core/audio/*` (`mdx_stft`, `mdx_tensor`, `chunk_window`), the native `AudioPipeline` (Android and iOS), `separation_model_repository_impl.dart`, `model_download_service.dart`.
- New features **call** this pipeline or **add new native methods next to it**. They never change it.
- Any step that would touch these files stops and asks for approval first.
- **Approved changes (2026-10-26, plan S15):** two lines in `ios/Runner/AudioPipeline.swift` `writeMovie`/`pump`: the pass-through video input gets a `sourceFormatHint` (it crashed the app), and sample buffers are no longer invalidated right after `append` (the write failed with "Failed to load sample data"). Remove music on a video had likely never finished on iOS before; it now does. Nothing else in the VIP files changed.
- Every step re-runs the DSP reference tests (`mdx_stft_test`, `mdx_tensor_test`) and the Remove music tests.

## 1. Purpose

Today the app takes a video and gives a video back. After this change, the user adds **one file** (an image, a sound or a video), sees only the actions that make sense for that file, and can:
- remove sound or music, cut a part, and save videos (as today),
- convert a video to an **audio file (M4A)** and save it to **Music**,
- remove the music from a **sound** file,
- **extract the text** from an image, a sound or a video, then edit and copy it,
- open the **original** file from any edited file, to compare.

## 2. Main screen

### 2.1 Empty

Under the app bar there is **only one widget**: an empty area with a large **add** icon in the center and a short hint (`addFileHint` "Add an image, a sound or a video").

Tapping it opens a small sheet with three choices: **Image**, **Sound**, **Video**. Each opens the matching system picker. Cancelling changes nothing.

### 2.2 A file is added

- The file's **preview** fills the top: an image viewer, an audio player (play/pause, seek bar, time), or the video player.
- Over the file there are at most **three icons**: **x** (clear), **cut** (video and sound only) and **original** (edited files only). There is no More actions toggle: only the needed actions show (005 is removed).
- The **x** icon **clears** the file: the file, any part and any outputs are dropped (and their temp copies deleted), and the screen goes back to Empty. While a job runs, x is disabled.
- Under the preview: the **actions** for this file type (§3).
- The app bar keeps the language button (004).

### 2.3 Labels

The label above the preview always says what is shown: *Original*, *Part 0:30–1:45*, *No sound*, *No music*, *Audio (M4A)*. For an image: *Image*.

## 3. Actions per file type

| File | On the preview | Actions under the preview |
|---|---|---|
| **Image** | x | **Extract text** (only this) |
| **Sound** | x · **cut icon** (choose a part of the sound) | **Remove music only** · **Extract text** |
| **Video** | x · **cut icon** (opens Choose a part, 003) | **Remove sound** · **Remove music only** · **Convert to audio** · **Extract text** |

### 3.1 After an edit (the output)

When an action produces a new file, the preview shows that output and the actions update:

**Rule A1: an operation never runs twice on the same file.** Once Remove music only has run, it is hidden for that output and every file made from it (for example the audio converted from it). A new cut starts again from the first added file, so every operation is offered again.

| Output | Actions under it |
|---|---|
| Video part (only a cut) | **Remove sound** · **Remove music only** · **Convert to audio** · **Extract text** · **Save to gallery** (Q12, resolved) |
| Video with music removed | **Convert to audio** · **Extract text** · **Save to gallery** |
| Video with sound removed | **Save to gallery** only (no audio is left, so nothing else can work) |
| Audio (from Convert to audio) | **Remove music only** (hidden if already applied, A1) · **Extract text** · **Save to Music** |
| Sound part (only a cut) | **Remove music only** · **Extract text** · **Save to Music** |
| Sound with music removed | **Extract text** · **Save to Music** |
| Text (from Extract text) | Opens the Text screen (§5); the file stays as it was |

Rules:
- Actions always run on the **current file** (the latest output) (Q8, resolved).
- **Save to gallery** shows only for a changed video; **Save to Music** only for a changed sound or an audio output. The untouched original is never offered for saving.
- The **cut icon** shows on every video and sound, input or output (Q14), and always cuts the **first added file** (F3).

### 3.2 View original

Every **edited** file (a part, a video result, an audio file, a sound with music removed) shows an **original icon** on its preview. Tapping it **opens a new screen** that plays the file **before the last operation**:
- Example: video → cut → Remove music → Convert to audio. On the audio file the icon opens the no-music video; on the no-music video it opens the part; on the part it opens the added video.
- So the app keeps the **input of the last operation** next to the output (Q1, resolved). Older steps are not kept.
- A video original opens a video player; a sound original opens an audio player.
- It starts at the same playback position as the edited file (Q3, resolved), when long enough.
- Back returns to the edited file, unchanged. The original screen has no actions: view only.
- The icon shows only when the original file still exists and is playable.

## 4. Flows

### F1 Add a file
Picks with the system picker (image, video: `image_picker`; sound: a file picker that allows audio types). The file is copied into the app's temp folder, so later steps never touch the user's own file. Errors: `errorPickFailed`, unsupported type → `errorUnsupportedFile`.

### F2 Clear (x)
Drops the file, part and every output; deletes the app's temp copies (never the user's own file); goes to Empty.

### F3 Cut (video and sound)
As 003 F6, opened from the **cut icon**. It **always cuts the first added file** (the original), never an output, so a new cut drops the outputs made after the old cut. For sound, the same screen with an audio player instead of the video and a native audio cut (new method). Adds: the screen says it shows the **original** and has a **Full video** reset (v1.0 T1/T2, kept).

### F4 Remove sound, F5 Remove music only (video)
Unchanged from 001 F2/F3 and 002. **VIP rule §0.**

### F6 Remove music only (sound file)
Runs the **same** separation (model, isolate, chunks, progress steps, length limit) on a sound file. Only the ends are new: reading audio from a sound-only file, and writing the voices to an audio file (no video to mux). These are **new** native methods; the existing extract/mux methods are not changed. Output: an audio file labeled *No music*.

### F7 Convert to audio (video)
Takes the audio track of the current video (or output) and writes an **M4A (AAC)** audio file (Q4, decided).
- Native, no new package: Android `MediaExtractor` + `MediaMuxer`, iOS `AVAssetExportSession` (`AppleM4A`).
- When the video's audio is already AAC (almost every phone video), the track is **copied**: instant, no quality loss. Otherwise it is re-encoded to AAC 192 kbps.
- The button reads **Convert to audio**, and the file label reads *Audio (M4A)*, so the user is never told it is an MP3 when it isn't.
- Why not real MP3: neither Android nor iOS has an MP3 encoder, so MP3 needs a bundled encoder (LAME). That makes the app bigger, encoding takes several seconds, and its LGPL license is awkward inside an iOS app. M4A plays in every music player, WhatsApp and the Files app. If real `.mp3` is ever required, it can be added later behind the same use case.
- Errors: no audio track → `errorNoAudioTrack`; anything else → `errorConvertFailed`.

### F8 Extract text
- **Offline only, Arabic and English** (Q7, resolved). No audio or image ever leaves the phone.
- **Image** (OCR), decided by the S12 spike:
  - **Android:** **Tesseract** (Tesseract4Android) with the English and Arabic `tessdata_fast` data **bundled** in the APK (about 5.5 MB). Google ML Kit's on-device recognizer has no Arabic, so it can't be the engine.
  - **iOS:** **Apple Vision**, built in and offline. It reads Arabic on current iOS (checked on iOS 26); on an older iOS without Arabic it reads English only. Tesseract on iOS was dropped: the Flutter plugin hangs when recognition returns nothing, and copies its data into Documents, which the Files app now shows (F10).
- **Sound or video** (speech to text), decided by the S14 spike: **whisper.cpp** through `whisper_cpp_flutter_plus` (no FFmpeg, inference off the UI thread), multilingual **`base`** model (about 148 MB; `tiny` reads Arabic poorly, `small` is not in the pinned catalog). The model is downloaded **once**, from a pinned revision, resumable, with its **SHA-256 checked**; a file that fails the check is deleted and downloaded again. **Before the first download the app asks** ("Download the speech model? … about 148 MB. Wi-Fi is recommended."); saying no changes nothing. The sound is taken with the existing native extract (called, not changed), turned into 16 kHz mono in a background isolate, then read with the language detected automatically. Progress shows while downloading and while listening. A length limit (5 min, cut first) applies, like Remove music. The plugin's microphone permission is removed from the Android manifest: the app never records.
- Language: detected automatically, with an Arabic / English choice on the Text screen to run again if detection is wrong.
- On success, opens the Text screen (§5). No text found → `noTextFound` message, stay on the screen.

### F9 Save to gallery
As 001 F4 (album "Mute Video"), for video outputs only.

### F10 Save to Music
Saves the audio output to the phone's music storage. Android: the shared `Music/Mute Video` folder. iOS: the app's folder in the **Files** app (On My iPhone › Mute Video) (Q5, resolved). Errors: permission → `errorPermission`; else `errorSaveFailed`.

## 5. Text screen

- A full-screen **editable** text field with the extracted text.
- A **Copy** button in the app bar copies the current (edited) text to the clipboard and shows `copied`.
- Back returns to the file. The edited text is kept while the file stays the same, so opening Extract text again shows the last edit instead of running again (Q10).
- RTL when the text is Arabic (follow the text direction, not only the app language).

## 6. State (direction, details in the plan)

- `MediaAsset { path, kind: image | audio | video, duration?, range? }` replaces `VideoAsset` step by step.
- The screen state keeps separate references: **original** (the added file, the base for every cut), **input of the last operation** (shown by the original icon), **output** (latest result), plus the extracted text. A job never writes over any of them; it only produces a new file.
- Temp files: parts, outputs and conversions are deleted when replaced, on Clear (x), and at the next launch, as today (001 R4). The original copy lives until Clear or a new add.

## 7. Requirements

| # | Requirement |
|---|---|
| W1 | Empty state shows only the add widget under the app bar (§2.1). |
| W2 | The add sheet offers Image, Sound, Video and opens the right picker. |
| W3 | x clears the file and returns to Empty; disabled during a job. |
| W4 | Actions per type and after edits exactly as §3 and §3.1, including rule A1 (no operation twice). No More actions toggle. |
| W5 | The cut icon shows on video and sound previews, and always cuts from the first added file (§F3). |
| W6 | Every edited file shows the original icon; it opens the file before the last operation, view only, at the same position (§3.2). |
| W7 | Convert to audio (M4A) and Save to Music (Android Music folder, iOS Files app) work on both platforms. |
| W8 | Extract text works **offline** in Arabic and English for image, sound and video, and the Text screen allows edit and copy. |
| W9 | Remove music on video behaves exactly as before (§0): same output, same steps, same limits, same tests green. |
| W10 | Every new string in EN and AR. No failure leaves the screen busy (001 R2). |
| W11 | Previews handle a missing or broken file with a message, never an endless spinner. |

## 8. Acceptance checks

| # | Check | Result (2026-10-26) |
|---|---|---|
| AC1 | Launch: only the add widget under the app bar. Add → Image/Sound/Video opens the right picker; cancel changes nothing. | Widget tests; pickers per kind by repository tests. Manual: open |
| AC2 | Image: only Extract text shows. Extract → Text screen → edit → Copy → the clipboard has the edited text. | Widget tests (edit, Copy); OCR read back on iOS simulator (Vision) and Android emulator (Tesseract), EN + AR |
| AC3 | Sound: Remove music only and Extract text show. Remove music gives an audio file with the voices; Save to Music works. | iOS simulator e2e with the real model: voices kept (Whisper read the full sentence); Save to Music native test both platforms |
| AC4 | Video: x, cut icons on the preview; Remove sound, Remove music only, Convert to audio, Extract text under it. No More actions toggle. | Widget and state tests |
| AC5 | Video → cut 1:00–2:00 → Remove music only → the actions are Convert to audio, Extract text, Save to gallery (Remove music hidden, A1). Save gives the part with voices only. Remove sound → only Save to gallery. | State and cubit tests (A1, Save of a part); e2e Remove music on a video passes on iOS simulator. Manual: open |
| AC6 | Convert to audio → Save to Music → the file plays in the phone's music app (Android) / shows in Files › On My iPhone › Mute Video (iOS). | Native tests: Android MediaStore insert, iOS Files folder. Seen in the music app / Files: open |
| AC7 | Every edited file shows the original icon; it opens the original at the same position; back returns unchanged. | Widget tests (icon, position hand-off). Manual: open |
| AC8 | x on any state returns to Empty and leaves no temp files of that file. | Cubit tests; native cleanup 6/6 on Android emulator |
| AC9 | 003 scenarios A–D and 002 AC1–AC5 still pass; DSP reference tests green (VIP rule). | DSP reference tests green; VIP files unchanged except the approved iOS fixes; Remove music video e2e passes on iOS simulator; 003 cut tests 5/5 on Android |
| AC10 | Arabic UI and Arabic text in the Text screen are RTL and readable. | Widget tests (RTL text, LTR time); Arabic OCR and speech read on both platforms. Manual: open |

## 9. Open questions

| # | Question | Default until answered |
|---|---|---|
| Q1 | What does the original icon open? | **Resolved:** the file before the last operation |
| Q2 | Audio features wanted? | **Resolved:** yes: MP3, Save to Music, sound files, extract text |
| Q3 | Same playback position on the original screen? | **Resolved:** yes |
| Q4 | MP3 or M4A, packages or native? | **Decided (delegated):** M4A (AAC) with native code, no new package (F7) |
| Q5 | Save to Music on iOS? | **Resolved:** the Files app (On My iPhone › Mute Video) |
| Q6 | Text from images: languages and engine? | **Resolved:** Arabic + English, offline; Tesseract on Android, Apple Vision on iOS (S12 spike) |
| Q7 | Offline or online, which languages? | **Resolved:** everything offline, Arabic and English (images, sound, video). Whisper on device |
| Q8 | After an edit, do the next actions run on the output or on the part before the edit? | **Resolved:** the current output |
| Q9 | After an edit, should Remove sound still be offered? | **Resolved:** after Remove sound only Save to gallery; after Remove music no (A1); after only a cut see Q12 |
| Q10 | Extract text again on the same file: show the last edited text, or run again? | Show the last edit, with a "Run again" option |
| Q12 | After **only a cut** (nothing else run yet), are all four actions offered again (Remove sound, Remove music only, Convert to audio, Extract text) plus Save to gallery? | **Resolved:** yes |
| Q13 | Video actions: 3 or 4? | **Resolved:** 4 (Remove sound, Remove music only, Convert to audio, Extract text) |
| Q14 | Which files have the cut icon? | **Resolved:** every video and sound, input or output; it always cuts the first added file |
| Q15 | Save to Music for a sound with the music removed? | **Resolved:** yes |
| Q16 | Text screen: Copy only, or also Share / save as file? | **Resolved:** edit, then Copy |
| Q17 | Keep 005's More actions toggle? | **Resolved:** removed |
| Q11 | Length limit for sound files on Remove music, and can sound be cut? | **Resolved:** sound has the cut icon; the same 5 min limit asks the user to cut first |
