import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../../models/badge_model.dart';
import '../../models/progression.dart';
import '../../models/reader_content.dart';
import '../../providers/app_provider.dart';
import '../../services/sound_service.dart';
import '../../widgets/buddy_mascot.dart';
import '../../widgets/reader_kit.dart';
import '../../widgets/reader_pictures.dart';
import '../../widgets/reader_scenery.dart';
import '../../widgets/reward_overlay.dart';
import 'sticker_book_screen.dart';

/// Everything one question needs from the run around it.
class ReaderStep {
  final int chapter;
  final int slot; // 0-based position within the chapter
  final bool ms;
  final bool locked; // an overlay is up; ignore input

  /// A correct move (a piece placed). Sound + Buddy hop.
  final VoidCallback onRight;

  /// A mistake. Costs a heart; may end the chapter.
  final VoidCallback onWrong;

  /// The question is finished. The run celebrates and moves on by itself.
  final VoidCallback onSolved;

  /// Puts a line in Buddy's speech bubble.
  final void Function(String text) say;

  const ReaderStep({
    required this.chapter,
    required this.slot,
    required this.ms,
    required this.locked,
    required this.onRight,
    required this.onWrong,
    required this.onSolved,
    required this.say,
  });

  String t(String en, String msText) => ms ? msText : en;
}

/// The endless chapter loop shared by the Buddy Reader games.
///
/// Chapters of [readerChapterLength] questions, three hearts each, a sticker
/// chest at the end, a new scenery world per chapter, and no menu between
/// questions. The game itself only supplies [buildStep].
class ReaderRun extends StatefulWidget {
  final String gameKey;

  /// What one question is called on the chapter card, e.g. ('words', 'perkataan').
  final (String, String) unit;

  /// Builds the question for a chapter slot. Must be keyed by the caller-given
  /// key so a new question starts with fresh state.
  final Widget Function(BuildContext context, Key key, ReaderStep step) buildStep;

  const ReaderRun({
    super.key,
    required this.gameKey,
    required this.unit,
    required this.buildStep,
  });

  @override
  State<ReaderRun> createState() => _ReaderRunState();
}

enum _Stage { intro, play, chest, gameOver }

class _ReaderRunState extends State<ReaderRun> {
  late final AppProvider _db;
  late final ConfettiController _confetti;

  bool _loading = true;
  _Stage _stage = _Stage.intro;
  int _chapter = 1;
  int _slot = 0;
  int _lives = readerLives;
  int _combo = 0;
  int _attempt = 0; // bumps on every chapter start so questions rebuild fresh
  bool _stepHadMistake = false;

  int _buddyBeat = 0;
  BuddyAnim _buddyAnim = BuddyAnim.wave;
  String? _bubble;
  Timer? _bubbleTimer;
  Timer? _advanceTimer;

  bool _chestOpen = false;
  bool _openingChest = false;
  ReaderSticker? _chestSticker;
  int _chestStars = 0;
  List<BadgeModel> _chestBadges = const [];

  bool get _ms => _db.selectedLanguage == 'ms';
  String _t(String en, String ms) => _ms ? ms : en;

  @override
  void initState() {
    super.initState();
    _db = context.read<AppProvider>();
    _confetti = ConfettiController(duration: const Duration(milliseconds: 1500));
    _restore();
  }

  Future<void> _restore() async {
    var chapter = 1;
    try {
      chapter = (await _db.gameStats(widget.gameKey)).resumeLevel.clamp(1, 9999);
    } catch (_) {
      // Storage unavailable — start at chapter 1 rather than refuse to open.
    }
    if (!mounted) return;
    setState(() {
      _chapter = chapter;
      _loading = false;
    });
    _startChapter();
  }

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    _advanceTimer?.cancel();
    _confetti.dispose();
    // Leaving mid-chapter resumes that chapter; an opened chest already saved
    // the next one.
    if (!_chestOpen) {
      _db.saveGameCheckpoint(widget.gameKey, level: _chapter).catchError((_) {});
    }
    super.dispose();
  }

  // ── Buddy ─────────────────────────────────────────────────────────────────

  void _say(String text, {Duration hold = const Duration(milliseconds: 2200)}) {
    if (!mounted) return;
    _bubbleTimer?.cancel();
    setState(() => _bubble = text);
    _bubbleTimer = Timer(hold, () {
      if (mounted) setState(() => _bubble = null);
    });
  }

  void _react(BuddyAnim anim) => setState(() {
        _buddyAnim = anim;
        _buddyBeat++;
      });

  // ── Flow ──────────────────────────────────────────────────────────────────

  void _startChapter() {
    _advanceTimer?.cancel();
    _bubbleTimer?.cancel();
    setState(() {
      _bubble = null;
      _stage = _Stage.intro;
      _slot = 0;
      _lives = readerLives;
      _stepHadMistake = false;
      _chestOpen = false;
      _chestSticker = null;
      _chestBadges = const [];
      _chestStars = 0;
      _attempt++;
    });
    SoundService.instance.star();
    _react(BuddyAnim.wave);
    _db.saveGameCheckpoint(widget.gameKey, level: _chapter).catchError((_) {});
    _advanceTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _stage = _Stage.play);
    });
  }

  void _onRight() {
    SoundService.instance.star();
    _react(BuddyAnim.hop);
  }

  void _onWrong() {
    if (_stage != _Stage.play) return;
    SoundService.instance.wrong();
    _react(BuddyAnim.think);
    setState(() {
      _lives--;
      _combo = 0;
      _stepHadMistake = true;
    });
    if (_lives <= 0) {
      _advanceTimer?.cancel();
      setState(() => _stage = _Stage.gameOver);
      return;
    }
    _say(_t('Oops! Try again.', 'Alamak! Cuba lagi.'));
  }

  void _onSolved() {
    if (!mounted || _stage != _Stage.play) return;
    setState(() {
      if (!_stepHadMistake) _combo++;
    });
    _confetti.play();
    SoundService.instance.correct();
    _react(BuddyAnim.cheer);
    _say(_cheer());
    final slot = _slot;
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted || _stage != _Stage.play || _slot != slot) return;
      if (_slot + 1 < readerChapterLength) {
        setState(() {
          _slot++;
          _stepHadMistake = false;
        });
      } else {
        _openChestStage();
      }
    });
  }

  String _cheer() {
    if (_combo >= 5) return _t('On fire!', 'Hebatnya!');
    if (_combo >= 3) return _t('Super star!', 'Bintang super!');
    const en = ['Great job!', 'Yay! Next one!', 'You did it!'];
    const ms = ['Bagus!', 'Yeay! Seterusnya!', 'Awak berjaya!'];
    final i = Random().nextInt(en.length);
    return _t(en[i], ms[i]);
  }

  void _openChestStage() {
    setState(() {
      _stage = _Stage.chest;
      _chestOpen = false;
    });
    SoundService.instance.complete();
    _say(_t('Tap the chest!', 'Tekan peti hadiah!'), hold: const Duration(seconds: 4));
  }

  Future<void> _openChest() async {
    if (_chestOpen || _openingChest) return;
    _openingChest = true;
    final chapter = _chapter;
    final lives = _lives;
    final sticker = readerStickerFor(chapter, _db.collectedStickers);

    GameReward? reward;
    var badges = <BadgeModel>[];
    try {
      reward = await _db.recordGameLevel(
        gameKey: widget.gameKey,
        level: chapter,
        rating: lives,
        perfect: lives >= readerLives,
      );
      badges = List.of(_db.newlyEarnedBadges);
      if (sticker != null) await _db.collectSticker(sticker.key);
      await _db.saveGameCheckpoint(widget.gameKey, level: chapter + 1);
    } catch (_) {
      // A storage failure must not stop the celebration.
    }
    _openingChest = false;
    if (!mounted) return;
    setState(() {
      _chestOpen = true;
      _chestSticker = sticker;
      _chestStars = reward?.total ?? 0;
      _chestBadges = badges;
    });
    _confetti.play();
    SoundService.instance.win();
    _react(BuddyAnim.cheer);
  }

  Future<void> _nextChapter() async {
    if (_chestBadges.isNotEmpty) {
      await showRewardSheet(
        context,
        title: _t('New badge!', 'Lencana baharu!'),
        badges: _chestBadges,
        buddy: buddyVariantFromId(_db.userAvatar),
        hat: _db.buddyHat,
        accessory: _db.buddyAccessory,
      );
      if (!mounted) return;
    }
    setState(() => _chapter++);
    _startChapter();
  }

  void _retryChapter() {
    SoundService.instance.tap();
    setState(() => _combo = 0);
    _startChapter();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: kReaderSkyBottom,
      body: Stack(
        children: [
          Positioned.fill(child: ReaderScenery(theme: readerSceneFor(_chapter))),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      if (_stage != _Stage.intro)
                        Positioned.fill(
                          top: 64,
                          child: widget.buildStep(
                            context,
                            ValueKey(
                                '${widget.gameKey}-$_attempt-$_chapter-$_slot-${_ms ? 'ms' : 'en'}'),
                            ReaderStep(
                              chapter: _chapter,
                              slot: _slot,
                              ms: _ms,
                              locked: _stage != _Stage.play,
                              onRight: _onRight,
                              onWrong: _onWrong,
                              onSolved: _onSolved,
                              say: _say,
                            ),
                          ),
                        ),
                      _buildHud(provider),
                      _buildBuddy(provider),
                      if (_stage == _Stage.intro) _buildIntro(),
                      if (_stage == _Stage.chest) _buildChest(),
                      if (_stage == _Stage.gameOver) _buildGameOver(),
                    ],
                  ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 30,
              colors: kReaderLetterColors,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHud(AppProvider provider) {
    return Positioned(
      top: 8,
      left: 12,
      right: 12,
      child: Row(
        children: [
          ReaderPaperButton(
            semanticLabel: _t('Back', 'Kembali'),
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back_rounded, color: kReaderInk, size: 26),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ReaderPaperButton(
              semanticLabel: _t(
                  'Chapter $_chapter, question ${_slot + 1} of $readerChapterLength, $_lives hearts',
                  'Bab $_chapter, soalan ${_slot + 1} daripada $readerChapterLength, $_lives nyawa'),
              child: Row(
                children: [
                  for (var i = 0; i < readerLives; i++)
                    AnimatedScale(
                      scale: i < _lives ? 1 : 0.8,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.favorite_rounded,
                        key: ValueKey('reader-heart-$i-${i < _lives ? 'full' : 'empty'}'),
                        size: 20,
                        color: i < _lives ? kReaderHeart : const Color(0xFFD9D2C3),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Expanded(child: _ChapterTrack(slot: _slot, finished: _stage == _Stage.chest)),
                  const SizedBox(width: 4),
                  const ReaderIconArt(ReaderIcon.chest, size: 26),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          ReaderPaperButton(
            semanticLabel: _t('Sticker Book', 'Buku Sticker'),
            onTap: () {
              SoundService.instance.tap();
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const StickerBookScreen()));
            },
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const ReaderIconArt(ReaderIcon.stickerBook, size: 24),
              const SizedBox(width: 4),
              Text('${provider.collectedStickers.length}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: kReaderInk,
                      fontFeatures: [FontFeature.tabularFigures()])),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildBuddy(AppProvider provider) {
    return Positioned(
      left: 8,
      bottom: 8,
      right: 16,
      child: IgnorePointer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            BuddyMascot(
              key: ValueKey(_buddyBeat),
              size: 88,
              variant: buddyVariantFromId(provider.userAvatar),
              hat: provider.buddyHat,
              accessory: provider.buddyAccessory,
              animation: _buddyAnim,
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 52),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_combo >= 2)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _ComboChip(combo: _combo),
                      ),
                    AnimatedOpacity(
                      opacity: _bubble == null ? 0 : 1,
                      duration: const Duration(milliseconds: 250),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: kReaderPaper,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(color: Color(0x263D3526), offset: Offset(0, 4))
                          ],
                        ),
                        child: Text(_bubble ?? '',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800, color: kReaderInk)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro() {
    final (unitEn, unitMs) = widget.unit;
    return Positioned.fill(
      child: AbsorbPointer(
        child: Center(
          child: TweenAnimationBuilder<double>(
            key: ValueKey('intro-$_attempt'),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 22),
              decoration: BoxDecoration(
                color: const Color(0xFF7C5CFF),
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [BoxShadow(color: Color(0xFF5A3FD6), offset: Offset(0, 8))],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_t('Chapter', 'Bab'),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 20, fontWeight: FontWeight.w800)),
                Text('$_chapter',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 64, fontWeight: FontWeight.w900, height: 1)),
                const SizedBox(height: 6),
                Text(
                    _t('$readerChapterLength $unitEn → 1 sticker!',
                        '$readerChapterLength $unitMs → 1 sticker!'),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChest() {
    final sticker = _chestSticker;
    return Positioned.fill(
      child: Container(
        color: const Color(0x993D3526),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: !_chestOpen
            ? Semantics(
                button: true,
                label: _t('Open the chest', 'Buka peti hadiah'),
                child: GestureDetector(
                  key: const ValueKey('reader-chest'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _openChest,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_t('Chapter $_chapter done!', 'Bab $_chapter selesai!'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 18),
                    const _ShakingChest(),
                    const SizedBox(height: 12),
                    Text(_t('Tap to open!', 'Tekan untuk buka!'),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  ]),
                ),
              )
            : TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  decoration:
                      BoxDecoration(color: kReaderPaper, borderRadius: BorderRadius.circular(32)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      sticker != null
                          ? _t('New sticker!', 'Sticker baharu!')
                          : _t('Sticker Book complete!', 'Buku Sticker lengkap!'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w900, color: kReaderInk),
                    ),
                    const SizedBox(height: 8),
                    // Stickers keep their emoji art; a full book shows the open chest.
                    if (sticker != null)
                      Text(sticker.emoji, style: const TextStyle(fontSize: 96))
                    else
                      const ReaderIconArt(ReaderIcon.chestOpen, size: 110),
                    if (sticker != null)
                      Text(_ms ? sticker.nameMs : sticker.name,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900, color: kReaderCoral)),
                    const SizedBox(height: 6),
                    Text(
                      _t('${_db.collectedStickers.length} / ${readerStickers.length} in your book',
                          '${_db.collectedStickers.length} / ${readerStickers.length} dalam buku'),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: kReaderMuted),
                    ),
                    if (_chestStars > 0) ...[
                      const SizedBox(height: 10),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('+$_chestStars',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: kReaderButterEdge)),
                        const Icon(Icons.star_rounded, color: kReaderButter, size: 28),
                      ]),
                    ],
                    const SizedBox(height: 18),
                    ReaderBigButton(
                        label: _t('Next chapter', 'Bab seterusnya'), onTap: _nextChapter),
                  ]),
                ),
              ),
      ),
    );
  }

  Widget _buildGameOver() {
    return Positioned.fill(
      child: Container(
        color: const Color(0x993D3526),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: kReaderPaper, borderRadius: BorderRadius.circular(32)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const ReaderIconArt(ReaderIcon.brokenHeart, size: 72),
            Text(_t('Out of hearts!', 'Nyawa habis!'),
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w900, color: kReaderInk)),
            const SizedBox(height: 4),
            Text(_t('Try chapter $_chapter again?', 'Cuba bab $_chapter lagi?'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: kReaderMuted)),
            const SizedBox(height: 18),
            ReaderBigButton(label: _t('Try again', 'Cuba lagi'), onTap: _retryChapter),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.maybePop(context),
              child: Text(_t('Exit', 'Keluar'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: kReaderMuted)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── HUD pieces ───────────────────────────────────────────────────────────────

/// One pip per question; the current one is taller.
class _ChapterTrack extends StatelessWidget {
  final int slot;
  final bool finished;
  const _ChapterTrack({required this.slot, required this.finished});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < readerChapterLength; i++)
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: i == slot && !finished ? 14 : 10,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: finished || i < slot
                    ? const Color(0xFF3FB36B)
                    : i == slot
                        ? kReaderButter
                        : const Color(0xFFE6DFCF),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
      ],
    );
  }
}

class _ComboChip extends StatelessWidget {
  final int combo;
  const _ComboChip({required this.combo});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(combo),
      tween: Tween(begin: 1.5, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: kReaderPaper,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x383D3526), offset: Offset(0, 3))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const ReaderIconArt(ReaderIcon.flame, size: 22),
          const SizedBox(width: 4),
          Text('x$combo',
              style: const TextStyle(
                  color: kReaderCoral, fontSize: 18, fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }
}

class _ShakingChest extends StatefulWidget {
  const _ShakingChest();

  @override
  State<_ShakingChest> createState() => _ShakingChestState();
}

class _ShakingChestState extends State<_ShakingChest> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        // A burst of wiggles, then a rest, so it reads as "something inside!"
        final v = _c.value;
        final angle = v < 0.4 ? sin(v * 2 * pi * 5) * 0.18 * (1 - v / 0.4) : 0.0;
        final scale = v < 0.4 ? 1.08 : 1.0;
        return Transform.rotate(angle: angle, child: Transform.scale(scale: scale, child: child));
      },
      child: const ReaderIconArt(ReaderIcon.chest, size: 150),
    );
  }
}
