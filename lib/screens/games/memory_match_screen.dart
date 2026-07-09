import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/animal_illustrations.dart';
import '../../widgets/bouncy_button.dart';
import '../../services/ad_helper.dart';
import '../../services/sound_service.dart';

const _kBg = Color(0xFFFFF4E0);
const _kPurple = Color(0xFF5B4DA8);
const _kCardBack = [Color(0xFF7B6EC8), Color(0xFF5B4DA8)];

// ─── Deck & tile model ─────────────────────────────────────────────────────────

/// One face on the board. Either an SVG illustration or an emoji glyph.
class _Tile {
  final String content; // SVG string or emoji character
  final bool isSvg;
  final Color color;
  const _Tile(this.content, this.isSvg, this.color);
}

/// A themed set of tiles ("world"). Each world is a run of 5 levels.
class _Deck {
  final String name;
  final String icon;
  final List<Color> gradient;
  final List<_Tile> tiles;
  const _Deck(this.name, this.icon, this.gradient, this.tiles);
}

List<_Tile> _emoji(List<List<Object>> data) =>
    data.map((d) => _Tile(d[0] as String, false, Color(d[1] as int))).toList();

List<_Deck> _buildDecks() {
  final animalTiles = allAnimals.map((a) => _Tile(a.svg, true, a.color)).toList();
  return [
    _Deck('Animal Kingdom', '🦁', const [Color(0xFFE8A85B), Color(0xFFD8894A)], animalTiles),
    _Deck('Fruit Basket', '🍎', const [Color(0xFFE85B5B), Color(0xFFC8425B)], _emoji(const [
      ['🍎', 0xFFE85B5B], ['🍌', 0xFFF4C942], ['🍇', 0xFF9B5BE8], ['🍓', 0xFFE85B9B],
      ['🍊', 0xFFF39C42], ['🍉', 0xFF6BBF6F], ['🍑', 0xFFF4A46B], ['🍒', 0xFFC8425B],
      ['🥝', 0xFF8BBF4F], ['🍍', 0xFFE8B94A], ['🥥', 0xFFA9805B], ['🍋', 0xFFEDE04A],
    ])),
    _Deck('Ocean World', '🐠', const [Color(0xFF5BBFE8), Color(0xFF5B8CE8)], _emoji(const [
      ['🐠', 0xFFF39C42], ['🐙', 0xFFC85BE8], ['🦀', 0xFFE85B5B], ['🐬', 0xFF5BBFE8],
      ['🐳', 0xFF5B8CE8], ['🦈', 0xFF8B9B9F], ['🐡', 0xFFF4C962], ['🦑', 0xFFE86B9B],
      ['🐚', 0xFFEFB6C8], ['🦞', 0xFFD85B4A], ['🐟', 0xFF6BBFCF], ['🐢', 0xFF6BBF6F],
    ])),
    _Deck('Speedy Wheels', '🚗', const [Color(0xFFF4A44A), Color(0xFFE8784A)], _emoji(const [
      ['🚗', 0xFFE85B5B], ['🚌', 0xFFF4C942], ['🚂', 0xFF8B6F4F], ['🚀', 0xFF785BC8],
      ['🚁', 0xFF5BBFE8], ['✈️', 0xFF5B8CE8], ['🚲', 0xFF6BBF6F], ['🏍️', 0xFF4A4A6A],
      ['🚤', 0xFF4BAFD8], ['⛵', 0xFFE8784A], ['🚜', 0xFFF4A44A], ['🚒', 0xFFD8452B],
    ])),
    _Deck('Yummy Food', '🍕', const [Color(0xFFE8784A), Color(0xFFC8845B)], _emoji(const [
      ['🍕', 0xFFE8784A], ['🍔', 0xFFC8845B], ['🍟', 0xFFF4C942], ['🌭', 0xFFE85B5B],
      ['🍿', 0xFFEDD8A8], ['🥪', 0xFFD8B46B], ['🌮', 0xFFF3A44A], ['🍩', 0xFFE85B9B],
      ['🍪', 0xFFB8845B], ['🎂', 0xFFF49BC8], ['🍦', 0xFF8BC8E8], ['🍫', 0xFF8B5B3B],
    ])),
    _Deck('Space Explorer', '🚀', const [Color(0xFF785BC8), Color(0xFF5B4DA8)], _emoji(const [
      ['🚀', 0xFFE85B5B], ['🪐', 0xFFF4C942], ['⭐', 0xFFF5C842], ['🌙', 0xFFEDE0A8],
      ['☄️', 0xFF8B6F9F], ['🛸', 0xFF5BBFE8], ['🌟', 0xFFF4D24A], ['🌍', 0xFF5B8CE8],
      ['👽', 0xFF6BBF6F], ['🔭', 0xFF785BC8], ['🌌', 0xFF5B4DA8], ['🌠', 0xFFE86B9B],
    ])),
  ];
}

// ─── Level model ───────────────────────────────────────────────────────────────

class _Level {
  final int index; // global 0-based
  final int deckIndex;
  final int pairs;
  const _Level(this.index, this.deckIndex, this.pairs);
}

// Difficulty ramp within each world (pairs of cards per level).
const _pairRamp = [3, 4, 5, 6, 8];

List<_Level> _buildLevels(int deckCount) {
  final levels = <_Level>[];
  int idx = 0;
  for (int d = 0; d < deckCount; d++) {
    for (final p in _pairRamp) {
      levels.add(_Level(idx++, d, p));
    }
  }
  return levels;
}

// ─── Progress persistence ──────────────────────────────────────────────────────

class _Progress {
  static const _kStars = 'mm_stars_v2_';

  static Future<Map<int, int>> load(int count) async {
    final prefs = await SharedPreferences.getInstance();
    final map = <int, int>{};
    for (int i = 0; i < count; i++) {
      final s = prefs.getInt('$_kStars$i');
      if (s != null && s > 0) map[i] = s;
    }
    return map;
  }

  static Future<void> saveStars(int level, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    final cur = prefs.getInt('$_kStars$level') ?? 0;
    if (stars > cur) await prefs.setInt('$_kStars$level', stars);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LEVEL SELECT (entry point)
// ═══════════════════════════════════════════════════════════════════════════════

class MemoryMatchScreen extends StatefulWidget {
  const MemoryMatchScreen({super.key});

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen> {
  late final List<_Deck> _decks = _buildDecks();
  late final List<_Level> _levels = _buildLevels(_decks.length);
  Map<int, int> _stars = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _Progress.load(_levels.length);
    if (!mounted) return;
    setState(() {
      _stars = s;
      _loading = false;
    });
  }

  bool _isUnlocked(int i) => i == 0 || (_stars[i - 1] ?? 0) > 0;

  int get _totalStars => _stars.values.fold(0, (a, b) => a + b);
  int get _maxStars => _levels.length * 3;

  Future<void> _openLevel(int i) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _MemoryGameScreen(
          levels: _levels,
          decks: _decks,
          startIndex: i,
          starsOf: (idx) => _stars[idx] ?? 0,
        ),
      ),
    );
    _load(); // refresh stars when returning from a game
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: _kPurple)))
            else
              Expanded(child: _buildWorldList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: _kPurple),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text('Memory Match',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _kPurple)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF5C842).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text('⭐ $_totalStars/$_maxStars',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFB8860B))),
          ),
        ],
      ),
    );
  }

  Widget _buildWorldList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _decks.length,
      itemBuilder: (_, worldIndex) {
        final deck = _decks[worldIndex];
        final worldLevels =
            _levels.where((l) => l.deckIndex == worldIndex).toList();
        final worldStars = worldLevels.fold<int>(0, (a, l) => a + (_stars[l.index] ?? 0));
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: deck.gradient),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: Text(deck.icon, style: const TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(deck.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _kPurple)),
                        Text('World ${worldIndex + 1}  •  ⭐ $worldStars/${worldLevels.length * 3}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF999999))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: worldLevels.map((lvl) {
                  return _LevelChip(
                    number: lvl.index + 1,
                    pairs: lvl.pairs,
                    stars: _stars[lvl.index] ?? 0,
                    unlocked: _isUnlocked(lvl.index),
                    gradient: deck.gradient,
                    onTap: () => _openLevel(lvl.index),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LevelChip extends StatelessWidget {
  final int number;
  final int pairs;
  final int stars;
  final bool unlocked;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _LevelChip({
    required this.number,
    required this.pairs,
    required this.stars,
    required this.unlocked,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      onTap: unlocked ? onTap : () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: unlocked ? LinearGradient(colors: gradient) : null,
              color: unlocked ? null : const Color(0xFFE8E4F0),
              borderRadius: BorderRadius.circular(16),
              boxShadow: unlocked
                  ? [BoxShadow(color: gradient[1].withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 3))]
                  : null,
            ),
            child: Center(
              child: unlocked
                  ? Text('$number',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white))
                  : const Icon(Icons.lock_rounded, color: Color(0xFFB0A8C8), size: 22),
            ),
          ),
          const SizedBox(height: 4),
          if (unlocked)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => Icon(
                    i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 11,
                    color: i < stars ? const Color(0xFFF5C842) : const Color(0xFFD8D0E8),
                  )),
            )
          else
            const SizedBox(height: 11),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GAME SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class _CardItem {
  final int pairId;
  final _Tile tile;
  bool isFlipped = false;
  bool isMatched = false;
  _CardItem(this.pairId, this.tile);
}

class _MemoryGameScreen extends StatefulWidget {
  final List<_Level> levels;
  final List<_Deck> decks;
  final int startIndex;
  final int Function(int levelIndex) starsOf;

  const _MemoryGameScreen({
    required this.levels,
    required this.decks,
    required this.startIndex,
    required this.starsOf,
  });

  @override
  State<_MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<_MemoryGameScreen>
    with TickerProviderStateMixin {
  final _rand = Random();

  late int _index;
  late List<_CardItem> _cards;
  late ConfettiController _confetti;

  int? _firstFlippedIndex;
  bool _locked = false;
  int _moves = 0;
  int _matchedPairs = 0;
  bool _won = false;
  int _earnedStars = 0;
  bool _newBest = false;
  Timer? _ticker;
  int _seconds = 0;

  _Level get _level => widget.levels[_index];
  _Deck get _deck => widget.decks[_level.deckIndex];

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    SoundService.instance.playMusic('playful');
    _go(widget.startIndex);
  }

  @override
  void dispose() {
    _confetti.dispose();
    _ticker?.cancel();
    SoundService.instance.playMusic('calm');
    super.dispose();
  }

  void _go(int index) {
    final level = widget.levels[index];
    final deck = widget.decks[level.deckIndex];
    final tiles = List.of(deck.tiles)..shuffle(_rand);
    final chosen = tiles.take(level.pairs).toList();
    final cards = <_CardItem>[];
    for (int i = 0; i < chosen.length; i++) {
      cards.add(_CardItem(i, chosen[i]));
      cards.add(_CardItem(i, chosen[i]));
    }
    cards.shuffle(_rand);

    _ticker?.cancel();
    setState(() {
      _index = index;
      _cards = cards;
      _firstFlippedIndex = null;
      _locked = false;
      _moves = 0;
      _matchedPairs = 0;
      _won = false;
      _earnedStars = 0;
      _newBest = false;
      _seconds = 0;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_won && mounted) setState(() => _seconds++);
    });
  }

  void _onCardTap(int index) {
    if (_locked || _cards[index].isFlipped || _cards[index].isMatched || _won) return;

    SoundService.instance.flip();
    setState(() => _cards[index].isFlipped = true);

    if (_firstFlippedIndex == null) {
      _firstFlippedIndex = index;
      return;
    }

    _moves++;
    final firstIndex = _firstFlippedIndex!;
    _firstFlippedIndex = null;

    if (_cards[firstIndex].pairId == _cards[index].pairId) {
      SoundService.instance.match();
      setState(() {
        _cards[firstIndex].isMatched = true;
        _cards[index].isMatched = true;
        _matchedPairs++;
      });
      if (_matchedPairs == _level.pairs) _onWin();
    } else {
      _locked = true;
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() {
          _cards[firstIndex].isFlipped = false;
          _cards[index].isFlipped = false;
          _locked = false;
        });
      });
    }
  }

  int _starsForMoves(int moves) {
    final perfect = _level.pairs;
    if (moves <= perfect + (perfect * 0.5).ceil()) return 3;
    if (moves <= perfect * 2) return 2;
    return 1;
  }

  Future<void> _onWin() async {
    _ticker?.cancel();
    final stars = _starsForMoves(_moves);
    final prev = widget.starsOf(_index);
    setState(() {
      _won = true;
      _earnedStars = stars;
      _newBest = stars > prev;
    });
    SoundService.instance.win();
    _confetti.play();
    await _Progress.saveStars(_index, stars);
  }

  bool get _hasNext => _index + 1 < widget.levels.length;

  Future<void> _nextLevel() async {
    await AdHelper.maybeShowInterstitial();
    if (mounted && _hasNext) _go(_index + 1);
  }

  Future<void> _retry() async {
    await AdHelper.maybeShowInterstitial();
    if (mounted) _go(_index);
  }

  Future<void> _exitToMap() async {
    await AdHelper.maybeShowInterstitial();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildGrid()),
              ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 30,
                colors: const [Color(0xFFE8784A), Color(0xFF7B6EC8), Color(0xFF6BBF6F), Color(0xFFF5C842)],
              ),
            ),
            if (_won) _buildWinOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final mins = (_seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_seconds % 60).toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: _kPurple),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Level ${_index + 1}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _kPurple)),
                Text('${_deck.icon} ${_deck.name}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF999999))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _kPurple),
            onPressed: () => _go(_index),
          ),
          const SizedBox(width: 2),
          _statChip('⏱ $mins:$secs'),
          const SizedBox(width: 6),
          _statChip('🔄 $_moves'),
        ],
      ),
    );
  }

  Widget _statChip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFF7B6EC8).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _kPurple)),
      );

  int _colsFor(int cards) {
    if (cards <= 6) return 3; // 3 pairs
    if (cards <= 8) return 4; // 4 pairs
    if (cards <= 10) return 5; // 5 pairs
    return 4; // 6 & 8 pairs
  }

  Widget _buildGrid() {
    final cards = _cards.length;
    final cols = _colsFor(cards);
    final rows = (cards / cols).ceil();
    const spacing = 10.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: LayoutBuilder(
        builder: (context, c) {
          final cardW = (c.maxWidth - (cols - 1) * spacing) / cols;
          final cardH = (c.maxHeight - (rows - 1) * spacing) / rows;
          final aspect = cardH > 0 ? (cardW / cardH) : 0.78;
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cards,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: aspect.clamp(0.5, 1.2),
            ),
            itemBuilder: (_, i) => _FlipCard(
              card: _cards[i],
              onTap: () => _onCardTap(i),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWinOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 36),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              Text(_hasNext ? 'Level ${_index + 1} Complete!' : 'You Finished Them All!',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _kPurple),
                  textAlign: TextAlign.center),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < _earnedStars ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: const Color(0xFFF5C842),
                        size: 40,
                      ),
                    )),
              ),
              const SizedBox(height: 12),
              Text('Moves: $_moves   •   Time: ${_seconds}s',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF888888))),
              if (_newBest)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('🏆 New Best!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFE8784A))),
                ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _overlayButton(
                    label: 'Map',
                    filled: false,
                    onTap: _exitToMap,
                  ),
                  const SizedBox(width: 10),
                  _overlayButton(
                    label: 'Retry',
                    filled: false,
                    onTap: _retry,
                  ),
                  const SizedBox(width: 10),
                  _overlayButton(
                    label: _hasNext ? 'Next ▶' : 'Done',
                    filled: true,
                    onTap: _hasNext ? _nextLevel : _exitToMap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overlayButton({required String label, required bool filled, required VoidCallback onTap}) {
    return Expanded(
      child: BouncyButton(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: filled ? const LinearGradient(colors: _kCardBack) : null,
            color: filled ? null : const Color(0xFFF0EEFA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: filled ? Colors.white : _kPurple)),
        ),
      ),
    );
  }
}

// ─── Flip card ─────────────────────────────────────────────────────────────────

class _FlipCard extends StatefulWidget {
  final _CardItem card;
  final VoidCallback onTap;
  const _FlipCard({required this.card, required this.onTap});

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _wasFlipped = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _wasFlipped = widget.card.isFlipped;
    if (_wasFlipped) _ctrl.value = 1;
  }

  @override
  void didUpdateWidget(_FlipCard old) {
    super.didUpdateWidget(old);
    if (widget.card.isFlipped != _wasFlipped) {
      _wasFlipped = widget.card.isFlipped;
      if (_wasFlipped) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          final isBack = _anim.value < 0.5;
          final angle = _anim.value * 3.14159;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..rotateY(angle),
            child: isBack
                ? _backFace()
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(3.14159),
                    child: _frontFace(),
                  ),
          );
        },
      ),
    );
  }

  Widget _backFace() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: _kCardBack),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF5B4DA8).withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: const Center(
        child: Text('?', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white)),
      ),
    );
  }

  Widget _frontFace() {
    final matched = widget.card.isMatched;
    final tile = widget.card.tile;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: matched ? const Color(0xFF6BBF6F) : tile.color, width: matched ? 3 : 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(8),
      child: Opacity(
        opacity: matched ? 0.55 : 1,
        child: tile.isSvg
            ? SvgPicture.string(tile.content, fit: BoxFit.contain)
            : FittedBox(
                fit: BoxFit.contain,
                child: Text(tile.content, style: const TextStyle(fontSize: 40)),
              ),
      ),
    );
  }
}
