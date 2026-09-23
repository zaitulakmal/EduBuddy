import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reader_content.dart';
import '../../providers/app_provider.dart';
import '../../services/sound_service.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/reader_scenery.dart';
import '../../widgets/reader_kit.dart';

/// Every Buddy Reader sticker, collected ones in full colour and the rest as
/// mystery silhouettes — the gaps are what bring a child back for one more
/// chapter.
class StickerBookScreen extends StatelessWidget {
  const StickerBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t = provider.t;
    final ms = provider.selectedLanguage == 'ms';
    final collected = provider.collectedStickers;
    final count = readerStickers.where((s) => collected.contains(s.key)).length;

    return Scaffold(
      backgroundColor: kReaderSkyBottom,
      body: Stack(
        children: [
          const Positioned.fill(child: ReaderScenery()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(children: [
                    ReaderPaperButton(
                      semanticLabel: t('Back', 'Kembali'),
                      onTap: () => Navigator.maybePop(context),
                      child: const Icon(Icons.arrow_back_rounded, color: kReaderInk, size: 26),
                    ),
                    const Spacer(),
                    ReaderPaperButton(
                      semanticLabel: t('$count of ${readerStickers.length} stickers',
                          '$count daripada ${readerStickers.length} sticker'),
                      child: Text('$count / ${readerStickers.length}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: kReaderInk,
                              fontFeatures: [FontFeature.tabularFigures()])),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                Text(t('Sticker Book', 'Buku Sticker'),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [Shadow(color: Color(0xFF5A3FD6), offset: Offset(0, 4))],
                    )),
                Text(
                    count == readerStickers.length
                        ? t('You found them all!', 'Awak dah kumpul semua!')
                        : t('Finish a chapter to find the next one!',
                            'Habiskan satu bab untuk dapat sticker!'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF5A3FD6))),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    decoration: BoxDecoration(
                      color: kReaderPaper,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [BoxShadow(color: kReaderPaperEdge, offset: Offset(0, 6))],
                    ),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(14),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 96,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: readerStickers.length,
                      itemBuilder: (_, i) {
                        final s = readerStickers[i];
                        return _StickerTile(
                          sticker: s,
                          owned: collected.contains(s.key),
                          ms: ms,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StickerTile extends StatefulWidget {
  final ReaderSticker sticker;
  final bool owned;
  final bool ms;
  const _StickerTile({required this.sticker, required this.owned, required this.ms});

  @override
  State<_StickerTile> createState() => _StickerTileState();
}

class _StickerTileState extends State<_StickerTile> with SingleTickerProviderStateMixin {
  late final AnimationController _hop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

  @override
  void dispose() {
    _hop.dispose();
    super.dispose();
  }

  void _tap() {
    if (!widget.owned) {
      SoundService.instance.tap();
      return;
    }
    _hop.forward(from: 0);
    SoundService.instance.star();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.ms ? widget.sticker.nameMs : widget.sticker.name;
    return Semantics(
      label: widget.owned ? name : '?',
      button: true,
      child: BouncyButton(
        onTap: _tap,
        child: Container(
          decoration: BoxDecoration(
            color: widget.owned ? const Color(0xFFFFF3C9) : const Color(0xFFEFE9DC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.owned ? kReaderButter : const Color(0xFFDCD3C0),
              width: 2,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _hop,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, -sin(_hop.value * pi) * 14),
                  child: child,
                ),
                child: widget.owned
                    ? Text(widget.sticker.emoji, style: const TextStyle(fontSize: 42))
                    : ColorFiltered(
                        colorFilter: const ColorFilter.mode(Color(0x55786D57), BlendMode.srcIn),
                        child: Text(widget.sticker.emoji, style: const TextStyle(fontSize: 42)),
                      ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.owned ? name : '?',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: widget.owned ? kReaderInk : kReaderMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
