# Mute Video: Roadmap

**Version:** v0.1 (proposal)  
**Status:** Draft. Waiting on the business answers B1–B5 (§4). Order and scope may change once they arrive.  
**Last updated:** 2026-10-26

The current app (001–005) is a free, offline, single-screen tool: pick → (choose a part) → remove sound or music → save. This roadmap proposes what comes next. Each feature gets its own `NNN-name/spec.md` when it is approved, following the README workflow.

---

## 1. Phase 0: Release the current app (before any new feature)

Nothing new is visible to users here, but these block a store release.

| # | Work | From | Blocked on |
|---|---|---|---|
| R0.1 | Merge `feature/004-app-language` into `main` | — | Device checks below |
| R0.2 | Device checks: 002 T6, 003 T6, 004 T5, 005 T3, 001 T3.3 (memory on the lowest device) | Existing tasks | A low-end Android device and an iPhone |
| R0.3 | One app name everywhere (launcher, `appTitle`, album) | 001 Q6, T9.1 | B1 |
| R0.4 | Model hosting, license and SHA-256 check | 001 Q3, WP6 | Product / legal |
| R0.5 | Native correctness with test clips (HE-AAC, trimmed, portrait, 48 kHz) | 001 WP5 | — |
| R0.6 | README, pubspec description, pin `intl`, replace the discontinued package | 001 WP9 | — |
| R0.7 | Store listing, privacy policy ("no data leaves the device"), screenshots EN/AR | New | B1 |

## 2. Proposed features

Ordered by value for the effort. **S/M/L** is a rough size (S ≈ 1–2 days, M ≈ 1 week, L ≈ 2+ weeks).

| ID | Feature | Why | Size | Depends on |
|---|---|---|---|---|
| **006** | **Share the result** (system share sheet) next to Save, and choose what happens after save (Q7) | Most users want to post the video, not just keep it. Cheap with `share_plus` | S | Q7 |
| **007** | **Cancel** Remove music and the model download (001 Q2, WP7 T7.2), plus ask before downloading on mobile data (Q4) | Remove music is slow; today the only way out is killing the app | M | Q2, Q4 |
| **008** | **Keep music, remove voices** (karaoke / instrumental). The instrumental is `original − vocals`, so it reuses the same model and pipeline with no new download | Second most asked-for use of a vocal separator; almost free on top of 002 | S–M | — |
| **009** | **Replace the audio**: put the user's own music (from files) under the cleaned video, with a volume mix for the kept voices | Turns "remove" into "fix my video's music" (e.g. copyright-muted clips) | M–L | 008 optional |
| **010** | **Export audio only**: save the voices (or the music) as an M4A | Podcasters and editors; reuses the mux step without video | S | — |
| **011** | **Recent results** list (last N outputs, re-share or save again), cleared on demand | Today a result is lost on the next pick | M | 006 |
| **012** | **Faster / better model option**: a smaller model for low-end phones, or a higher-quality one on capable devices | Speed is the main complaint risk on mid-range phones (001 Q2) | L | R0.4, device benchmarks |
| **013** | **Longer videos for Remove music**: stream chunks to and from disk, lifting the 5 min limit (001 WP3 step 2) | Removes the "choose a part first" step for long clips | L | 001 T3.3 numbers |
| **014** | **Monetization** (only if B2 says so): e.g. free with a daily limit on Remove music + a one-time unlock, or ads on save | Revenue. Changes 001 §2 out of scope (no ads/purchases/analytics) | M | B2, B3 |

Not proposed for now: in-app recording, crop/filters/full editing, batch processing, a backend or accounts. They fight the "simple, offline, private" position and cost much more.

## 3. Suggested order

1. **Phase 0** (R0.1–R0.7), so there is a shippable v1.0 in the stores.
2. **v1.1:** 006 Share + 007 Cancel / mobile data. Small, and they fix the two biggest UX gaps.
3. **v1.2:** 008 Keep music + 010 Export audio. Both reuse the 002 pipeline.
4. **v1.3:** 009 Replace the audio and 011 Recent results.
5. **Later, data-driven:** 012 / 013 once device numbers exist; 014 once B2 is decided.

## 4. Business questions (answer before writing specs 006+)

| # | Question | Why it matters |
|---|---|---|
| B1 | What is the app's name and target user (creators re-posting clips, people removing copyrighted music, podcasters…)? | Name (Q6), store listing, which of 008–010 comes first |
| B2 | How does the app make money: free, paid, freemium, ads? | Decides 014 and whether analytics are allowed (001 §2 says no) |
| B3 | Must everything stay on the device (no backend, no accounts)? | Keeps 001's privacy promise; rules out cloud processing for long videos |
| B4 | Which platforms and lowest devices for launch (Android only first? min RAM)? | 001 Q1, the 5 min limit, 012/013 priority |
| B5 | Is there a deadline or a first-release date? | How much of §3 fits before launch |

When answers arrive: record them here, then write each approved feature's `spec.md` (with an issues `review.md` before coding, as in 004/005), and add it to the README index.
