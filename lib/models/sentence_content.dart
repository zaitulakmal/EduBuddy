/// Content and question rules for the Sentences game (Bina Ayat).
///
/// Every item is one picture and one sentence, used three ways: build the
/// sentence from scattered words, fill in its missing word, or match it to its
/// picture. The sentences are deliberately different from Buddy Reader's.
library;

import '../widgets/reader_pictures.dart';
import 'reader_content.dart';

class SentenceItem {
  final ReaderPic pic;
  final String sentence;

  /// The word hidden in a fill-in-the-blank question (as it appears, minus
  /// punctuation).
  final String blank;

  /// Two wrong words offered alongside [blank].
  final List<String> distractors;

  const SentenceItem(this.pic, this.sentence, this.blank, this.distractors);

  List<String> get tokens => sentence.split(' ');

  /// Position of [blank] among [tokens].
  int get blankIndex => tokens.indexWhere((t) => readerBare(t) == readerBare(blank));
}

enum SentenceQuestion { build, fill, match }

/// Questions rotate build → fill → match, offset by chapter so each chapter
/// opens with a different kind.
SentenceQuestion sentenceQuestionFor(int chapter, int slot) =>
    SentenceQuestion.values[(chapter - 1 + slot) % SentenceQuestion.values.length];

SentenceItem sentenceItemFor(List<SentenceItem> items, int chapter, int slot) =>
    items[((chapter - 1) * readerChapterLength + slot) % items.length];

/// The two wrong pictures shown with [item] in a match question. Always two
/// different pictures, neither of them the right one.
List<ReaderPic> sentenceMatchDecoys(List<SentenceItem> items, SentenceItem item) {
  final i = items.indexOf(item);
  final n = items.length;
  return [items[(i + 7) % n].pic, items[(i + 19) % n].pic];
}

// ─── English ─────────────────────────────────────────────────────────────────

const sentenceItemsEn = <SentenceItem>[
  SentenceItem(ReaderPic.cat, 'The cat sleeps on the bed.', 'sleeps', ['swims', 'flies']),
  SentenceItem(ReaderPic.sun, 'The sun is hot today.', 'hot', ['cold', 'wet']),
  SentenceItem(ReaderPic.bus, 'We ride the yellow bus.', 'yellow', ['green', 'pink']),
  SentenceItem(ReaderPic.hat, 'Dad wears a purple hat.', 'hat', ['cup', 'egg']),
  SentenceItem(ReaderPic.bee, 'The bee makes sweet honey.', 'honey', ['milk', 'rice']),
  SentenceItem(ReaderPic.cow, 'The cow gives us milk.', 'milk', ['eggs', 'cake']),
  SentenceItem(ReaderPic.egg, 'Mom cooks an egg.', 'egg', ['shoe', 'key']),
  SentenceItem(ReaderPic.fox, 'The fox runs very fast.', 'runs', ['sings', 'reads']),
  SentenceItem(ReaderPic.car, 'Our red car goes fast.', 'car', ['tree', 'bed']),
  SentenceItem(ReaderPic.ant, 'The ant carries food.', 'carries', ['sings', 'reads']),
  SentenceItem(ReaderPic.cup, 'I drink tea from a cup.', 'cup', ['shoe', 'hat']),
  SentenceItem(ReaderPic.key, 'The key opens the door.', 'key', ['cake', 'fish']),
  SentenceItem(ReaderPic.bed, 'I sleep in my bed.', 'sleep', ['swim', 'cook']),
  SentenceItem(ReaderPic.box, 'The toy is in the box.', 'box', ['sun', 'moon']),
  SentenceItem(ReaderPic.hen, 'The hen lays an egg.', 'lays', ['reads', 'drives']),
  SentenceItem(ReaderPic.fish, 'The fish swims in water.', 'swims', ['flies', 'walks']),
  SentenceItem(ReaderPic.frog, 'The green frog can jump.', 'jump', ['read', 'cook']),
  SentenceItem(ReaderPic.cake, 'We eat cake at parties.', 'cake', ['shoes', 'keys']),
  SentenceItem(ReaderPic.star, 'Stars shine at night.', 'night', ['breakfast', 'school']),
  SentenceItem(ReaderPic.duck, 'The duck swims in the pond.', 'pond', ['sky', 'bed']),
  SentenceItem(ReaderPic.lion, 'The lion roars very loudly.', 'roars', ['whispers', 'reads']),
  SentenceItem(ReaderPic.moon, 'I see the moon at night.', 'moon', ['cake', 'shoe']),
  SentenceItem(ReaderPic.tree, 'The bird sits in the tree.', 'tree', ['cup', 'bus']),
  SentenceItem(ReaderPic.ship, 'The ship sails on the sea.', 'sea', ['road', 'sky']),
  SentenceItem(ReaderPic.ball, 'I kick the ball hard.', 'kick', ['eat', 'read']),
  SentenceItem(ReaderPic.book, 'I read a fun book.', 'read', ['eat', 'drink']),
  SentenceItem(ReaderPic.kite, 'My kite flies up high.', 'flies', ['swims', 'sleeps']),
  SentenceItem(ReaderPic.milk, 'Milk makes me strong.', 'strong', ['sleepy', 'cold']),
  SentenceItem(ReaderPic.rain, 'Rain makes the grass wet.', 'wet', ['dry', 'hot']),
  SentenceItem(ReaderPic.shoe, 'I tie my shoe.', 'tie', ['eat', 'drink']),
  SentenceItem(ReaderPic.bird, 'The bird sings a song.', 'sings', ['swims', 'digs']),
  SentenceItem(ReaderPic.lamp, 'The lamp gives us light.', 'light', ['milk', 'rain']),
  SentenceItem(ReaderPic.door, 'Please close the door.', 'close', ['eat', 'drink']),
  SentenceItem(ReaderPic.rice, 'We eat rice for lunch.', 'rice', ['shoes', 'keys']),
  SentenceItem(ReaderPic.apple, 'The apple is red and sweet.', 'sweet', ['salty', 'furry']),
  SentenceItem(ReaderPic.house, 'We live in a house.', 'live', ['swim', 'fly']),
  SentenceItem(ReaderPic.snake, 'The snake is long and green.', 'long', ['square', 'furry']),
  SentenceItem(ReaderPic.whale, 'The whale lives in the sea.', 'sea', ['tree', 'bed']),
  SentenceItem(ReaderPic.bread, 'I eat bread with jam.', 'bread', ['shoes', 'rocks']),
  SentenceItem(ReaderPic.mouse, 'The mouse likes cheese.', 'cheese', ['rocks', 'shoes']),
  SentenceItem(ReaderPic.cloud, 'The cloud is white and soft.', 'soft', ['hard', 'sharp']),
  SentenceItem(ReaderPic.flower, 'The flower smells nice.', 'smells', ['barks', 'runs']),
  SentenceItem(ReaderPic.banana, 'Monkeys love to eat bananas.', 'bananas', ['rocks', 'shoes']),
  SentenceItem(ReaderPic.turtle, 'The turtle has a hard shell.', 'shell', ['wing', 'horn']),
  SentenceItem(ReaderPic.elephant, 'The elephant has a long trunk.', 'trunk', ['wing', 'beak']),
];

// ─── Bahasa Melayu ───────────────────────────────────────────────────────────

const sentenceItemsMs = <SentenceItem>[
  SentenceItem(ReaderPic.cat, 'Kucing tidur di atas katil.', 'tidur', ['berenang', 'terbang']),
  SentenceItem(ReaderPic.sun, 'Matahari sangat panas hari ini.', 'panas', ['sejuk', 'basah']),
  SentenceItem(ReaderPic.bus, 'Kami naik bas sekolah.', 'naik', ['makan', 'minum']),
  SentenceItem(ReaderPic.hat, 'Ayah pakai topi ungu.', 'topi', ['cawan', 'telur']),
  SentenceItem(ReaderPic.bee, 'Lebah hasilkan madu manis.', 'madu', ['susu', 'nasi']),
  SentenceItem(ReaderPic.cow, 'Lembu beri kita susu.', 'susu', ['telur', 'kek']),
  SentenceItem(ReaderPic.egg, 'Ibu masak telur goreng.', 'telur', ['kasut', 'kunci']),
  SentenceItem(ReaderPic.fox, 'Musang itu lari laju.', 'lari', ['menyanyi', 'membaca']),
  SentenceItem(ReaderPic.car, 'Kereta merah itu laju.', 'kereta', ['pokok', 'katil']),
  SentenceItem(ReaderPic.ant, 'Semut angkat makanan.', 'angkat', ['menyanyi', 'membaca']),
  SentenceItem(ReaderPic.cup, 'Saya minum teh dalam cawan.', 'cawan', ['kasut', 'topi']),
  SentenceItem(ReaderPic.key, 'Kunci ini buka pintu.', 'kunci', ['kek', 'ikan']),
  SentenceItem(ReaderPic.bed, 'Saya tidur di atas katil.', 'tidur', ['berenang', 'memasak']),
  SentenceItem(ReaderPic.box, 'Mainan ada dalam kotak.', 'kotak', ['matahari', 'bulan']),
  SentenceItem(ReaderPic.hen, 'Ayam bertelur setiap hari.', 'bertelur', ['membaca', 'memandu']),
  SentenceItem(ReaderPic.fish, 'Ikan berenang dalam air.', 'berenang', ['terbang', 'berjalan']),
  SentenceItem(ReaderPic.frog, 'Katak hijau itu melompat.', 'melompat', ['membaca', 'memasak']),
  SentenceItem(ReaderPic.cake, 'Kami makan kek hari jadi.', 'kek', ['kasut', 'kunci']),
  SentenceItem(ReaderPic.star, 'Bintang bersinar pada waktu malam.', 'malam', ['sekolah', 'sarapan']),
  SentenceItem(ReaderPic.duck, 'Itik berenang di kolam.', 'kolam', ['langit', 'katil']),
  SentenceItem(ReaderPic.lion, 'Singa mengaum dengan kuat.', 'mengaum', ['berbisik', 'membaca']),
  SentenceItem(ReaderPic.moon, 'Saya nampak bulan waktu malam.', 'bulan', ['kek', 'kasut']),
  SentenceItem(ReaderPic.tree, 'Burung hinggap di pokok.', 'pokok', ['cawan', 'bas']),
  SentenceItem(ReaderPic.ship, 'Kapal belayar di laut.', 'laut', ['jalan', 'langit']),
  SentenceItem(ReaderPic.ball, 'Saya tendang bola itu.', 'tendang', ['makan', 'baca']),
  SentenceItem(ReaderPic.book, 'Saya baca buku cerita.', 'baca', ['makan', 'minum']),
  SentenceItem(ReaderPic.kite, 'Wau saya terbang tinggi.', 'terbang', ['berenang', 'tidur']),
  SentenceItem(ReaderPic.milk, 'Susu buat badan kuat.', 'kuat', ['mengantuk', 'sejuk']),
  SentenceItem(ReaderPic.rain, 'Hujan buat rumput basah.', 'basah', ['kering', 'panas']),
  SentenceItem(ReaderPic.shoe, 'Saya ikat tali kasut.', 'ikat', ['makan', 'minum']),
  SentenceItem(ReaderPic.bird, 'Burung itu menyanyi.', 'menyanyi', ['berenang', 'menggali']),
  SentenceItem(ReaderPic.lamp, 'Lampu beri kita cahaya.', 'cahaya', ['susu', 'hujan']),
  SentenceItem(ReaderPic.door, 'Tolong tutup pintu itu.', 'tutup', ['makan', 'minum']),
  SentenceItem(ReaderPic.rice, 'Kami makan nasi tengah hari.', 'nasi', ['kasut', 'kunci']),
  SentenceItem(ReaderPic.apple, 'Epal itu merah dan manis.', 'manis', ['masin', 'berbulu']),
  SentenceItem(ReaderPic.house, 'Kami tinggal di rumah.', 'tinggal', ['berenang', 'terbang']),
  SentenceItem(ReaderPic.snake, 'Ular itu panjang dan hijau.', 'panjang', ['berbulu', 'bersayap']),
  SentenceItem(ReaderPic.whale, 'Paus tinggal di laut.', 'laut', ['pokok', 'katil']),
  SentenceItem(ReaderPic.bread, 'Saya makan roti dengan jem.', 'roti', ['kasut', 'batu']),
  SentenceItem(ReaderPic.mouse, 'Tikus suka makan keju.', 'keju', ['batu', 'kasut']),
  SentenceItem(ReaderPic.cloud, 'Awan itu putih dan lembut.', 'lembut', ['keras', 'tajam']),
  SentenceItem(ReaderPic.flower, 'Bunga itu sangat wangi.', 'wangi', ['bising', 'tajam']),
  SentenceItem(ReaderPic.banana, 'Monyet suka makan pisang.', 'pisang', ['batu', 'kasut']),
  SentenceItem(ReaderPic.turtle, 'Penyu ada cangkerang keras.', 'cangkerang', ['sayap', 'tanduk']),
  SentenceItem(ReaderPic.elephant, 'Gajah ada belalai panjang.', 'belalai', ['sayap', 'paruh']),
];
