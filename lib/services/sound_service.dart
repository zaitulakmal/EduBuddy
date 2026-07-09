import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide audio: calm looping background music + soft sound effects.
///
/// All tracks are bundled in assets/audio/ (synthesized in-house, royalty
/// free). Music and effects can be toggled independently from the Profile
/// screen; both preferences persist across launches.
class SoundService with WidgetsBindingObserver {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const _kMusicPref = 'sound_music_enabled';
  static const _kSfxPref = 'sound_sfx_enabled';

  static const _musicVolume = 0.35;

  final AudioPlayer _music = AudioPlayer(playerId: 'bgm');
  // Small pool so rapid taps/flips don't cut each other off.
  final List<AudioPlayer> _sfxPool =
      List.generate(3, (i) => AudioPlayer(playerId: 'sfx$i'));
  int _sfxIndex = 0;

  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  bool _initialized = false;
  String? _currentTrack;

  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    _musicEnabled = prefs.getBool(_kMusicPref) ?? true;
    _sfxEnabled = prefs.getBool(_kSfxPref) ?? true;
    await _music.setReleaseMode(ReleaseMode.loop);
    await _music.setVolume(_musicVolume);
    for (final p in _sfxPool) {
      await p.setReleaseMode(ReleaseMode.stop);
    }
    // Ambient category: respects the ring/silent switch and mixes politely
    // with other apps' audio (ambient implies mixWithOthers on iOS).
    await AudioPlayer.global.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
        options: const {},
      ),
      android: const AudioContextAndroid(
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      ),
    ));
    WidgetsBinding.instance.addObserver(this);
  }

  // ── Background music ────────────────────────────────────────────────────────

  /// Starts (or switches to) a looping music track: 'calm' or 'playful'.
  Future<void> playMusic([String track = 'calm']) async {
    await init();
    _currentTrack = track;
    if (!_musicEnabled) return;
    await _music.stop();
    await _music.play(AssetSource('audio/bgm_$track.m4a'));
  }

  Future<void> stopMusic() async {
    _currentTrack = null;
    await _music.stop();
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMusicPref, enabled);
    if (!enabled) {
      await _music.pause();
    } else if (_currentTrack != null) {
      await playMusic(_currentTrack!);
    } else {
      await playMusic();
    }
  }

  Future<void> setSfxEnabled(bool enabled) async {
    _sfxEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSfxPref, enabled);
  }

  // ── Sound effects ───────────────────────────────────────────────────────────

  Future<void> _sfx(String name, double volume) async {
    if (!_sfxEnabled) return;
    await init();
    final p = _sfxPool[_sfxIndex];
    _sfxIndex = (_sfxIndex + 1) % _sfxPool.length;
    try {
      await p.stop();
      await p.setVolume(volume);
      await p.play(AssetSource('audio/sfx_$name.m4a'));
    } catch (_) {
      // Never let a sound glitch break gameplay.
    }
  }

  Future<void> tap() => _sfx('tap', 0.35);
  Future<void> correct() => _sfx('correct', 0.7);
  Future<void> wrong() => _sfx('wrong', 0.55);
  Future<void> flip() => _sfx('flip', 0.5);
  Future<void> match() => _sfx('match', 0.7);
  Future<void> star() => _sfx('star', 0.6);
  Future<void> win() => _sfx('win', 0.75);
  Future<void> complete() => _sfx('complete', 0.7);

  // ── Lifecycle: pause music when app goes to background ─────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _music.pause();
    } else if (state == AppLifecycleState.resumed &&
        _musicEnabled &&
        _currentTrack != null) {
      _music.resume();
    }
  }
}
