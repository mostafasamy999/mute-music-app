# Mute Video: Specs

Spec-driven development (SDD) specs for `mute-music-app`. The same workflow as `~/work/specs-projects` (branch `mute-music-app`): `spec.md` is the source of truth, unresolved rules become open questions, bump the version on every spec change, commit as `spec(NNN): …`.

**Snapshot:** 2026-10-26, commit `3e8fde4` (`feature/004-app-language`, which also holds 005). `flutter test`: 94 pass. `flutter analyze`: clean.

## Index

| ID | Feature | Status | Still open |
|---|---|---|---|
| [001](001-mute-video/spec.md) | Mute Video: remove sound or music, save | Implemented (v1.2) | Q1–Q4, Q6–Q8; WP5 native correctness, WP6 model hash, WP7 download UX, WP9 housekeeping |
| [002](002-music-removal-isolate/spec.md) | Remove music in a background isolate, with step progress | Implemented | T6 device check |
| [003](003-choose-part/spec.md) | Choose a part (cut without re-encoding) | Implemented (v1.1) | P1–P4 confirm; T6 device check (scenarios A–C, 20-min clip, Arabic) |
| [004](004-app-language/spec.md) | In-app language (Phone / English / العربية) | Implemented | T5 device check |
| [005](005-fewer-actions/spec.md) | Fewer actions on the main screen | Implemented | T3 device check |
| [006](006-media-workspace/spec.md) | Media workspace: image, sound and video; Convert to audio (M4A); Extract text; Save to Music; View original | Draft v2.4. [Plan](006-media-workspace/implementation_plan.md): S1–S10 done | Q10 (default used); nothing blocked |

**Next:** [ROADMAP.md](ROADMAP.md) (new features, in order) and [001 NEXT.md](001-mute-video/NEXT.md) (where to pick up).

## Branches

`main` is still at `6fd1532` (v1.0). Everything from 001 WP1 to 005 is on `feature/004-app-language` and is not merged yet.
