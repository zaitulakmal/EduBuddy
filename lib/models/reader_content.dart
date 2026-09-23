/// Content and pacing rules for Buddy Reader.
///
/// Plain data plus pure functions, so the endless run (which word comes next,
/// which sticker a chapter pays) can be tested without a widget tree.
library;

import '../widgets/reader_pictures.dart';

class ReaderWord {
  final ReaderPic pic;
  final String word;
  const ReaderWord(this.pic, this.word);
}

/// Strips punctuation so "cat." matches "cat".
String readerBare(String token) =>
    token.replaceAll(RegExp(r'[^A-Za-z]'), '').toLowerCase();

/// Words in one chapter. A chapter ends with a sticker chest.
const readerChapterLength = 5;

/// Hearts per chapter. Losing them all restarts the chapter.
const readerLives = 3;

// ─── English — ordered easy (3 letters) to harder (5+ letters) ───────────────

const readerWordsEn = <ReaderWord>[
  // 3 letters
  ReaderWord(ReaderPic.cat, 'cat'),
  ReaderWord(ReaderPic.sun, 'sun'),
  ReaderWord(ReaderPic.bus, 'bus'),
  ReaderWord(ReaderPic.hat, 'hat'),
  ReaderWord(ReaderPic.bee, 'bee'),
  ReaderWord(ReaderPic.cow, 'cow'),
  ReaderWord(ReaderPic.egg, 'egg'),
  ReaderWord(ReaderPic.fox, 'fox'),
  ReaderWord(ReaderPic.car, 'car'),
  ReaderWord(ReaderPic.ant, 'ant'),
  ReaderWord(ReaderPic.cup, 'cup'),
  ReaderWord(ReaderPic.key, 'key'),
  ReaderWord(ReaderPic.bed, 'bed'),
  ReaderWord(ReaderPic.box, 'box'),
  ReaderWord(ReaderPic.hen, 'hen'),
  // 4 letters
  ReaderWord(ReaderPic.fish, 'fish'),
  ReaderWord(ReaderPic.frog, 'frog'),
  ReaderWord(ReaderPic.cake, 'cake'),
  ReaderWord(ReaderPic.star, 'star'),
  ReaderWord(ReaderPic.duck, 'duck'),
  ReaderWord(ReaderPic.lion, 'lion'),
  ReaderWord(ReaderPic.moon, 'moon'),
  ReaderWord(ReaderPic.tree, 'tree'),
  ReaderWord(ReaderPic.ship, 'ship'),
  ReaderWord(ReaderPic.ball, 'ball'),
  ReaderWord(ReaderPic.book, 'book'),
  ReaderWord(ReaderPic.kite, 'kite'),
  ReaderWord(ReaderPic.milk, 'milk'),
  ReaderWord(ReaderPic.rain, 'rain'),
  ReaderWord(ReaderPic.shoe, 'shoe'),
  ReaderWord(ReaderPic.bird, 'bird'),
  ReaderWord(ReaderPic.lamp, 'lamp'),
  ReaderWord(ReaderPic.door, 'door'),
  ReaderWord(ReaderPic.rice, 'rice'),
  // 5+ letters
  ReaderWord(ReaderPic.apple, 'apple'),
  ReaderWord(ReaderPic.house, 'house'),
  ReaderWord(ReaderPic.snake, 'snake'),
  ReaderWord(ReaderPic.whale, 'whale'),
  ReaderWord(ReaderPic.bread, 'bread'),
  ReaderWord(ReaderPic.mouse, 'mouse'),
  ReaderWord(ReaderPic.cloud, 'cloud'),
  ReaderWord(ReaderPic.flower, 'flower'),
  ReaderWord(ReaderPic.banana, 'banana'),
  ReaderWord(ReaderPic.turtle, 'turtle'),
  ReaderWord(ReaderPic.elephant, 'elephant'),
];

// ─── Bahasa Melayu — 3 huruf ke perkataan lebih panjang ──────────────────────

const readerWordsMs = <ReaderWord>[
  // 3 huruf
  ReaderWord(ReaderPic.bus, 'bas'),
  ReaderWord(ReaderPic.cake, 'kek'),
  ReaderWord(ReaderPic.kite, 'wau'),
  // 4 huruf
  ReaderWord(ReaderPic.hat, 'topi'),
  ReaderWord(ReaderPic.fish, 'ikan'),
  ReaderWord(ReaderPic.ball, 'bola'),
  ReaderWord(ReaderPic.book, 'buku'),
  ReaderWord(ReaderPic.apple, 'epal'),
  ReaderWord(ReaderPic.snake, 'ular'),
  ReaderWord(ReaderPic.whale, 'paus'),
  ReaderWord(ReaderPic.bread, 'roti'),
  ReaderWord(ReaderPic.milk, 'susu'),
  ReaderWord(ReaderPic.cloud, 'awan'),
  ReaderWord(ReaderPic.rice, 'nasi'),
  ReaderWord(ReaderPic.duck, 'itik'),
  ReaderWord(ReaderPic.hen, 'ayam'),
  // 5 huruf
  ReaderWord(ReaderPic.bee, 'lebah'),
  ReaderWord(ReaderPic.cow, 'lembu'),
  ReaderWord(ReaderPic.egg, 'telur'),
  ReaderWord(ReaderPic.ant, 'semut'),
  ReaderWord(ReaderPic.cup, 'cawan'),
  ReaderWord(ReaderPic.key, 'kunci'),
  ReaderWord(ReaderPic.bed, 'katil'),
  ReaderWord(ReaderPic.box, 'kotak'),
  ReaderWord(ReaderPic.frog, 'katak'),
  ReaderWord(ReaderPic.lion, 'singa'),
  ReaderWord(ReaderPic.moon, 'bulan'),
  ReaderWord(ReaderPic.tree, 'pokok'),
  ReaderWord(ReaderPic.ship, 'kapal'),
  ReaderWord(ReaderPic.house, 'rumah'),
  ReaderWord(ReaderPic.rain, 'hujan'),
  ReaderWord(ReaderPic.shoe, 'kasut'),
  ReaderWord(ReaderPic.flower, 'bunga'),
  ReaderWord(ReaderPic.mouse, 'tikus'),
  ReaderWord(ReaderPic.elephant, 'gajah'),
  ReaderWord(ReaderPic.lamp, 'lampu'),
  ReaderWord(ReaderPic.door, 'pintu'),
  ReaderWord(ReaderPic.turtle, 'penyu'),
  // lebih panjang
  ReaderWord(ReaderPic.cat, 'kucing'),
  ReaderWord(ReaderPic.fox, 'musang'),
  ReaderWord(ReaderPic.car, 'kereta'),
  ReaderWord(ReaderPic.star, 'bintang'),
  ReaderWord(ReaderPic.bird, 'burung'),
  ReaderWord(ReaderPic.banana, 'pisang'),
  ReaderWord(ReaderPic.sun, 'matahari'),
];

/// Letter *sounds*, not letter names, spelled so TTS says roughly the right
/// thing. Stand-ins until recorded phonics clips replace them.
const readerPhonicsEn = {
  'a': 'ah', 'b': 'buh', 'c': 'kuh', 'd': 'duh', 'e': 'eh', 'f': 'fff',
  'g': 'guh', 'h': 'huh', 'i': 'ih', 'j': 'juh', 'k': 'kuh', 'l': 'lll',
  'm': 'mmm', 'n': 'nnn', 'o': 'aw', 'p': 'puh', 'r': 'rrr', 's': 'sss',
  't': 'tuh', 'u': 'uh', 'v': 'vvv', 'w': 'wuh', 'x': 'ks', 'y': 'yuh',
  'z': 'zzz', 'q': 'kwuh',
};
const readerPhonicsMs = {
  'a': 'a', 'b': 'be', 'c': 'ce', 'd': 'de', 'e': 'e', 'f': 'fe', 'g': 'ge',
  'h': 'he', 'i': 'i', 'j': 'je', 'k': 'ke', 'l': 'le', 'm': 'me', 'n': 'ne',
  'o': 'o', 'p': 'pe', 'r': 're', 's': 'se', 't': 'te', 'u': 'u', 'v': 've',
  'w': 'we', 'y': 'ye', 'z': 'ze',
};

// ─── Stickers ─────────────────────────────────────────────────────────────────

class ReaderSticker {
  final String key;
  final String emoji;
  final String name;
  final String nameMs;
  const ReaderSticker(this.key, this.emoji, this.name, this.nameMs);
}

const readerStickers = <ReaderSticker>[
  ReaderSticker('sticker_unicorn', '🦄', 'Unicorn', 'Unikorn'),
  ReaderSticker('sticker_dragon', '🐲', 'Dragon', 'Naga'),
  ReaderSticker('sticker_trex', '🦖', 'T-Rex', 'T-Rex'),
  ReaderSticker('sticker_octopus', '🐙', 'Octopus', 'Sotong Kurita'),
  ReaderSticker('sticker_butterfly', '🦋', 'Butterfly', 'Rama-rama'),
  ReaderSticker('sticker_dolphin', '🐬', 'Dolphin', 'Ikan Lumba-lumba'),
  ReaderSticker('sticker_flamingo', '🦩', 'Flamingo', 'Flamingo'),
  ReaderSticker('sticker_parrot', '🦜', 'Parrot', 'Burung Kakak Tua'),
  ReaderSticker('sticker_penguin', '🐧', 'Penguin', 'Penguin'),
  ReaderSticker('sticker_hedgehog', '🦔', 'Hedgehog', 'Landak'),
  ReaderSticker('sticker_turtle', '🐢', 'Turtle', 'Kura-kura'),
  ReaderSticker('sticker_dino', '🦕', 'Dino', 'Dinosaur'),
  ReaderSticker('sticker_rocket', '🚀', 'Rocket', 'Roket'),
  ReaderSticker('sticker_ufo', '🛸', 'UFO', 'UFO'),
  ReaderSticker('sticker_rainbow', '🌈', 'Rainbow', 'Pelangi'),
  ReaderSticker('sticker_icecream', '🍦', 'Ice Cream', 'Aiskrim'),
  ReaderSticker('sticker_donut', '🍩', 'Donut', 'Donat'),
  ReaderSticker('sticker_cupcake', '🧁', 'Cupcake', 'Kek Cawan'),
  ReaderSticker('sticker_strawberry', '🍓', 'Strawberry', 'Strawberi'),
  ReaderSticker('sticker_watermelon', '🍉', 'Watermelon', 'Tembikai'),
  ReaderSticker('sticker_balloon', '🎈', 'Balloon', 'Belon'),
  ReaderSticker('sticker_gift', '🎁', 'Gift', 'Hadiah'),
  ReaderSticker('sticker_castle', '🏰', 'Castle', 'Istana'),
  ReaderSticker('sticker_carousel', '🎠', 'Carousel', 'Kuda Pusing'),
  ReaderSticker('sticker_ferris', '🎡', 'Ferris Wheel', 'Roda Ria'),
  ReaderSticker('sticker_helicopter', '🚁', 'Helicopter', 'Helikopter'),
  ReaderSticker('sticker_giraffe', '🦒', 'Giraffe', 'Zirafah'),
  ReaderSticker('sticker_kangaroo', '🦘', 'Kangaroo', 'Kanggaru'),
  ReaderSticker('sticker_sloth', '🦥', 'Sloth', 'Sloth'),
  ReaderSticker('sticker_otter', '🦦', 'Otter', 'Memerang'),
  ReaderSticker('sticker_ladybug', '🐞', 'Ladybug', 'Kumbang Kura'),
  ReaderSticker('sticker_sunflower', '🌻', 'Sunflower', 'Bunga Matahari'),
  ReaderSticker('sticker_cactus', '🌵', 'Cactus', 'Kaktus'),
  ReaderSticker('sticker_mushroom', '🍄', 'Mushroom', 'Cendawan'),
  ReaderSticker('sticker_whale', '🐳', 'Whale', 'Ikan Paus'),
  ReaderSticker('sticker_shark', '🦈', 'Shark', 'Jerung'),
  ReaderSticker('sticker_crown', '👑', 'Crown', 'Mahkota'),
  ReaderSticker('sticker_gem', '💎', 'Gem', 'Permata'),
  ReaderSticker('sticker_trophy', '🏆', 'Trophy', 'Piala'),
  ReaderSticker('sticker_star', '🌟', 'Super Star', 'Bintang Hebat'),
];

// ─── Pacing ───────────────────────────────────────────────────────────────────

/// The [slot]th word (0-based) of [chapter] (1-based). Chapters walk the list
/// from easy to hard and wrap around, so the run never ends.
ReaderWord readerWordFor(List<ReaderWord> words, int chapter, int slot) {
  final index = ((chapter - 1) * readerChapterLength + slot) % words.length;
  return words[index];
}

/// The sticker a finished chapter pays: the first one not yet collected,
/// starting from the chapter's own place in the catalogue. Null once the book
/// is complete.
ReaderSticker? readerStickerFor(int chapter, Set<String> collected) {
  for (var i = 0; i < readerStickers.length; i++) {
    final s = readerStickers[(chapter - 1 + i) % readerStickers.length];
    if (!collected.contains(s.key)) return s;
  }
  return null;
}
