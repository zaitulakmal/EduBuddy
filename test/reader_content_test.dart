import 'package:flutter_test/flutter_test.dart';
import 'package:edubuddy/models/reader_content.dart';
import 'package:edubuddy/widgets/reader_pictures.dart';

void main() {
  for (final (lang, words, phonics) in [
    ('English', readerWordsEn, readerPhonicsEn),
    ('Malay', readerWordsMs, readerPhonicsMs),
  ]) {
    group('$lang word list', () {
      test('uses every drawing exactly once', () {
        expect(words.map((w) => w.pic).toSet(), ReaderPic.values.toSet(),
            reason: 'each drawn picture should have a word, and no word shares one');
        expect(words.length, ReaderPic.values.length);
      });

      test('never lists the same word twice', () {
        final seen = <String>{};
        for (final w in words) {
          expect(seen.add(w.word), isTrue, reason: '"${w.word}" appears twice');
        }
      });

      test('every letter can be sounded out', () {
        for (final w in words) {
          for (final ch in w.word.split('')) {
            expect(phonics.containsKey(ch), isTrue,
                reason: 'no sound for "$ch" in "${w.word}"');
          }
        }
      });
    });
  }

  group('pacing', () {
    test('chapter 1 opens with the first five words in order', () {
      final chapter1 = [for (var i = 0; i < readerChapterLength; i++) readerWordFor(readerWordsEn, 1, i)];
      expect(chapter1, readerWordsEn.take(readerChapterLength).toList());
    });

    test('the run wraps around instead of ending', () {
      final lastChapter = (readerWordsEn.length / readerChapterLength).ceil() + 3;
      expect(() => readerWordFor(readerWordsEn, lastChapter, 4), returnsNormally);
    });

    test('a chapter pays a sticker not yet in the book', () {
      final first = readerStickerFor(1, {});
      expect(first, readerStickers.first);

      final next = readerStickerFor(1, {readerStickers.first.key});
      expect(next, isNot(readerStickers.first));
    });

    test('a full book pays no sticker', () {
      final all = readerStickers.map((s) => s.key).toSet();
      expect(readerStickerFor(7, all), isNull);
    });

    test('sticker keys are unique', () {
      final keys = readerStickers.map((s) => s.key).toSet();
      expect(keys.length, readerStickers.length);
    });
  });
}
