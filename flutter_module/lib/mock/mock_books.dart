/// 书城 / 书详情页使用的本地模拟数据。
///
/// 字段命名与原项目 domain 模型 `BookItem` 对齐（BookId / BookName / Author /
/// BookCategoryName / Description / WordsCount / BookStatus），
/// 便于后续接入原生侧同一套接口数据时零转换。
class Book {
  final int bookId;
  final String bookName;
  final String authorName;
  final String categoryName;
  final String description;

  /// 章节总数（对应原 BookItem.ChapterCount）
  final int chapterCount;

  /// 总字数，单位「字」（对应原 BookItem.WordsCount）
  final int wordsCount;

  /// "1" 连载 / "2" 完本（对应原 BookItem.BookStatus）
  final String bookStatus;

  /// 评分，0-100（对应原 BookDetailItem.BookStar）
  final int bookStar;

  const Book({
    required this.bookId,
    required this.bookName,
    required this.authorName,
    required this.categoryName,
    required this.description,
    required this.chapterCount,
    required this.wordsCount,
    required this.bookStatus,
    required this.bookStar,
  });

  bool get finished => bookStatus == '2';

  /// 字数展示（与原项目一致，按「万字」取整）
  int get wordsInWan => (wordsCount / 10000).round();
}

const List<String> categoryList = [
  '玄幻', '都市', '言情', '科幻', '悬疑', '历史', '军事', '游戏', '体育', '短篇',
];

const List<Book> mockBooks = [
  Book(
    bookId: 1013391,
    bookName: '元尊',
    authorName: '天蚕土豆',
    categoryName: '玄幻',
    description: '大周王朝少年周元，觉醒了祖龙之血，从此踏上了一路披荆斩棘的传奇之路。',
    chapterCount: 1620,
    wordsCount: 4830000,
    bookStatus: '2',
    bookStar: 92,
  ),
  Book(
    bookId: 1023384,
    bookName: '万相之王',
    authorName: '天蚕土豆',
    categoryName: '玄幻',
    description: '李洛为救母亲，踏上了修行之路，一步步揭开万相之间的秘密。',
    chapterCount: 1189,
    wordsCount: 3560000,
    bookStatus: '1',
    bookStar: 91,
  ),
  Book(
    bookId: 1000000,
    bookName: '大道朝天',
    authorName: '猫腻',
    categoryName: '玄幻',
    description: '井底之蛙，也知天之大。问天问道，问的是自己的本心。',
    chapterCount: 782,
    wordsCount: 2360000,
    bookStatus: '2',
    bookStar: 94,
  ),
  Book(
    bookId: 1010477,
    bookName: '赘婿',
    authorName: '愤怒的香蕉',
    categoryName: '历史',
    description: '一个现代金融精英穿越到古代商贾之家，一步步成为帝国最强大的商人。',
    chapterCount: 1410,
    wordsCount: 4180000,
    bookStatus: '2',
    bookStar: 95,
  ),
  Book(
    bookId: 1010384,
    bookName: '诡秘之主',
    authorName: '爱潜水的乌贼',
    categoryName: '悬疑',
    description: '蒸汽与机械的世界里，一个愚者从死亡中苏醒，开始了一场漫长的扮演。',
    chapterCount: 1433,
    wordsCount: 4460000,
    bookStatus: '2',
    bookStar: 97,
  ),
  Book(
    bookId: 1030001,
    bookName: '宿命之环',
    authorName: '爱潜水的乌贼',
    categoryName: '悬疑',
    description: '诡秘世界的新篇章，克莱恩之后，新的命运之环缓缓转动。',
    chapterCount: 521,
    wordsCount: 1580000,
    bookStatus: '1',
    bookStar: 90,
  ),
  Book(
    bookId: 1010495,
    bookName: '庆余年',
    authorName: '猫腻',
    categoryName: '历史',
    description: '一个有着现代灵魂的私生子，在庆国的朝堂与江湖之间游走。',
    chapterCount: 1001,
    wordsCount: 3060000,
    bookStatus: '2',
    bookStar: 96,
  ),
  Book(
    bookId: 1028167,
    bookName: '夜的命名术',
    authorName: '会说话的肘子',
    categoryName: '科幻',
    description: '在废土与赛博之间，少年阿夜手握世界的钥匙。',
    chapterCount: 682,
    wordsCount: 2080000,
    bookStatus: '2',
    bookStar: 93,
  ),
  Book(
    bookId: 1027012,
    bookName: '大奉打更人',
    authorName: '卖报小郎君',
    categoryName: '悬疑',
    description: '穿越而来的打更人许七安，从刑狱中走出，一路高歌猛进。',
    chapterCount: 1090,
    wordsCount: 3300000,
    bookStatus: '2',
    bookStar: 95,
  ),
  Book(
    bookId: 1009735,
    bookName: '凡人修仙传',
    authorName: '忘语',
    categoryName: '玄幻',
    description: '一个普通山村少年，误入江湖门派，从此踏上修仙长路。',
    chapterCount: 2429,
    wordsCount: 7450000,
    bookStatus: '2',
    bookStar: 94,
  ),
  Book(
    bookId: 1030002,
    bookName: '夜的守望者',
    authorName: '会说话的肘子',
    categoryName: '都市',
    description: '都市夜幕之下，一个守望者守护着属于普通人的日常。',
    chapterCount: 412,
    wordsCount: 1240000,
    bookStatus: '1',
    bookStar: 88,
  ),
  Book(
    bookId: 1009871,
    bookName: '择天记',
    authorName: '猫腻',
    categoryName: '玄幻',
    description: '少年陈长生，逆天改命，一纸文书掀动天下风云。',
    chapterCount: 1029,
    wordsCount: 3180000,
    bookStatus: '2',
    bookStar: 92,
  ),
];

/// 根据书籍生成章节列表（章节名与原项目目录格式一致）。
List<String> chaptersOf(Book book) {
  final n = book.chapterCount > 20 ? 20 : book.chapterCount;
  return List.generate(n, (i) => '第${i + 1}章 章节${i + 1}');
}
