import 'package:flutter/foundation.dart';
import '../providers/app_provider.dart';

/// Strings for the Draw tab. The language follows EduBuddy's app-wide EN/BM
/// setting (AppProvider); the switch in the tab changes that same setting.
class SketchLang extends ValueNotifier<String> {
  SketchLang._() : super('en');

  static final SketchLang instance = SketchLang._();
  AppProvider? _app;

  void attach(AppProvider app) {
    if (identical(_app, app)) return;
    _app?.removeListener(_sync);
    _app = app..addListener(_sync);
    _sync();
  }

  void _sync() => value = _app!.selectedLanguage == 'ms' ? 'ms' : 'en';

  void set(String lang) {
    final app = _app;
    if (app == null) {
      value = lang;
    } else if (app.selectedLanguage != lang) {
      app.toggleLanguage();
    }
  }

  String t(String key) => (_strings[key] ?? const {})[value] ?? key;
}

const _strings = <String, Map<String, String>>{
  'tab': {'en': 'Draw', 'ms': 'Lukis'},
  'heading': {'en': 'Draw it one line at a time', 'ms': 'Lukis satu garisan demi satu garisan'},
  'myDrawings': {'en': 'My drawings', 'ms': 'Lukisan saya'},
  'continue': {'en': 'Continue', 'ms': 'Sambung'},
  'skill': {'en': 'Skill', 'ms': 'Skill'},
  'subject': {'en': 'Subject', 'ms': 'Subjek'},
  'practice': {'en': 'Practice', 'ms': 'Latihan'},
  'steps': {'en': 'steps', 'ms': 'langkah'},
  'min': {'en': 'min', 'ms': 'min'},
  'step': {'en': 'Step', 'ms': 'Langkah'},
  'of': {'en': 'of', 'ms': 'daripada'},
  'next': {'en': 'Next step', 'ms': 'Langkah seterusnya'},
  'finish': {'en': 'Finish drawing', 'ms': 'Siapkan lukisan'},
  'undo': {'en': 'Undo', 'ms': 'Buat asal'},
  'eraser': {'en': 'Eraser', 'ms': 'Pemadam'},
  'guide': {'en': 'Guide', 'ms': 'Panduan'},
  'traceHint': {'en': 'Trace the violet line', 'ms': 'Surih garisan ungu'},
  'shadeHint': {'en': 'Shade inside the hatched area', 'ms': 'Lorek di dalam kawasan berjalur'},
  'onTarget': {'en': 'on target', 'ms': 'tepat'},
  'emptyStep': {'en': 'Draw over the guide first, then tap next.', 'ms': 'Lukis atas panduan dulu, kemudian tekan seterusnya.'},
  'skip': {'en': 'Skip this step', 'ms': 'Langkau langkah ini'},
  'doneTitle': {'en': 'Drawing finished', 'ms': 'Lukisan siap'},
  'accuracy': {'en': 'Accuracy', 'ms': 'Ketepatan'},
  'savedNote': {'en': 'Saved to My drawings.', 'ms': 'Disimpan dalam Lukisan saya.'},
  'saveImage': {'en': 'Save image', 'ms': 'Simpan gambar'},
  'drawAgain': {'en': 'Draw it again', 'ms': 'Lukis semula'},
  'back': {'en': 'Back to lessons', 'ms': 'Kembali ke pelajaran'},
  'unfinished': {'en': 'Not finished yet', 'ms': 'Belum siap'},
  'finished': {'en': 'Finished', 'ms': 'Sudah siap'},
  'emptyTitle': {'en': 'No drawings yet', 'ms': 'Belum ada lukisan'},
  'emptyBody': {
    'en': 'Finished drawings are kept here. Your drawing saves as you go, so you can stop and continue any time.',
    'ms': 'Lukisan yang siap disimpan di sini. Lukisan anda disimpan secara automatik, jadi boleh berhenti dan sambung bila-bila masa.',
  },
  'delete': {'en': 'Delete', 'ms': 'Padam'},
  'deleteQ': {'en': 'Delete this drawing? This cannot be undone.', 'ms': 'Padam lukisan ini? Tindakan ini tidak boleh dibuat asal.'},
  'cancel': {'en': 'Cancel', 'ms': 'Batal'},
};
