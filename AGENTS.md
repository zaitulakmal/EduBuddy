# EduBuddy — project contract

Flutter learning app for kids: Home, Spelling, Quizzes, Stories, Draw/Lukis, Profile.
SQLite via sqflite (`lib/db/database_helper.dart`), state via provider. App is portrait-only.

## Draw tab ("Lukis") — added 2026-09-21
A native Flutter port of SketchStep (https://sketchstep.vercel.app, repo zaitulakmal/sketchstep).
Decisions confirmed with Zaitul:
- Rewritten in Flutter (not a WebView). Code lives in `lib/sketch/`.
- New bottom tab "Draw"/"Lukis" between Stories and Profile (`lib/screens/main_nav.dart`),
  six tabs in all. The 1.0.4 redesign replaced the emoji labels with `Icons.*_rounded`, so the
  tab uses `Icons.draw_rounded` rather than the pencil emoji the port shipped with.
- Tab has an EN/BM switch. It follows and changes the app-wide language (AppProvider
  `selectedLanguage`), so there is one language setting (`sketch_lang.dart`).
- Saving images to Photos uses `share_plus` (system share sheet).
- SQLite v10 adds `sketch_drawings`, `sketch_drafts`, `sketch_progress`. The port was written
  against v6, but the 1.0.5 release line had already claimed 6-9 (v6 quiz migration, sticker
  table, `buddy_accessory`, v9), so the tables migrate at 10.
  Existing tables untouched. `SketchStore` also runs CREATE TABLE IF NOT EXISTS on first use,
  in case a device's DB already reports a newer version without them. PNGs live in `<documents>/sketches/`.

### Lessons are generated, do not edit the JSON
`assets/data/sketch_lessons.json` is exported from SketchStep, which is the single source of truth
for lesson content. To change or add lessons, edit them in SketchStep, then in that repo run:
`PATH=$HOME/.local/bin:$PATH npm run export:edubuddy` (writes ../EduBuddy/assets/data/sketch_lessons.json).

### Files
- `sketch_data.dart` — loads the JSON into lessons/steps/polylines (400×400 space).
- `pencil.dart` — grain-textured pencil, stroke (de)serialisation, PNG export.
- `sketch_score.dart` — per-step accuracy and stars (same rules as the web app).
- `sketch_store.dart` — drawings, drafts (autosaved after every stroke), stars.
- `sketch_tab_screen.dart`, `sketch_lesson_screen.dart`, `sketch_gallery_screen.dart` — UI.

### Tests
- `flutter test` — unit tests incl. `test/sketch_test.dart`.
- On a simulator: `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/sketch_flow_test.dart -d <device>`
  (set SCREENSHOT_DIR to keep screenshots).

## Open questions
