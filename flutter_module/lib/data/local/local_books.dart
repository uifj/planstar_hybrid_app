import '../../domain/model/book.dart';
import '../../domain/model/book_detail.dart';
import '../../domain/model/book_page.dart';
import '../../domain/model/chapter.dart';

/// 本地书单：网络不可用或返回空数据时兜底，保证书城仍有可浏览内容。
///
/// 字段与原项目 `BookItem` 对齐，后续接入原生接口时可零转换。
class LocalBooksDataSource {
  /// 书城分类 Tab；网络书的分类统一映射为「文学」，因此不在此列。
  static const List<String> categories = [
    '玄幻',
    '都市',
    '言情',
    '科幻',
    '悬疑',
    '历史',
    '军事',
    '游戏',
    '体育',
    '短篇',
  ];

  static const List<Book> books = [
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

  /// 只在首屏兜底时使用，因此不实现真正的分页切片。
  BookPage firstPage() => const BookPage(items: books, page: 1, hasMore: false);

  BookPage search(String query) {
    final keyword = query.trim();
    final matched = books
        .where(
          (book) =>
              book.bookName.contains(keyword) ||
              book.authorName.contains(keyword) ||
              book.categoryName == keyword,
        )
        .toList();
    return BookPage(items: matched, page: 1, hasMore: false);
  }

  Book? findById(int bookId) {
    for (final book in books) {
      if (book.bookId == bookId) return book;
    }
    return null;
  }

  BookDetail detailOf(Book book) =>
      BookDetail(book: book, chapters: chaptersOf(book));

  /// 目录给前 30 章：与详情页展示上限一致，避免一次性构建上千条列表项。
  List<Chapter> chaptersOf(Book book) {
    final count = book.chapterCount > 30 ? 30 : book.chapterCount;
    return List.generate(
      count,
      (index) =>
          Chapter(index: index + 1, title: '第${index + 1}章 章节${index + 1}'),
    );
  }
}
