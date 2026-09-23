# EduBuddy — project contract

Flutter learning app for kids: Home, Spelling, Quizzes, Stories, Profile.
Drawing lessons (Draw/Lukis) live under the Drawing Studio card in Home, not in the nav bar.
SQLite via sqflite (`lib/db/database_helper.dart`), state via provider. App is portrait-only.

## Draw tab ("Lukis") — added 2026-09-21
A native Flutter port of SketchStep (https://sketchstep.vercel.app, repo zaitulakmal/sketchstep).
Decisions confirmed with Zaitul:
- Rewritten in Flutter (not a WebView). Code lives in `lib/sketch/`.
- No bottom tab. Zaitul changed this on 2026-09-23: the lessons replace the free-draw
  Drawing Studio rather than sitting beside it. The "Drawing Studio"/"Studio Lukisan" card in
  Home's creative activities row, and the `drawing` stop in the journey, both push
  `SketchTabScreen`. The bottom nav stays at five tabs.
- `lib/screens/drawing/drawing_studio_screen.dart` (the free-draw canvas) is therefore
  unreachable. It is kept in the tree, not deleted, in case the free canvas comes back.
- `SketchTabScreen` was written as a tab, so it carries no AppBar. It now renders
  `HeaderBackButton` in its gradient header, which draws nothing when there is no route to
  pop — the screen works both ways.
- Tab has an EN/BM switch. It follows and changes the app-wide language (AppProvider
  `selectedLanguage`), so there is one language setting (`sketch_lang.dart`).
- Saving images to Photos uses `share_plus` (system share sheet).
- SQLite v10 adds `sketch_drawings`, `sketch_drafts`, `sketch_progress`. The port was written
  against v6, but the 1.0.5 release line had already claimed 6-9 (v6 quiz migration, sticker
  table, `buddy_accessory`, v9), so the tables migrate at 10.
  Existing tables untouched. `SketchStore` also runs CREATE TABLE IF NOT EXISTS on first use,
  in case a device's DB already reports a newer version without them. PNGs live in `<documents>/sketches/`.

### Styling follows the app, not SketchStep
The port arrived in SketchStep's dark violet. On 2026-09-23 it was pulled onto EduBuddy's
palette: `themeSkin.background` and `themeSkin.headerGradient` (so the Draw screens change with
the skin the child buys in the star shop), `AppColors` for every other surface, `Icons.*_rounded`
in place of the ✏️/🖼️ emoji. The lesson screen is light now, and the paper is separated from the
background by a `divider` border plus a soft shadow instead of a dark surround.

Two colours are deliberately NOT themed, because they are functional rather than decorative:
- The HB / 2B / 6B leads in `sketch_widgets.dart` and the dock — they show real graphite darkness.
- The guide line (`sketchViolet` in `sketch_painters.dart`) stays violet, because the lesson copy
  says "Trace the violet line" / "Surih garisan ungu". Only its shade moved to `AppColors.punchViolet`.

Watch the light-on-light traps when editing these screens: the widgets were written for a dark
surround, so `paperColor` was a *foreground* colour. Selected tool buttons and the EN/BM pill both
had to be re-inked to `AppColors.onPrimary` on `primarySoft` to stay readable.

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
  (set SCREENSHOT_DIR to keep screenshots). The test reaches the lessons by scrolling Home to
  the Drawing Studio card, so it breaks if that card is renamed.

## Open questions
