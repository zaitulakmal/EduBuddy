import 'package:flutter_test/flutter_test.dart';
import 'package:edubuddy/models/reader_content.dart';
import 'package:edubuddy/models/sentence_content.dart';
import 'package:edubuddy/widgets/reader_pictures.dart';

void main() {
  for (final (lang, items) in [
    ('English', sentenceItemsEn),
    ('Malay', sentenceItemsMs),
  ]) {
    group('$lang sentences', () {
      test('use every drawing exactly once', () {
        expect(items.map((i) => i.pic).toSet(), ReaderPic.values.toSet());
        expect(items.length, ReaderPic.values.length);
      });

      test('the hidden word appears exactly once in its sentence', () {
        for (final i in items) {
          final hits = i.tokens.where((t) => readerBare(t) == readerBare(i.blank)).length;
          expect(hits, 1, reason: '"${i.blank}" in "${i.sentence}"');
        }
      });

      test('wrong choices are two different words not already in the sentence', () {
        for (final i in items) {
          final bare = i.tokens.map(readerBare).toSet();
          expect(i.distractors.toSet().length, 2, reason: i.sentence);
          for (final d in i.distractors) {
            expect(bare.contains(readerBare(d)), isFalse, reason: '"$d" in "${i.sentence}"');
            expect(readerBare(d), isNot(readerBare(i.blank)));
          }
        }
      });

      test('sentences fit on a phone', () {
        for (final i in items) {
          expect(i.tokens.length, lessThanOrEqualTo(6), reason: i.sentence);
        }
      });

      test('match questions show three different pictures', () {
        for (final i in items) {
          final pics = {i.pic, ...sentenceMatchDecoys(items, i)};
          expect(pics.length, 3, reason: i.sentence);
        }
      });
    });
  }

  test('every chapter mixes all three question kinds', () {
    for (var chapter = 1; chapter <= 6; chapter++) {
      final kinds = {
        for (var slot = 0; slot < readerChapterLength; slot++) sentenceQuestionFor(chapter, slot)
      };
      expect(kinds, SentenceQuestion.values.toSet());
    }
  });
}
