import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category_model.dart';
import '../models/video_model.dart';
import '../models/quiz_model.dart';
import '../models/storybook_model.dart';
import '../models/worksheet_model.dart';
import '../models/badge_model.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _db;

  DatabaseHelper._internal();
  factory DatabaseHelper() => _instance ??= DatabaseHelper._internal();

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'edubuddy.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _seedMoreQuizzes(db);
    }
    if (oldVersion < 3) {
      await _seedExtraQuestions(db);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        name_ms TEXT NOT NULL,
        icon TEXT NOT NULL,
        color_index INTEGER NOT NULL,
        age_group TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE videos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        title_ms TEXT NOT NULL,
        description TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        age_group TEXT NOT NULL,
        duration TEXT NOT NULL,
        thumbnail_emoji TEXT NOT NULL,
        video_url TEXT NOT NULL,
        is_downloaded INTEGER DEFAULT 0,
        is_watched INTEGER DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE quizzes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        title_ms TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        age_group TEXT NOT NULL,
        emoji TEXT NOT NULL,
        high_score INTEGER DEFAULT 0,
        is_completed INTEGER DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quiz_id INTEGER NOT NULL,
        question TEXT NOT NULL,
        question_ms TEXT NOT NULL,
        options TEXT NOT NULL,
        options_ms TEXT NOT NULL,
        correct_index INTEGER NOT NULL,
        explanation TEXT DEFAULT '',
        FOREIGN KEY (quiz_id) REFERENCES quizzes(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE storybooks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        title_ms TEXT NOT NULL,
        description TEXT NOT NULL,
        cover_emoji TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        age_group TEXT NOT NULL,
        page_count INTEGER NOT NULL,
        is_read INTEGER DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE storybook_pages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        storybook_id INTEGER NOT NULL,
        page_number INTEGER NOT NULL,
        text TEXT NOT NULL,
        text_ms TEXT NOT NULL,
        background_emoji TEXT NOT NULL,
        background_color TEXT NOT NULL,
        FOREIGN KEY (storybook_id) REFERENCES storybooks(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE worksheets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        title_ms TEXT NOT NULL,
        subject TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        age_group TEXT NOT NULL,
        grade TEXT NOT NULL,
        emoji TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE badges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        name_ms TEXT NOT NULL,
        description TEXT NOT NULL,
        emoji TEXT NOT NULL,
        requirement TEXT NOT NULL,
        required_count INTEGER NOT NULL,
        is_earned INTEGER DEFAULT 0,
        earned_date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL DEFAULT 'Explorer',
        avatar_emoji TEXT NOT NULL DEFAULT '🦁',
        total_stars INTEGER DEFAULT 0,
        videos_watched INTEGER DEFAULT 0,
        quizzes_completed INTEGER DEFAULT 0,
        stories_read INTEGER DEFAULT 0,
        worksheets_done INTEGER DEFAULT 0,
        streak_days INTEGER DEFAULT 0,
        last_active TEXT
      )
    ''');

    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    // Insert categories
    final categoryIds = <int>[];
    final categories = [
      {'name': 'Animals', 'name_ms': 'Haiwan', 'icon': '🦁', 'color_index': 0, 'age_group': 'all'},
      {'name': 'Numbers', 'name_ms': 'Nombor', 'icon': '🔢', 'color_index': 1, 'age_group': 'all'},
      {'name': 'Colors', 'name_ms': 'Warna', 'icon': '🎨', 'color_index': 2, 'age_group': 'preschool'},
      {'name': 'Science', 'name_ms': 'Sains', 'icon': '🔬', 'color_index': 3, 'age_group': 'primary'},
      {'name': 'Language', 'name_ms': 'Bahasa', 'icon': '📚', 'color_index': 4, 'age_group': 'all'},
      {'name': 'Arts & Craft', 'name_ms': 'Seni', 'icon': '✂️', 'color_index': 5, 'age_group': 'all'},
      {'name': 'Math', 'name_ms': 'Matematik', 'icon': '➕', 'color_index': 6, 'age_group': 'primary'},
      {'name': 'Music', 'name_ms': 'Muzik', 'icon': '🎵', 'color_index': 7, 'age_group': 'all'},
    ];

    for (final cat in categories) {
      final id = await db.insert('categories', cat);
      categoryIds.add(id);
    }

    // Insert videos
    final videoData = [
      {'title': 'Farm Animals Song', 'title_ms': 'Lagu Haiwan Ladang', 'description': 'Learn about farm animals through a fun song!', 'category_id': categoryIds[0], 'age_group': 'preschool', 'duration': '3:45', 'thumbnail_emoji': '🐄', 'video_url': 'https://www.youtube.com/watch?v=example1', 'is_downloaded': 0, 'is_watched': 0},
      {'title': 'Wild Animals Adventure', 'title_ms': 'Pengembaraan Haiwan Liar', 'description': 'Discover amazing wild animals from around the world!', 'category_id': categoryIds[0], 'age_group': 'primary', 'duration': '5:20', 'thumbnail_emoji': '🦊', 'video_url': 'https://www.youtube.com/watch?v=example2', 'is_downloaded': 0, 'is_watched': 0},
      {'title': 'Count to 20 with Robots', 'title_ms': 'Kira hingga 20 dengan Robot', 'description': 'Count from 1 to 20 with our friendly robot friends!', 'category_id': categoryIds[1], 'age_group': 'preschool', 'duration': '4:10', 'thumbnail_emoji': '🤖', 'video_url': 'https://www.youtube.com/watch?v=example3', 'is_downloaded': 0, 'is_watched': 0},
      {'title': 'Rainbow Colors Magic', 'title_ms': 'Sihir Warna Pelangi', 'description': 'Explore all the colors of the rainbow!', 'category_id': categoryIds[2], 'age_group': 'preschool', 'duration': '3:30', 'thumbnail_emoji': '🌈', 'video_url': 'https://www.youtube.com/watch?v=example4', 'is_downloaded': 0, 'is_watched': 0},
      {'title': 'Solar System Adventure', 'title_ms': 'Pengembaraan Sistem Solar', 'description': 'Travel through our amazing solar system!', 'category_id': categoryIds[3], 'age_group': 'primary', 'duration': '6:15', 'thumbnail_emoji': '🚀', 'video_url': 'https://www.youtube.com/watch?v=example5', 'is_downloaded': 0, 'is_watched': 0},
      {'title': 'ABC Song Fun', 'title_ms': 'Lagu ABC yang Seronok', 'description': 'Learn the alphabet with a catchy song!', 'category_id': categoryIds[4], 'age_group': 'preschool', 'duration': '2:50', 'thumbnail_emoji': '🔤', 'video_url': 'https://www.youtube.com/watch?v=example6', 'is_downloaded': 0, 'is_watched': 0},
      {'title': 'Origami for Kids', 'title_ms': 'Origami untuk Kanak-kanak', 'description': 'Make fun origami shapes step by step!', 'category_id': categoryIds[5], 'age_group': 'all', 'duration': '7:00', 'thumbnail_emoji': '🦢', 'video_url': 'https://www.youtube.com/watch?v=example7', 'is_downloaded': 0, 'is_watched': 0},
      {'title': 'Addition is Easy!', 'title_ms': 'Tambah itu Mudah!', 'description': 'Learn addition with fun examples and tricks!', 'category_id': categoryIds[6], 'age_group': 'primary', 'duration': '4:45', 'thumbnail_emoji': '🍎', 'video_url': 'https://www.youtube.com/watch?v=example8', 'is_downloaded': 0, 'is_watched': 0},
      {'title': 'Do Re Mi Song', 'title_ms': 'Lagu Do Re Mi', 'description': 'Learn music notes with this classic song!', 'category_id': categoryIds[7], 'age_group': 'all', 'duration': '3:20', 'thumbnail_emoji': '🎶', 'video_url': 'https://www.youtube.com/watch?v=example9', 'is_downloaded': 0, 'is_watched': 0},
      {'title': 'Ocean Animals', 'title_ms': 'Haiwan Lautan', 'description': 'Dive deep and meet amazing sea creatures!', 'category_id': categoryIds[0], 'age_group': 'all', 'duration': '5:00', 'thumbnail_emoji': '🐠', 'video_url': 'https://www.youtube.com/watch?v=example10', 'is_downloaded': 0, 'is_watched': 0},
      {'title': 'Shapes All Around', 'title_ms': 'Bentuk di Sekeliling Kita', 'description': 'Discover shapes hiding everywhere around us!', 'category_id': categoryIds[1], 'age_group': 'preschool', 'duration': '3:55', 'thumbnail_emoji': '⭐', 'video_url': 'https://www.youtube.com/watch?v=example11', 'is_downloaded': 0, 'is_watched': 0},
      {'title': 'Plant Life Cycle', 'title_ms': 'Kitaran Hidup Tumbuhan', 'description': 'Watch how a tiny seed grows into a big plant!', 'category_id': categoryIds[3], 'age_group': 'primary', 'duration': '5:30', 'thumbnail_emoji': '🌱', 'video_url': 'https://www.youtube.com/watch?v=example12', 'is_downloaded': 0, 'is_watched': 0},
    ];

    for (final v in videoData) {
      await db.insert('videos', v);
    }

    // Insert quizzes
    final quiz1Id = await db.insert('quizzes', {
      'title': 'Animal Kingdom Quiz',
      'title_ms': 'Kuiz Alam Haiwan',
      'category_id': categoryIds[0],
      'age_group': 'all',
      'emoji': '🦁',
      'high_score': 0,
      'is_completed': 0,
    });

    final quiz2Id = await db.insert('quizzes', {
      'title': 'Math Magic Quiz',
      'title_ms': 'Kuiz Sihir Matematik',
      'category_id': categoryIds[6],
      'age_group': 'primary',
      'emoji': '🔢',
      'high_score': 0,
      'is_completed': 0,
    });

    final quiz3Id = await db.insert('quizzes', {
      'title': 'Colors & Shapes',
      'title_ms': 'Warna & Bentuk',
      'category_id': categoryIds[2],
      'age_group': 'preschool',
      'emoji': '🎨',
      'high_score': 0,
      'is_completed': 0,
    });

    final quiz4Id = await db.insert('quizzes', {
      'title': 'Space Explorer Quiz',
      'title_ms': 'Kuiz Penjelajah Angkasa',
      'category_id': categoryIds[3],
      'age_group': 'primary',
      'emoji': '🚀',
      'high_score': 0,
      'is_completed': 0,
    });

    // Quiz 1 questions
    final q1Questions = [
      {'quiz_id': quiz1Id, 'question': 'What sound does a lion make?', 'question_ms': 'Apakah bunyi yang dibuat singa?', 'options': 'Moo|Roar|Oink|Baa', 'options_ms': 'Moo|Raungan|Oink|Baa', 'correct_index': 1, 'explanation': 'Lions roar loudly!'},
      {'quiz_id': quiz1Id, 'question': 'Which animal has a trunk?', 'question_ms': 'Haiwan manakah yang mempunyai belalai?', 'options': 'Horse|Giraffe|Elephant|Rhino', 'options_ms': 'Kuda|Zirafah|Gajah|Badak', 'correct_index': 2, 'explanation': 'Elephants use their trunk to drink and eat!'},
      {'quiz_id': quiz1Id, 'question': 'Where do fish live?', 'question_ms': 'Di manakah ikan tinggal?', 'options': 'Trees|Water|Underground|Sky', 'options_ms': 'Pokok|Air|Bawah tanah|Langit', 'correct_index': 1, 'explanation': 'Fish breathe underwater!'},
      {'quiz_id': quiz1Id, 'question': 'How many legs does a spider have?', 'question_ms': 'Berapa kaki yang dimiliki labah-labah?', 'options': '4|6|8|10', 'options_ms': '4|6|8|10', 'correct_index': 2, 'explanation': 'Spiders have 8 legs!'},
      {'quiz_id': quiz1Id, 'question': 'Which bird cannot fly?', 'question_ms': 'Burung manakah yang tidak boleh terbang?', 'options': 'Eagle|Penguin|Parrot|Sparrow', 'options_ms': 'Helang|Penguin|Kakak Tua|Pipit', 'correct_index': 1, 'explanation': 'Penguins swim instead of flying!'},
    ];

    final q2Questions = [
      {'quiz_id': quiz2Id, 'question': 'What is 3 + 4?', 'question_ms': 'Berapa 3 + 4?', 'options': '5|6|7|8', 'options_ms': '5|6|7|8', 'correct_index': 2, 'explanation': '3 + 4 = 7'},
      {'quiz_id': quiz2Id, 'question': 'What is 10 - 3?', 'question_ms': 'Berapa 10 - 3?', 'options': '5|6|7|8', 'options_ms': '5|6|7|8', 'correct_index': 2, 'explanation': '10 - 3 = 7'},
      {'quiz_id': quiz2Id, 'question': 'What is 2 × 5?', 'question_ms': 'Berapa 2 × 5?', 'options': '7|8|9|10', 'options_ms': '7|8|9|10', 'correct_index': 3, 'explanation': '2 × 5 = 10'},
      {'quiz_id': quiz2Id, 'question': 'Which is the biggest number?', 'question_ms': 'Nombor manakah yang terbesar?', 'options': '15|9|21|18', 'options_ms': '15|9|21|18', 'correct_index': 2, 'explanation': '21 is bigger than 15, 9, and 18!'},
      {'quiz_id': quiz2Id, 'question': 'What comes after 19?', 'question_ms': 'Nombor apakah selepas 19?', 'options': '18|20|21|22', 'options_ms': '18|20|21|22', 'correct_index': 1, 'explanation': '20 comes after 19!'},
    ];

    final q3Questions = [
      {'quiz_id': quiz3Id, 'question': 'What color is the sky?', 'question_ms': 'Apakah warna langit?', 'options': 'Red|Green|Blue|Yellow', 'options_ms': 'Merah|Hijau|Biru|Kuning', 'correct_index': 2, 'explanation': 'The sky is blue!'},
      {'quiz_id': quiz3Id, 'question': 'What shape is a ball?', 'question_ms': 'Apakah bentuk bola?', 'options': 'Square|Circle|Triangle|Rectangle', 'options_ms': 'Segi empat|Bulat|Tiga segi|Segiempat tepat', 'correct_index': 1, 'explanation': 'A ball is round like a circle!'},
      {'quiz_id': quiz3Id, 'question': 'What color do you get mixing red and yellow?', 'question_ms': 'Warna apa yang terhasil dari merah dan kuning?', 'options': 'Purple|Green|Orange|Pink', 'options_ms': 'Ungu|Hijau|Jingga|Pink', 'correct_index': 2, 'explanation': 'Red + Yellow = Orange!'},
      {'quiz_id': quiz3Id, 'question': 'How many sides does a triangle have?', 'question_ms': 'Berapa sisi yang dimiliki segitiga?', 'options': '2|3|4|5', 'options_ms': '2|3|4|5', 'correct_index': 1, 'explanation': 'A triangle has 3 sides!'},
      {'quiz_id': quiz3Id, 'question': 'What color are leaves usually?', 'question_ms': 'Apakah warna daun biasanya?', 'options': 'Red|Blue|Green|Purple', 'options_ms': 'Merah|Biru|Hijau|Ungu', 'correct_index': 2, 'explanation': 'Most leaves are green!'},
    ];

    final q4Questions = [
      {'quiz_id': quiz4Id, 'question': 'Which planet is closest to the Sun?', 'question_ms': 'Planet manakah yang paling dekat dengan Matahari?', 'options': 'Earth|Venus|Mercury|Mars', 'options_ms': 'Bumi|Zuhrah|Utarid|Marikh', 'correct_index': 2, 'explanation': 'Mercury is the closest planet to the Sun!'},
      {'quiz_id': quiz4Id, 'question': 'How many planets are in our solar system?', 'question_ms': 'Berapa planet dalam sistem solar kita?', 'options': '7|8|9|10', 'options_ms': '7|8|9|10', 'correct_index': 1, 'explanation': 'There are 8 planets in our solar system!'},
      {'quiz_id': quiz4Id, 'question': 'What is the largest planet?', 'question_ms': 'Planet manakah yang terbesar?', 'options': 'Saturn|Jupiter|Earth|Neptune', 'options_ms': 'Zuhal|Musytari|Bumi|Neptun', 'correct_index': 1, 'explanation': 'Jupiter is the biggest planet!'},
      {'quiz_id': quiz4Id, 'question': 'What do we call the center of our solar system?', 'question_ms': 'Apakah nama pusat sistem solar kita?', 'options': 'Moon|Star|Sun|Mars', 'options_ms': 'Bulan|Bintang|Matahari|Marikh', 'correct_index': 2, 'explanation': 'The Sun is the center of our solar system!'},
      {'quiz_id': quiz4Id, 'question': 'Which planet has rings?', 'question_ms': 'Planet manakah yang mempunyai cincin?', 'options': 'Mars|Jupiter|Saturn|Venus', 'options_ms': 'Marikh|Musytari|Zuhal|Zuhrah', 'correct_index': 2, 'explanation': 'Saturn has beautiful rings!'},
    ];

    for (final q in [...q1Questions, ...q2Questions, ...q3Questions, ...q4Questions]) {
      await db.insert('quiz_questions', q);
    }

    await _seedMoreQuizzes(db);
    await _seedExtraQuestions(db);

    // Insert storybooks
    final story1Id = await db.insert('storybooks', {
      'title': 'The Little Star',
      'title_ms': 'Bintang Kecil',
      'description': 'A little star learns to shine bright!',
      'cover_emoji': '⭐',
      'category_id': categoryIds[7],
      'age_group': 'preschool',
      'page_count': 5,
      'is_read': 0,
    });

    final story2Id = await db.insert('storybooks', {
      'title': 'Raja the Brave Lion',
      'title_ms': 'Raja Singa Berani',
      'description': 'Raja the lion discovers true bravery!',
      'cover_emoji': '🦁',
      'category_id': categoryIds[0],
      'age_group': 'primary',
      'page_count': 6,
      'is_read': 0,
    });

    final story3Id = await db.insert('storybooks', {
      'title': 'The Magic Garden',
      'title_ms': 'Taman Ajaib',
      'description': 'Explore a magical garden full of wonders!',
      'cover_emoji': '🌸',
      'category_id': categoryIds[3],
      'age_group': 'all',
      'page_count': 5,
      'is_read': 0,
    });

    // Story pages
    final story1Pages = [
      {'storybook_id': story1Id, 'page_number': 1, 'text': 'High up in the sky, there was a tiny star named Bintang. 🌟\nEvery night, Bintang looked down at the Earth below.', 'text_ms': 'Tinggi di langit, ada bintang kecil bernama Bintang. 🌟\nSetiap malam, Bintang melihat ke bawah ke Bumi.', 'background_emoji': '🌙', 'background_color': '#1a1a3e'},
      {'storybook_id': story1Id, 'page_number': 2, 'text': '"I wish I could shine brighter," said Bintang sadly.\nAll the other stars seemed so much more brilliant.', 'text_ms': '"Saya ingin bersinar lebih terang," kata Bintang sedih.\nSemua bintang lain kelihatan lebih bersinar.', 'background_emoji': '✨', 'background_color': '#2d2d6e'},
      {'storybook_id': story1Id, 'page_number': 3, 'text': 'One night, a little child looked up and said,\n"That little star is my favorite! It makes me feel safe." ⭐', 'text_ms': 'Satu malam, seorang kanak-kanak melihat ke atas dan berkata,\n"Bintang kecil itu yang saya suka! Ia buat saya rasa selamat." ⭐', 'background_emoji': '🏠', 'background_color': '#3d3d8e'},
      {'storybook_id': story1Id, 'page_number': 4, 'text': 'Bintang heard this and felt warm inside.\nMaybe being small wasn\'t so bad after all! 💫', 'text_ms': 'Bintang mendengar ini dan rasa hangat di dalam hati.\nMungkin menjadi kecil tidak begitu buruk! 💫', 'background_emoji': '💛', 'background_color': '#4d4dae'},
      {'storybook_id': story1Id, 'page_number': 5, 'text': 'From that night on, Bintang shone with all its heart.\nBecause the biggest shine comes from love! 🌟✨🌟', 'text_ms': 'Dari malam itu, Bintang bersinar dengan sepenuh hati.\nKerana cahaya terbesar datang dari kasih sayang! 🌟✨🌟', 'background_emoji': '🌠', 'background_color': '#5d5dce'},
    ];

    final story2Pages = [
      {'storybook_id': story2Id, 'page_number': 1, 'text': 'In the green jungle, there lived a young lion named Raja. 🦁\nAll the animals said he was the bravest of all!', 'text_ms': 'Di hutan hijau, ada seekor singa muda bernama Raja. 🦁\nSemua haiwan berkata dia adalah yang paling berani!', 'background_emoji': '🌿', 'background_color': '#1a4a1a'},
      {'storybook_id': story2Id, 'page_number': 2, 'text': 'But one day, Raja came to a big dark cave.\nInside, he could hear strange sounds. He was scared! 😰', 'text_ms': 'Tapi satu hari, Raja tiba di gua gelap yang besar.\nDi dalam, dia boleh dengar bunyi pelik. Dia takut! 😰', 'background_emoji': '🕳️', 'background_color': '#2a5a2a'},
      {'storybook_id': story2Id, 'page_number': 3, 'text': '"Real bravery is not the absence of fear," said wise Elephant.\n"Bravery is doing what is right even when you are scared!" 🐘', 'text_ms': '"Keberanian sebenar bukan ketiadaan ketakutan," kata Gajah yang bijak.\n"Berani adalah melakukan yang betul walaupun kamu takut!" 🐘', 'background_emoji': '💡', 'background_color': '#3a6a3a'},
      {'storybook_id': story2Id, 'page_number': 4, 'text': 'Raja took a deep breath and entered the cave.\nInside, he found a family of lost rabbits who needed help! 🐰', 'text_ms': 'Raja mengambil nafas dalam dan masuk ke gua.\nDi dalam, dia jumpa keluarga arnab yang sesat dan memerlukan bantuan! 🐰', 'background_emoji': '🐇', 'background_color': '#4a7a4a'},
      {'storybook_id': story2Id, 'page_number': 5, 'text': 'Raja led the rabbits safely out of the cave.\nAll the jungle animals cheered! 🎉', 'text_ms': 'Raja membawa arnab keluar dari gua dengan selamat.\nSemua haiwan hutan bersorak! 🎉', 'background_emoji': '🌟', 'background_color': '#5a8a5a'},
      {'storybook_id': story2Id, 'page_number': 6, 'text': 'Raja learned that true bravery means helping others.\nAnd that made him the best lion in the whole jungle! 🦁❤️', 'text_ms': 'Raja belajar bahawa keberanian sebenar bermaksud membantu orang lain.\nDan itu menjadikannya singa terbaik di seluruh hutan! 🦁❤️', 'background_emoji': '👑', 'background_color': '#6a9a6a'},
    ];

    final story3Pages = [
      {'storybook_id': story3Id, 'page_number': 1, 'text': 'Behind the old school, there was a secret garden. 🌸\nNo one knew it existed... until little Aisha found a golden key!', 'text_ms': 'Di belakang sekolah lama, ada taman rahsia. 🌸\nTiada siapa tahu ia wujud... sehingga Aisha kecil jumpa kunci emas!', 'background_emoji': '🗝️', 'background_color': '#fff0f5'},
      {'storybook_id': story3Id, 'page_number': 2, 'text': 'The garden was full of the most colorful flowers.\nButterflies and bees danced around in the warm sunshine! 🦋🐝', 'text_ms': 'Taman itu penuh dengan bunga yang paling berwarna-warni.\nKupu-kupu dan lebah menari di bawah cahaya matahari yang hangat! 🦋🐝', 'background_emoji': '🌺', 'background_color': '#f0fff0'},
      {'storybook_id': story3Id, 'page_number': 3, 'text': 'A talking sunflower said, "To grow, we need sun, water, and love!" 🌻\nAisha decided to take care of the garden every day.', 'text_ms': 'Bunga matahari yang boleh bercakap berkata, "Untuk tumbuh, kita perlu cahaya, air, dan kasih sayang!" 🌻\nAisha memutuskan untuk menjaga taman setiap hari.', 'background_emoji': '💧', 'background_color': '#f0f0ff'},
      {'storybook_id': story3Id, 'page_number': 4, 'text': 'She watered the plants every morning before school.\nSoon, new flowers began blooming everywhere! 🌷🌹🌸', 'text_ms': 'Dia menyiram tanaman setiap pagi sebelum sekolah.\nNot lama, bunga baru mula mekar di mana-mana! 🌷🌹🌸', 'background_emoji': '🌱', 'background_color': '#fffff0'},
      {'storybook_id': story3Id, 'page_number': 5, 'text': 'Aisha shared the garden\'s secret with her friends.\nTogether, they made it the most beautiful place in town! 🌍❤️🌿', 'text_ms': 'Aisha berkongsi rahsia taman dengan rakan-rakannya.\nBersama-sama, mereka menjadikannya tempat paling indah di pekan! 🌍❤️🌿', 'background_emoji': '🏡', 'background_color': '#f5fff5'},
    ];

    for (final p in [...story1Pages, ...story2Pages, ...story3Pages]) {
      await db.insert('storybook_pages', p);
    }

    // Insert worksheets
    final worksheetData = [
      {'title': 'Trace the Letters A-E', 'title_ms': 'Lukis Huruf A-E', 'subject': 'English', 'category_id': categoryIds[4], 'age_group': 'preschool', 'grade': 'Pre-school', 'emoji': '✏️', 'is_completed': 0},
      {'title': 'Count and Color 1-10', 'title_ms': 'Kira dan Warna 1-10', 'subject': 'Math', 'category_id': categoryIds[1], 'age_group': 'preschool', 'grade': 'Pre-school', 'emoji': '🖍️', 'is_completed': 0},
      {'title': 'Animal Matching Game', 'title_ms': 'Permainan Padanan Haiwan', 'subject': 'Science', 'category_id': categoryIds[0], 'age_group': 'all', 'grade': 'Year 1', 'emoji': '🦓', 'is_completed': 0},
      {'title': 'Addition Worksheet 1-20', 'title_ms': 'Lembaran Tambah 1-20', 'subject': 'Math', 'category_id': categoryIds[6], 'age_group': 'primary', 'grade': 'Year 1', 'emoji': '➕', 'is_completed': 0},
      {'title': 'Color the Rainbow', 'title_ms': 'Warnakan Pelangi', 'subject': 'Art', 'category_id': categoryIds[2], 'age_group': 'preschool', 'grade': 'Pre-school', 'emoji': '🌈', 'is_completed': 0},
      {'title': 'Sentence Building', 'title_ms': 'Bina Ayat', 'subject': 'English', 'category_id': categoryIds[4], 'age_group': 'primary', 'grade': 'Year 2', 'emoji': '📝', 'is_completed': 0},
      {'title': 'Multiplication Table 2', 'title_ms': 'Sifir 2', 'subject': 'Math', 'category_id': categoryIds[6], 'age_group': 'primary', 'grade': 'Year 3', 'emoji': '✖️', 'is_completed': 0},
      {'title': 'Draw My Favourite Animal', 'title_ms': 'Lukis Haiwan Kegemaran', 'subject': 'Art', 'category_id': categoryIds[5], 'age_group': 'all', 'grade': 'All', 'emoji': '🎨', 'is_completed': 0},
      {'title': 'Plant Parts Label', 'title_ms': 'Label Bahagian Tumbuhan', 'subject': 'Science', 'category_id': categoryIds[3], 'age_group': 'primary', 'grade': 'Year 2', 'emoji': '🌿', 'is_completed': 0},
      {'title': 'Bahasa Malaysia: Kata Nama', 'title_ms': 'Bahasa Malaysia: Kata Nama', 'subject': 'Bahasa Malaysia', 'category_id': categoryIds[4], 'age_group': 'primary', 'grade': 'Year 1', 'emoji': '📖', 'is_completed': 0},
    ];

    for (final w in worksheetData) {
      await db.insert('worksheets', w);
    }

    // Insert badges
    final badgeData = [
      {'name': 'First Star', 'name_ms': 'Bintang Pertama', 'description': 'Complete your first quiz!', 'emoji': '⭐', 'requirement': 'quizzes', 'required_count': 1, 'is_earned': 0},
      {'name': 'Video Fan', 'name_ms': 'Peminat Video', 'description': 'Watch 5 videos!', 'emoji': '📺', 'requirement': 'videos', 'required_count': 5, 'is_earned': 0},
      {'name': 'Bookworm', 'name_ms': 'Kutu Buku', 'description': 'Read 3 storybooks!', 'emoji': '📚', 'requirement': 'stories', 'required_count': 3, 'is_earned': 0},
      {'name': 'Quiz Champion', 'name_ms': 'Juara Kuiz', 'description': 'Get 100% in any quiz!', 'emoji': '🏆', 'requirement': 'perfect', 'required_count': 1, 'is_earned': 0},
      {'name': 'Super Learner', 'name_ms': 'Pelajar Super', 'description': 'Complete 10 worksheets!', 'emoji': '🎓', 'requirement': 'worksheets', 'required_count': 10, 'is_earned': 0},
      {'name': 'Explorer', 'name_ms': 'Penjelajah', 'description': 'Try all 4 categories!', 'emoji': '🗺️', 'requirement': 'categories', 'required_count': 4, 'is_earned': 0},
    ];

    for (final b in badgeData) {
      await db.insert('badges', b);
    }

    // Insert default user profile
    await db.insert('user_profile', {
      'id': 1,
      'name': 'Explorer',
      'avatar_emoji': '🦁',
      'total_stars': 0,
      'videos_watched': 0,
      'quizzes_completed': 0,
      'stories_read': 0,
      'worksheets_done': 0,
      'streak_days': 1,
      'last_active': DateTime.now().toIso8601String(),
    });
  }

  // ==================== CATEGORIES ====================
  Future<List<CategoryModel>> getCategories() async {
    final db = await database;
    final result = await db.query('categories');
    return result.map((m) => CategoryModel.fromMap(m)).toList();
  }

  // ==================== VIDEOS ====================
  Future<List<VideoModel>> getVideos({int? categoryId}) async {
    final db = await database;
    final result = categoryId != null
        ? await db.query('videos', where: 'category_id = ?', whereArgs: [categoryId])
        : await db.query('videos');
    return result.map((m) => VideoModel.fromMap(m)).toList();
  }

  Future<void> markVideoWatched(int id) async {
    final db = await database;
    await db.update('videos', {'is_watched': 1}, where: 'id = ?', whereArgs: [id]);
    await db.rawUpdate('UPDATE user_profile SET videos_watched = videos_watched + 1 WHERE id = 1');
  }

  // ==================== QUIZZES ====================
  Future<List<QuizModel>> getQuizzes({int? categoryId}) async {
    final db = await database;
    final result = categoryId != null
        ? await db.query('quizzes', where: 'category_id = ?', whereArgs: [categoryId])
        : await db.query('quizzes');
    return result.map((m) => QuizModel.fromMap(m)).toList();
  }

  Future<List<QuizQuestion>> getQuizQuestions(int quizId) async {
    final db = await database;
    final result = await db.query('quiz_questions', where: 'quiz_id = ?', whereArgs: [quizId]);
    return result.map((m) => QuizQuestion.fromMap(m)).toList();
  }

  Future<void> saveQuizScore(int quizId, int score) async {
    final db = await database;
    final quiz = await db.query('quizzes', where: 'id = ?', whereArgs: [quizId]);
    if (quiz.isNotEmpty) {
      final currentHigh = quiz.first['high_score'] as int;
      if (score > currentHigh) {
        await db.update('quizzes', {'high_score': score, 'is_completed': 1},
            where: 'id = ?', whereArgs: [quizId]);
      } else {
        await db.update('quizzes', {'is_completed': 1}, where: 'id = ?', whereArgs: [quizId]);
      }
    }
    await db.rawUpdate(
        'UPDATE user_profile SET quizzes_completed = quizzes_completed + 1, total_stars = total_stars + ? WHERE id = 1',
        [score]);
  }

  // ==================== STORYBOOKS ====================
  Future<List<StorybookModel>> getStorybooks({int? categoryId}) async {
    final db = await database;
    final result = categoryId != null
        ? await db.query('storybooks', where: 'category_id = ?', whereArgs: [categoryId])
        : await db.query('storybooks');
    return result.map((m) => StorybookModel.fromMap(m)).toList();
  }

  Future<List<StorybookPage>> getStorybookPages(int storybookId) async {
    final db = await database;
    final result = await db.query('storybook_pages',
        where: 'storybook_id = ?', whereArgs: [storybookId], orderBy: 'page_number');
    return result.map((m) => StorybookPage.fromMap(m)).toList();
  }

  Future<void> markStorybookRead(int id) async {
    final db = await database;
    await db.update('storybooks', {'is_read': 1}, where: 'id = ?', whereArgs: [id]);
    await db.rawUpdate('UPDATE user_profile SET stories_read = stories_read + 1, total_stars = total_stars + 2 WHERE id = 1');
  }

  // ==================== WORKSHEETS ====================
  Future<List<WorksheetModel>> getWorksheets({int? categoryId}) async {
    final db = await database;
    final result = categoryId != null
        ? await db.query('worksheets', where: 'category_id = ?', whereArgs: [categoryId])
        : await db.query('worksheets');
    return result.map((m) => WorksheetModel.fromMap(m)).toList();
  }

  Future<void> markWorksheetDone(int id) async {
    final db = await database;
    await db.update('worksheets', {'is_completed': 1}, where: 'id = ?', whereArgs: [id]);
    await db.rawUpdate('UPDATE user_profile SET worksheets_done = worksheets_done + 1, total_stars = total_stars + 1 WHERE id = 1');
  }

  // ==================== BADGES ====================
  Future<List<BadgeModel>> getBadges() async {
    final db = await database;
    final result = await db.query('badges');
    return result.map((m) => BadgeModel.fromMap(m)).toList();
  }

  // ==================== USER PROFILE ====================
  Future<Map<String, dynamic>?> getUserProfile() async {
    final db = await database;
    final result = await db.query('user_profile', where: 'id = ?', whereArgs: [1]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> updateUserProfile(String name, String avatarEmoji) async {
    final db = await database;
    await db.update('user_profile', {'name': name, 'avatar_emoji': avatarEmoji},
        where: 'id = ?', whereArgs: [1]);
  }

  Future<void> _seedExtraQuestions(Database db) async {
    final quizRows = await db.query('quizzes', orderBy: 'id ASC');
    for (final quiz in quizRows) {
      final qId = quiz['id'] as int;
      final title = quiz['title'] as String;
      final count = (await db.rawQuery(
              'SELECT COUNT(*) as c FROM quiz_questions WHERE quiz_id = ?', [qId]))
          .first['c'] as int;
      if (count >= 10) continue;
      final extras = _extraQFor(qId, title);
      for (final q in extras) {
        await db.insert('quiz_questions', q);
      }
    }
  }

  List<Map<String, dynamic>> _extraQFor(int id, String title) {
    // Returns 5 additional questions based on quiz title
    if (title.contains('Animal')) {
      return [
        {'quiz_id': id, 'question': 'What is a baby cat called?', 'question_ms': 'Apakah nama anak kucing?', 'options': 'Pup|Kitten|Cub|Foal', 'options_ms': 'Anak anjing|Anak kucing|Anak beruang|Anak kuda', 'correct_index': 1, 'explanation': 'A baby cat is called a kitten!'},
        {'quiz_id': id, 'question': 'Which is the fastest land animal?', 'question_ms': 'Haiwan manakah yang paling laju di darat?', 'options': 'Lion|Horse|Cheetah|Leopard', 'options_ms': 'Singa|Kuda|Cheetah|Harimau Bintang', 'correct_index': 2, 'explanation': 'Cheetahs can run up to 120 km/h!'},
        {'quiz_id': id, 'question': 'What do bees produce?', 'question_ms': 'Apa yang dihasilkan lebah?', 'options': 'Milk|Honey|Wax only|Juice', 'options_ms': 'Susu|Madu|Lilin sahaja|Jus', 'correct_index': 1, 'explanation': 'Bees make delicious honey!'},
        {'quiz_id': id, 'question': 'Which animal has black and white stripes?', 'question_ms': 'Haiwan manakah yang mempunyai jalur hitam dan putih?', 'options': 'Tiger|Cheetah|Zebra|Panda', 'options_ms': 'Harimau|Cheetah|Zebra|Panda', 'correct_index': 2, 'explanation': 'Zebras have black and white stripes!'},
        {'quiz_id': id, 'question': 'How many legs does a crab have?', 'question_ms': 'Berapa kaki yang dimiliki ketam?', 'options': '6|8|10|12', 'options_ms': '6|8|10|12', 'correct_index': 2, 'explanation': 'Crabs have 10 legs!'},
      ];
    }
    if (title.contains('Math')) {
      return [
        {'quiz_id': id, 'question': 'What is 5 + 5?', 'question_ms': 'Berapa 5 + 5?', 'options': '8|9|10|11', 'options_ms': '8|9|10|11', 'correct_index': 2, 'explanation': '5 + 5 = 10!'},
        {'quiz_id': id, 'question': 'What is 15 - 6?', 'question_ms': 'Berapa 15 - 6?', 'options': '7|8|9|10', 'options_ms': '7|8|9|10', 'correct_index': 2, 'explanation': '15 - 6 = 9!'},
        {'quiz_id': id, 'question': 'What is 3 × 3?', 'question_ms': 'Berapa 3 × 3?', 'options': '6|7|8|9', 'options_ms': '6|7|8|9', 'correct_index': 3, 'explanation': '3 × 3 = 9!'},
        {'quiz_id': id, 'question': 'What is half of 10?', 'question_ms': 'Berapa separuh daripada 10?', 'options': '3|4|5|6', 'options_ms': '3|4|5|6', 'correct_index': 2, 'explanation': 'Half of 10 is 5!'},
        {'quiz_id': id, 'question': 'What is 20 ÷ 4?', 'question_ms': 'Berapa 20 ÷ 4?', 'options': '4|5|6|7', 'options_ms': '4|5|6|7', 'correct_index': 1, 'explanation': '20 ÷ 4 = 5!'},
      ];
    }
    if (title.contains('Colors') || title.contains('Colours')) {
      return [
        {'quiz_id': id, 'question': 'What colour do you get mixing blue and yellow?', 'question_ms': 'Warna apa yang terhasil dari biru dan kuning?', 'options': 'Green|Orange|Purple|Red', 'options_ms': 'Hijau|Jingga|Ungu|Merah', 'correct_index': 0, 'explanation': 'Blue + Yellow = Green!'},
        {'quiz_id': id, 'question': 'How many sides does a square have?', 'question_ms': 'Berapa sisi yang dimiliki segi empat?', 'options': '3|4|5|6', 'options_ms': '3|4|5|6', 'correct_index': 1, 'explanation': 'A square has 4 equal sides!'},
        {'quiz_id': id, 'question': 'What shape is a pizza?', 'question_ms': 'Apakah bentuk pizza?', 'options': 'Square|Triangle|Circle|Rectangle', 'options_ms': 'Segi empat|Segi tiga|Bulat|Segiempat tepat', 'correct_index': 2, 'explanation': 'A pizza is round — a circle!'},
        {'quiz_id': id, 'question': 'What colour is the grass?', 'question_ms': 'Apakah warna rumput?', 'options': 'Yellow|Blue|Green|Red', 'options_ms': 'Kuning|Biru|Hijau|Merah', 'correct_index': 2, 'explanation': 'Grass is green!'},
        {'quiz_id': id, 'question': 'How many sides does a rectangle have?', 'question_ms': 'Berapa sisi segiempat tepat?', 'options': '3|4|5|6', 'options_ms': '3|4|5|6', 'correct_index': 1, 'explanation': 'A rectangle has 4 sides!'},
      ];
    }
    if (title.contains('Space')) {
      return [
        {'quiz_id': id, 'question': 'How long does Earth take to orbit the Sun?', 'question_ms': 'Berapa lama Bumi mengelilingi Matahari?', 'options': '1 week|1 month|1 year|10 years', 'options_ms': '1 minggu|1 bulan|1 tahun|10 tahun', 'correct_index': 2, 'explanation': 'Earth takes 1 year to go around the Sun!'},
        {'quiz_id': id, 'question': 'What is a shooting star really?', 'question_ms': 'Apakah sebenarnya bintang jatuh?', 'options': 'A star|A meteor|A planet|A comet', 'options_ms': 'Bintang|Meteor|Planet|Komet', 'correct_index': 1, 'explanation': 'Shooting stars are actually meteors burning up!'},
        {'quiz_id': id, 'question': 'Which planet is known as the Red Planet?', 'question_ms': 'Planet manakah dikenali sebagai Planet Merah?', 'options': 'Venus|Jupiter|Mars|Neptune', 'options_ms': 'Zuhrah|Musytari|Marikh|Neptun', 'correct_index': 2, 'explanation': 'Mars is called the Red Planet!'},
        {'quiz_id': id, 'question': 'What do astronauts wear in space?', 'question_ms': 'Apa yang pakai angkasawan di angkasa?', 'options': 'Normal clothes|Space suit|Raincoat|Swimsuit', 'options_ms': 'Baju biasa|Baju angkasawan|Baju hujan|Baju renang', 'correct_index': 1, 'explanation': 'Astronauts wear space suits to survive!'},
        {'quiz_id': id, 'question': 'What is the name of Earth\'s natural satellite?', 'question_ms': 'Apakah nama satelit semula jadi Bumi?', 'options': 'Sun|Star|Moon|Mars', 'options_ms': 'Matahari|Bintang|Bulan|Marikh', 'correct_index': 2, 'explanation': 'The Moon is Earth\'s natural satellite!'},
      ];
    }
    if (title.contains('Bahasa')) {
      return [
        {'quiz_id': id, 'question': 'Apakah maksud "Sekolah"?', 'question_ms': 'Apakah maksud "Sekolah"?', 'options': 'Home|Library|School|Park', 'options_ms': 'Rumah|Perpustakaan|Sekolah|Taman', 'correct_index': 2, 'explanation': 'Sekolah = School!'},
        {'quiz_id': id, 'question': 'Manakah kata adjektif (sifat)?', 'question_ms': 'Manakah kata adjektif?', 'options': 'Meja|Cantik|Berlari|Buku', 'options_ms': 'Meja|Cantik|Berlari|Buku', 'correct_index': 1, 'explanation': 'Cantik (beautiful) adalah kata adjektif!'},
        {'quiz_id': id, 'question': 'Apakah "Air" dalam Bahasa Inggeris?', 'question_ms': 'Apakah "Air" dalam Bahasa Inggeris?', 'options': 'Fire|Earth|Water|Wind', 'options_ms': 'Api|Tanah|Air|Angin', 'correct_index': 2, 'explanation': 'Air = Water!'},
        {'quiz_id': id, 'question': 'Manakah kata ganti nama diri?', 'question_ms': 'Manakah kata ganti nama diri?', 'options': 'Aku|Meja|Lari|Pokok', 'options_ms': 'Aku|Meja|Lari|Pokok', 'correct_index': 0, 'explanation': 'Aku adalah kata ganti nama diri!'},
        {'quiz_id': id, 'question': 'Apakah maksud "Terima kasih"?', 'question_ms': 'Apakah maksud "Terima kasih"?', 'options': 'Sorry|Hello|Thank you|Goodbye', 'options_ms': 'Maaf|Helo|Terima kasih|Selamat tinggal', 'correct_index': 2, 'explanation': 'Terima kasih = Thank you!'},
      ];
    }
    if (title.contains('English')) {
      return [
        {'quiz_id': id, 'question': 'Which word is an adjective?', 'question_ms': 'Perkataan manakah kata adjektif?', 'options': 'Run|Beautiful|Eat|Jump', 'options_ms': 'Berlari|Cantik|Makan|Lompat', 'correct_index': 1, 'explanation': 'Beautiful describes something — it\'s an adjective!'},
        {'quiz_id': id, 'question': 'What is the opposite of "big"?', 'question_ms': 'Apakah antonim "big"?', 'options': 'Tall|Small|Heavy|Long', 'options_ms': 'Tinggi|Kecil|Berat|Panjang', 'correct_index': 1, 'explanation': 'Big ↔ Small!'},
        {'quiz_id': id, 'question': 'Which sentence is correct?', 'question_ms': 'Ayat manakah betul?', 'options': 'I has a book|I have a book|I haves a book|I having a book', 'options_ms': 'I has a book|I have a book|I haves a book|I having a book', 'correct_index': 1, 'explanation': '"I have" is correct!'},
        {'quiz_id': id, 'question': 'What is the past tense of "run"?', 'question_ms': 'Apakah kata lampau "run"?', 'options': 'Runned|Runs|Ran|Running', 'options_ms': 'Runned|Runs|Ran|Running', 'correct_index': 2, 'explanation': 'The past tense of run is ran!'},
        {'quiz_id': id, 'question': 'Which word is a pronoun?', 'question_ms': 'Perkataan manakah kata ganti nama?', 'options': 'Table|She|Beautiful|Jump', 'options_ms': 'Meja|Dia (perempuan)|Cantik|Lompat', 'correct_index': 1, 'explanation': '"She" is a pronoun!'},
      ];
    }
    if (title.contains('Living')) {
      return [
        {'quiz_id': id, 'question': 'Which of these is NOT a living thing?', 'question_ms': 'Manakah BUKAN benda hidup?', 'options': 'Stone|Butterfly|Mushroom|Grass', 'options_ms': 'Batu|Kupu-kupu|Cendawan|Rumput', 'correct_index': 0, 'explanation': 'Stones are not living — they don\'t grow or breathe!'},
        {'quiz_id': id, 'question': 'What do animals need to survive?', 'question_ms': 'Apa yang diperlukan haiwan untuk hidup?', 'options': 'Food only|Water only|Food, water & air|Sunlight only', 'options_ms': 'Makanan sahaja|Air sahaja|Makanan, air & udara|Cahaya sahaja', 'correct_index': 2, 'explanation': 'Animals need food, water and air!'},
        {'quiz_id': id, 'question': 'Which insect makes honey?', 'question_ms': 'Serangga manakah yang menghasilkan madu?', 'options': 'Ant|Butterfly|Bee|Mosquito', 'options_ms': 'Semut|Kupu-kupu|Lebah|Nyamuk', 'correct_index': 2, 'explanation': 'Bees make honey!'},
        {'quiz_id': id, 'question': 'What process do plants use to make food?', 'question_ms': 'Proses apakah yang digunakan tumbuhan untuk membuat makanan?', 'options': 'Digestion|Photosynthesis|Respiration|Absorption', 'options_ms': 'Penghadaman|Fotosintesis|Pernafasan|Penyerapan', 'correct_index': 1, 'explanation': 'Plants make food through photosynthesis!'},
        {'quiz_id': id, 'question': 'Which of these is a mammal?', 'question_ms': 'Manakah mamalia?', 'options': 'Eagle|Crocodile|Whale|Snake', 'options_ms': 'Helang|Buaya|Ikan Paus|Ular', 'correct_index': 2, 'explanation': 'Whales are mammals — they breathe air!'},
      ];
    }
    if (title.contains('Human') || title.contains('Body')) {
      return [
        {'quiz_id': id, 'question': 'How many bones does an adult human have?', 'question_ms': 'Berapa tulang yang dimiliki manusia dewasa?', 'options': '106|156|206|306', 'options_ms': '106|156|206|306', 'correct_index': 2, 'explanation': 'Adults have 206 bones!'},
        {'quiz_id': id, 'question': 'Which organ do we use to breathe?', 'question_ms': 'Organ manakah yang kita gunakan untuk bernafas?', 'options': 'Heart|Lungs|Stomach|Brain', 'options_ms': 'Jantung|Paru-paru|Perut|Otak', 'correct_index': 1, 'explanation': 'We breathe using our lungs!'},
        {'quiz_id': id, 'question': 'Which food is good for your bones?', 'question_ms': 'Makanan manakah baik untuk tulang?', 'options': 'Soda|Candy|Milk|Chips', 'options_ms': 'Soda|Gula-gula|Susu|Kerepek', 'correct_index': 2, 'explanation': 'Milk has calcium which makes bones strong!'},
        {'quiz_id': id, 'question': 'What carries oxygen around the body?', 'question_ms': 'Apakah yang membawa oksigen ke seluruh badan?', 'options': 'Water|Blood|Air|Saliva', 'options_ms': 'Air|Darah|Udara|Air liur', 'correct_index': 1, 'explanation': 'Blood carries oxygen everywhere!'},
        {'quiz_id': id, 'question': 'How many teeth does an adult normally have?', 'question_ms': 'Berapa gigi yang dimiliki orang dewasa?', 'options': '24|28|32|36', 'options_ms': '24|28|32|36', 'correct_index': 2, 'explanation': 'Adults normally have 32 teeth!'},
      ];
    }
    if (title.contains('Fruit') || title.contains('Food')) {
      return [
        {'quiz_id': id, 'question': 'What colour is a lemon?', 'question_ms': 'Apakah warna lemon?', 'options': 'Red|Blue|Yellow|Green', 'options_ms': 'Merah|Biru|Kuning|Hijau', 'correct_index': 2, 'explanation': 'Lemons are bright yellow!'},
        {'quiz_id': id, 'question': 'Which vegetable is orange in colour?', 'question_ms': 'Sayur manakah berwarna jingga?', 'options': 'Broccoli|Carrot|Cabbage|Spinach', 'options_ms': 'Brokoli|Lobak merah|Kobis|Bayam', 'correct_index': 1, 'explanation': 'Carrots are orange!'},
        {'quiz_id': id, 'question': 'Which drink comes from cows?', 'question_ms': 'Minuman manakah yang datang daripada lembu?', 'options': 'Water|Juice|Milk|Tea', 'options_ms': 'Air|Jus|Susu|Teh', 'correct_index': 2, 'explanation': 'Milk comes from cows!'},
        {'quiz_id': id, 'question': 'Which fruit has a hard shell and white inside?', 'question_ms': 'Buah manakah mempunyai kulit keras dan isi putih?', 'options': 'Mango|Orange|Coconut|Grape', 'options_ms': 'Mangga|Oren|Kelapa|Anggur', 'correct_index': 2, 'explanation': 'Coconuts have a hard shell and white flesh inside!'},
        {'quiz_id': id, 'question': 'What colour is a ripe mango?', 'question_ms': 'Apakah warna mangga yang masak?', 'options': 'Blue|Purple|Yellow-orange|Green', 'options_ms': 'Biru|Ungu|Kuning-jingga|Hijau', 'correct_index': 2, 'explanation': 'Ripe mangoes are yellow-orange!'},
      ];
    }
    if (title.contains('Music')) {
      return [
        {'quiz_id': id, 'question': 'How many strings does a standard guitar have?', 'question_ms': 'Berapa tali pada gitar standard?', 'options': '4|5|6|7', 'options_ms': '4|5|6|7', 'correct_index': 2, 'explanation': 'A guitar has 6 strings!'},
        {'quiz_id': id, 'question': 'What does "tempo" mean in music?', 'question_ms': 'Apakah maksud "tempo" dalam muzik?', 'options': 'Volume|Speed|Pitch|Rhythm', 'options_ms': 'Kelantangan|Kelajuan|Pic|Irama', 'correct_index': 1, 'explanation': 'Tempo means the speed of the music!'},
        {'quiz_id': id, 'question': 'Which instrument has strings you pluck?', 'question_ms': 'Alat muzik manakah mempunyai tali yang dicabut?', 'options': 'Trumpet|Flute|Harp|Drum', 'options_ms': 'Trompet|Seruling|Harpa|Dram', 'correct_index': 2, 'explanation': 'You pluck the strings of a harp!'},
        {'quiz_id': id, 'question': 'How many keys does a standard piano have?', 'question_ms': 'Berapa kekunci piano standard?', 'options': '68|76|88|92', 'options_ms': '68|76|88|92', 'correct_index': 2, 'explanation': 'A standard piano has 88 keys!'},
        {'quiz_id': id, 'question': 'What do you call a group of musicians playing together?', 'question_ms': 'Apakah nama sekumpulan ahli muzik yang bermain bersama?', 'options': 'Band|Team|Club|Squad', 'options_ms': 'Kumpulan muzik|Pasukan|Kelab|Skuad', 'correct_index': 0, 'explanation': 'A group of musicians is called a band!'},
      ];
    }
    if (title.contains('Arts') || title.contains('Craft')) {
      return [
        {'quiz_id': id, 'question': 'What are the three primary colours?', 'question_ms': 'Apakah tiga warna asas?', 'options': 'Red, Blue, Yellow|Green, Blue, Red|Orange, Purple, Yellow|Pink, Black, White', 'options_ms': 'Merah, Biru, Kuning|Hijau, Biru, Merah|Jingga, Ungu, Kuning|Pink, Hitam, Putih', 'correct_index': 0, 'explanation': 'The primary colours are Red, Blue and Yellow!'},
        {'quiz_id': id, 'question': 'What type of art uses clay to make shapes?', 'question_ms': 'Jenis seni apakah yang menggunakan tanah liat?', 'options': 'Drawing|Sculpture|Painting|Printing', 'options_ms': 'Melukis|Arca|Melukis cat|Mencetak', 'correct_index': 1, 'explanation': 'Sculpture uses clay to make 3D shapes!'},
        {'quiz_id': id, 'question': 'Which famous painting shows a mysterious smiling woman?', 'question_ms': 'Lukisan terkenal manakah menunjukkan wanita senyum misteri?', 'options': 'Starry Night|Mona Lisa|Sunflowers|The Scream', 'options_ms': 'Malam Berbintang|Mona Lisa|Bunga Matahari|Jeritan', 'correct_index': 1, 'explanation': 'The Mona Lisa by Leonardo da Vinci!'},
        {'quiz_id': id, 'question': 'What do you call art made from small coloured tiles?', 'question_ms': 'Apakah nama seni yang dibuat dari jubin kecil berwarna?', 'options': 'Mosaic|Collage|Sketch|Portrait', 'options_ms': 'Mozek|Kolaj|Lakaran|Potret', 'correct_index': 0, 'explanation': 'Mosaic art is made from small coloured tiles!'},
        {'quiz_id': id, 'question': 'What is origami?', 'question_ms': 'Apakah origami?', 'options': 'Paper painting|Paper folding|Paper cutting|Paper gluing', 'options_ms': 'Melukis kertas|Melipat kertas|Memotong kertas|Melekat kertas', 'correct_index': 1, 'explanation': 'Origami is the Japanese art of paper folding!'},
      ];
    }
    if (title.contains('Weather')) {
      return [
        {'quiz_id': id, 'question': 'Which season is the coldest?', 'question_ms': 'Musim manakah yang paling sejuk?', 'options': 'Spring|Summer|Autumn|Winter', 'options_ms': 'Musim bunga|Musim panas|Musim luruh|Musim sejuk', 'correct_index': 3, 'explanation': 'Winter is the coldest season!'},
        {'quiz_id': id, 'question': 'What instrument measures temperature?', 'question_ms': 'Alat apakah yang mengukur suhu?', 'options': 'Compass|Thermometer|Ruler|Scale', 'options_ms': 'Kompas|Termometer|Pembaris|Penimbang', 'correct_index': 1, 'explanation': 'A thermometer measures temperature!'},
        {'quiz_id': id, 'question': 'At what temperature does water freeze?', 'question_ms': 'Pada suhu berapakah air membeku?', 'options': '0°C|10°C|50°C|100°C', 'options_ms': '0°C|10°C|50°C|100°C', 'correct_index': 0, 'explanation': 'Water freezes at 0°C!'},
        {'quiz_id': id, 'question': 'What do we call the layer of air around Earth?', 'question_ms': 'Apakah lapisan udara yang mengelilingi Bumi?', 'options': 'Stratosphere|Atmosphere|Ionosphere|Biosphere', 'options_ms': 'Stratosfera|Atmosfera|Ionosfera|Biosfera', 'correct_index': 1, 'explanation': 'The atmosphere surrounds our Earth!'},
        {'quiz_id': id, 'question': 'What causes lightning?', 'question_ms': 'Apakah yang menyebabkan kilat?', 'options': 'Rain|Electricity in clouds|Wind|Sunshine', 'options_ms': 'Hujan|Elektrik dalam awan|Angin|Cahaya matahari', 'correct_index': 1, 'explanation': 'Lightning is caused by electrical charges in clouds!'},
      ];
    }
    return [];
  }

  Future<void> _seedMoreQuizzes(Database db) async {
    // Get category IDs from existing data
    final cats = await db.query('categories', orderBy: 'id ASC');
    if (cats.isEmpty) return;

    // categories order: Animals[0], Numbers[1], Colors[2], Science[3], Language[4], Arts[5], Math[6], Music[7]
    final cIds = cats.map((c) => c['id'] as int).toList();

    // ---- Quiz 5: Bahasa Malaysia ----
    final q5Id = await db.insert('quizzes', {
      'title': 'Bahasa Malaysia Fun',
      'title_ms': 'Bahasa Malaysia Seronok',
      'category_id': cIds.length > 4 ? cIds[4] : cIds[0],
      'age_group': 'primary',
      'emoji': '🇲🇾',
      'high_score': 0,
      'is_completed': 0,
    });
    final q5 = [
      {'quiz_id': q5Id, 'question': 'Which is a "Kata Nama" (noun)?', 'question_ms': 'Manakah "Kata Nama"?', 'options': 'Berlari|Buku|Cantik|Cepat', 'options_ms': 'Berlari|Buku|Cantik|Cepat', 'correct_index': 1, 'explanation': 'Buku (book) is a noun!'},
      {'quiz_id': q5Id, 'question': 'What does "Merah" mean in English?', 'question_ms': 'Apakah maksud "Merah" dalam Bahasa Inggeris?', 'options': 'Blue|Green|Red|Yellow', 'options_ms': 'Biru|Hijau|Merah|Kuning', 'correct_index': 2, 'explanation': 'Merah = Red!'},
      {'quiz_id': q5Id, 'question': 'Which is a "Kata Kerja" (verb)?', 'question_ms': 'Manakah "Kata Kerja"?', 'options': 'Rumah|Bunga|Makan|Besar', 'options_ms': 'Rumah|Bunga|Makan|Besar', 'correct_index': 2, 'explanation': 'Makan (eat) is a verb!'},
      {'quiz_id': q5Id, 'question': 'How do you say "Hello" in Malay?', 'question_ms': 'Bagaimana anda berkata "Hello" dalam Bahasa Melayu?', 'options': 'Selamat tinggal|Terima kasih|Selamat datang|Apa khabar', 'options_ms': 'Selamat tinggal|Terima kasih|Selamat datang|Apa khabar', 'correct_index': 3, 'explanation': 'Apa khabar = Hello / How are you!'},
      {'quiz_id': q5Id, 'question': 'What does "Kucing" mean?', 'question_ms': 'Apakah maksud "Kucing"?', 'options': 'Dog|Bird|Cat|Fish', 'options_ms': 'Anjing|Burung|Kucing|Ikan', 'correct_index': 2, 'explanation': 'Kucing = Cat!'},
    ];

    // ---- Quiz 6: English Grammar ----
    final q6Id = await db.insert('quizzes', {
      'title': 'English Grammar',
      'title_ms': 'Tatabahasa Inggeris',
      'category_id': cIds.length > 4 ? cIds[4] : cIds[0],
      'age_group': 'primary',
      'emoji': '📝',
      'high_score': 0,
      'is_completed': 0,
    });
    final q6 = [
      {'quiz_id': q6Id, 'question': 'Which word is a noun?', 'question_ms': 'Perkataan manakah kata nama?', 'options': 'Run|Happy|Apple|Quickly', 'options_ms': 'Berlari|Gembira|Epal|Dengan cepat', 'correct_index': 2, 'explanation': 'Apple is a noun — a thing!'},
      {'quiz_id': q6Id, 'question': 'What is the plural of "cat"?', 'question_ms': 'Apakah jamak "cat"?', 'options': 'Cates|Cats|Catz|Cat', 'options_ms': 'Cates|Cats|Catz|Cat', 'correct_index': 1, 'explanation': 'cat + s = cats!'},
      {'quiz_id': q6Id, 'question': 'Which is a verb (action word)?', 'question_ms': 'Manakah kata kerja?', 'options': 'Big|Sad|Jump|Tree', 'options_ms': 'Besar|Sedih|Lompat|Pokok', 'correct_index': 2, 'explanation': 'Jump is an action — a verb!'},
      {'quiz_id': q6Id, 'question': 'What colour is the sun?', 'question_ms': 'Apakah warna matahari?', 'options': 'Blue|Green|Yellow|Purple', 'options_ms': 'Biru|Hijau|Kuning|Ungu', 'correct_index': 2, 'explanation': 'The sun is yellow!'},
      {'quiz_id': q6Id, 'question': 'How many vowels are in the alphabet?', 'question_ms': 'Berapa vokal dalam abjad?', 'options': '3|4|5|6', 'options_ms': '3|4|5|6', 'correct_index': 2, 'explanation': 'A, E, I, O, U — 5 vowels!'},
    ];

    // ---- Quiz 7: Science — Living Things ----
    final q7Id = await db.insert('quizzes', {
      'title': 'Living Things',
      'title_ms': 'Benda Hidup',
      'category_id': cIds.length > 3 ? cIds[3] : cIds[0],
      'age_group': 'primary',
      'emoji': '🌿',
      'high_score': 0,
      'is_completed': 0,
    });
    final q7 = [
      {'quiz_id': q7Id, 'question': 'Which of these is a living thing?', 'question_ms': 'Manakah benda hidup?', 'options': 'Rock|Tree|Water|Air', 'options_ms': 'Batu|Pokok|Air|Udara', 'correct_index': 1, 'explanation': 'Trees are living things — they grow!'},
      {'quiz_id': q7Id, 'question': 'What do plants need to grow?', 'question_ms': 'Apa yang diperlukan tumbuhan untuk membesar?', 'options': 'Sand only|Sunlight & water|Darkness|Ice', 'options_ms': 'Pasir sahaja|Cahaya & air|Gelap|Ais', 'correct_index': 1, 'explanation': 'Plants need sunlight and water to grow!'},
      {'quiz_id': q7Id, 'question': 'Which animal lays eggs?', 'question_ms': 'Haiwan manakah yang bertelur?', 'options': 'Dog|Cat|Hen|Cow', 'options_ms': 'Anjing|Kucing|Ayam|Lembu', 'correct_index': 2, 'explanation': 'Hens lay eggs!'},
      {'quiz_id': q7Id, 'question': 'What do we call animals that eat only plants?', 'question_ms': 'Apakah nama haiwan yang hanya makan tumbuhan?', 'options': 'Carnivore|Herbivore|Omnivore|Predator', 'options_ms': 'Karnivor|Herbivor|Omnivor|Predator', 'correct_index': 1, 'explanation': 'Herbivores eat only plants!'},
      {'quiz_id': q7Id, 'question': 'Which part of the plant makes food?', 'question_ms': 'Bahagian tumbuhan manakah yang membuat makanan?', 'options': 'Root|Stem|Leaf|Flower', 'options_ms': 'Akar|Batang|Daun|Bunga', 'correct_index': 2, 'explanation': 'Leaves make food through photosynthesis!'},
    ];

    // ---- Quiz 8: Human Body ----
    final q8Id = await db.insert('quizzes', {
      'title': 'Human Body',
      'title_ms': 'Tubuh Badan',
      'category_id': cIds.length > 3 ? cIds[3] : cIds[0],
      'age_group': 'all',
      'emoji': '🧠',
      'high_score': 0,
      'is_completed': 0,
    });
    final q8 = [
      {'quiz_id': q8Id, 'question': 'How many fingers do we have in total?', 'question_ms': 'Berapa jumlah jari kita?', 'options': '8|9|10|12', 'options_ms': '8|9|10|12', 'correct_index': 2, 'explanation': 'We have 10 fingers total!'},
      {'quiz_id': q8Id, 'question': 'Which organ pumps blood?', 'question_ms': 'Organ manakah yang mengepam darah?', 'options': 'Brain|Lung|Heart|Stomach', 'options_ms': 'Otak|Paru-paru|Jantung|Perut', 'correct_index': 2, 'explanation': 'The heart pumps blood around our body!'},
      {'quiz_id': q8Id, 'question': 'What do we use to smell?', 'question_ms': 'Apa yang kita gunakan untuk menghidu?', 'options': 'Eyes|Ears|Nose|Tongue', 'options_ms': 'Mata|Telinga|Hidung|Lidah', 'correct_index': 2, 'explanation': 'We use our nose to smell!'},
      {'quiz_id': q8Id, 'question': 'How many senses do humans have?', 'question_ms': 'Berapa deria yang dimiliki manusia?', 'options': '3|4|5|6', 'options_ms': '3|4|5|6', 'correct_index': 2, 'explanation': 'We have 5 senses: sight, hearing, smell, taste, touch!'},
      {'quiz_id': q8Id, 'question': 'What protects our brain?', 'question_ms': 'Apa yang melindungi otak kita?', 'options': 'Spine|Skull|Ribs|Skin', 'options_ms': 'Tulang belakang|Tengkorak|Tulang rusuk|Kulit', 'correct_index': 1, 'explanation': 'The skull protects our brain!'},
    ];

    // ---- Quiz 9: Fruits & Food ----
    final q9Id = await db.insert('quizzes', {
      'title': 'Fruits & Food',
      'title_ms': 'Buah-buahan & Makanan',
      'category_id': cIds[0],
      'age_group': 'preschool',
      'emoji': '🍎',
      'high_score': 0,
      'is_completed': 0,
    });
    final q9 = [
      {'quiz_id': q9Id, 'question': 'Which fruit is yellow and curved?', 'question_ms': 'Buah manakah berwarna kuning dan melengkung?', 'options': 'Apple|Banana|Grape|Mango', 'options_ms': 'Epal|Pisang|Anggur|Mangga', 'correct_index': 1, 'explanation': 'Bananas are yellow and curved!'},
      {'quiz_id': q9Id, 'question': 'What colour is a ripe strawberry?', 'question_ms': 'Apakah warna strawberi masak?', 'options': 'Blue|Green|Red|Yellow', 'options_ms': 'Biru|Hijau|Merah|Kuning', 'correct_index': 2, 'explanation': 'Ripe strawberries are red!'},
      {'quiz_id': q9Id, 'question': 'Which fruit grows on a palm tree?', 'question_ms': 'Buah manakah tumbuh pada pokok palma?', 'options': 'Apple|Orange|Coconut|Grape', 'options_ms': 'Epal|Oren|Kelapa|Anggur', 'correct_index': 2, 'explanation': 'Coconuts grow on palm trees!'},
      {'quiz_id': q9Id, 'question': 'Which food gives us energy to grow?', 'question_ms': 'Makanan manakah memberi tenaga untuk membesar?', 'options': 'Candy|Vegetables|Soda|Chips', 'options_ms': 'Gula-gula|Sayur-sayuran|Soda|Kerepek', 'correct_index': 1, 'explanation': 'Vegetables give us vitamins to grow strong!'},
      {'quiz_id': q9Id, 'question': 'What is the national fruit of Malaysia?', 'question_ms': 'Apakah buah kebangsaan Malaysia?', 'options': 'Mango|Rambutan|Durian|Papaya', 'options_ms': 'Mangga|Rambutan|Durian|Betik', 'correct_index': 2, 'explanation': 'Durian is the King of Fruits in Malaysia!'},
    ];

    // ---- Quiz 10: Music & Instruments ----
    final q10Id = await db.insert('quizzes', {
      'title': 'Music & Instruments',
      'title_ms': 'Muzik & Alat Muzik',
      'category_id': cIds.length > 7 ? cIds[7] : cIds[0],
      'age_group': 'all',
      'emoji': '🎸',
      'high_score': 0,
      'is_completed': 0,
    });
    final q10 = [
      {'quiz_id': q10Id, 'question': 'How many strings does a guitar have?', 'question_ms': 'Berapa tali pada gitar?', 'options': '4|5|6|7', 'options_ms': '4|5|6|7', 'correct_index': 2, 'explanation': 'A standard guitar has 6 strings!'},
      {'quiz_id': q10Id, 'question': 'Which instrument do you blow to play?', 'question_ms': 'Alat muzik manakah dimainkan dengan meniup?', 'options': 'Drum|Piano|Flute|Guitar', 'options_ms': 'Dram|Piano|Seruling|Gitar', 'correct_index': 2, 'explanation': 'You blow into a flute to play it!'},
      {'quiz_id': q10Id, 'question': 'What is the first note in "Do Re Mi"?', 'question_ms': 'Apakah nota pertama "Do Re Mi"?', 'options': 'Re|Mi|Do|Fa', 'options_ms': 'Re|Mi|Do|Fa', 'correct_index': 2, 'explanation': 'Do is the first note — Do Re Mi Fa Sol La Ti!'},
      {'quiz_id': q10Id, 'question': 'Which instrument has keys you press?', 'question_ms': 'Alat muzik manakah mempunyai kekunci yang ditekan?', 'options': 'Violin|Drum|Piano|Trumpet', 'options_ms': 'Biola|Dram|Piano|Trompet', 'correct_index': 2, 'explanation': 'Piano has black and white keys you press!'},
      {'quiz_id': q10Id, 'question': 'What do you use to hit a drum?', 'question_ms': 'Apa yang digunakan untuk memukul dram?', 'options': 'Bow|Stick|Fingers|String', 'options_ms': 'Busur|Kayu pemukul|Jari|Tali', 'correct_index': 1, 'explanation': 'Drumsticks are used to hit a drum!'},
    ];

    // ---- Quiz 11: Arts & Craft ----
    final q11Id = await db.insert('quizzes', {
      'title': 'Arts & Craft',
      'title_ms': 'Seni & Kraf',
      'category_id': cIds.length > 5 ? cIds[5] : cIds[0],
      'age_group': 'all',
      'emoji': '✂️',
      'high_score': 0,
      'is_completed': 0,
    });
    final q11 = [
      {'quiz_id': q11Id, 'question': 'What do you use to cut paper?', 'question_ms': 'Apa yang digunakan untuk memotong kertas?', 'options': 'Ruler|Pencil|Scissors|Glue', 'options_ms': 'Pembaris|Pensel|Gunting|Gam', 'correct_index': 2, 'explanation': 'Scissors are used to cut paper!'},
      {'quiz_id': q11Id, 'question': 'Mixing blue and red makes what colour?', 'question_ms': 'Mencampurkan biru dan merah menghasilkan warna apa?', 'options': 'Green|Orange|Purple|Brown', 'options_ms': 'Hijau|Jingga|Ungu|Coklat', 'correct_index': 2, 'explanation': 'Blue + Red = Purple!'},
      {'quiz_id': q11Id, 'question': 'What is used to stick things together?', 'question_ms': 'Apa yang digunakan untuk melekatkan benda?', 'options': 'Paint|Water|Glue|Crayon', 'options_ms': 'Cat|Air|Gam|Krayon', 'correct_index': 2, 'explanation': 'Glue sticks things together!'},
      {'quiz_id': q11Id, 'question': 'Which tool makes straight lines?', 'question_ms': 'Alat manakah membuat garis lurus?', 'options': 'Brush|Ruler|Eraser|Crayon', 'options_ms': 'Berus|Pembaris|Pemadam|Krayon', 'correct_index': 1, 'explanation': 'A ruler helps draw straight lines!'},
      {'quiz_id': q11Id, 'question': 'What is origami?', 'question_ms': 'Apakah origami?', 'options': 'Paper painting|Paper folding|Paper cutting|Paper gluing', 'options_ms': 'Melukis kertas|Melipat kertas|Memotong kertas|Melekat kertas', 'correct_index': 1, 'explanation': 'Origami is the art of paper folding!'},
    ];

    // ---- Quiz 12: Weather & Nature ----
    final q12Id = await db.insert('quizzes', {
      'title': 'Weather & Nature',
      'title_ms': 'Cuaca & Alam Semula Jadi',
      'category_id': cIds.length > 3 ? cIds[3] : cIds[0],
      'age_group': 'all',
      'emoji': '🌤️',
      'high_score': 0,
      'is_completed': 0,
    });
    final q12 = [
      {'quiz_id': q12Id, 'question': 'What causes rain?', 'question_ms': 'Apa yang menyebabkan hujan?', 'options': 'Wind|Clouds|Sun|Moon', 'options_ms': 'Angin|Awan|Matahari|Bulan', 'correct_index': 1, 'explanation': 'Clouds release water droplets that fall as rain!'},
      {'quiz_id': q12Id, 'question': 'What appears after rain when the sun shines?', 'question_ms': 'Apa yang muncul selepas hujan apabila matahari bersinar?', 'options': 'Snow|Storm|Rainbow|Thunder', 'options_ms': 'Salji|Ribut|Pelangi|Guruh', 'correct_index': 2, 'explanation': 'Rainbows appear after rain in sunshine!'},
      {'quiz_id': q12Id, 'question': 'What is frozen water called?', 'question_ms': 'Apakah nama air yang membeku?', 'options': 'Steam|Cloud|Ice|Fog', 'options_ms': 'Wap|Awan|Ais|Kabus', 'correct_index': 2, 'explanation': 'Frozen water is called ice!'},
      {'quiz_id': q12Id, 'question': 'Which season has the most flowers blooming?', 'question_ms': 'Musim manakah yang paling banyak bunga mekar?', 'options': 'Winter|Autumn|Spring|Summer', 'options_ms': 'Musim sejuk|Musim luruh|Musim bunga|Musim panas', 'correct_index': 2, 'explanation': 'Spring is when most flowers bloom!'},
      {'quiz_id': q12Id, 'question': 'What do we call a very strong wind with rain?', 'question_ms': 'Apa nama angin kencang dengan hujan?', 'options': 'Breeze|Tornado|Storm|Fog', 'options_ms': 'Angin sepoi|Tornado|Ribut|Kabus', 'correct_index': 2, 'explanation': 'A storm is strong wind with heavy rain!'},
    ];

    for (final q in [
      ...q5, ...q6, ...q7, ...q8, ...q9, ...q10, ...q11, ...q12,
    ]) {
      await db.insert('quiz_questions', q);
    }
  }
}
